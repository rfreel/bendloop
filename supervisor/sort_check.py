#!/usr/bin/env python3
"""Independent sorting observations; no Python result enters production admission."""
import argparse,collections,copy,hashlib,json,pathlib,random,subprocess,time
HERE=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--binary',type=pathlib.Path,required=True);p.add_argument('--sha256',required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args();binary=a.binary.resolve();assert hashlib.sha256(binary.read_bytes()).hexdigest()==a.sha256
base=json.loads((HERE/'sort/example.json').read_text());start=time.monotonic();cases=0

def rows(v):return [tuple(v[i:i+3]) for i in range(0,len(v),3)]
def flat(v):return [x for r in v for x in r]
def valid(ref,candidate):
 return candidate is not None and len(candidate)==24 and all(rows(candidate)[i][0]<=rows(candidate)[i+1][0] for i in range(7)) and collections.Counter(rows(ref))==collections.Counter(rows(candidate))
def quality(v):
 r=rows(v);return sum(r[i][0]==r[j][0] and r[i][1]>r[j][1] for i in range(8) for j in range(i+1,8))
def expected(q):
 incumbent=q['fallback'] if q['evaluator']==2 and valid(q['reference'],q['fallback']) else None
 if q['phase']=='active' and q['budget']>=4 and q['evaluator']==2 and valid(q['reference'],q['candidate']):
  if incumbent is None or quality(q['candidate'])<quality(incumbent):incumbent=q['candidate']
 out={'kind':'failure','task':q['task'],'epoch':q['epoch'],'sequence':q['sequence']}
 if incumbent is not None and q['permission']=='publish':out.update(kind='publish',artifact=incumbent)
 return out

def call(q,command='decide'):
 r=subprocess.run([str(binary),command,'+RTS','--threads','1','--gpu','off','-RTS'],input=json.dumps(q).encode(),capture_output=True,timeout=15)
 return r.returncode,json.loads(r.stdout)
ref=rows(base['reference']);correct=flat(sorted(ref));worst=flat(sorted(ref,key=lambda r:(r[0],-r[1])))
bad=list(correct);bad[3:6]=bad[0:3] # keep8records while dropping one duplicate and adding another
bad_value=list(correct);bad_value[5]=(bad_value[5]+1)%21
bad_id=list(correct);bad_id[4]=(bad_id[4]+1)%21
variants=[correct,worst,bad,bad_value,bad_id,base['reference']]
for i in range(24):
 changed=list(correct);changed[i]=(changed[i]+1)%21;variants.append(changed)
rng=random.Random(261026)
for _ in range(96):
 shuffled=list(ref);rng.shuffle(shuffled);variants.append(flat(shuffled))
for candidate in variants:
 for fallback in (correct,worst,None):
  q={**base,'candidate':candidate,'fallback':fallback};code,observed=call(q)
  if code or observed!=expected(q):raise AssertionError((q,code,observed,expected(q)))
  cases+=1
for budget in (0,1,3,4,5,9):
 for evaluator in (1,2,3):
  for permission in ('publish','deny'):
   for phase in ('active','expired'):
    q={**base,'candidate':correct,'fallback':worst,'budget':budget,'evaluator':evaluator,'permission':permission,'phase':phase};code,observed=call(q)
    if code or observed!=expected(q):raise AssertionError((q,code,observed,expected(q)))
    cases+=1
inspections=[]
for candidate in variants[:6]:
 q={**base,'candidate':candidate};code,observed=call(q,'inspect');cr=rows(candidate)
 ordered=all(cr[i][0]<=cr[i+1][0] for i in range(7));preserved=collections.Counter(ref)==collections.Counter(cr)
 if code or observed['ordered']!=ordered or observed['records_preserved']!=preserved:raise AssertionError(('inspection mismatch',q,observed))
 if not preserved:
  m=observed['missing_record'];record=tuple(m['record']);before=collections.Counter(ref)[record];after=collections.Counter(cr)[record]
  if (before,after)!=(m['expected_count'],m['observed_count']) or before==after:raise AssertionError(('false counterexample',observed))
 inspections.append(observed)
invalid=0
for key,value in [('candidate',correct[:-1]),('candidate',[True]+correct[1:]),('candidate',[21]+correct[1:]),('max_nodes',8),('allowed_ops',[17]),('approved',True),('budget',True)]:
 q={**base,key:value};code,observed=call(q)
 if code!=2:raise AssertionError(('invalid sorting request accepted',q,observed))
 invalid+=1
out={'status':'PASS','scope':'Finite actual sorting native checks against independent Python ordering, complete-record Counter and tie-preference arithmetic','binary_sha256':a.sha256,'decisions':cases,'invalid_requests':invalid,'inspections':inspections,'elapsed_seconds':time.monotonic()-start}
a.output.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:out[k] for k in ('status','decisions','invalid_requests','binary_sha256')}))
