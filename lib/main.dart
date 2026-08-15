import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_page.dart';

const green = Color(0xFF078A43);
const darkGreen = Color(0xFF06452A);
const gold = Color(0xFFFFC107);

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
      title: 'MH Solar & Electronics',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: green),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int page = 0;

  final pages = const [
    HomePage(),
    RatesPage(),
    ProductsPage(),
    AdminPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text('MH SOLAR & ELECTRONICS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      body: pages[page],
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.price_change_outlined), selectedIcon: Icon(Icons.price_change), label: 'Daily Rates'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [darkGreen, green]),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wb_sunny, color: gold, size: 55),
              SizedBox(height: 8),
              Text('DAILY SOLAR RATES', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Latest solar market rates for Sialkot', style: TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('MH Solar & Electronics', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Solar Panels • Inverters • Batteries • Accessories', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        _homeCard(Icons.solar_power, 'Solar Panels', 'Check latest panel prices'),
        _homeCard(Icons.electric_bolt, 'Inverters', 'Fronus, Solis and more'),
        _homeCard(Icons.battery_full, 'Batteries', 'Latest battery rates'),
        _homeCard(Icons.local_offer, 'Special Offers', 'Check current deals'),
        const SizedBox(height: 15),
        const AddressBox(),
      ],
    );
  }

  Widget _homeCard(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE7F5EC), child: Icon(icon, color: green)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class RatesPage extends StatelessWidget {
  const RatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('solar_rates').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Rates error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('☀️ TODAY\'S SOLAR RATES', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(DateFormat('dd MMMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            if (docs.isEmpty) const EmptyBox() else ...docs.map((doc) => RateCard(data: doc.data())),
            const SizedBox(height: 12),
            const AddressBox(),
          ],
        );
      },
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Panels', icon: Icon(Icons.solar_power)),
              Tab(text: 'Inverters', icon: Icon(Icons.electric_bolt)),
              Tab(text: 'Batteries', icon: Icon(Icons.battery_full)),
              Tab(text: 'Accessories', icon: Icon(Icons.settings)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: const [
                CategoryList(category: 'Solar Panel'),
                CategoryList(category: 'Inverter'),
                CategoryList(category: 'Battery'),
                CategoryList(category: 'Accessory'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final String category;
  const CategoryList({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('solar_rates').where('category', isEqualTo: category).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No $category products yet.'));
        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((doc) => RateCard(data: doc.data())).toList(),
        );
      },
    );
  }
}

class RateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const RateCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final price = data['price'];
    final priceText = NumberFormat('#,###').format(price is num ? price : int.tryParse('$price') ?? 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFE7F5EC), child: Icon(Icons.solar_power, color: green)),
        title: Text('${data['brand'] ?? 'Product'} ${data['model'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${data['category'] ?? ''} • ${data['watt'] ?? ''}'),
        trailing: Text('Rs. $priceText', style: const TextStyle(color: green, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class AddressBox extends StatelessWidget {
  const AddressBox({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [darkGreen, green]), borderRadius: BorderRadius.circular(20)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MH SOLAR & ELECTRONICS', style: TextStyle(color: gold, fontSize: 17, fontWeight: FontWeight.w900)),
        SizedBox(height: 10),
        Text('Near Emnabad Sweets, Pulli Kammanwala, Chaprar Road, Sialkot', style: TextStyle(color: Colors.white, height: 1.4)),
        SizedBox(height: 8),
        Text('📞 0336-6760264', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class EmptyBox extends StatelessWidget {
  const EmptyBox({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No rates available. Add rates from Admin.', textAlign: TextAlign.center)));
}
