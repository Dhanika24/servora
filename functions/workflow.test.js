const test=require('node:test'),assert=require('node:assert/strict');
const {transition,reward,level}=require('./workflow');
test('customer picks quote and reviews only once',()=>{
  assert.equal(transition('open','accept',true,false),'booked');
  assert.throws(()=>transition('booked','accept',true,false));
  assert.throws(()=>transition('completed','review',true,false));
  assert.throws(()=>transition('awaiting review','review',false,true));
});
test('assigned provider progresses in order',()=>{
  assert.throws(()=>transition('booked','finish',false,true));
  assert.throws(()=>transition('booked','start',false,false));
  assert.equal(transition('booked','start',false,true),'in progress');
  assert.equal(transition('in progress','finish',false,true),'awaiting review');
  assert.equal(transition('awaiting review','review',true,false),'completed');
});
test('benefits and performance boundaries',()=>{
  assert.equal(reward({stars:5,onTime:true,quick:true,verified:true}),25);
  assert.equal(reward({stars:2}),10);
  assert.deepEqual([49,50,119,120].map(p=>level(p).fee),[10,8,8,5]);
});
