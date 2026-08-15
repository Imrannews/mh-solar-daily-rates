import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD10lAtuJ4dtlvMEq1IWnhqWTdwTwz2ONs',
      appId: '1:488848209199:android:da96ee3b48c10e49111dda',
      messagingSenderId: '488848209199',
      projectId: 'mh-solar-daily-rates',
      storageBucket: 'mh-solar-daily-rates.firebasestorage.app',
    ),
  );
  runApp(const MHSolarApp());
}

class MHSolarApp extends StatelessWidget {
  const MHSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MH Solar Daily Rates',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF159447),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class SolarRate {
  final String id;
  final String brand;
  final String model;
  final String watt;
  final int price;
  final String category;

  const SolarRate({
    required this.id,
    required this.brand,
    required this.model,
    required this.watt,
    required this.price,
    required this.category,
  });

  factory SolarRate.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawWatt = data['watt'];
    final watt = rawWatt is num ? '${rawWatt.toInt()}W' : (rawWatt?.toString() ?? '');
    final rawPrice = data['price'];
    final price = rawPrice is num ? rawPrice.toInt() : int.tryParse(rawPrice?.toString().replaceAll(',', '') ?? '') ?? 0;
    return SolarRate(
      id: doc.id,
      brand: data['brand']?.toString() ?? 'Unknown Brand',
      model: data['model']?.toString() ?? '',
      watt: watt,
      price: price,
      category: data['category']?.toString() ?? 'Solar Panel',
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String get today => DateFormat('dd MMMM yyyy').format(DateTime.now());

  Stream<List<SolarRate>> get ratesStream {
    return FirebaseFirestore.instance
        .collection('solar_rates')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SolarRate.fromDocument).where((rate) => rate.price > 0).toList());
  }

  Future<void> openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/923366760264?text=Assalam%20o%20Alaikum%2C%20mujhe%20aaj%20ke%20solar%20rates%20chahiye.');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareRates(BuildContext context, List<SolarRate> rates) async {
    if (rates.isEmpty) return;
    final text = StringBuffer('☀️ MH SOLAR & ELECTRONICS\n📅 Daily Solar Panel Rates — $today\n\n');
    for (final rate in rates) {
      text.writeln('${rate.brand} ${rate.watt}: Rs. ${NumberFormat('#,###').format(rate.price)}');
    }
    text.writeln('\n📞 0336-6760264');
    text.writeln('📍 Sialkot, Punjab');
    await Share.share(text.toString());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SolarRate>>(
      stream: ratesStream,
      builder: (context, snapshot) {
        final rates = snapshot.data ?? const <SolarRate>[];
        final loading = snapshot.connectionState == ConnectionState.waiting;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MH SOLAR', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('& ELECTRONICS', style: TextStyle(fontSize: 11, letterSpacing: 1.2)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Admin',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
                icon: const Icon(Icons.admin_panel_settings),
              ),
              IconButton(
                onPressed: rates.isEmpty ? null : () => shareRates(context, rates),
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance.collection('solar_rates').get(const GetOptions(source: Source.server));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade500]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.solar_power, color: Colors.white, size: 42),
                      SizedBox(height: 10),
                      Text('Today’s Solar Rates', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Live rates from MH Solar & Electronics', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _InfoCard(icon: Icons.calendar_month, title: 'Updated', value: today)),
                  const SizedBox(width: 12),
                  const Expanded(child: _InfoCard(icon: Icons.location_on, title: 'Market', value: 'Sialkot')),
                ]),
                const SizedBox(height: 22),
                const Text('☀️ Solar Panel Rates', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  const _MessageCard(icon: Icons.cloud_off, title: 'Rates unavailable', message: 'Please check your internet connection or Firestore rules.')
                else if (rates.isEmpty)
                  const _MessageCard(icon: Icons.price_check, title: 'No rates added yet', message: 'Add products to the solar_rates collection in Firebase.')
                else
                  ...rates.map((rate) => _RateCard(rate: rate)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(onPressed: rates.isEmpty ? null : () => shareRates(context, rates), icon: const Icon(Icons.share), label: const Text('Share Rates'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: openWhatsApp, icon: const Icon(Icons.chat), label: const Text('WhatsApp'))),
                ]),
                const SizedBox(height: 20),
                const Center(child: Text('Powering the Future • MH Solar & Electronics', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: Colors.green), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))])));
}

class _RateCard extends StatelessWidget {
  final SolarRate rate;
  const _RateCard({required this.rate});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.wb_sunny, color: Colors.green)), title: Text(rate.brand, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${rate.model} • ${rate.watt}'), trailing: Text('Rs. ${NumberFormat('#,###').format(rate.price)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))));
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _MessageCard({required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [Icon(icon, size: 42, color: Colors.green), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center)])));
}
