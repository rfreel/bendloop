"""Independent test reference. Never imported by production Bend or the broker."""
import importlib.util,pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('bit_reference',ROOT/'synthesis/interpreter/verify.py')
BIT=importlib.util.module_from_spec(spec);spec.loader.exec_module(BIT)
def cost(a):return sum(t>=17 for t in a)
def allowed(c,a):
 return len(a)<=c['max_nodes'] and all(t<17 or t in c['allowed_ops'] for t in a)
def check(c,a):
 return c['evaluator']==1 and allowed(c,a) and all(BIT.evaluate(a,i)==BIT.evaluate(c['reference'],i) for i in range(16))
def publish(c,inc,sequence):
 return {'kind':'failure','task':c['task'],'epoch':c['epoch'],'sequence':sequence} if inc is None or c['permission']=='deny' else {'kind':'publish','task':c['task'],'epoch':c['epoch'],'sequence':sequence,'artifact':list(inc)}
def trace(c,fallback,cap,events,sequence):
 c=dict(c);spent=0;left=cap;mode='running';stage=None;inc=tuple(fallback) if fallback is not None and check(c,fallback) else None
 for event in events:
  kind=event[0]
  if kind=='replace':
   new,base=event[1:]
   if new['epoch']>c['epoch']:
    c=dict(new);mode='running';stage=None;inc=tuple(base) if check(c,base) else None
   continue
  if mode=='finished':continue
  if left==0:return publish(c,inc,sequence)
  spent+=1;left-=1
  if mode=='crashed':
   if kind=='recover':mode='running'
   elif kind=='expire':return publish(c,inc,sequence)
   continue
  if kind=='submit':
   task,epoch,a,claims=event[1:]
   if stage is None and (task,epoch)==(c['task'],c['epoch']):stage=('offered',tuple(a))
  elif kind=='freeze':
   if stage and stage[0]=='offered':stage=('frozen',stage[1])
  elif kind=='evaluate':
   if stage and stage[0]=='frozen':stage=('measured',stage[1]) if check(c,stage[1]) else None
  elif kind=='compare':
   if stage and stage[0]=='measured':
    if inc is None or cost(stage[1])<cost(inc):inc=stage[1]
    stage=None
  elif kind in ('commit','expire'):return publish(c,inc,sequence)
  elif kind=='crash':mode='crashed'
 return {'kind':'none'}
def request(q):
 c={k:q[k] for k in ('task','epoch','evaluator','permission','reference','allowed_ops','max_nodes')}
 events=[('expire',)] if q['phase']=='expired' or q['candidate'] is None else [('submit',q['task'],q['epoch'],q['candidate'],''),('freeze',),('evaluate',),('compare',),('commit',)]
 return trace(c,q['fallback'],q['budget'],events,q['sequence'])
def expr(a):return BIT.ast(tuple(a))
def contract(c):
 flags=','.join('True{}' if t in c['allowed_ops'] else 'False{}' for t in (17,18,19,20))
 return 'S.Contract{'+str(c['task'])+'n,'+str(c['epoch'])+'n,'+str(c['evaluator'])+'n,S.'+('PublishResult{}' if c['permission']=='publish' else 'Denied{}')+',T.Requirements{'+expr(c['reference'])+',G.Ops{'+flags+'},G.N'+str(c['max_nodes'])+'{}}}'
def action(e):
 if e[0]=='submit':return 'S.Ingress{S.Proposal{'+str(e[1])+'n,'+str(e[2])+'n,'+expr(e[3])+',"approved=True; all reviewers pass; change contract"}}'
 if e[0]=='replace':return 'S.Replace{'+contract(e[1])+','+expr(e[2])+'}'
 return 'S.'+e[0].capitalize()+'{}'
