import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
    apiKey: 'AIzaSyD10lAtuJ4dtlvMEq1IWnhqWTdwTwz2ONs',
    appId: '1:488848209199:android:da96ee3b48c10e49111dda',
    messagingSenderId: '488848209199', projectId: 'mh-solar-daily-rates',
    storageBucket: 'mh-solar-daily-rates.firebasestorage.app',
  ));
  runApp(const MHSolarApp());
}

class MHSolarApp extends StatelessWidget {
  const MHSolarApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'MH Solar Daily Rates',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF159447), scaffoldBackgroundColor: const Color(0xFFF4F7F5)),
    home: const HomePage(),
  );
}

class SolarRate {
  final String id, brand, model, watt, category; final int price;
  const SolarRate({required this.id, required this.brand, required this.model, required this.watt, required this.price, required this.category});
  factory SolarRate.fromDocument(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data()??{}; final w=d['watt']; final p=d['price'];
    return SolarRate(id:doc.id, brand:d['brand']?.toString()??'Unknown', model:d['model']?.toString()??'', watt:w is num?'${w.toInt()}W':'${w??''}', price:p is num?p.toInt():int.tryParse('${p??''}'.replaceAll(',',''))??0, category:d['category']?.toString()??'Solar Panel');
  }
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  String search='', category='All'; final searchController=TextEditingController();
  String get today=>DateFormat('dd MMMM yyyy').format(DateTime.now());
  Stream<List<SolarRate>> get ratesStream=>FirebaseFirestore.instance.collection('solar_rates').snapshots().map((s)=>s.docs.map(SolarRate.fromDocument).where((r)=>r.price>0).toList());
  Future<void> openWhatsApp() async { final u=Uri.parse('https://wa.me/923366760264?text=Assalam%20o%20Alaikum%2C%20mujhe%20aaj%20ke%20solar%20rates%20chahiye.'); if(await canLaunchUrl(u)) await launchUrl(u,mode:LaunchMode.externalApplication); }
  Future<void> shareRates(List<SolarRate> rates) async { final b=StringBuffer('☀️ MH SOLAR & ELECTRONICS\n📅 Daily Solar Rates — $today\n\n'); for(final r in rates)b.writeln('${r.brand} ${r.watt}: Rs. ${NumberFormat('#,###').format(r.price)}'); b.writeln('\n📞 0336-6760264\n📍 Sialkot, Punjab'); await Share.share(b.toString()); }
  @override Widget build(BuildContext context)=>StreamBuilder<List<SolarRate>>(stream:ratesStream,builder:(context,snapshot){
    final all=snapshot.data??const <SolarRate>[]; final cats=['All',...{for(final r in all)r.category}];
    final filtered=all.where((r){final q=search.toLowerCase(); return (category=='All'||r.category==category)&&'${r.brand} ${r.model} ${r.watt} ${r.category}'.toLowerCase().contains(q);}).toList();
    return Scaffold(appBar:AppBar(backgroundColor:Colors.green.shade700,foregroundColor:Colors.white,title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('MH SOLAR',style:TextStyle(fontWeight:FontWeight.w900)),Text('& ELECTRONICS',style:TextStyle(fontSize:10,letterSpacing:1.5))]),actions:[IconButton(tooltip:'Admin',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage())),icon:const Icon(Icons.admin_panel_settings)),IconButton(tooltip:'Share',onPressed:filtered.isEmpty?null:()=>shareRates(filtered),icon:const Icon(Icons.share))]),
      body:RefreshIndicator(onRefresh:()async{await FirebaseFirestore.instance.collection('solar_rates').get(const GetOptions(source:Source.server));},child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,28),children:[
        Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:LinearGradient(colors:[Colors.green.shade900,Colors.green.shade500]),borderRadius:BorderRadius.circular(24)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.solar_power,color:Colors.white,size:44),SizedBox(height:8),Text("Today's Solar Rates",style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('Live market rates • MH Solar & Electronics',style:TextStyle(color:Colors.white70))])),
        const SizedBox(height:14),Row(children:[Expanded(child:_InfoCard(icon:Icons.calendar_month,title:'Updated',value:today)),const SizedBox(width:10),const Expanded(child:_InfoCard(icon:Icons.location_on,title:'Market',value:'Sialkot'))]),const SizedBox(height:16),
        TextField(controller:searchController,onChanged:(v)=>setState(()=>search=v),decoration:InputDecoration(hintText:'Search brand, model or watt...',prefixIcon:const Icon(Icons.search),suffixIcon:search.isEmpty?null:IconButton(onPressed:(){searchController.clear();setState(()=>search='');},icon:const Icon(Icons.clear)),filled:true,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none))),const SizedBox(height:12),
        SizedBox(height:42,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:cats.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){final c=cats[i];return ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c));})),const SizedBox(height:18),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('☀️ Daily Rates',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Text('${filtered.length} items',style:const TextStyle(color:Colors.grey))]),const SizedBox(height:10),
        if(snapshot.connectionState==ConnectionState.waiting)const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator())) else if(snapshot.hasError)const _MessageCard(icon:Icons.cloud_off,title:'Rates unavailable',message:'Check internet connection and Firebase rules.') else if(all.isEmpty)const _MessageCard(icon:Icons.price_check,title:'No rates added yet',message:'Open Admin and add your products.') else if(filtered.isEmpty)const _MessageCard(icon:Icons.search_off,title:'No matching rates',message:'Try another search or category.') else ...filtered.map((r)=>_RateCard(rate:r)),
        const SizedBox(height:8),Row(children:[Expanded(child:FilledButton.icon(onPressed:filtered.isEmpty?null:()=>shareRates(filtered),icon:const Icon(Icons.share),label:const Text('Share Rates'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:openWhatsApp,icon:const Icon(Icons.chat),label:const Text('WhatsApp')))]),const SizedBox(height:20),const Center(child:Text('Powering the Future • MH Solar & Electronics',style:TextStyle(color:Colors.grey)))
      ]));
  });
}
class _InfoCard extends StatelessWidget { final IconData icon; final String title,value; const _InfoCard({required this.icon,required this.title,required this.value}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(icon,color:Colors.green),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.grey)),Text(value,style:const TextStyle(fontWeight:FontWeight.bold))]))]))); }
class _RateCard extends StatelessWidget { final SolarRate rate; const _RateCard({required this.rate}); @override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(leading:CircleAvatar(backgroundColor:Colors.green.shade50,child:const Icon(Icons.wb_sunny,color:Colors.green)),title:Text(rate.brand,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${rate.model} • ${rate.watt}\n${rate.category}'),isThreeLine:true,trailing:Text('Rs. ${NumberFormat('#,###').format(rate.price)}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15))); }
class _MessageCard extends StatelessWidget { final IconData icon; final String title,message; const _MessageCard({required this.icon,required this.title,required this.message}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[Icon(icon,size:46,color:Colors.green),const SizedBox(height:10),Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(message,textAlign:TextAlign.center)]))); }
