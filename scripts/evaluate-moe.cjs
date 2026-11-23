// Run after compiling tests/MoeTestMain.hx. Evaluate the frozen published Pascal corpus.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');const root=path.join(__dirname,'..');
require(path.join(root,'build/moe-tests.js'));
const {Catalog,Bytes,Model,Router}=global.MoeTests;
const catalog=new Catalog(fs.readFileSync(path.join(root,'dist/experts/catalog.json'),'utf8'));
const bytes=p=>{const b=fs.readFileSync(p);return new Bytes(b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength));};
const rows=fs.readFileSync(path.join(root,'tests/fixtures/moe-comparison.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
let active=-1,model;const totals={};const differences=[];
for(const row of rows){
 const route=Router.route(row.question);if(active!==route.id){model=route.id===0?new Model(bytes(path.join(root,'dist/TINY.BIN'))):catalog.decode(route.id,bytes(path.join(root,'dist/experts',catalog.get(route.id).name)));active=route.id;}
 const answer=model.answer(route.text,0,null);const key=row.suite;
 totals[key]??={questions:0,routingAgreement:0,pascalAnswerAgreement:0,exactAnswers:0};const result=totals[key];
 result.questions++;if(route.id===row.routed)result.routingAgreement++;if(answer===row.specialist)result.pascalAnswerAgreement++;if(answer===row.target)result.exactAnswers++;else if(differences.length<20)differences.push({question:row.question,id:route.id,expected:row.target,answer,pascal:row.specialist});
}
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
const result={provenance:{pasTinyCommit:JSON.parse(fs.readFileSync(path.join(root,'dist/experts/catalog.json'))).commit,corpusSha256:hash('tests/fixtures/moe-comparison.jsonl'),catalogSha256:hash('dist/experts/catalog.json'),workerSha256:hash('dist/worker.js')},method:'Frozen PasTiny SPEC100 paired evaluation; creativity 0; Haxe float inference with double accumulators vs published Pascal integer inference; exact includes punctuation.',totals,differences};
fs.writeFileSync(path.join(root,'benchmarks/moe-evaluation.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(totals,null,2));
