// Build first: haxe -cp src -cp tests -main MoeTestMain -js build/moe-tests.js -D js-es=6
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const root=path.join(__dirname,'..');
require(path.join(root,'build/moe-tests.js'));
const {Router,Catalog,Bytes}=global.MoeTests;
const catalog=new Catalog(fs.readFileSync(path.join(root,'dist/experts/catalog.json'),'utf8'));
assert.equal(catalog.entries.length,100);
const rows=fs.readFileSync(path.join(__dirname,'fixtures/moe-route-probes.tsv'),'utf8').trim().split('\n').slice(1).map(line=>{const [expert,kind,question]=line.split('\t');return {expert:+expert,kind,question};});
const counts={};
for(const row of rows){const before=Router.rules(row.question),after=Router.route(row.question).id;counts[row.kind]??={n:0,rules:0,typo:0};counts[row.kind].n++;if(before===row.expert)counts[row.kind].rules++;if(after===row.expert)counts[row.kind].typo++;if(before!==0)assert.equal(after,before);}
assert.deepEqual(counts,{fresh:{n:201,rules:198,typo:198},typo:{n:100,rules:33,typo:67},none:{n:20,rules:19,typo:19}});
const comparisons=fs.readFileSync(path.join(__dirname,'fixtures/moe-comparison.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
for(const row of comparisons)assert.equal(Router.route(row.question).id,row.routed,`route differs: ${row.question}`);
const samples=new Map();
for(const row of comparisons)if(row.intended>0&&row.specialist===row.target&&!samples.has(row.intended))samples.set(row.intended,row);
assert.equal(samples.size,100);
let exact=0;const differences=[];
for(const entry of catalog.entries){
 const data=fs.readFileSync(path.join(root,'dist/experts',entry.name));
 const bytes=new Bytes(data.buffer.slice(data.byteOffset,data.byteOffset+data.byteLength));
 const model=catalog.decode(entry.id,bytes);const sample=samples.get(entry.id);
 const answer=model.answer(sample.question,0,null);
 if(answer===sample.target)exact++;
 else differences.push({id:entry.id,question:sample.question,expected:sample.target,answer});
}
const entry=catalog.entries[0];const data=fs.readFileSync(path.join(root,'dist/experts',entry.name));data[data.length-1]^=1;
assert.throws(()=>catalog.decode(entry.id,new Bytes(data.buffer.slice(data.byteOffset,data.byteOffset+data.byteLength))));
assert.throws(()=>catalog.get(999));
assert.throws(()=>new Catalog(JSON.stringify({version:1,experts:[{id:1,name:'../escape.BIN',title:'Bad',sha256:'0'.repeat(64)}]})));
console.log('Numerical differences from the integer Pascal engine:',differences);
assert(exact>=99&&differences.every(d=>d.id===48),'Unexpected specialist inference regression outside the documented abbreviation case');
console.log('PASS:',counts,`${comparisons.length} recorded route agreements; ${exact}/100 published successful examples; checksums and unsafe catalog rejection`);
