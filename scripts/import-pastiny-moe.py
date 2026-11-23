"""Import PasTiny's SPEC100 models and generated topic/glossary tables.
Usage: python3 scripts/import-pastiny-moe.py /path/to/PasTiny
"""
from pathlib import Path
import hashlib, json, re, shutil, struct, subprocess, sys, zipfile, zlib
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1]).resolve();moe=source/'PasTinyMoE'
revision=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
assets=root/'dist/experts';assets.mkdir(exist_ok=True)
entries=[]
with zipfile.ZipFile(moe/'dist/SPEC100.ZIP') as archive:
    data=archive.read('EXPERTS.CAT')
    assert data[:4]==b'PEC1' and data[4]==100 and len(data)==6805
    for i in range(data[4]):
        record=data[5+i*68:5+(i+1)*68];p=1;fields=[]
        for capacity in (12,28,20):
            length=record[p];assert length<=capacity
            fields.append(record[p+1:p+1+length].decode('ascii'));p+=capacity+1
        name,title,keyword=fields
        assert re.fullmatch(r'[A-Z0-9_]+\.BIN',name),name
        model=archive.read(name);crc=struct.unpack_from('<I',record,p)[0]
        assert zlib.crc32(model)==crc and len(model)==381808
        (assets/name).write_bytes(model)
        entries.append(dict(id=record[0],name=name,title=title,keyword=keyword,sha256=hashlib.sha256(model).hexdigest()))
entries.sort(key=lambda e:e['id']);assert [e['id'] for e in entries]==list(range(1,101))
(assets/'catalog.json').write_text(json.dumps(dict(version=1,source='https://github.com/FMXExpress/PasTiny',commit=revision,experts=entries),indent=2)+'\n')
shutil.copy2(moe/'LICENSE',assets/'LICENSE');shutil.copy2(moe/'NOTICE.TXT',assets/'NOTICE.txt')
topics=[(term,int(id)) for term,id in re.findall(r"\(Term:'([^']+)'; Id:(\d+)\)",(moe/'TOPIC100.INC').read_text())];assert len(topics)==536
(root/'src/ExpertTopics.hx').write_text('// Generated from PasTiny TOPIC100.INC at '+revision+'; see dist/experts/LICENSE.\nclass ExpertTopics {\n public static final entries:Array<{term:String,id:Int}> = [\n'+',\n'.join('  {term:'+json.dumps(t)+',id:'+str(i)+'}' for t,i in topics)+'\n ];\n}\n')
pascal=(moe/'PILOTRT.PAS').read_text()
functions=[]
for original,new,args in [('GlossaryDomain','glossary','c:String'),('PCAndPascalDomain','pcAndPascal','q:String,c:String'),('DOSGlossaryDomain','dosGlossary','q:String,c:String')]:
    part=pascal[pascal.index('function '+original):];part=part[part.index('begin'):part.index('\nend;')]
    rules=re.findall(r'(?:else\s+)?if\s+(.*?)\s+then\s+'+original+r':=(\d+)',part,re.S)
    code=[]
    for condition,id in rules:
        pieces=re.split(r"('(?:[^']|'')*')",condition)
        for i in range(0,len(pieces),2):
            x=pieces[i]
            for a,b in [('Pos','pos'),('Context','c'),('Q','q'),('C','c'),('and','&&'),('or','||'),('not','!')]:x=re.sub(r'\b'+a+r'\b',b,x)
            x=x.replace('<>','!=');x=re.sub(r'(?<![<>!:])=(?!=)','==',x)
            pieces[i]=x
        code.append('  if ('+''.join(pieces).strip()+') return '+id+';')
    functions.append(' public static function '+new+'('+args+'):Int {\n'+'\n'.join(code)+'\n  return 0;\n }')
(root/'src/ExpertGlossary.hx').write_text('// Generated SPEC100 glossary precedence rules; PasTiny commit '+revision+'.\nclass ExpertGlossary {\n static inline function pos(term:String,text:String):Int return text.indexOf(term)+1;\n'+'\n'.join(functions)+'\n}\n')
shutil.copy2(moe/'tests/route_probes.tsv',root/'tests/fixtures/moe-route-probes.tsv')
print('Imported 100 verified models, 536 topics and glossary rules from',revision)

shutil.copy2(moe/'specialists/batch100/comparison.jsonl',root/'tests/fixtures/moe-comparison.jsonl')
