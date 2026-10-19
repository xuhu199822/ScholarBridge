import fs from 'node:fs';import https from 'node:https';import crypto from 'node:crypto';import path from 'node:path';import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');const ca=new crypto.X509Certificate(fs.readFileSync(path.join(root,'data','word-web','localhost.cer'))).toString();
function request(method,url,body,token,origin){return new Promise((resolve,reject)=>{const req=https.request({hostname:'127.0.0.1',port:18766,path:url,method,ca,servername:'localhost',headers:{Host:'localhost:18766','Content-Type':'application/json',...(token?{'X-Scholar-Token':token}:{}),...(origin?{Origin:origin}:{})}},res=>{res.setEncoding('utf8');let data='';res.on('data',chunk=>data+=chunk);res.on('end',()=>resolve({status:res.statusCode,body:data}));});req.on('error',reject);if(body)req.write(JSON.stringify(body));req.end();});}
try{
  const page=await request('GET','/taskpane.html');if(page.status!==200||!page.body.includes('学桥'))throw new Error('Task pane page unavailable.');
  const session=await request('GET','/api/session');const token=JSON.parse(session.body).token;
  const unauthorized=await request('POST','/api/translate',{text:'测试',mode:'日常交流'});if(unauthorized.status!==403)throw new Error('Missing-token request accepted.');
  const external=await request('POST','/api/translate',{text:'测试',mode:'日常交流'},token,'https://example.org');if(external.status!==403)throw new Error('External-origin request accepted.');
  const response=await request('POST','/api/translate',{text:'试件的抗压强度为 35 MPa。',mode:'土木工程'},token,'https://localhost:18766');const result=JSON.parse(response.body);
  if(!result.ok||!result.text.includes('35 MPa')||!result.text.toLowerCase().includes('compressive strength'))throw new Error('Real local academic translation failed: '+response.body);
  const extra=[];
  for(const [mode,text,expected] of [['计算机','缓存命中率为 90%，推理延迟为 12 ms。','cache hit rate'],['油气开采','该井的含水率为 80%，储层含水饱和度为 35%。','water saturation']]){
    if(!page.body.includes('<option>'+mode+'</option>'))throw new Error('Missing domain in served page: '+mode);
    const translated=JSON.parse((await request('POST','/api/translate',{text,mode},token,'https://localhost:18766')).body);
    if(!translated.ok||!translated.text.toLowerCase().includes(expected))throw new Error('New domain bridge failed: '+JSON.stringify(translated));
    extra.push(mode+': '+translated.text);
  }
  if(!page.body.includes('value="en-zh"'))throw new Error('Missing reverse translation selector.');
  const invalidDirection=await request('POST','/api/translate',{text:'Hello.',mode:'日常交流',direction:'invalid'},token,'https://localhost:18766');if(invalidDirection.status!==400)throw new Error('Invalid direction accepted.');
  for(const [mode,text] of [['日常交流','Could you send me the file tomorrow? No rush.'],['计算机','The cache hit rate is 90%, and latency is 12 ms.'],['土木工程','The compressive strength is 35 MPa.']]){
    const translated=JSON.parse((await request('POST','/api/translate',{text,mode,direction:'en-zh'},token,'https://localhost:18766')).body);
    if(!translated.ok||translated.direction!=='en-zh'||!/[\u4e00-\u9fff]/.test(translated.text)||translated.terms.length!==0)throw new Error('Reverse bridge failed: '+JSON.stringify(translated));
    extra.push(mode+' English to Chinese: '+translated.text);
  }
  const report='PASS: trusted localhost TLS, task-pane page, CSRF-token guard, external-origin refusal, UTF-8 named-pipe bridge, real local civil/computing/petroleum translation, reverse chat/computing/civil translation, target direction propagation and invalid direction refusal.\n'+[result.text,...extra].join('\n');
  fs.writeFileSync(path.join(root,'artifacts','word-web-test.txt'),report);console.log(report);
}catch(error){fs.writeFileSync(path.join(root,'artifacts','word-web-test.txt'),error.stack);console.error(error.message);process.exitCode=1;}
