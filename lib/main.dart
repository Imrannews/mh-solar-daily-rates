import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MHSolarApp());

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
  final String brand;
  final String model;
  final String watt;
  final int price;
  const SolarRate(this.brand, this.model, this.watt, this.price);
}

const rates = <SolarRate>[
  SolarRate('Jinko Solar', '585W N-Type', '585W', 24500),
  SolarRate('Canadian Solar', '585W N-Type', '585W', 24800),
  SolarRate('LONGi', 'Hi-MO Series', '585W', 24600),
  SolarRate('JA Solar', 'N-Type', '625W', 26500),
  SolarRate('AIKO', 'ABC Series', '650W', 28500),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String get today => DateFormat('dd MMMM yyyy').format(DateTime.now());

  Future<void> openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/923366760264?text=Assalam%20o%20Alaikum%2C%20mujhe%20aaj%20ke%20solar%20rates%20chahiye.');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareRates() async {
    final text = StringBuffer('☀️ MH SOLAR & ELECTRONICS\n📅 Daily Solar Panel Rates — $today\n\n');
    for (final r in rates) {
      text.writeln('${r.brand} ${r.watt}: Rs. ${NumberFormat('#,###').format(r.price)}');
    }
    text.writeln('\n📞 0336-6760264');
    text.writeln('📍 Sialkot, Punjab');
    await Share.share(text.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MH SOLAR', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('& ELECTRONICS', style: TextStyle(fontSize: 11, letterSpacing: 1.2)),
        ]),
        actions: [
          IconButton(onPressed: shareRates, icon: const Icon(Icons.share)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade500]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.solar_power, color: Colors.white, size: 42),
                SizedBox(height: 10),
                Text('Today’s Solar Rates', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Fresh market rates from MH Solar & Electronics', style: TextStyle(color: Colors.white70)),
              ]),
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
            ...rates.map((r) => _RateCard(rate: r)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: shareRates, icon: const Icon(Icons.share), label: const Text('Share Rates'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: openWhatsApp, icon: const Icon(Icons.chat), label: const Text('WhatsApp'))),
            ]),
            const SizedBox(height: 20),
            const Center(child: Text('Powering the Future • MH Solar & Electronics', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String title; final String value;
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
