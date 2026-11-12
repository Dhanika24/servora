import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

part 'accounts.dart';
part 'dashboard.dart';
part 'requests.dart';
part 'jobs.dart';
part 'discovery.dart';
part 'portfolio.dart';

typedef RowData = Map<String,dynamic>;
const categories=['Plumbing','Electrical','Painting','Carpentry','Masonry','Gardening','Cleaning','Mechanic'];
const ink=Color(0xff173d39);
final db=FirebaseFirestore.instance;
String get uid=>FirebaseAuth.instance.currentUser!.uid;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {await Firebase.initializeApp(); runApp(const Servora());}
  catch(e){runApp(MaterialApp(home:Scaffold(body:Center(child:Text('Firebase setup required. See the repository README.\n$e')))));}
}
class Servora extends StatelessWidget {
  const Servora({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(title:'Servora',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:ink),scaffoldBackgroundColor:const Color(0xfff6f7f2),useMaterial3:true,inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),home:StreamBuilder(stream:FirebaseAuth.instance.authStateChanges(),builder:(c,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.data==null)return const Login();
    return StreamBuilder(stream:db.collection('members').doc(s.data!.uid).snapshots(),builder:(c,m){
      if(m.hasError)return page('Account',[Text('${m.error}'),action('Sign out',()=>FirebaseAuth.instance.signOut())]);
      if(!m.hasData)return const Center(child:CircularProgressIndicator());
      final member=m.data!.data();return member==null?const Register():Home(member:member);
    });
  }));
}
Widget page(String title,List<Widget> children)=>Scaffold(appBar:AppBar(title:Text(title)),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[for(final w in children) Padding(padding:const EdgeInsets.only(bottom:14),child:w)])));
Widget action(String text,VoidCallback fn)=>FilledButton(onPressed:fn,child:Text(text));
Widget card(String title,String detail,[VoidCallback? fn])=>Card(child:ListTile(title:Text(title),subtitle:Text(detail),onTap:fn,trailing:fn==null?null:const Icon(Icons.chevron_right)));
void go(BuildContext c,Widget w)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>w));
Future<void> handle(BuildContext c,Future<void> Function() fn)async{try{await fn();}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('$e')));}}
Future<void> send(String name,RowData data)async{await FirebaseFunctions.instance.httpsCallable('command').call({'action':name,...data});}
Widget rows(Query<RowData> q,Widget Function(String,RowData) item)=>StreamBuilder(stream:q.snapshots(),builder:(c,s){
  if(s.hasError)return Text('${s.error}');if(!s.hasData)return const LinearProgressIndicator();
  if(s.data!.docs.isEmpty)return const Text('No entries yet.');
  return Column(children:[for(final d in s.data!.docs)item(d.id,d.data())]);
});
