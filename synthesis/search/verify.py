#!/usr/bin/env python3
"""Independent finite checks. This is not the missing enumeration/search proof."""
import argparse,importlib.util,itertools,json,os,shutil,tempfile,time
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[1]
def load(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
G=load('gate',ROOT/'scripts/verify.py');O=load('oracle',ROOT/'synthesis/interpreter/verify.py')
p=argparse.ArgumentParser();p.add_argument('--tools',type=Path,default=ROOT/'.tools');p.add_argument('--output',type=Path);a=p.parse_args()
tools=a.tools.resolve();out=(a.output or ROOT/'.artifacts'/('search-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
env=dict(os.environ);env['PATH']=str(tools/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH'];env['CC']=shutil.which('clang-18') or 'clang-18';env['BEND_NO_TELEMETRY']='1'
for k in ['BENDTT','BEND_DIR','NODE_OPTIONS','BUN_OPTIONS','CPATH','C_INCLUDE_PATH','PYTHONPATH']:env.pop(k,None)
bend=tools/'bend/bin/bend';report={'status':'ERROR','scope':'finite search/serialization evidence; source search laws not yet proved'}
def grammar(n,ops):
 if n==1:return [(i,) for i in range(17)]
 rows=[]
 if 17 in ops:rows += [(17,)+e for e in grammar(n-1,ops)]
 for op in ops:
  if op==17:continue
  for left in range(1,n-1):rows += [(op,)+x+y for x in grammar(left,ops) for y in grammar(n-1-left,ops)]
 return sorted(rows)
def cost(e):return sum(x>=17 for x in e)
def expected(ref,ops,n,cap):
 space=[e for size in range(1,n+1) for e in grammar(size,ops)]
 spent=min(cap,len(space));good=[e for e in space[:spent] if cost(e)<cost(ref) and all(O.evaluate(e,x)==O.evaluate(ref,x) for x in range(16))]
 candidate=min(good,key=lambda e:(cost(e),len(e),e)) if good else None
 best=None if candidate is None else {'candidate':list(candidate),'cost':cost(candidate),'nodes':len(candidate),'certificate':{'schema':'bendloop-synth4-v1','reference':list(ref),'candidate':list(candidate),'candidate_cost':cost(candidate),'outputs':[O.evaluate(candidate,x) for x in range(16)]}}
 return {'schema':'bendloop-synth4-v1','reference':list(ref),'allowed_ops':ops,'max_nodes':n,'cap':cap,'spent':spent,'left':cap-spent,'cursor':spent,'status':'SpaceExhausted' if spent==len(space) else 'BudgetExhausted','best':best}
refs=[tuple(c['program']) for c in json.loads((ROOT/'synthesis/spec/cases.json').read_text()) if c['kind']=='eval']
jobs=[];answers=[]
for mask,n,ref,cap in itertools.product(range(16),[1,2],refs,[0,1,2,16,17,18,40]):
 ops=[17+i for i in range(4) if mask&(1<<i)]
 flags=','.join('True{}' if mask&(1<<i) else 'False{}' for i in range(4))
 jobs.append('Job{'+O.ast(ref)+',G.Ops{'+flags+'},G.N'+str(n)+'{},'+str(cap)+'n}')
 answers.append(expected(ref,ops,n,cap))
try:
 if G.sha(bend)!=json.loads((ROOT/'toolchain.lock').read_text())['bend']['binary_sha256']:raise ValueError('unpinned Bend')
 with tempfile.TemporaryDirectory(prefix='search-check-') as tmp:
  snap=Path(tmp);shutil.copytree(ROOT/'synthesis',snap/'synthesis',ignore=shutil.ignore_patterns('__pycache__'));work=snap/'synthesis/search'
  def run(cmd,name,timeout=180):return G.run([str(x) for x in cmd],work,env,timeout,out/(name+'.log'))
  run([bend,'main.bend','--verdict'],'definitions')
  run([bend,'main.bend','-o',out/'search-demo'],'build-demo')
  rts=['+RTS','--threads','1','--gpu','off','-RTS']
  demo=json.loads(run([out/'search-demo',*rts],'demo',30))
  if demo!=expected((20,0,0),[17,18,19,20],3,2):raise ValueError('demo disagrees')
  pre='''import Base
import ./runtime.bend as S
import ./grammar.bend as G
import ./render.bend as J
import ../interpreter/runtime.bend as R

type Job is Data:
  Job{reference: R.Expr, ops: G.Ops, bound: G.Bound, budget: Nat}

def emit(job: Job) -> IO(Unit):
  match job:
    case Job{ref,ops,bound,budget}: IO.print(J.result(S.synthesize(ref,ops,bound,budget)))

'''
  for chunk,start in enumerate(range(0,len(jobs),784)):
   code=pre+'def main() -> IO(Unit):\n  List.for_each(&2,Job,emit,['+',\n'.join(jobs[start:start+784])+'])\n'
   (work/'fixture.bend').write_text(code);(out/f'fixture-{chunk}.bend.txt').write_text(code)
   run([bend,'fixture.bend','-o',out/f'fixture-{chunk}'],f'build-{chunk}')
   text=run([out/f'fixture-{chunk}',*rts],f'native-{chunk}',60)
   observed=[json.loads(line) for line in text.splitlines()]
   if observed!=answers[start:start+784]:raise ValueError('search mismatch in batch '+str(chunk))
  all_expr=[e for n in range(1,4) for e in grammar(n,[17,18,19,20])]
  code=pre+'''def show(value: Maybe<&2,G.Code>) -> String:
  match value:
    case None{}: "end"
    case Some{G.Code{n,value}}: U32.show(value)

def emit_index(i: U32) -> IO(Unit):
  IO.print(show(G.at(G.N3{},G.Ops{True{},True{},True{},True{}},i)))

def main() -> IO(Unit):
  List.for_each(&2,U32,emit_index,['''+','.join(str(i) for i in range(len(all_expr)+1))+'])\n'
  (work/'fixture.bend').write_text(code);(out/'enumeration.bend.txt').write_text(code)
  run([bend,'fixture.bend','-o',out/'enumeration'],'build-enumeration')
  found=run([out/'enumeration',*rts],'enumeration',30).splitlines()
  packed=[]
  for e in all_expr:
   v=0
   for t in e:v=v*21+t
   packed.append(str(v))
  if found!=packed+['end']:raise ValueError('enumeration order/coverage mismatch')
  code=pre+'''def main() -> IO(Unit):
  IO.print(J.result(S.continue(S.advance(1n,S.start(R.Xor{R.Input{},R.Input{}},G.Ops{False{},False{},False{},False{}},G.N1{},20n)),s => S.continue(S.advance(0n,s),s => S.continue(S.advance(1n,s),s => S.advance(100n,s))))))
'''
  (work/'fixture.bend').write_text(code);(out/'resume.bend.txt').write_text(code)
  run([bend,'fixture.bend','-o',out/'resume'],'build-resume')
  if json.loads(run([out/'resume',*rts],'resume',30))!=expected((20,0,0),[],1,20):raise ValueError('resume mismatch')
 report.update(status='PASS',search_cases=len(jobs),enumerated_programs=len(all_expr),resume_cases=1,json_output=True,json_input=False,proofs_complete=False)
except G.GateError as e:report.update(status=e.status,reason=e.message)
except (OSError,ValueError) as e:report.update(status='ERROR',reason=str(e))
report['sources']={str(f.relative_to(ROOT)):G.sha(f) for f in HERE.glob('*') if f.is_file()};report['artifacts']={f.name:G.sha(f) for f in out.iterdir() if f.is_file()}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'status':report['status'],'reason':report.get('reason'),'report':str(out/'report.json')}));raise SystemExit(0 if report['status']=='PASS' else 1)
