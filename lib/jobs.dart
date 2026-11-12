part of 'main.dart';

class Job extends StatelessWidget{final String id;const Job({required this.id,super.key});
  @override Widget build(BuildContext c){final ref=db.collection('jobs').doc(id);return StreamBuilder(stream:ref.snapshots(),builder:(c,s){final j=s.data?.data();
    if(j==null)return page('Request',[Text(s.hasError?'This request is unavailable.':'Loading request…')]);
    final owner=j['owner']==uid,assigned=j['assigned']==uid,status=j['status'];
    return page(j['title'],[Text('${j['category']} · ${j['area']}\n${j['status']} · Budget LKR ${j['budget']}'),Text(j['description']),photoView(j['photo']),
      OutlinedButton(onPressed:()=>handle(c,()async{final opened=await launchUrl(Uri.https('www.google.com','/maps/search/',{'api':'1','query':'${j['lat']},${j['lng']}'}),mode:LaunchMode.externalApplication);if(!opened)throw Exception('Map unavailable');}),child:const Text('Open location in Maps')),
      if(owner&&status=='open')...[action('Compare recommended providers',()=>go(c,Discover(job:j))),const Text('Provider quotations'),rows(ref.collection('quotes'),(pid,q)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${q['name']} · LKR ${q['amount']} · ${q['hours']} h'),Text(q['note']),Wrap(children:[TextButton(onPressed:()=>go(c,Profile(id:pid)),child:const Text('View portfolio')),TextButton(onPressed:()=>handle(c,()=>send('accept',{'jobId':id,'provider':pid})),child:const Text('Accept quote'))])]))))],
      if(!owner&&status=='open')action('Send or edit quotation',()=>go(c,Editor(mode:'quote',jobId:id))),
      if(j['amount']!=null)Text('Booked with ${j['providerName']} · LKR ${j['amount']}'),
      if(assigned&&status=='booked')action('Start job',()=>handle(c,()=>send('start',{'jobId':id}))),
      if(assigned&&status=='in progress')action('Submit work result',()=>go(c,Editor(mode:'finish',jobId:id))),
      if(j['summary']!=null)...[Text(j['summary']),photoView(j['result'])],
      if(owner&&status=='awaiting review')action('Confirm and review',()=>go(c,Editor(mode:'review',jobId:id))),
      if(status=='completed')Text('${j['stars']}/5 · ${j['feedback']}\nService charge: LKR ${j['serviceCharge']} (${j['feePercent']}%)')]);});}
}
