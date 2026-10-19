import fs from 'node:fs';import vm from 'node:vm';import path from 'node:path';import {fileURLToPath} from 'node:url';import assert from 'node:assert/strict';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const elements=new Map();function element(id){if(!elements.has(id))elements.set(id,{value:'',checked:false,disabled:false,textContent:'',listeners:{},classList:{toggle(){}},addEventListener(name,fn){this.listeners[name]=fn;}});return elements.get(id);}
element('mode').value='土木工程';
let bindings=0;let writes=0;const range={text:'抗压强度为 35 MPa。',load(){},font:{bold:false,italic:false,name:'Arial',size:11,load(){}},paragraphs:{items:[{getPreviousOrNullObject:()=>({isNullObject:true,text:'',load(){}}),getNextOrNullObject:()=>({isNullObject:true,text:'',load(){}})}],load(){}},insertText(){writes++;},getOoxml:()=>({value:'<w:p>plain</w:p>'}),getTextRanges:()=>({items:[range],load(){}})};
const context={document:{getSelection:()=>range},trackedObjects:{add(){},remove(){}},sync:async()=>{}};
const mock={document:{getElementById:element},window:{Office:{},confirm:()=>true,addEventListener(){}},Office:{HostType:{Word:'Word'},context:{requirements:{isSetSupported:()=>true}},onReady:fn=>fn({host:'Word'})},Word:{run:async (...args)=>{if(args.length===2){assert.equal(args[0],range);bindings++;}return args.at(-1)(context);}},AbortController,navigator:{clipboard:{writeText:async()=>{}}},fetch:async url=>({json:async()=>url==='/api/session'?{token:'test'}:{ok:true,text:'The compressive strength was 35 MPa.',terms:[]}})};
vm.runInNewContext(fs.readFileSync(path.join(root,'word-web','numeric-text.js'),'utf8'),mock);
vm.runInNewContext(fs.readFileSync(path.join(root,'word-web','app.js'),'utf8'),mock);
await element('capture').onclick();assert.equal(element('source').value,range.text);
await element('translate').onclick();assert.equal(element('replace').disabled,false);
range.text='用户已修改原文。';await element('replace').onclick();assert.equal(writes,0);assert.match(element('status').textContent,/原文已改变/);
range.text='抗压强度为 35 MPa。';await element('capture').onclick();await element('translate').onclick();element('output').value='The compressive strength was 40 MPa.';element('output').listeners.input();assert.equal(element('replace').disabled,true);
element('source').value='另一句';element('source').listeners.input();assert.equal(element('output').value,'');assert.equal(element('replace').disabled,true);
range.text='抗压强度为 35 MPa。';await element('capture').onclick();await element('translate').onclick();await element('replace').onclick();assert.equal(writes,1);assert.ok(bindings>0,"Saved ranges must reuse their request context.");
let posts=0,sessions=0;mock.fetch=async url=>{if(url==="/api/session"){sessions++;return {status:200,json:async()=>({token:"rotated"})};}posts++;return posts===1?{status:403,json:async()=>({ok:false})}:{status:200,json:async()=>({ok:true,text:"The compressive strength was 35 MPa.",terms:[]})};};await element("capture").onclick();await element("translate").onclick();assert.equal(posts,2);assert.equal(sessions,1);assert.equal(element("replace").disabled,false);
mock.fetch=async url=>({status:200,json:async()=>url==='/api/session'?{token:'test'}:{ok:true,text:'The compressive strength was 35 MPa.',terms:[{Chinese:'抗压强度',English:'compressive strength',Locked:true}]}});range.text='抗压强度为 35 MPa。';await element('capture').onclick();await element('translate').onclick();element('output').value='The strength was 35 MPa.';element('output').listeners.input();assert.equal(element('replace').disabled,true);
range.text='P<0.05';await element('capture').onclick();await element('translate').onclick();element('output').value='P>0.05';element('output').listeners.input();assert.equal(element('replace').disabled,true);
range.text='分别为 10 MPa 和 20 MPa';await element('capture').onclick();await element('translate').onclick();element('output').value='They were 10 MPa and 20 kPa';element('output').listeners.input();assert.equal(element('replace').disabled,true);
for(const [original,changed] of [['延迟 12 ms','Latency 12 ns'],['产量 12 m³/d','Production 12 m³/h'],['调用 `None`','Call `none`']]){range.text=original;await element('capture').onclick();await element('translate').onclick();element('output').value=changed;element('output').listeners.input();assert.equal(element('replace').disabled,true);}
range.text='抗压强度为 35 MPa。';await element('capture').onclick();await element('translate').onclick();element('context').value='新的试验条件';element('context').listeners.input();assert.equal(element('output').value,'');assert.equal(element('replace').disabled,true);
const pane=fs.readFileSync(path.join(root,'word-web','taskpane.html'),'utf8');for(const name of ['医学','土木工程','计算机','油气开采','日常交流'])assert.ok(pane.includes('<option>'+name+'</option>'));
assert.ok(pane.includes('value="en-zh"'));
range.text='The strength is 35 MPa.';await element('capture').onclick();element('direction').value='en-zh';element('direction').listeners.change();assert.equal(element('output').value,'');assert.equal(element('replace').disabled,true);
let posted;mock.fetch=async (url,options)=>{if(options?.body)posted=JSON.parse(options.body);return {status:200,json:async()=>url==='/api/session'?{token:'test'}:{ok:true,text:'强度为 35 MPa。',terms:[]}};};
await element('translate').onclick();assert.equal(posted.direction,'en-zh');assert.equal(element('output').value,'强度为 35 MPa。');assert.equal(element('replace').disabled,false);const reverseWrites=writes;await element('replace').onclick();assert.equal(writes,reverseWrites+1);
range.text='Latency is 12 ms.';await element('capture').onclick();await element('translate').onclick();element('output').value='延迟为12毫秒。';element('output').listeners.input();assert.equal(element('replace').disabled,false);element('output').value='延迟为12纳秒。';element('output').listeners.input();assert.equal(element('replace').disabled,true);
// One-click capture must not translate a previous selection if capture fails.
const requestsBefore=posted;range.text='';await element('capture-translate').onclick();assert.equal(posted,requestsBefore);assert.match(element('status').textContent,/选中/);
range.text='The strength is 35 MPa.';await element('capture-translate').onclick();assert.equal(element('output').value,'强度为 35 MPa。');
// A failed quality check remains inspectable, with writes disabled.
mock.fetch=async url=>({status:200,json:async()=>url==='/api/session'?{token:'test'}:{ok:false,text:'强度为 40 MPa。',error:'数字变化',terms:[]}});await element('translate').onclick();assert.equal(element('output').value,'强度为 40 MPa。');assert.equal(element('replace').disabled,true);assert.match(element('status').textContent,/检查未通过/);
// Persist only the two nonsensitive preferences.
let stored;mock.window.localStorage={setItem:(key,value)=>{stored=JSON.parse(value);},getItem:()=>null};element('mode').value='计算机';element('mode').listeners.change();assert.deepEqual(stored,{direction:'en-zh',mode:'计算机'});
range.text='The stiffness increased.';mock.fetch=async url=>({status:200,json:async()=>url==='/api/session'?{token:'test'}:{ok:true,text:'刚度增加。',terms:[{Chinese:'刚度',English:'stiffness',Locked:true,Direction:'en-zh'}]}});
await element('capture-translate').onclick();assert.equal(element('replace').disabled,false);element('output').value='强度增加。';element('output').listeners.input();assert.equal(element('replace').disabled,true);assert.match(element('status').textContent,/stiffness → 刚度/);
const numericCases=JSON.parse(fs.readFileSync(path.join(root,'tests','numeric-cases.json'),'utf8'));
for(const fixture of numericCases){
  element('direction').value=/^[A-Za-z]/.test(fixture.source)?'en-zh':'zh-en';element('direction').listeners.change();
  range.text=fixture.source;
  mock.fetch=async url=>({status:200,json:async()=>url==='/api/session'?{token:'test'}:{ok:true,text:fixture.result,terms:[]}});
  await element('capture-translate').onclick();
  assert.equal(element('replace').disabled,!fixture.ok,'numeric/time candidate guard '+fixture.source+' -> '+fixture.result);
  if(fixture.ok){element('output').value=fixture.result+' ';element('output').listeners.input();assert.equal(element('replace').disabled,false,'equivalent edited candidate');}
}
const report='PASS: frontend capture/preview, changed-source refusal, edited-number/comparison/locked-term/repeated-unit/computing-unit/production-rate/code refusal, source/context/direction stale-candidate clearing, explicit apply in both directions, saved-range context binding, server-token refresh after restart, five domain options, reverse request direction, equivalent Chinese unit acceptance, wrong Chinese unit refusal and explicit reverse locked-term edit refusal and 51 shared time/quantity candidate fixtures.\nMock Office API checks frontend guards; this is not a live Word-host acceptance test.';
fs.writeFileSync(path.join(root,'artifacts','word-ui-guard-test.txt'),report);console.log(report);


