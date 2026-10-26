#!/usr/bin/env python3
"""Independent native checks for the typed certifier and proof-path mutations."""
import argparse, importlib.util, json, os, shutil, tempfile, time
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def module(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
G=module('gate',ROOT/'scripts/verify.py')
O=module('oracle',ROOT/'synthesis/interpreter/verify.py')
p=argparse.ArgumentParser();p.add_argument('--tools',type=Path,default=ROOT/'.tools');p.add_argument('--output',type=Path);a=p.parse_args()
tools=a.tools.resolve();out=(a.output or ROOT/'.artifacts'/('certificates-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
env=dict(os.environ);env['PATH']=str(tools/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH'];env['BEND_NO_TELEMETRY']='1'
for k in ['BENDTT','BEND_DIR','NODE_OPTIONS','BUN_OPTIONS','CPATH','C_INCLUDE_PATH','PYTHONPATH']:env.pop(k,None)
cc=shutil.which('clang-18');env['CC']=cc or 'clang-18';bend=tools/'bend/bin/bend'
report={'status':'ERROR','scope':'typed certificates, not JSON replay or search','stages':[]}
try:
 lock=json.loads((ROOT/'toolchain.lock').read_text())
 if G.sha(bend)!=lock['bend']['binary_sha256']:raise ValueError('unpinned Bend')
 refs=[tuple(x['program']) for x in json.loads((ROOT/'synthesis/spec/cases.json').read_text()) if x['kind']=='eval']
 pairs=[((a,),(b,)) for a in range(1,17) for b in range(1,17)]
 pairs += [(r,(i,)) for r in refs for i in range(17)] + [(r,r) for r in refs]
 pairs += [((17,17,0),(0,)),((17,20,0,6),(20,0,11)),((20,0,0),(1,))]
 expected=[]
 for r,c in pairs:
  mismatches=[x for x in range(16) if O.evaluate(r,x)!=O.evaluate(c,x)]
  if mismatches:
   x=mismatches[0];expected.append(f'D:{x}:{O.evaluate(r,x)}:{O.evaluate(c,x)}')
  else:expected.append('E')
 fixture='''import Base
import ../interpreter/runtime.bend as R
import ./runtime.bend as C

def observe(+reference: R.Expr, +candidate: R.Expr, result: C.Check<reference,candidate>) -> String:
  match result:
    case C.Equivalent{certificate}: "E"
    case C.Different{input,refute}:
      +x = input
      "D:" ++ U32.show(R.number(x)) ++ ":" ++ U32.show(R.number(R.eval(reference,x))) ++ ":" ++ U32.show(R.number(R.eval(candidate,x)))

def emit(pair: R.Expr & R.Expr) -> IO(Unit):
  (+r,+c) = pair
  IO.print(observe(r,c,C.certify(r,c)))

def main() -> IO(Unit):
  List.for_each(&1,R.Expr & R.Expr,emit,['''+',\n'.join('('+O.ast(r)+','+O.ast(c)+')' for r,c in pairs)+'])\n'
 with tempfile.TemporaryDirectory(prefix='certifier-') as tmp:
  snap=Path(tmp);shutil.copytree(ROOT/'synthesis',snap/'synthesis',ignore=shutil.ignore_patterns('__pycache__'))
  work=snap/'synthesis/certificates'
  def run(cmd,name,reject=False):return G.run([str(x) for x in cmd],work,env,180,out/(name+'.log'),expect_rejection=reject)
  verdict=run([bend,'PROOF.bend','--verdict'],'kernel')
  if verdict.strip()!='ALL PROOFS CHECK':raise ValueError('missing exact kernel verdict')
  report['stages'].append('kernel')
  run([bend,'PROOF.bend','-o',out/'PROOF.bendtt'],'translation')
  (work/'fixture.bend').write_text(fixture);(out/'fixture.bend.txt').write_text(fixture)
  run([bend,'fixture.bend','-o',out/'fixture'],'build')
  observed=run([out/'fixture','+RTS','--threads','1','--gpu','off','-RTS'],'native')
  wanted='\n'.join(expected)+'\n';(out/'expected.txt').write_text(wanted)
  if observed!=wanted:raise ValueError('certifier/counterexample disagrees with independent oracle')
  report.update(pairs=len(pairs),equivalent=expected.count('E'),different=len(pairs)-expected.count('E'))
  report['stages'].append('native-certificates-and-counterexamples')
  file=work/'runtime.bend';original=file.read_text()
  for name,old,new in [('disconnected_evaluator','E.decide(R.eval(reference,input_0()),R.eval(candidate,input_0()))','E.decide(R.eval(reference,input_0()),R.eval(reference,input_0()))'),('skip_last_input',',p14,p15}}',',p14,p14}}')]:
   if old not in original:raise ValueError('mutation anchor missing '+name)
   file.write_text(original.replace(old,new,1));run([bend,'PROOF.bend','--verdict'],name,True);file.write_text(original);report['stages'].append('rejected:'+name)
 report['status']='PASS'
except G.GateError as e:report.update(status=e.status,reason=e.message)
except (OSError,ValueError) as e:report.update(status='ERROR',reason=str(e))
report['sources']={str(f.relative_to(ROOT)):G.sha(f) for f in HERE.glob('*') if f.is_file()}
report['artifacts']={f.name:G.sha(f) for f in out.iterdir() if f.is_file()}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'status':report['status'],'reason':report.get('reason'),'report':str(out/'report.json')}))
raise SystemExit(0 if report['status']=='PASS' else 1)
