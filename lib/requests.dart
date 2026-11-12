part of 'main.dart';

class Editor extends StatefulWidget{final String mode;final RowData? initial; final String? jobId;const Editor({required this.mode,this.initial,this.jobId,super.key});
  @override State<Editor> createState()=>_Editor();}
class _Editor extends State<Editor>{
  late RowData d;late final String id;bool busy=false;final ctrls=<String,TextEditingController>{};
  @override void initState(){super.initState();d={'category':widget.mode=='emergency'?'Mechanic':'Plumbing','available':true,'stars':5,'consent':false,...?widget.initial};id=widget.jobId??db.collection('jobs').doc().id;}
  @override void dispose(){for(final c in ctrls.values){c.dispose();}super.dispose();}
  Widget field(String key,String label,{bool number=false}){final ctrl=ctrls.putIfAbsent(key,()=>TextEditingController(text:d[key]?.toString()??''));return TextField(controller:ctrl,keyboardType:number?const TextInputType.numberWithOptions(decimal:true,signed:true):TextInputType.text,decoration:InputDecoration(labelText:label),onChanged:(v)=>d[key]=number?num.tryParse(v):v);}
  Future<void> gps()async{var p=await Geolocator.checkPermission();if(p==LocationPermission.denied)p=await Geolocator.requestPermission();
    if(p==LocationPermission.denied||p==LocationPermission.deniedForever)throw Exception('Enter coordinates manually or enable location in Settings.');
    final pos=await Geolocator.getCurrentPosition(timeLimit:const Duration(seconds:20));if(!mounted)return;
    setState((){d['lat']=pos.latitude;d['lng']=pos.longitude;for(final k in ['lat','lng']){ctrls[k]?.text=d[k].toString();}});}
  Future<void> upload(String key)async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1600);if(f==null)return;
    final bytes=await f.readAsBytes();if(bytes.length>=8*1024*1024)throw Exception('Choose an image smaller than 8 MB.');
    final ref=FirebaseStorage.instance.ref('photos/$uid/$id/${DateTime.now().microsecondsSinceEpoch}');await ref.putData(bytes,SettableMetadata(contentType:f.mimeType??(f.name.toLowerCase().endsWith('.png')?'image/png':'image/jpeg')));if(mounted)setState(()=>d[key]=ref.fullPath);}
  Future<void> run(Future<void> Function() fn)async{if(busy)return;setState(()=>busy=true);await handle(context,fn);if(mounted)setState(()=>busy=false);}
  @override Widget build(BuildContext c){final mode=widget.mode,post=mode=='post'||mode=='emergency',profile=mode=='profile';return page({'post':'Request a service','emergency':'Emergency mechanic','profile':'Service profile','quote':'Your quotation','finish':'Work result','review':'Review this job'}[mode]!,[
    if((post||profile)&&mode!='emergency')select('Service',d['category'],categories,(v)=>setState(()=>d['category']=v)),
    if(post)...[field('title','Task title'),field('description','Describe the problem'),field('budget','Budget (LKR)',number:true)],
    if(profile)...[field('price','Starting rate (LKR)',number:true),field('years','Years of experience',number:true),SwitchListTile(title:const Text('Available for work'),value:d['available'],onChanged:(v)=>setState(()=>d['available']=v))],
    if(post||profile)...[field('area','Town or service area'),OutlinedButton.icon(icon:const Icon(Icons.my_location),label:const Text('Use current location'),onPressed:busy?null:()=>run(gps)),field('lat','Latitude',number:true),field('lng','Longitude',number:true)],
    if(mode=='quote')...[field('amount','Total quote (LKR)',number:true),field('hours','Hours to finish after booking',number:true),field('note','What is included?')],
    if(mode=='finish')field('summary','Describe the completed work'),
    if(mode=='finish'||post)OutlinedButton(onPressed:busy?null:()=>run(()=>upload(post?'photo':'result')),child:Text(d[post?'photo':'result']==null?'Attach an optional photo':'Photo attached · replace')),
    if(mode=='review')...[select('Rating',d['stars'].toString(),['1','2','3','4','5'],(v)=>setState(()=>d['stars']=int.parse(v))),field('feedback','Your feedback'),CheckboxListTile(title:const Text('Allow the work result photo in the provider portfolio'),value:d['consent'],onChanged:(v)=>setState(()=>d['consent']=v??false))],
    FilledButton(onPressed:busy?null:()=>run(()async{await send(post?'post':mode,{...d,'jobId':id,'emergency':mode=='emergency'});if(c.mounted)Navigator.pop(c);}),child:Text(busy?'Working…':post?'Post request':'Save'))]);}
}
Widget photoView(String? path){if(path==null||path.isEmpty)return const SizedBox.shrink();return FutureBuilder<Uint8List?>(future:FirebaseStorage.instance.ref(path).getData(8*1024*1024),builder:(c,s)=>s.hasError?const Text('Image unavailable'):s.data==null?const LinearProgressIndicator():Image.memory(s.data!,height:190,fit:BoxFit.contain));}
