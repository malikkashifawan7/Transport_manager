
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db=await SharedPreferences.getInstance();
  runApp(TransportHisab(db:db));
}
class TransportHisab extends StatelessWidget {
 final SharedPreferences db;
 const TransportHisab({super.key,required this.db});
 @override Widget build(BuildContext c)=>MaterialApp(
  debugShowCheckedModeBanner:false,title:'Transport Hisab',
  theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.indigo),
  home:Home(db:db));
}
class Home extends StatefulWidget{
 final SharedPreferences db; const Home({super.key,required this.db});
 @override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home>{
 List<Map<String,dynamic>> get records{
  final raw=db.getString('records')??'[]';
  return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e)).toList();
 }
 Future<void> add(String module)async{
  final n=TextEditingController(),a=TextEditingController(),d=TextEditingController();
  await showDialog(context,builder:(x)=>AlertDialog(
   title:Text('Add $module'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:n,decoration:const InputDecoration(labelText:'Name / Vehicle / Party')),
    TextField(controller:a,decoration:const InputDecoration(labelText:'Amount'),keyboardType:TextInputType.number),
    TextField(controller:d,decoration:const InputDecoration(labelText:'Details')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Cancel')),
   FilledButton(onPressed:()async{
    final r=records;r.add({'module':module,'name':n.text,'amount':a.text,'details':d.text,'date':DateTime.now().toIso8601String().substring(0,10)});
    await db.setString('records',jsonEncode(r)); if(mounted){setState((){});Navigator.pop(x);}
   },child:const Text('Save'))]
  ));
 }
 @override Widget build(BuildContext c){
  final modules=<String,IconData>{
   'Vehicles':Icons.directions_bus,'Drivers & Salaries':Icons.badge,
   'Advance Bookings':Icons.event_available,'Trips / Journeys':Icons.route,
   'Fuel & Pumps':Icons.local_gas_station,'Expenses':Icons.payments,
   'Maintenance & Tyres':Icons.build,'Challans / Passing':Icons.description,
   'Party Ledger':Icons.account_balance,'Calendar & Alerts':Icons.calendar_month,
   'Monthly Reports':Icons.analytics,'Backup / Restore':Icons.cloud_sync,
   'Print / Share':Icons.print,
  };
  return Scaffold(appBar:AppBar(title:const Text('Transport Hisab'),actions:[
   IconButton(onPressed:()=>showSearch(context:context,delegate(S(records))),icon:const Icon(Icons.search))
  ]),
  floatingActionButton:FloatingActionButton.extended(onPressed:()=>add('General'),icon:const Icon(Icons.add),label:const Text('Quick Add')),
  body:ListView(padding:const EdgeInsets.all(14),children:[
   Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Transport Dashboard',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
    const SizedBox(height:6),Text('Saved offline records: ${records.length}'),
    const SizedBox(height:12),const Text('Offline-first • Auto-save • Search • Backup-ready')
   ]))),
   const SizedBox(height:10),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
    crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:1.7,
    children:modules.entries.map((e)=>Card(child:InkWell(
     onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Page(.db db,title:e.key))),
     child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(e.value,size:30),const SizedBox(height:6),Text(e.key,textAlign:TextAlign.center)
     ])))).toList())
  ]));
 }
}
class Page extends StatefulWidget{
 final SharedPreferences db; final String title;
 const Page({super.key,required this.db,required this.title});
 @override State<Page> createState()=>_PageState();
}
class _PageState extends State<Page>{
 List<Map<String,dynamic>> get rs=>(jsonDecode(widget.db.getString('records')??'[]') as List).map((e)=>Map<String,dynamic>.from(e)).where((e)=>e['module']==widget.title).toList();
 Future<void> add()async{
  final n=TextEditingController(),a=TextEditingController(),d=TextEditingController();
  await showDialog(context:context,builder:(x)=>AlertDialog(title:Text('New ${widget.title}'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:n,decoration:const InputDecoration(labelText:'Name / Vehicle / Party')),
    TextField(controller:a,decoration:const InputDecoration(labelText:'Amount / Total')),
    TextField(controller:d,decoration:const InputDecoration(labelText:'Details / Notes')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Cancel')),
   FilledButton(onPressed:()async{
    final all=(jsonDecode(widget.db.getString('records')??'[]') as List).map((e)=>Map<String,dynamic>.from(e)).toList();
    all.add({'module':widget.title,'name':n.text,'amount':a.text,'details':d.text,'date':DateTime.now().toIso8601String().substring(0,10)});
    await widget.db.setString('records',jsonEncode(all)); if(mounted){setState((){});Navigator.pop(x);}
   },child:const Text('Save'))]
  ));
 }
 String desc(String s)=>switch(s){
 'Advance Bookings'=>'Party • contact • address • vehicle • driver • route • departure/return • total • advance • balance • status: Pending/Confirmed/Completed/Cancelled/No Show • refund/cancellation reason',
 'Fuel & Pumps'=>'Diesel • Petrol • LPG • pump ledger • vehicle fuel • date-wise rate • litres • KM • cost • credit • receipt',
 'Trips / Journeys'=>'Start/end KM • route • driver • fuel • toll • allowance • other expenses • income • trip profit',
 'Monthly Reports'=>'Vehicle • driver • route • category • pump • income • expenses • KM • fuel • average • profit/loss',
 'Calendar & Alerts'=>'Advance trips • departure reminders • payment due • oil/service • tyres • passing • token • insurance',
 'Vehicles'=>'Separate vehicle history: bookings • trips • fuel • average • expenses • repair • documents • challans • profit/loss',
 _=>'Complete transport module with offline records.'
 };
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.title),actions:[IconButton(onPressed:add,icon:const Icon(Icons.add))]),
 body:ListView(padding:const EdgeInsets.all(14),children:[
  Card(child:Padding(padding:const EdgeInsets.all(15),child:Text(desc(widget.title),style:const TextStyle(height:1.4)))),
  const SizedBox(height:10),...rs.reversed.map((r)=>Card(child:ListTile(
   title:Text(r['name']??''),subtitle:Text('${r['date']} • ${r['details']??''}'),trailing:Text(r['amount']??''))))
 ]));
}
class S extends SearchDelegate<String>{
 final List<Map<String,dynamic>> r; S(this.r);
 @override List<Widget>? buildActions(c)=>[IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear))];
 @override Widget? buildLeading(c)=>IconButton(onPressed:()=>close(c,''),icon:const Icon(Icons.arrow_back));
 @override Widget buildResults(c)=>list(); @override Widget buildSuggestions(c)=>list();
 Widget list()=>ListView(children:r.where((x)=>jsonEncode(x).toLowerCase().contains(query.toLowerCase())).map(
 (x)=>ListTile(title:Text(x['name']??''),subtitle:Text(x['module']??''))).toList());
}
