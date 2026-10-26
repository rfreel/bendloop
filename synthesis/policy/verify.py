#!/usr/bin/env python3
"""Independent native/proof/adversarial checks. Never supplies production answers."""
import argparse,copy,hashlib,importlib.util,itertools,json,os,pathlib,shutil,subprocess,tempfile,time
HERE=pathlib.Path(__file__).resolve().parent;ROOT=HERE.parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
G=load('gate',ROOT/'scripts/verify.py');O=load('policy_oracle',HERE/'oracle.py');I=load('expression_oracle',ROOT/'synthesis/interpreter/verify.py')
p=argparse.ArgumentParser();p.add_argument('--tools',type=pathlib.Path,default=ROOT/'.tools');p.add_argument('--output',type=pathlib.Path);a=p.parse_args()
tools=a.tools.resolve();out=(a.output or ROOT/'.artifacts'/('policy-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
bend=tools/'bend/bin/bend';env={k:v for k,v in os.environ.items() if k not in ('BENDTT','BEND_DIR','NODE_OPTIONS','BUN_OPTIONS','CPATH','C_INCLUDE_PATH','PYTHONPATH','LD_PRELOAD')}
env['PATH']=str(tools/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH'];env['CC']=shutil.which('clang-18') or str(tools/'clang18/usr/lib/llvm-18/bin/clang');env['BEND_NO_TELEMETRY']='1'
report={'status':'ERROR','scope':'source policy/replay laws and finite native learning experiments; not full synth4 release','negative_controls':[]}
started=time.monotonic()
def run(cmd,cwd,name,timeout=180,rejection=False):return G.run([str(x) for x in cmd],cwd,env,timeout,out/(name+'.log'),expect_rejection=rejection)
def call(binary,obj,raw=False):
    data=obj if raw else json.dumps(obj).encode()
    if isinstance(data,str):data=data.encode()
    r=subprocess.run([str(binary),'experiment','+RTS','--threads','1','--gpu','off','-RTS'],input=data,capture_output=True,timeout=15)
    return r.returncode,json.loads(r.stdout),r.stderr.decode(errors='replace')
try:
    lock=json.loads((ROOT/'toolchain.lock').read_text())
    if G.sha(bend)!=lock['bend']['binary_sha256']:raise ValueError('unpinned Bend')
    contract=json.loads((HERE/'contract.json').read_text())
    for name,expected in contract['sha256'].items():
        if G.sha(ROOT/name)!=expected:raise ValueError('review identity mismatch: '+name)
    report['contract_sha256']=G.sha(HERE/'contract.json')
    report['sources']={str(x.relative_to(ROOT)):G.sha(x) for d in ('policy','replay') for x in (ROOT/'synthesis'/d).glob('*') if x.is_file()}
    with tempfile.TemporaryDirectory(prefix='policy-verify-') as temp:
        snap=pathlib.Path(temp)/'source';shutil.copytree(ROOT,snap,ignore=shutil.ignore_patterns('.git','.artifacts','.tools','__pycache__'))
        for name,entry in [('policy','synthesis/policy/PROOF.bend'),('replay','synthesis/replay/PROOF.bend')]:
            verdict=run([bend,entry,'--verdict'],snap,name+'-kernel')
            if verdict.strip()!='ALL PROOFS CHECK':raise ValueError('missing exact kernel verdict')
            run([bend,entry,'-o',out/(name+'.bendtt')],snap,name+'-translation')
        binary=out/'policy';run([bend,'synthesis/policy/main.bend','-o',binary],snap,'cli-build')
        example=json.loads((HERE/'examples/learn-and-revise.json').read_text())
        experiments=[]
        for order,z,o,meta,cycle in itertools.product(('zero-first','ones-first','root-aware'),(False,True),(False,True),(0,1,3,5),(0,1,2)):
            q=copy.deepcopy(example);q['policy']={'zero':z,'ones':o,'order':order};q['meta_budget']=meta;q['cycle_budget']=cycle
            code,actual,stderr=call(binary,q);expected=O.experiment(q)
            if code or actual!=expected:raise ValueError('native experiment differs: '+str((q['policy'],meta,cycle,code,stderr)))
            experiments.append({'policy':q['policy'],'meta_budget':meta,'cycle_budget':cycle,'recursive_gain':actual['observed_recursive_gain']})
        report['native_experiments']=len(experiments)
        (out/'experiments.json').write_text(json.dumps(experiments,indent=2)+'\n')
        code,observed,_=call(binary,example)
        if code or not observed['observed_recursive_gain']:raise ValueError('positive learning/revision control failed')
        (out/'example-input.json').write_text(json.dumps(example,indent=2)+'\n');(out/'example-result.json').write_text(json.dumps(observed,indent=2)+'\n')
        report['observed']={'cold_costs':observed['heldout_learning_comparison']['old']['cold_costs'],
          'old_after':observed['heldout_learning_comparison']['old']['after_costs'],'new_after':observed['heldout_learning_comparison']['new']['after_costs'],
          'old_accepted':observed['original_revision_branch']['accepted'],'new_accepted':observed['revised_revision_branch']['accepted']}
        invalid=[]
        for key,value in [('candidate_budget',True),('meta_budget',-1),('max_nodes',8),('cycle_budget',17),('validation',[]),('cycles',[])]:
            q=copy.deepcopy(example);q[key]=value;invalid.append(q)
        for key,value in [('order','ignored'),('zero',1),('$','RootAware')]:
            q=copy.deepcopy(example);q['policy'][key]=value;invalid.append(q)
        q=copy.deepcopy(example);q['training'][0]['training']=[20,0];invalid.append(q)
        q=copy.deepcopy(example);q['validation'][0]['transfer']=[[99]];invalid.append(q)
        q=copy.deepcopy(example);q['scores']={'accepted':True};invalid.append(q)
        for group,key in [('validation','training'),('validation','transfer')]:
            q=copy.deepcopy(example);q[group][0][key]=q['training'][0]['training'] if key=='training' else [q['training'][0]['training']];invalid.append(q)
        q=copy.deepcopy(example);q['cycles'][0]=q['validation'][0]['transfer'][0];invalid.append(q)
        q=copy.deepcopy(example);q['protected']=[q['validation'][0]['training']];invalid.append(q)
        for q in invalid:
            code,actual,_=call(binary,q)
            if code!=2 or actual['status']!='InvalidInput':raise ValueError('invalid request accepted')
        for raw in ['{"policy":{},"policy":{}}','{"meta_budget":1.0}','[1,2]',b'\xff',b' '*65537]:
            code,actual,_=call(binary,raw,True)
            if code!=2:raise ValueError('malformed bytes accepted')
        report['invalid_requests']=len(invalid)+5
        # Bulk public-search check: all expressions of size<=3, all 12 policies,
        # and four candidate budgets. Expected answers use independent bit arithmetic.
        refs=O.space(3);policies=[{'zero':z,'ones':o,'order':m} for m,z,o in itertools.product(('zero-first','ones-first','root-aware'),(False,True),(False,True))]
        header='''import Base
import ./types.bend as P
import ./search.bend as S
import ../interpreter/runtime.bend as R
import ../search/grammar.bend as G

def show(result: Result<&2,&2,String,S.Observation>) -> String:
  match result:
    case Fail{e}: "ERROR"
    case Done{S.Observation{attempts,left,cost,improved,inputs,nodes,trials}}:
      Nat.show(attempts) ++ "," ++ Nat.show(left) ++ "," ++ Nat.show(cost) ++ "," ++ Bool.show(improved) ++ "," ++ Nat.show(inputs) ++ "," ++ Nat.show(nodes)
def caps(xs: +List<Nat>,+p: P.Policy,+e: R.Expr) -> IO(Unit):
  match xs:
    case Nil{}: IO.pure(Unit,Unit{})
    case Con{+n,tail}: IO.bind(Unit,Unit,IO.print(show(S.observed(S.run(p,e,G.Ops{True{},True{},True{},True{}},G.N3{},n)))),u => caps(tail,p,e))
def expressions(xs: +List<R.Expr>,+p: P.Policy) -> IO(Unit):
  match xs:
    case Nil{}: IO.pure(Unit,Unit{})
    case Con{e,tail}: IO.bind(Unit,Unit,caps([0n,1n,2n,17n],p,e),u => expressions(tail,p))
def policies(xs: +List<P.Policy>,+refs: +List<R.Expr>) -> IO(Unit):
  match xs:
    case Nil{}: IO.pure(Unit,Unit{})
    case Con{p,tail}: IO.bind(Unit,Unit,expressions(refs,p),u => policies(tail,refs))
'''
        modes={'zero-first':'ZeroFirst','ones-first':'OnesFirst','root-aware':'RootAware'}
        plist=["P.Policy{"+('True{}' if p['zero'] else 'False{}')+','+('True{}' if p['ones'] else 'False{}')+',P.'+modes[p['order']]+'{}}' for p in policies]
        code=header+'def main() -> IO(Unit):\n  policies(['+','.join(plist)+'],['+','.join(I.ast(e) for e in refs)+'])\n'
        fixture=snap/'synthesis/policy/bulk.bend';fixture.write_text(code);(out/'bulk.bend.txt').write_text(code)
        run([bend,'synthesis/policy/bulk.bend','-o',out/'bulk'],snap,'bulk-build')
        actual=run([out/'bulk','+RTS','--threads','1','--gpu','off','-RTS'],snap,'bulk-native',120).splitlines()
        expected=[]
        for p,ref,cap in itertools.product(policies,refs,(0,1,2,17)):
            o=O.observe(p,(ref,3,cap))
            expected.append(','.join(str(o[k]) for k in ('attempts','remaining','best_cost','improved','checked_inputs','verification_nodes')))
        if actual!=expected:
            i=next((i for i,(a,b) in enumerate(zip(actual,expected)) if a!=b),min(len(actual),len(expected)))
            raise ValueError('bulk public operation mismatch at '+str((i,actual[i:i+1],expected[i:i+1])))
        report['public_search_cases']=len(expected)
        # Every expression admitted in the individual traces is independently checked.
        report['expressions']=len(refs);report['policies']=len(policies)
        mutations=[
          ('collapse_permutation','policy/runtime.bend','case P.SeedZero{} 1n: 0n','case P.SeedZero{} 1n: 1n','policy/PROOF.bend'),
          ('disconnect_priority','policy/runtime.bend','select(zero && zero_form(reference),ones && ones_form(reference))','select(False{},False{})','policy/PROOF.bend'),
          ('disconnect_proposal','policy/runtime.bend','prefer(p,zero_form(task))','prefer(p,True{})','policy/PROOF.bend'),
          ('skip_charge','policy/search.bend','cap,1n+spent,left,best,trial','cap,spent,left,best,trial','policy/PROOF.bend'),
          ('create_credit','policy/search.bend','cap,spent,1n+left,best,trials','cap,spent,2n+left,best,trials','policy/PROOF.bend'),
          ('zero_quota_step','policy/search.bend','case 0n: Done{state}','case 0n: step(state)','policy/PROOF.bend'),
          ('ignore_starting_knowledge','policy/learning.bend','same_knowledge(before,proposed) && accepts(new,old)','True{} && accepts(new,old)','policy/PROOF.bend'),
          ('ignore_cold_start','policy/learning.bend','E.equal_costs(ac,bc) && E.no_worse(aw,bw)','True{} && E.no_worse(aw,bw)','policy/PROOF.bend'),
          ('accept_without_gain','policy/experiment.bend','no_worse(ac,bc) && better(ac,bc)','no_worse(ac,bc) && True{}','policy/PROOF.bend'),
          ('install_wrong_policy','policy/experiment.bend','case Comparison{before,proposed,old,new,True{}}: proposed','case Comparison{before,proposed,old,new,True{}}: before','policy/PROOF.bend'),
          ('alias_last_output','replay/runtime.bend','  v15\ndef matches_0','  v14\ndef matches_0','replay/PROOF.bend'),
          ('forge_cost','replay/runtime.bend','Packet{r,c,R.cost(c),Table{','Packet{r,c,0n,Table{','replay/PROOF.bend'),
        ]
        for name,path,before,after,entry in mutations:
            file=snap/'synthesis'/path;original=file.read_text()
            if before not in original:raise ValueError('negative-control anchor missing: '+name)
            file.write_text(original.replace(before,after,1))
            try:run([bend,'synthesis/'+entry,'--verdict'],snap,name,rejection=True)
            finally:file.write_text(original)
            report['negative_controls'].append(name)
        file=snap/'synthesis/policy/api.bend';original=file.read_text()
        marker='Separation.valid(training,validation,cycles,guard)'
        if marker not in original:raise ValueError('missing separation boundary')
        file.write_text(original.replace(marker,'True{}',1))
        run([bend,'synthesis/policy/main.bend','-o',out/'leaking-policy'],snap,'leakage-build')
        q=copy.deepcopy(example);q['cycles'][0]=q['validation'][0]['transfer'][0]
        code,_,_=call(out/'leaking-policy',q)
        if code!=0:raise ValueError('leakage mutant did not expose the intended false acceptance')
        # The same request was rejected by the clean binary above. This is a
        # native boundary control, not a claim of universal separation proof.
        report['negative_controls'].append('leakage_boundary_native')
        file.write_text(original)
        report['status']='PASS'
except Exception as error:
    report['error']=str(error)
finally:
    report['elapsed_seconds']=time.monotonic()-started
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':report['status'],'report':str(out/'report.json'),**({'error':report['error']} if 'error' in report else {})}))
raise SystemExit(0 if report['status']=='PASS' else 1)
