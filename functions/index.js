'use strict';
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {categories,level,reward,transition} = require('./workflow');
initializeApp();
const db = getFirestore();
function requireValue(ok, message) {
  if (!ok) throw new HttpsError('failed-precondition', message);
}
function str(v,max=500){requireValue(typeof v==='string' && v.trim().length>0 && v.trim().length<=max,'Enter valid text.');return v.trim();}
function num(v,min,max){requireValue(Number.isFinite(v)&&v>=min&&v<=max,'Number outside allowed range.');return v;}
function id(v){return str(v,150).replace(/\//g,()=>{throw new HttpsError('invalid-argument','Invalid identifier.');});}
function location(d){return {lat:num(d.lat,-90,90),lng:num(d.lng,-180,180)};}
function photo(path,uid,jobId){if(!path)return '';requireValue(typeof path==='string'&&path.startsWith('photos/'+uid+'/'+jobId+'/')&&/^photos\/[\w-]+\/[\w-]+\/[\w.-]+$/.test(path),'Invalid upload.');return path;}
exports.command = onCall(async req=>{
  if(!req.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const uid=req.auth.uid,d=req.data||{},action=d.action;
  const me=db.collection('members').doc(uid), provider=db.collection('providers').doc(uid);
  return db.runTransaction(async tx=>{
    const member=(await tx.get(me)).data();
    if(action==='register'){
      if(member)return;
      requireValue(['customer','provider'].includes(d.role),'Choose a role.');
      tx.create(me,{name:str(d.name,80),role:d.role});return;
    }
    requireValue(member,'Complete your profile.');
    if(action==='profile'){
      requireValue(member.role==='provider'&&categories.includes(d.category),'Select a provider service.');
      const prev=(await tx.get(provider)).data();
      tx.set(provider,{...(prev||{points:0,jobs:0,stars:0,ontime:0,quick:0,verified:0,...level(0)}),name:member.name,category:d.category,area:str(d.area,80),price:num(d.price,1,1e8),years:num(d.years,0,80),available:d.available===true,...location(d)});return;
    }
    const job=db.collection('jobs').doc(id(d.jobId));
    if(action==='post'){
      requireValue(member.role==='customer' && categories.includes(d.category),'Choose a service.');
      const existing=(await tx.get(job)).data();if(existing){requireValue(existing.owner===uid,'Invalid request.');return;}
      tx.create(job,{owner:uid,name:member.name,category:d.category,title:str(d.title,100),description:str(d.description),area:str(d.area,80),budget:num(d.budget,1,1e8),...location(d),emergency:d.category==='Mechanic'&&d.emergency===true,photo:photo(d.photo,uid,job.id),status:'open',assigned:'',created:Date.now()});return;
    }
    const j=(await tx.get(job)).data();requireValue(j,'Request missing.');
    const owner=j.owner===uid, assigned=j.assigned===uid;
    if(action==='quote'){
      const p=(await tx.get(provider)).data();requireValue(j.status==='open'&&p?.category===j.category&&p.available,'A matching available provider is required.');
      const ref=job.collection('quotes').doc(uid), prior=(await tx.get(ref)).data();
      tx.set(ref,{provider:uid,name:member.name,amount:num(d.amount,1,1e8),hours:num(d.hours,1,720),note:str(d.note),created:prior?.created||Date.now()});return;
    }
    let status;try{status=transition(j.status,action,owner,assigned);}catch(e){throw new HttpsError('failed-precondition',e.message);}
    const update={status};
    if(action==='accept'){
      const pid=id(d.provider), q=(await tx.get(job.collection('quotes').doc(pid))).data();
      requireValue(q,'Select a quotation.');Object.assign(update,{assigned:pid,providerName:q.name,amount:q.amount,due:Date.now()+q.hours*3600000,quick:q.created-j.created<=3600000});
    }
    if(action==='finish')Object.assign(update,{result:photo(d.result,uid,job.id),finished:Date.now(),summary:str(d.summary)});
    if(action==='review'){
      const stars=num(d.stars,1,5);requireValue(Number.isInteger(stars),'Choose whole stars.');
      const ref=db.collection('providers').doc(j.assigned), p=(await tx.get(ref)).data();
      const verified=Boolean(j.result&&d.consent===true),onTime=j.finished<=j.due;
      const points=p.points+reward({stars,onTime,quick:j.quick,verified});
      const benefits=level(points);
      const examples=[...(p.examples||[]),{budget:j.budget,stars}].slice(-30);
      tx.update(ref,{points,examples,jobs:p.jobs+1,stars:p.stars+stars,verified:p.verified+Number(verified),quick:p.quick+Number(j.quick),ontime:p.ontime+Number(onTime),...benefits});
      tx.set(ref.collection('work').doc(job.id),{title:j.title,feedback:str(d.feedback),stars,summary:j.summary,result:verified?j.result:'',created:Date.now()});
      Object.assign(update,{stars,feedback:d.feedback,feePercent:p.fee,serviceCharge:Math.round(j.amount*p.fee)/100});
    }
    tx.update(job,update);
  }).then(()=>({ok:true}));
});
exports.notifyStatus = onDocumentUpdated('jobs/{job}',async event=>{
  const before=event.data.before.data(),after=event.data.after.data();
  if(before.status===after.status)return;
  const target=['booked','completed'].includes(after.status)?after.assigned:after.owner;
  const device=(await db.collection('devices').doc(target).get()).data();
  if(device?.token)await getMessaging().send({token:device.token,notification:{title:after.title,body:'Job status: '+after.status}});
});
