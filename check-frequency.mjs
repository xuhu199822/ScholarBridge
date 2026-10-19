import fs from 'node:fs';
import net from 'node:net';
import {execFileSync} from 'node:child_process';
const sid=execFileSync('powershell.exe',['-NoProfile','-Command','[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'],{encoding:'utf8',windowsHide:true}).trim();
const session='frequency-readiness-'+process.pid;
function call(action){return new Promise((resolve,reject)=>{let body='';const socket=net.createConnection(`\\\\.\\pipe\\ScholarBridge.Rime.${sid}`);socket.setTimeout(5000,()=>socket.destroy(new Error('Timeout')));socket.on('connect',()=>socket.write(JSON.stringify({action,session})+'\n'));socket.on('data',data=>{body+=data.toString('utf8');if(body.includes('\n')){socket.end();try{resolve(JSON.parse(body.split('\n')[0]));}catch(e){reject(e);}}});socket.on('error',reject);});}
const response=await call('context');await call('close');
if(!response.ok||!fs.existsSync(new URL('../data/rime/scholar_frequency.userdb',import.meta.url)))throw new Error('Frequency database did not initialize.');
console.log('PASS: installed schema opened its local frequency database; no keys, selections or user text were read or entered.');
