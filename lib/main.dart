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
    debugShowCheckedModeBanner: false, title: 'MH Solar & Electronics',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF159447), scaffoldBackgroundColor: const Color(0xFFF5F8F6)),
    home: const AppShell(),
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

class AppShell extends StatefulWidget { const AppShell({super.key}); @override State<AppShell> createState()=>_AppShellState(); }
class _AppShellState extends State<AppShell> {
  int index=0;
  final pages=const [
    HomePage(), PanelsPage(), InvertersPage(), BatteriesPage(), AccessoriesPage(), OffersPage(), DailyRatesPage(), ContactPage()
  ];
  final titles=['Home','Solar Panels','Inverters','Batteries','Accessories','Special Offers','Daily Rates','Contact Us'];
  final icons=[Icons.home,Icons.solar_power,Icons.electric_bolt,Icons.battery_full,Icons.settings_input_component,Icons.local_offer,Icons.price_change,Icons.phone];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(backgroundColor:Colors.green.shade700,foregroundColor:Colors.white,title:Text('MH SOLAR • ${titles[index]}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),actions:[IconButton(tooltip:'Admin',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage())),icon:const Icon(Icons.admin_panel_settings))]),
    drawer:Drawer(child:SafeArea(child:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(20,28,20,24),color:Colors.green.shade700,child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.solar_power,color:Colors.white,size:46),SizedBox(height:8),Text('MH SOLAR & ELECTRONICS',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),Text('Powering the Future • Sialkot',style:TextStyle(color:Colors.white70))])),
      Expanded(child:ListView.builder(itemCount:titles.length,itemBuilder:(c,i)=>ListTile(leading:Icon(icons[i],color:index==i?Colors.green:null),title:Text(titles[i],style:TextStyle(fontWeight:index==i?FontWeight.bold:FontWeight.normal)),selected:index==i,onTap:(){setState(()=>index=i);Navigator.pop(context);}))),
      const Divider(),ListTile(leading:const Icon(Icons.admin_panel_settings),title:const Text('Admin Panel'),onTap:(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage()));}),
    ]))),
    body:IndexedStack(index:index,children:pages),
  );
}

class HomePage extends StatelessWidget { const HomePage({super.key});
  @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('solar_rates').snapshots(),builder:(c,s){
    final rates=s.data?.docs.map(SolarRate.fromDocument).where((r)=>r.price>0).toList()??[];
    final brands={for(final r in rates)r.brand}.toList();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:LinearGradient(colors:[Colors.green.shade900,Colors.green.shade500]),borderRadius:BorderRadius.circular(26)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.wb_sunny,color:Colors.white,size:52),SizedBox(height:8),Text('Daily Solar Market',style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Live rates, panels, inverters & batteries',style:TextStyle(color:Colors.white70,fontSize:15))])),
      const SizedBox(height:16),Row(children:[_Dash(icon:Icons.solar_power,label:'Panels',value:'${rates.where((r)=>r.category.toLowerCase().contains('panel')).length}'),_Dash(icon:Icons.electric_bolt,label:'Inverters',value:'${rates.where((r)=>r.category.toLowerCase().contains('inverter')).length}'),_Dash(icon:Icons.battery_full,label:'Batteries',value:'${rates.where((r)=>r.category.toLowerCase().contains('battery')).length}')]),
      const SizedBox(height:20),const Text('Explore Categories',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.45,children:[_HomeTile(icon:Icons.solar_power,title:'Solar Panels',onTap:()=>_go(context,1)),_HomeTile(icon:Icons.electric_bolt,title:'Inverters',onTap:()=>_go(context,2)),_HomeTile(icon:Icons.battery_full,title:'Batteries',onTap:()=>_go(context,3)),_HomeTile(icon:Icons.settings_input_component,title:'Accessories',onTap:()=>_go(context,4)),_HomeTile(icon:Icons.local_offer,title:'Special Offers',onTap:()=>_go(context,5)),_HomeTile(icon:Icons.price_change,title:'Daily Rates',onTap:()=>_go(context,6))]),
      const SizedBox(height:20),Text('Popular Brands',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:brands.map((b)=>Chip(label:Text(b))).toList()),
      const SizedBox(height:18),FilledButton.icon(onPressed:()=>_go(context,7),icon:const Icon(Icons.phone),label:const Text('Contact MH Solar Sialkot')),
    ]);
  });
}
void _go(BuildContext context,int i){final shell=context.findAncestorStateOfType<_AppShellState>();shell?.setState(()=>shell.index=i);}

class _Dash extends StatelessWidget {final IconData icon;final String label,value;const _Dash({required this.icon,required this.label,required this.value});@override Widget build(BuildContext c)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Icon(icon,color:Colors.green),Text(value,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:Colors.grey))]))));}
class _HomeTile extends StatelessWidget {final IconData icon;final String title;final VoidCallback onTap;const _HomeTile({required this.icon,required this.title,required this.onTap});@override Widget build(BuildContext c)=>Card(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.all(14),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:34,color:Colors.green),const SizedBox(height:8),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold))]))));}

class PanelsPage extends StatelessWidget {const PanelsPage({super.key});@override Widget build(BuildContext c)=>const CategoryPage(title:'Solar Panels',category:'Solar Panel',icon:Icons.solar_power);}
class InvertersPage extends StatelessWidget {const InvertersPage({super.key});@override Widget build(BuildContext c)=>const CategoryPage(title:'Inverters',category:'Inverter',icon:Icons.electric_bolt);}
class BatteriesPage extends StatelessWidget {const BatteriesPage({super.key});@override Widget build(BuildContext c)=>const CategoryPage(title:'Batteries',category:'Battery',icon:Icons.battery_full);}
class AccessoriesPage extends StatelessWidget {const AccessoriesPage({super.key});@override Widget build(BuildContext c)=>const CategoryPage(title:'Solar Accessories',category:'Accessory',icon:Icons.settings_input_component);}

class CategoryPage extends StatelessWidget {final String title,category;final IconData icon;const CategoryPage({super.key,required this.title,required this.category,required this.icon});
 @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('solar_rates').where('category',isEqualTo:category).snapshots(),builder:(c,s){final rates=s.data?.docs.map(SolarRate.fromDocument).where((r)=>r.price>0).toList()??[];return ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.green.shade50,borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(icon,size:44,color:Colors.green.shade700),const SizedBox(width:14),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text('${rates.length} products')])])),const SizedBox(height:14),if(s.hasError)Text('Unable to load $title. Check Firestore category values.') else if(rates.isEmpty)const _Empty(title:'No products yet',message:'Add products from Admin Panel and choose the matching category.') else ...rates.map((r)=>_RateCard(rate:r))]);});}

class DailyRatesPage extends StatelessWidget {const DailyRatesPage({super.key});@override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('solar_rates').snapshots(),builder:(c,s){final rates=s.data?.docs.map(SolarRate.fromDocument).where((r)=>r.price>0).toList()??[];return ListView(padding:const EdgeInsets.all(16),children:[Text('☀️ Today\'s Complete Rate List',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(DateFormat('dd MMMM yyyy').format(DateTime.now()),style:const TextStyle(color:Colors.grey)),const SizedBox(height:14),if(rates.isEmpty)const _Empty(title:'No rates found',message:'Add rates through Admin Panel.') else ...rates.map((r)=>_RateCard(rate:r))]);});}

class OffersPage extends StatelessWidget {const OffersPage({super.key});@override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('solar_rates').where('isOffer',isEqualTo:true).snapshots(),builder:(c,s){final rates=s.data?.docs.map(SolarRate.fromDocument).toList()??[];return ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:LinearGradient(colors:[Colors.orange.shade800,Colors.red.shade600]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.local_offer,color:Colors.white,size:42),SizedBox(height:8),Text('Special Offers',style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),Text('Latest MH Solar deals',style:TextStyle(color:Colors.white70))])),const SizedBox(height:14),if(rates.isEmpty)const _Empty(title:'No active offers',message:'Offers added from the Admin Panel will appear here.') else ...rates.map((r)=>_RateCard(rate:r))]);});}

class ContactPage extends StatelessWidget {const ContactPage({super.key});Future<void> whatsapp()async{final u=Uri.parse('https://wa.me/923366760264');if(await canLaunchUrl(u))await launchUrl(u,mode:LaunchMode.externalApplication);} @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.green.shade700,borderRadius:BorderRadius.circular(24)),child:const Column(children:[Icon(Icons.solar_power,color:Colors.white,size:60),SizedBox(height:10),Text('MH SOLAR & ELECTRONICS',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),Text('Sialkot, Punjab • Powering the Future',style:TextStyle(color:Colors.white70))])),const SizedBox(height:16),Card(child:Column(children:[const ListTile(leading:Icon(Icons.phone,color:Colors.green),title:Text('Call / WhatsApp'),subtitle:Text('0336-6760264')),const ListTile(leading:Icon(Icons.location_on,color:Colors.green),title:Text('Location'),subtitle:Text('Sialkot, Punjab, Pakistan')),const ListTile(leading:Icon(Icons.solar_power,color:Colors.green),title:Text('Services'),subtitle:Text('Solar Panels • Inverters • Batteries • Installation • Accessories'))])),const SizedBox(height:14),FilledButton.icon(onPressed:whatsapp,icon:const Icon(Icons.chat),label:const Text('Chat on WhatsApp'))]);}

class _RateCard extends StatelessWidget {final SolarRate rate;const _RateCard({required this.rate});@override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(leading:CircleAvatar(backgroundColor:Colors.green.shade50,child:Icon(rate.category.toLowerCase().contains('battery')?Icons.battery_full:rate.category.toLowerCase().contains('inverter')?Icons.electric_bolt:Icons.solar_power,color:Colors.green)),title:Text(rate.brand,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${rate.model} • ${rate.watt}\n${rate.category}'),isThreeLine:true,trailing:Text('Rs. ${NumberFormat('#,###').format(rate.price)}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)));}
class _Empty extends StatelessWidget {final String title,message;const _Empty({required this.title,required this.message});@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(28),child:Column(children:[const Icon(Icons.inventory_2_outlined,size:52,color:Colors.grey),const SizedBox(height:10),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Colors.grey))])));}
