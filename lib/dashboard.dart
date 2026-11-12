part of 'main.dart';

class Home extends StatelessWidget{final RowData member;const Home({required this.member,super.key});
  @override Widget build(BuildContext c){final provider=member['role']=='provider';return page('Servora',[Text('Hello, ${member['name']}',style:Theme.of(c).textTheme.headlineMedium),
    if(!provider)...[card('Request a service','Describe the task and set a budget',()=>go(c,const Editor(mode:'post'))),card('Emergency mechanic','Request roadside assistance',()=>go(c,const Editor(mode:'emergency'))),card('Explore providers','Compare local professionals',()=>go(c,const Discover()))],
    if(provider)...[card('Service profile','Set your availability, rate and location',()=>handle(c,()async{final p=await db.collection('providers').doc(uid).get();if(c.mounted)go(c,Editor(mode:'profile',initial:p.data()));})),card('Available requests','Find requests in your service category',()=>go(c,const Inbox())),card('My performance and portfolio','Completed work, points and benefits',()=>go(c,Profile(id:uid)))],
    card('My jobs','Track requests and completed work',()=>go(c,JobList(provider:provider))),
    TextButton(onPressed:()=>handle(c,notifications),child:const Text('Enable job notifications')),
    TextButton(onPressed:()=>handle(c,()async{await db.collection('devices').doc(uid).delete();await FirebaseAuth.instance.signOut();}),child:const Text('Sign out'))]);}
}
class JobList extends StatelessWidget{final bool provider;const JobList({required this.provider,super.key});
  @override Widget build(BuildContext c)=>page('My jobs',[rows(db.collection('jobs').where(provider?'assigned':'owner',isEqualTo:uid),(id,d)=>card(d['title'],'${d['status']} · ${d['area']}',()=>go(c,Job(id:id))))]);}
class Inbox extends StatelessWidget{const Inbox({super.key});
  @override Widget build(BuildContext c)=>StreamBuilder(stream:db.collection('providers').doc(uid).snapshots(),builder:(c,s){final p=s.data?.data();
    return page('Available requests',[if(s.hasError)Text('${s.error}') else if(!s.hasData)const LinearProgressIndicator() else if(p==null)const Text('Create your service profile first.') else rows(db.collection('jobs').where('status',isEqualTo:'open').where('category',isEqualTo:p['category']),(id,d)=>card(d['title'],'${d['emergency']?'URGENT · ':''}${d['area']} · LKR ${d['budget']}',()=>go(c,Job(id:id))))]);});}
