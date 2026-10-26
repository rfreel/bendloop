#!/usr/bin/env python3
"""Receiver-controlled proof/native/mutation checks. No candidate supplies expected results."""
import argparse,copy,hashlib,importlib.util,itertools,json,os,pathlib,shutil,subprocess,tempfile,time
HERE=pathlib.Path(__file__).resolve().parent;ROOT=HERE.parent

def load(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
G=load('gate',ROOT/'scripts/verify.py');O=load('supervisor_reference',HERE/'oracle.py')
p=argparse.ArgumentParser();p.add_argument('--tools',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path);a=p.parse_args()
tools=a.tools.resolve();out=(a.output or ROOT/'.artifacts'/('supervisor-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
bend=tools/'bend/bin/bend';env={k:v for k,v in os.environ.items() if k not in ('LD_PRELOAD','BENDTT','BEND_DIR','PYTHONPATH','CPATH','C_INCLUDE_PATH')};env['CC']=shutil.which('clang-18') or str(tools/'clang18/usr/lib/llvm-18/bin/clang');env['PATH']=str(tools/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH']
report={'status':'ERROR','scope':'actual Bend supervisor source laws, finite native traces and receiver broker integration; not host/ISA refinement','negative_controls':[]};started=time.monotonic()
def run(cmd,cwd,name,reject=False):return G.run([str(x) for x in cmd],cwd,env,180,out/(name+'.log'),expect_rejection=reject)
def call(binary,q,raw=False):
 r=subprocess.run([str(binary),'decide','+RTS','--threads','1','--gpu','off','-RTS'],input=q if raw else json.dumps(q).encode(),capture_output=True,timeout=15)
 try:value=json.loads(r.stdout)
 except ValueError:raise ValueError('invalid native output '+repr((r.returncode,r.stdout,r.stderr)))
 return r.returncode,value
try:
 lock=json.loads((ROOT/'toolchain.lock').read_text());assert G.sha(bend)==lock['bend']['binary_sha256'],'unpinned Bend'
 report['sources']={str(x.relative_to(ROOT)):G.sha(x) for x in HERE.rglob('*') if x.suffix in ('.bend','.py','.tla','.cfg') and '__pycache__' not in str(x)}
 with tempfile.TemporaryDirectory(prefix='supervisor-check-') as temporary:
  snap=pathlib.Path(temporary)/'source';shutil.copytree(ROOT,snap,ignore=shutil.ignore_patterns('.git','.artifacts','.tools','__pycache__'))
  for name in ('PROOF','main'):
   if run([bend,'supervisor/'+name+'.bend','--verdict'],snap,name+'-kernel').strip()!='ALL PROOFS CHECK':raise ValueError('missing exact verdict')
  run([bend,'supervisor/PROOF.bend','-o',out/'supervisor.bendtt'],snap,'source-translation')
  binary=out/'supervisor';run([bend,'supervisor/main.bend','-o',binary],snap,'native-build');report['binary_sha256']=G.sha(binary)
  base={'task':7,'epoch':1,'evaluator':1,'permission':'publish','reference':[20,0,0],'allowed_ops':[17,18,19,20],'max_nodes':3,'fallback':[20,0,0],'candidate':[1],'budget':5,'sequence':2,'phase':'active'}
  requests=[]
  for reference,fallback,candidate in [([20,0,0],[20,0,0],[1]),([17,17,0],[17,17,0],[0]),([19,0,16],[19,0,16],[16]),([0],[0],[1]),([20,0,0],[0],[1]),([20,0,0],[0],[0]),([20,0,0],None,None),([20,0,0],None,[1])]:
   for budget,permission,evaluator,phase in itertools.product((0,1,3,4,5,9),('publish','deny'),(1,2),('active','expired')):
    q={**base,'reference':reference,'fallback':fallback,'candidate':candidate,'budget':budget,'permission':permission,'evaluator':evaluator,'phase':phase};requests.append(q)
  for ops,bound in itertools.product(([],[17],[18],[19],[20],[17,18,19,20]),(1,2,3)):
   requests.append({**base,'allowed_ops':ops,'max_nodes':bound})
  for q in requests:
   code,value=call(binary,q)
   if code or value!=O.request(q):raise ValueError('native request disagreement '+repr((q,code,value,O.request(q))))
  report['native_requests']=len(requests)
  code,positive=call(binary,base);assert positive['artifact']==[1] and code==0
  (out/'example-request.json').write_text(json.dumps(base,indent=2)+'\n');(out/'example-result.json').write_text(json.dumps(positive,indent=2)+'\n')
  invalid=[]
  for key,value in [('budget',True),('budget',257),('evaluator',-1),('candidate',[20,0]),('candidate',[True]),('permission','approved'),('reference',[]),('max_nodes',8),('allowed_ops',[20,17]),('approved',True),('phase','worker')]:
   q=copy.deepcopy(base);q[key]=value;invalid.append(q)
  for q in invalid:
   code,value=call(binary,q)
   if code!=2 or value!={'kind':'invalid'}:raise ValueError('invalid input admitted')
  for raw in [b'\xff',b' '*65537,b'{"task":1,"task":1}',b'{"budget":1.0}']:
   code,value=call(binary,raw,True)
   if code!=2:raise ValueError('invalid bytes admitted')
  report['invalid_requests']=len(invalid)+4
  # Exercise actual public transitions, not just the straight-line wire adapter.
  c={k:base[k] for k in ('task','epoch','evaluator','permission','reference','allowed_ops','max_nodes')}
  submit=('submit',7,1,[1],'claims');bad=('submit',7,1,[0],'approved');stale=('submit',7,0,[1],'replay')
  normal=[submit,('freeze',),('evaluate',),('compare',),('commit',)]
  revoked={**c,'epoch':2,'permission':'deny'};rollback={**c,'epoch':0,'permission':'deny'};changed={**c,'epoch':2,'reference':[0]}
  scripts=[normal,[bad,*normal[1:]],[stale,*normal[1:]],[submit,('freeze',),bad,('evaluate',),('compare',),('commit',)],
   [submit,('freeze',),('evaluate',),('replace',revoked,[20,0,0]),('compare',),('commit',)],
   [('replace',revoked,[20,0,0]),('commit',)],[('replace',rollback,[20,0,0]),*normal],
   [submit,('freeze',),('evaluate',),('replace',changed,[0]),('compare',),('commit',)],
   [('crash',),*normal,('recover',),('expire',)],[('crash',),('recover',),*normal],[bad]*12+[('expire',)],
   [('evaluate',),('compare',),('commit',)]]
  cases=[(cap,script) for cap,script in itertools.product((0,1,3,5,8,20),scripts)]
  source='import Base\nimport ./runtime.bend as S\nimport ./task.bend as T\nimport ./driver.bend as D\nimport ../synthesis/search/grammar.bend as G\nimport ../synthesis/interpreter/runtime.bend as R\n'
  source+='def output(r: D.Reply) -> IO(Unit):\n  D.Reply{code,text,error} = r\n  IO.print(text)\n'
  body='IO.pure(Unit,Unit{})'
  expected=[]
  for cap,script in reversed(cases):
   expression='D.drive(['+','.join(O.action(e) for e in script)+'],'+str(cap)+'n,2n,T.initial('+O.contract(c)+','+str(cap)+'n,'+O.expr([20,0,0])+'))'
   body='IO.bind(Unit,Unit,output('+expression+'),u => '+body+')'
  source+='def main() -> IO(Unit):\n  '+body+'\n'
  (snap/'supervisor/traces.bend').write_text(source);(out/'traces.bend.txt').write_text(source)
  run([bend,'supervisor/traces.bend','-o',out/'traces'],snap,'trace-build')
  actual=[json.loads(line) for line in run([out/'traces','+RTS','--threads','1','--gpu','off','-RTS'],snap,'trace-native').splitlines()]
  expected=[O.trace(c,[20,0,0],cap,script,2) for cap,script in cases]
  if actual!=expected:raise ValueError('public transition trace disagreement')
  report['native_protocol_traces']=len(cases)
  mutants=[('ignore_evaluator','task.bend','Nat.is_eq(evaluator,1n)','True{}'),
   ('ignore_qualification','task.bend','certified(reference,a,C.certify(reference,a))','True{}'),
   ('ignore_membership','task.bend','supported(c) && Replay.member(request(c),a)','supported(c) && True{}'),
   ('worse_winner','runtime.bend','Nat.is_lt(score(c,a),score(c,b))','Nat.is_lt(score(c,b),score(c,a))'),
   ('uncharged_event','runtime.bend','operate(K,A,check,score,cap,c,1n+spent,left,charged(spent,left,cap,p),mode,stage,inc,action)','operate(K,A,check,score,cap,c,spent,1n+left,p,mode,stage,inc,action)'),
   ('overwrite_frozen','runtime.bend','case _ _: stage\ndef freeze(', 'case Frozen{a} _: Offered{message}\n    case _ _: stage\ndef freeze('),
   ('zero_budget_revocation','runtime.bend','case Replace{next,fallback}: replace(K,A,check,cap,state,next,fallback)','case Replace{next,fallback}: budgeted(K,A,check,score,cap,state,Replace{next,fallback})')]
  for name,path,before,after in mutants:
   file=snap/'supervisor'/path;original=file.read_text()
   if before not in original:raise ValueError('mutation anchor missing: '+name)
   file.write_text(original.replace(before,after,1))
   try:
    if run([bend,'supervisor/task.bend','--verdict'],snap,name+'-welltyped').strip()!='ALL PROOFS CHECK':raise ValueError('mutation did not remain well typed')
    run([bend,'supervisor/PROOF.bend','--verdict'],snap,name,reject=True)
   finally:file.write_text(original)
   report['negative_controls'].append(name)
  env['BENDLOOP_HOST_EVIDENCE']=str(out/'host-capability.json')
  run(['python3','supervisor/host/test_host.py'],snap,'host-unit')
  run(['python3','supervisor/host/test_native.py','--binary',binary,'--sha256',G.sha(binary),'--output',out/'host-native.json'],snap,'host-native')
  run(['python3','supervisor/adversarial.py',binary,'--output',out/'adversarial.json'],snap,'adversarial-native')
  report['worker_isolation_available']=json.loads((out/'host-capability.json').read_text())['available']
  report['host_native_tests']=json.loads((out/'host-native.json').read_text())['tests']
  report['adversarial_cases']=json.loads((out/'adversarial.json').read_text())['count']
  for name in ('PROOF','main'):
   if run([bend,'supervisor/sort/'+name+'.bend','--verdict'],snap,'sort-'+name+'-kernel').strip()!='ALL PROOFS CHECK':raise ValueError('sorting kernel failed')
  sort_binary=out/'sort';run([bend,'supervisor/sort/main.bend','-o',sort_binary],snap,'sort-native-build')
  sort_sha=G.sha(sort_binary);report['sort_binary_sha256']=sort_sha
  run(['python3','supervisor/sort_check.py','--binary',sort_binary,'--sha256',sort_sha,'--output',out/'sort-native.json'],snap,'sort-independent')
  report['sorting_decisions']=json.loads((out/'sort-native.json').read_text())['decisions']
  sort_mutants=[('sort_drop_payload','sort/model.bend','Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi) && Nat.is_eq(av,bv)','Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi)'),
   ('sort_omit_count','sort/model.bend','Nat.add(flag(same(r0,record)),','Nat.add(0n,'),
   ('sort_skip_preservation','sort/task.bend','supported(c) && M.ordered(a) && M.preserved(reference(c),a)','supported(c) && M.ordered(a)'),
   ('sort_wrong_namespace','sort/task.bend','Nat.is_eq(evaluator,2n)','True{}')]
  for name,path,before,after in sort_mutants:
   file=snap/'supervisor'/path;original=file.read_text()
   if before not in original:raise ValueError('sorting mutation anchor missing: '+name)
   file.write_text(original.replace(before,after,1))
   try:
    if run([bend,'supervisor/sort/task.bend','--verdict'],snap,name+'-welltyped').strip()!='ALL PROOFS CHECK':raise ValueError('sorting mutant did not typecheck')
    run([bend,'supervisor/sort/PROOF.bend','--verdict'],snap,name,reject=True)
   finally:file.write_text(original)
   report['negative_controls'].append(name)
  run(['python3','supervisor/test_interface.py','--binary',binary,'--sha256',G.sha(binary),'--adapter','expr','--output',out/'interface-expr.json'],snap,'interface-expr')
  run(['python3','supervisor/test_interface.py','--binary',sort_binary,'--sha256',sort_sha,'--adapter','sort8','--output',out/'interface-sort.json'],snap,'interface-sort')
  report['interfaces']={n:json.loads((out/('interface-'+n+'.json')).read_text()) for n in ('expr','sort')}
  report['kernel_laws']={n:sum(line.startswith('law ') for line in (snap/p).read_text().splitlines()) for n,p in [('expression','supervisor/LAWS.bend'),('sorting','supervisor/sort/LAWS.bend')]}
  report['status']='PASS'
except Exception as e:report['error']=str(e)
finally:
 report['elapsed_seconds']=time.monotonic()-started;(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':report['status'],'report':str(out/'report.json'),**({'error':report['error']} if 'error' in report else {})}))
raise SystemExit(0 if report['status']=='PASS' else 1)
