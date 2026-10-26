#!/usr/bin/env python3
"""Native stdin/stdout tests; Python only supplies independent expected answers."""
import argparse,copy,hashlib,importlib.util,itertools,json,os,resource,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--binary',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
spec=importlib.util.spec_from_file_location('oracle',ROOT/'synthesis/interpreter/verify.py');O=importlib.util.module_from_spec(spec);spec.loader.exec_module(O)
count={'eval':0,'search':0,'replay':0,'invalid':0,'syntax':0}
def limits():
 resource.setrlimit(resource.RLIMIT_AS,(16*1024**3,16*1024**3));resource.setrlimit(resource.RLIMIT_CPU,(10,10))
def call(cmd,obj,raw=False):
 data=obj if raw else json.dumps(obj).encode()
 if isinstance(data,str):data=data.encode()
 r=subprocess.run([str(a.binary.resolve()),cmd,'+RTS','--threads','1','--gpu','off','-RTS'],input=data,capture_output=True,timeout=15,preexec_fn=limits)
 return r.returncode,json.loads(r.stdout),r.stderr.decode(errors='replace')
def grammar(n,ops):
 if n==1:return [(i,) for i in range(17)]
 rows=[]
 if 17 in ops:rows += [(17,)+x for x in grammar(n-1,ops)]
 for op in ops:
  if op==17:continue
  for l in range(1,n-1):rows.extend((op,)+x+y for x in grammar(l,ops) for y in grammar(n-1-l,ops))
 return sorted(rows)
def cost(x):return sum(t>=17 for t in x)
def expect(req):
 ref=tuple(req['reference']);space=[x for n in range(1,req['max_nodes']+1) for x in grammar(n,req['allowed_ops'])];spent=min(len(space),req['budget'])
 good=[x for x in space[:spent] if cost(x)<cost(ref) and all(O.evaluate(x,i)==O.evaluate(ref,i) for i in range(16))]
 candidate=min(good,key=lambda x:(cost(x),len(x),x)) if good else None
 best=None if candidate is None else {'candidate':list(candidate),'cost':cost(candidate),'nodes':len(candidate),'certificate':{'schema':'bendloop-synth4-v1','reference':list(ref),'candidate':list(candidate),'candidate_cost':cost(candidate),'outputs':[O.evaluate(candidate,i) for i in range(16)]}}
 return {'schema':'bendloop-synth4-v1','reference':list(ref),'allowed_ops':req['allowed_ops'],'max_nodes':req['max_nodes'],'cap':req['budget'],'spent':spent,'left':req['budget']-spent,'cursor':spent,'status':'SpaceExhausted' if spent==len(space) else 'BudgetExhausted','best':best}
refs=[x['program'] for x in json.loads((ROOT/'synthesis/spec/cases.json').read_text()) if x['kind']=='eval']
start=time.monotonic();replay_example=None
for ref,i in itertools.product(refs,range(16)):
 code,out,err=call('eval',{'program':ref,'input':i});assert(code,out,err)==(0,{'status':'Evaluated','output':O.evaluate(tuple(ref),i)},'');count['eval']+=1
for mask,n,ref,budget in itertools.product(range(16),[1,2],refs,[0,1,2,16,17,18,40]):
 req={'schema':'bendloop-synth4-v1','reference':ref,'allowed_ops':[17+i for i in range(4) if mask&(1<<i)],'max_nodes':n,'budget':budget}
 code,out,err=call('synthesize',req);assert code==0 and not err and out==expect(req),(req,code,out,err);count['search']+=1
 if out['best']:
  obj={'request':req,'certificate':out['best']['certificate']}
  code,out,err=call('replay',obj);assert(code,out,err)==(0,{'status':'VerifiedImprovement'},'');count['replay']+=1;replay_example=obj
assert replay_example
for field,value in [('candidate_cost',7),('reference',[16]),('outputs',[1]*16),('candidate',[0])]:
 obj=copy.deepcopy(replay_example);obj['certificate'][field]=value
 code,out,err=call('replay',obj);assert code==2 and out['status']=='InvalidCertificate' and err,(field,out);count['invalid']+=1
for obj in [{'program':[], 'input':0},{'program':[0,0],'input':0},{'program':[17],'input':0},{'program':[21],'input':0},{'program':[0],'input':True},{'program':[0],'input':1.0},{'program':[0],'input':-1},{'program':[0],'input':16},{'program':[0],'input':2**64},{'program':[0],'input':0,'extra':1}]:
 code,out,err=call('eval',obj);assert code==2 and err;count['invalid']+=1
for raw in [b'{',b'{"program":[0],"input":0,}',b'{"program":[0,],"input":0}',b'{"program":[0],"input":01}',b'{"program":[0],"input":NaN}',b'{"program":[0],"input":0,"input":1}',b'{"program":[0],"input":0,"inpu\\u0074":1}',b'{"program":[0],"input":0} false',b'\xff',b'\xc0\x80',b' '*65537]:
 code,out,err=call('eval',raw,True);assert code==2 and err,(raw,code,out,err);count['invalid']+=1
for raw in [b'{"progr\\u0061m":[0],"input":0}',b'{"program":[0],"input":-0}',b'{"program":[0],"input":0}'+b' '*(65536-25)]:
 code,out,err=call('eval',raw,True);assert code==0 and out['output']==0,(len(raw),code,out,err);count['syntax']+=1
# Frozen contract fixtures, including certificate status names.
for fixture in json.loads((ROOT/'synthesis/spec/cases.json').read_text()):
 kind=fixture['kind']
 if kind in ('eval','advance'):continue
 if kind=='synthesize':
  code,out,err=call('synthesize',fixture['request']);assert code==0 and out==expect(fixture['request']),fixture['id']
 elif kind=='invalid_request':
  code,out,err=call('synthesize',fixture['request']);assert code==2 and out['status']=='InvalidInput',fixture['id']
 elif kind=='invalid_json':
  code,out,err=call('synthesize',fixture['raw'],True);assert code==2,fixture['id']
 elif kind=='replay':
  code,out,err=call('replay',{'request':fixture['request'],'certificate':fixture['certificate']});assert code==fixture.get('expected_exit',0) and out['status']==fixture['expected'],fixture['id']
for raw,message in [('{"program":[99],"input":true}','type: input'),('{"program":[99],"input":16}','range: input'),('{"program":[0],"input":0,"z":0,"a":0}','key: a')]:
 code,out,err=call('eval',raw,True);assert code==2 and err.strip()==message,(raw,err)
report={'status':'PASS','counts':count,'elapsed_seconds':time.monotonic()-start,'binary_sha256':hashlib.sha256(a.binary.read_bytes()).hexdigest(),'sources':{str(x.relative_to(ROOT)):hashlib.sha256(x.read_bytes()).hexdigest() for x in (ROOT/'synthesis/json').glob('*.bend')},'formal_scope':'native boundary tests; no universal parser or replay theorem'}
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
