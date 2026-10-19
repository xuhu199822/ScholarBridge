import net from 'node:net';
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const sid=execFileSync('powershell.exe',['-NoProfile','-Command','[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'],{encoding:'utf8',windowsHide:true}).trim();
const examples=['我今天晚上十点下班。','我今天晚上10点下班。','我晚上十点半下班。','我们三个人等五分钟。'];
function translate(text){return new Promise((resolve,reject)=>{const socket=net.createConnection(`\\\\.\\pipe\\ScholarBridge.Translate.${sid}`);let body='';socket.setEncoding('utf8');socket.setTimeout(120000,()=>socket.destroy(new Error('Timeout')));socket.on('connect',()=>socket.write(JSON.stringify({text,mode:'日常交流'})+'\n'));socket.on('data',chunk=>{body+=chunk;if(body.includes('\n')){socket.end();try{resolve(JSON.parse(body.split('\n')[0]));}catch(e){reject(e);}}});socket.on('error',reject);});}
const report=[];
for(const text of examples){const r=await translate(text);report.push({source:text,ok:r.ok,text:r.text,error:r.error});}
const after=process.argv.includes('--after');
fs.writeFileSync(new URL(after?'../artifacts/time-after.json':'../artifacts/time-before.json',import.meta.url),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
if(after&&report.some(r=>!r.ok))process.exitCode=1;
