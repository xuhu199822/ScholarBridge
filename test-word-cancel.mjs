import fs from 'node:fs';
import https from 'node:https';
import crypto from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const ca=new crypto.X509Certificate(fs.readFileSync(path.join(root,'data/word-web/localhost.cer'))).toString();
function request(url,token,body,abort=false){return new Promise((resolve,reject)=>{
  let interrupted=false,timer;
  const req=https.request({hostname:'127.0.0.1',port:18766,path:url,method:body?'POST':'GET',ca,servername:'localhost',headers:{Host:'localhost:18766','Content-Type':'application/json',...(token?{'X-Scholar-Token':token,Origin:'https://localhost:18766'}:{})}},res=>{
    let text='';res.setEncoding('utf8');res.on('data',chunk=>text+=chunk);res.on('end',()=>{clearTimeout(timer);resolve(JSON.parse(text));});
  });
  req.setTimeout(20000,()=>req.destroy(new Error('Request timed out.')));
  req.on('error',error=>{clearTimeout(timer);if(interrupted)resolve({interrupted:true});else reject(error);});
  req.end(body?JSON.stringify(body):undefined);
  if(abort)timer=setTimeout(()=>{interrupted=true;req.destroy(new Error('Synthetic caller cancellation.'));},100);
});}
try{
  const {token}=await request('/api/session');
  const canceled=await request('/api/translate',token,{text:'试件的抗压强度增加，但不能据此推断长期耐久性。'.repeat(70),mode:'土木工程'},true);
  if(!canceled.interrupted)throw new Error('Fixture completed before cancellation; cancellation was not exercised.');
  const result=await request('/api/translate',token,{text:'我饿了。',mode:'日常交流'});
  if(!result.ok||!result.text.toLowerCase().includes('hungry'))throw new Error('Next request failed after canceled caller.');
  const report='PASS: actual localhost HTTPS caller interrupted; next real local translation succeeded through the shared broker. Synthetic text only. Model CPU stop latency was not measured.';
  fs.writeFileSync(path.join(root,'artifacts/word-cancel-test.txt'),report);console.log(report);
}catch(error){fs.writeFileSync(path.join(root,'artifacts/word-cancel-test.txt'),error.stack);console.error(error.message);process.exitCode=1;}
