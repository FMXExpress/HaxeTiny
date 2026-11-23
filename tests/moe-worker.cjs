const assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const root=path.join(__dirname,'..','dist');
const messages=[],downloads=[];let pending;let corrupt='';let blocked='';let release;
const buffer=bytes=>bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength);
const scope={postMessage(message){messages.push(message);if(pending&&pending.type===message.type){const done=pending.resolve;pending=null;done(message);}},
 async fetch(url){downloads.push(url);if(url===blocked)await new Promise(resolve=>release=resolve);let data=fs.readFileSync(path.join(root,url));if(url===corrupt){data=Buffer.from(data);data[data.length-1]^=1;}return {ok:true,async text(){return data.toString();},async arrayBuffer(){return buffer(data);}};}};
const context={self:scope,console,Date,Math,Promise,Float32Array,Int8Array,DataView,ArrayBuffer,Uint8Array,Int32Array,setTimeout,clearTimeout,setInterval,clearInterval};
vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(root,'worker.js'),'utf8'),context);
function send(data){scope.onmessage({data});}
function wait(type){return new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Timeout: '+type)),10000);pending={type,resolve:m=>{clearTimeout(timer);resolve(m);}};});}
async function ask(text,expert){const start=messages.length;const done=wait('done');send({type:'ask',text,expert,creativity:0});const answer=await done;return {answer:answer.text,selected:messages.slice(start).find(m=>m.type==='selected')};}
(async()=>{
 let ready=wait('ready');send({type:'load',buffer:buffer(fs.readFileSync(path.join(root,'TINY.BIN')))});await ready;
 const cat=wait('catalog');send({type:'catalog'});assert.equal((await cat).entries.length,100);
 assert.deepEqual(downloads,['experts/catalog.json']);
 const fixtures=fs.readFileSync(path.join(__dirname,'fixtures/moe-comparison.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
 const example=id=>fixtures.find(r=>r.intended===id&&r.specialist===r.target);
 for(const id of [28,41,2]){const row=example(id);const r=await ask(row.question,id===28?-1:id);assert.equal(r.selected.id,id);assert.equal(r.answer,row.target);}
 const pascal=example(2);const before=downloads.length;await ask(pascal.question,2);assert.equal(downloads.length,before,'same expert should reuse the model');
 const fallback=await ask('what is the capital of peru',-1);assert.equal(fallback.selected.id,0);assert.equal(fallback.answer,'Lima.');
 const typo=await ask('what is a breakpiont',-1);assert.equal(typo.selected.id,28);assert.equal(typo.selected.corrected,true);assert(typo.selected.text.includes('breakpoint'));
 corrupt='experts/'+JSON.parse(fs.readFileSync(path.join(root,'experts/catalog.json'))).experts.find(e=>e.id===41).name;
 let failed=wait('error');send({type:'ask',text:example(41).question,expert:41,creativity:0});assert.match((await failed).message,/checksum/);
 const cached=downloads.length;await ask(example(28).question,28);assert.equal(downloads.length,cached,'failed load should retain previous expert');corrupt='';
 blocked='experts/'+JSON.parse(fs.readFileSync(path.join(root,'experts/catalog.json'))).experts.find(e=>e.id===1).name;
 const boundary=messages.length;send({type:'ask',text:example(1).question,expert:1,creativity:0});
 while(!release)await new Promise(resolve=>setTimeout(resolve,1));
 send({type:'stop'});release();await new Promise(resolve=>setTimeout(resolve,30));
 assert(!messages.slice(boundary).some(m=>m.type==='selected'||m.type==='done'),'stopped download must not replace model or generate');
 await ask(example(28).question,28);
 console.log('PASS: lazy loading, auto/manual routing, cache reuse, general fallback, typo correction, checksum failure recovery, cancelled download');
})().catch(error=>{console.error(error);process.exitCode=1;});
