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
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool busy = false;
  String? error;
  User? user;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final adminDoc = await db.collection('admins').doc(credential.user!.uid).get();
      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        await auth.signOut();
        throw Exception('This account is not registered as an MH Solar admin.');
      }
      if (mounted) {
        setState(() => user = credential.user);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Login failed.');
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    if (mounted) setState(() => user = null);
  }

  Widget inputField(TextEditingController controller, String label, IconData icon, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> saveRate({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final brand = TextEditingController();
    final model = TextEditingController();
    final watt = TextEditingController();
    final price = TextEditingController();
    String category = 'Solar Panel';
    bool offer = false;

    if (doc != null) {
      final data = doc.data() ?? {};
      brand.text = '${data['brand'] ?? ''}';
      model.text = '${data['model'] ?? ''}';
      watt.text = '${data['watt'] ?? ''}';
      price.text = '${data['price'] ?? ''}';
      category = '${data['category'] ?? 'Solar Panel'}';
      offer = data['isOffer'] == true;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: Text(doc == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    inputField(brand, 'Brand', Icons.business),
                    inputField(model, 'Model / Capacity', Icons.solar_power),
                    inputField(watt, 'Watt / Size', Icons.bolt, number: true),
                    inputField(price, 'Price (Rs.)', Icons.payments, number: true),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        'Solar Panel',
                        'Inverter',
                        'Battery',
                        'Accessory',
                      ].map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                      onChanged: (value) {
                        setDialog(() => category = value ?? 'Solar Panel');
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Special Offer'),
                      value: offer,
                      onChanged: (value) {
                        setDialog(() => offer = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final w = int.tryParse(watt.text.trim());
                    final p = int.tryParse(price.text.trim().replaceAll(',', ''));
                    if (brand.text.trim().isEmpty || model.text.trim().isEmpty || w == null || p == null) {
                      return;
                    }
                    final data = <String, dynamic>{
                      'brand': brand.text.trim(),
                      'model': model.text.trim(),
                      'watt': w,
                      'price': p,
                      'category': category,
                      'isOffer': offer,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (doc == null) {
                      await db.collection('solar_rates').add(data);
                    } else {
                      await doc.reference.update(data);
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    brand.dispose();
    model.dispose();
    watt.dispose();
    price.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully.')),
      );
    }
  }

  Future<void> deleteRate(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete ${data['brand'] ?? ''} ${data['model'] ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await doc.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return loginView();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MH Solar Admin'),
        actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => saveRate(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('solar_rates').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load products: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = [...snapshot.data!.docs];
          docs.sort((a, b) {
            final at = a.data()['updatedAt'];
            final bt = b.data()['updatedAt'];
            final ad = at is Timestamp ? at.toDate() : DateTime(1970);
            final bd = bt is Timestamp ? bt.toDate() : DateTime(1970);
            return bd.compareTo(ad);
          });

          if (docs.isEmpty) return const Center(child: Text('No products yet. Tap Add Product.'));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final priceValue = data['price'];
              final price = priceValue is num ? priceValue.toInt() : int.tryParse('$priceValue') ?? 0;
              final category = '${data['category'] ?? ''}';
              final icon = category == 'Battery'
                  ? Icons.battery_full
                  : category == 'Inverter'
                      ? Icons.electric_bolt
                      : Icons.solar_power;

              String dateText = 'Existing rate';
              final updated = data['updatedAt'];
              if (updated is Timestamp) {
                dateText = DateFormat('dd MMM, hh:mm a').format(updated.toDate());
              }

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(icon)),
                  title: Text(
                    '${data['brand'] ?? ''} • ${data['model'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$category • ${data['watt'] ?? ''}\n${data['isOffer'] == true ? '🔥 SPECIAL OFFER • ' : ''}$dateText',
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 125,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rs. ${NumberFormat('#,###').format(price)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') saveRate(doc: doc);
                            if (value == 'delete') deleteRate(doc);
                          },
                          itemBuilder: (context) => const [
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

  Widget loginView() {
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
                const Text(
                  'Manage panels, inverters, batteries, accessories and offers.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Admin email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : login,
                    icon: const Icon(Icons.login),
                    label: Text(busy ? 'Signing in...' : 'Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
