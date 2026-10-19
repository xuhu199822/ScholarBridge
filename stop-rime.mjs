import net from 'node:net';
import {execFileSync} from 'node:child_process';
const sid=execFileSync('powershell.exe',['-NoProfile','-Command','[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'],{encoding:'utf8',windowsHide:true}).trim();
await new Promise((resolve,reject)=>{
  let settled=false,body='';const socket=net.createConnection(`\\\\.\\pipe\\ScholarBridge.Rime.${sid}`);
  socket.setTimeout(5000,()=>socket.destroy(new Error('Rime service busy; no forced termination performed.')));
  socket.on('connect',()=>socket.write(JSON.stringify({action:'shutdown'})+'\n'));
  socket.on('data',data=>{body+=data.toString('utf8');if(body.includes('\n')){try{if(!JSON.parse(body.split('\n')[0]).ok)throw new Error('Shutdown refused');settled=true;socket.end();resolve();}catch(error){socket.destroy(error);}}});
  socket.on('error',error=>{if(error.code==='ENOENT'){settled=true;resolve();}else reject(error);});
  socket.on('close',()=>{if(!settled)reject(new Error('Service closed before acknowledgement'));});
});
console.log('ScholarBridge pinyin service stopped normally or was already absent.');
