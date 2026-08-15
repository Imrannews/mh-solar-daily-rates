import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final uid = credential.user!.uid;
      final adminDoc = await _db.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('This account is not registered as an MH Solar admin.');
      }
      setState(() => _user = credential.user);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed.');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) setState(() => _user = null);
  }

  Future<void> _saveRate({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final brand = TextEditingController();
    final model = TextEditingController();
    final watt = TextEditingController();
    final price = TextEditingController();
    final category = TextEditingController(text: 'Solar Panel');

    if (doc != null) {
      final d = doc.data() ?? {};
      brand.text = d['brand']?.toString() ?? '';
      model.text = d['model']?.toString() ?? '';
      watt.text = d['watt']?.toString() ?? '';
      price.text = d['price']?.toString() ?? '';
      category.text = d['category']?.toString() ?? 'Solar Panel';
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? 'Add Solar Rate' : 'Edit Solar Rate'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(brand, 'Brand', Icons.business),
              _field(model, 'Model', Icons.solar_power),
              _field(watt, 'Watt (e.g. 585)', Icons.bolt, number: true),
              _field(price, 'Price (Rs.)', Icons.payments, number: true),
              _field(category, 'Category', Icons.category),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final wattValue = int.tryParse(watt.text.trim());
              final priceValue = int.tryParse(price.text.trim().replaceAll(',', ''));
              if (brand.text.trim().isEmpty || model.text.trim().isEmpty || wattValue == null || priceValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid brand, model, watt and price.')));
                return;
              }
              final data = <String, dynamic>{
                'brand': brand.text.trim(),
                'model': model.text.trim(),
                'watt': wattValue,
                'price': priceValue,
                'category': category.text.trim().isEmpty ? 'Solar Panel' : category.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (doc == null) {
                await _db.collection('solar_rates').add(data);
              } else {
                await doc.reference.update(data);
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    brand.dispose();
    model.dispose();
    watt.dispose();
    price.dispose();
    category.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate saved successfully.')));
    }
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> _deleteRate(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final name = '${doc.data()?['brand'] ?? ''} ${doc.data()?['model'] ?? ''}'.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete rate?'),
        content: Text('Delete $name from the daily rates?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await doc.reference.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return _loginView();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MH Solar Admin'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveRate(),
        icon: const Icon(Icons.add),
        label: const Text('Add Rate'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('solar_rates').orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load rates: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No rates yet. Tap Add Rate.'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data();
              final price = d['price'];
              final updated = d['updatedAt'];
              final updatedText = updated is Timestamp ? DateFormat('dd MMM, hh:mm a').format(updated.toDate()) : 'Just updated';
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.solar_power)),
                  title: Text('${d['brand'] ?? ''} ${d['watt'] ?? ''}W'),
                  subtitle: Text('${d['model'] ?? ''} • ${d['category'] ?? ''}\n$updatedText'),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(child: Text('Rs. ${NumberFormat('#,###').format(price is num ? price : int.tryParse('$price') ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _saveRate(doc: doc);
                            if (value == 'delete') _deleteRate(doc);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _loginView() {
    return Scaffold(
      appBar: AppBar(title: const Text('MH Solar Admin Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 72, color: Colors.green),
                const SizedBox(height: 14),
                const Text('Admin Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Only authorized MH Solar administrators can change rates.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 16),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center)),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _login, icon: const Icon(Icons.login), label: Text(_busy ? 'Signing in...' : 'Sign in'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
