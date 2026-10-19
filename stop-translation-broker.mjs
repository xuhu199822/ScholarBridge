import net from 'node:net';
import {execFileSync} from 'node:child_process';
const sid=execFileSync('powershell.exe',['-NoProfile','-Command','[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'],{encoding:'utf8',windowsHide:true}).trim();
await new Promise((resolve,reject)=>{
  const socket=net.createConnection(`\\\\.\\pipe\\ScholarBridge.Translate.${sid}`);let body='',settled=false;
  socket.setTimeout(5000,()=>socket.destroy(new Error('Broker is busy; no forced termination was performed.')));
  socket.on('connect',()=>socket.write(JSON.stringify({action:'shutdown'})+'\n'));
  socket.on('data',chunk=>{body+=chunk.toString('utf8');if(body.includes('\n')){try{if(!JSON.parse(body.split('\n')[0]).ok)throw new Error('Shutdown rejected.');settled=true;socket.end();resolve();}catch(error){socket.destroy(error);}}});
  socket.on('error',error=>{if(error.code==='ENOENT'){settled=true;resolve();}else reject(error);});
  socket.on('close',()=>{if(!settled)reject(new Error('Broker closed before acknowledging shutdown.'));});
});
console.log('Local translation broker stopped or already absent; it will restart on the next translation request.');
