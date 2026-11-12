part of 'main.dart';

class Login extends StatefulWidget{const Login({super.key});@override State<Login> createState()=>_Login();}
class _Login extends State<Login>{
  String email='',password='';bool signup=false,busy=false;
  @override Widget build(BuildContext c)=>page('Servora',[
    Text(signup?'Create your account':'Welcome back',style:Theme.of(c).textTheme.headlineMedium),
    TextField(keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email'),onChanged:(v)=>email=v.trim()),
    TextField(obscureText:true,decoration:const InputDecoration(labelText:'Password'),onChanged:(v)=>password=v),
    FilledButton(onPressed:busy?null:()async{setState(()=>busy=true);await handle(c,()async{if(signup){await FirebaseAuth.instance.createUserWithEmailAndPassword(email:email,password:password);}else{await FirebaseAuth.instance.signInWithEmailAndPassword(email:email,password:password);}});if(mounted)setState(()=>busy=false);},child:Text(signup?'Create account':'Sign in')),
    TextButton(onPressed:()=>setState(()=>signup=!signup),child:Text(signup?'Already registered? Sign in':'New here? Create account'))]);
}
class Register extends StatefulWidget{const Register({super.key});@override State<Register> createState()=>_Register();}
class _Register extends State<Register>{String name='',role='customer';
  @override Widget build(BuildContext c)=>page('Your account',[TextField(decoration:const InputDecoration(labelText:'Display name'),onChanged:(v)=>name=v),select('Account type',role,['customer','provider'],(v)=>setState(()=>role=v)),action('Continue',()=>handle(c,()=>send('register',{'name':name,'role':role})))]);
}
Widget select(String label,String value,List<String> choices,ValueChanged<String> change)=>DropdownButtonFormField<String>(value:value,decoration:InputDecoration(labelText:label),items:[for(final x in choices)DropdownMenuItem(value:x,child:Text(x))],onChanged:(v){if(v!=null)change(v);});
Future<void> notifications()async{await FirebaseMessaging.instance.requestPermission();final t=await FirebaseMessaging.instance.getToken();if(t!=null)await db.collection('devices').doc(uid).set({'token':t});}
