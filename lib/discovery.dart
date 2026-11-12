part of 'main.dart';

double distance(RowData a,RowData b)=>Geolocator.distanceBetween(a['lat'].toDouble(),a['lng'].toDouble(),b['lat'].toDouble(),b['lng'].toDouble())/1000;
double rating(RowData p)=>(p['stars']+15)/(p['jobs']+4);
// Predict satisfaction from the three most similar completed budgets.
double predictedRating(RowData provider, RowData? job) {
  if (job == null) return rating(provider) / 5;
  final history = List<Map>.from(provider['examples'] ?? []);
  double gap(Map entry) => (math.log(entry['budget']) - math.log(job['budget'])).abs();
  history.sort((a, b) => gap(a).compareTo(gap(b)));
  double total = rating(provider) / 5;
  double weights = 1;
  for (final example in history.take(3)) {
    final weight = 1 / (1 + gap(example));
    total += weight * example['stars'] / 5;
    weights += weight;
  }
  return total / weights;
}
double score(RowData p,RowData? job,String priority){
  final jobs=p['jobs'] as num,km=job==null?0.0:distance(p,job);
  final fit=job==null?1.0:math.min(1.0,job['budget']/p['price']).toDouble();
  final near=1/(1+km/10),quality=predictedRating(p,job);
  final performance=(p['ontime']+p['quick']+p['verified']+3)/(3*jobs+6);
  return 0.13*fit+0.13*near+0.18*quality+0.15*performance+0.06*math.min(1,jobs/20)+0.03*p['visibility']+0.29*(priority=='Budget'?fit:priority=='Distance'?near:quality);
}
class Discover extends StatefulWidget{final RowData? job;const Discover({this.job,super.key});@override State<Discover> createState()=>_Discover();}
class _Discover extends State<Discover>{late String cat;String priority='Quality';final selected=<String>{};
  @override void initState(){super.initState();cat=widget.job?['category']??categories.first;}
  @override Widget build(BuildContext c)=>page('Find a professional',[if(widget.job==null)select('Service',cat,categories,(v)=>setState((){cat=v;selected.clear();})),select('My priority',priority,widget.job==null?['Quality']:['Quality','Budget','Distance'],(v)=>setState(()=>priority=v)),
    StreamBuilder(stream:db.collection('providers').where('category',isEqualTo:cat).snapshots(),builder:(c,s){
      if(s.hasError)return Text('${s.error}');if(!s.hasData)return const LinearProgressIndicator();
      final list=s.data!.docs.where((d)=>d['available']==true).toList()..sort((a,b)=>score(b.data(),widget.job,priority).compareTo(score(a.data(),widget.job,priority)));
      if(list.isEmpty)return const Text('No available providers in this category.');
      final picks=list.where((p)=>selected.contains(p.id)).toList();
      return Column(children:[if(picks.length==2)action('Compare selected providers',()=>go(c,page('Provider comparison',[Table(columnWidths:const {0:FlexColumnWidth(1),1:FlexColumnWidth(1.25),2:FlexColumnWidth(1.25)},children:[for(final entry in {'Provider':'name','Starting LKR':'price','Town':'area','Available':'available','Years':'years','Jobs':'jobs','Level':'level'}.entries)TableRow(children:[entry.key,...picks.map((p)=>p[entry.value].toString())].map((x)=>Padding(padding:const EdgeInsets.all(4),child:Text(x))).toList())]),for(final p in picks)card('Feedback and work · ${p['name']}','Open portfolio',()=>go(c,Profile(id:p.id)))]))),
        for(final p in list)Card(child:ListTile(leading:Checkbox(value:selected.contains(p.id),onChanged:(v)=>setState((){if(v==false){selected.remove(p.id);}else if(selected.length<2){selected.add(p.id);}})),title:Text(p['name']),subtitle:Text('${p['area']} · LKR ${p['price']} · ${p['level']}\n${widget.job==null?'': '${distance(p.data(),widget.job!).toStringAsFixed(1)} km · '}${p['jobs']} completed'),onTap:()=>go(c,Profile(id:p.id))))]);})]);
}
