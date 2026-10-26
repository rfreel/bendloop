import argparse,hashlib,json,subprocess,sys,tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('binary',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
binary=a.binary.resolve();cases=[]
base={'task':7,'epoch':42,'evaluator':1,'permission':'publish','reference':[20,0,0],'allowed_ops':[17,18,19,20],'max_nodes':3,'fallback':[20,0,0],'candidate':[1],'budget':5,'sequence':0,'phase':'active'}
def run(label,q,code,artifact=None,kind=None):
 raw=q if isinstance(q,bytes) else json.dumps(q).encode()
 r=subprocess.run([str(binary),'decide','+RTS','--threads','1','--gpu','off','-RTS'],input=raw,capture_output=True,timeout=15)
 try:d=json.loads(r.stdout)
 except Exception as e:raise AssertionError((label,r.returncode,r.stdout[:100],r.stderr[:100])) from e
 assert r.returncode==code,(label,r.returncode,d,r.stderr)
 if artifact is not None:assert d.get('artifact')==artifact,(label,d)
 if kind is not None:assert d.get('kind')==kind,(label,d)
 cases.append({'name':label,'exit':r.returncode,'reply':d})
for budget in range(6):run('budget_'+str(budget),{**base,'budget':budget},0,artifact=[1] if budget>=4 else [20,0,0],kind='publish')
run('invalid_input_with_fabricated_review_fields',{**base,'candidate':[0],'reviews':[{'approved':True}]},2,kind='invalid')
run('actual_bad_candidate',{**base,'candidate':[0]},0,artifact=[20,0,0],kind='publish')
run('unsupported_evaluator',{**base,'evaluator':2},0,kind='failure')
run('revoked_permission',{**base,'permission':'deny'},0,kind='failure')
run('expired_ignores_candidate',{**base,'phase':'expired'},0,artifact=[20,0,0],kind='publish')
run('malformed_ast',{**base,'candidate':[20,0]},2,kind='invalid')
run('bool_sequence',{**base,'sequence':True},2,kind='invalid')
run('outside_grammar_and_no_qualified_fallback',{**base,'allowed_ops':[],'max_nodes':1,'fallback':[0],'candidate':[17,17,1]},0,kind='failure')
run('worker_trusted_effect_forgery',b'{"kind":"publish","approved":true,"artifact":[0]}',2,kind='invalid')
# Actual receiver adapter and broker path. All data/snapshots remain in /tmp.
sys.path.insert(0,str(Path(__file__).resolve().parent/'host'))
from broker import Broker,BoundaryError
from native import BendPort
sha=hashlib.sha256(binary.read_bytes()).hexdigest()
contracts={(7,42):{k:v for k,v in base.items() if k in {'evaluator','permission','reference','allowed_ops','max_nodes','fallback','budget'}}}
port=BendPort(binary,sha,contracts)
with tempfile.TemporaryDirectory() as td:
 b=Broker(Path(td)/'receiver',port);b.issue(7,42,4,60,incumbent=b'[20,0,0]')
 try:b.submit(b'{"kind":"publish","approved":true,"reviews":[true]}')
 except BoundaryError:cases.append({'name':'broker_rejects_forged_effect','result':'rejected'})
 else:raise AssertionError('forged worker effect entered trusted dispatcher')
 f=b.submit(b'[0]');assert b.commit(f);assert b.read_delivered()==b'[20,0,0]'
 cases.append({'name':'native_broker_rejects_invalid_candidate','artifact':[20,0,0]})
 f=b.submit(b'[1]');assert b.commit(f);assert b.read_delivered()==b'[1]'
 cases.append({'name':'native_broker_admits_valid_improvement','artifact':[1]})
 oldport=b._native_port
 def stale(c,f):
  c['last_effect']=-1
  return oldport(c,f)
 b._native_port=stale
 try:b.commit(f)
 except BoundaryError:cases.append({'name':'broker_rejects_stale_native_sequence','result':'rejected'})
 else:raise AssertionError('stale native sequence committed')
 b.close()
report={'status':'PASS','binary_sha256':sha,'count':len(cases),'cases':cases,'scope':'Finite adversarial checks against actual compiled native supervisor and host broker; not a universal host proof.'}
a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ('status','binary_sha256','count')}))
