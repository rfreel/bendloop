#!/usr/bin/env python3
"""Run stock pinned TLC; classify counterexamples separately from tool failures."""
import argparse,hashlib,json,pathlib,re,shutil,subprocess,tempfile,time
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
p=argparse.ArgumentParser();p.add_argument('--jar',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path);p.add_argument('--timeout',type=int,default=180);a=p.parse_args()
out=(a.output or ROOT/'.artifacts'/('supervisor-tla-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
lock=json.loads((HERE/'toolchain.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
report={'status':'ERROR','scope':'finite protocol model; no Bend/host refinement theorem','runs':[],'negative_controls':[],'sources':{p.name:sha(p) for p in HERE.iterdir() if p.suffix in ('.tla','.cfg','.py','.json')},'jar_sha256':sha(a.jar.resolve())}
started=time.monotonic()
def run(where,config,name,violation=None):
    command=['java','-XX:+UseParallelGC','-Xmx1200m','-cp',str(a.jar.resolve()),'tlc2.TLC','-workers','1','-cleanup','-config',config,'Supervisor.tla']
    try:r=subprocess.run(command,cwd=where,capture_output=True,text=True,timeout=a.timeout)
    except subprocess.TimeoutExpired as e:
        (out/(name+'.log')).write_text((e.stdout or b'').decode(errors='replace') if isinstance(e.stdout,bytes) else e.stdout or '')
        raise RuntimeError(name+': TLC timeout, not logical rejection')
    text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text)
    if violation is not None:
        if not re.search(r'Error: Invariant '+re.escape(violation)+r' is violated\.',text):raise RuntimeError(name+': missing intended counterexample; exit '+str(r.returncode))
        if 'Error: The behavior up to this point is:' not in text:raise RuntimeError(name+': missing counterexample trace')
        report['negative_controls'].append({'name':name,'invariant':violation,'exit_code':r.returncode,'log_sha256':sha(out/(name+'.log'))})
    else:
        if r.returncode or 'Model checking completed. No error has been found.' not in text:raise RuntimeError(name+': model check failed; exit '+str(r.returncode))
        states=re.findall(r'([\d,]+) states generated, ([\d,]+) distinct states found',text)
        report['runs'].append({'name':name,'config':config,'states_generated':int(states[-1][0].replace(',','')),'distinct_states':int(states[-1][1].replace(',','')),'log_sha256':sha(out/(name+'.log'))})
try:
    if report['jar_sha256']!=lock['sha256']:raise ValueError('TLC jar hash mismatch')
    java=subprocess.run(['java','-version'],capture_output=True,text=True,check=True);report['java']=java.stderr.strip()
    source=(HERE/'Supervisor.tla').read_text()
    with tempfile.TemporaryDirectory(prefix='supervisor-tla-') as tmp:
        directory=pathlib.Path(tmp)
        for name in ('Supervisor.tla','Small.cfg','NoFallback.cfg','ZeroFallback.cfg','ZeroFailure.cfg'):shutil.copy2(HERE/name,directory/name)
        run(directory,'Small.cfg','with-fallback');run(directory,'NoFallback.cfg','without-fallback')
        run(directory,'ZeroFallback.cfg','zero-budget-fallback');run(directory,'ZeroFailure.cfg','zero-budget-failure')
        config=(HERE/'Small.cfg').read_text();config=config.replace('PROPERTY Progress\n','')
        (directory/'Safety.cfg').write_text(config)
        mutations=[
          ('worker_approval','qualified |-> Qualified(frozen.epoch, frozen.artifact)','qualified |-> TRUE','EvidenceBinding'),
          ('snapshot_mismatch','/\\ evaluation.snapshot = frozen /\\ evaluation.snapshot.epoch = epoch','/\\ evaluation.snapshot.epoch = epoch','ExactFrozenEvidence'),
          ('stale_admission','/\\ evaluation.snapshot = frozen /\\ evaluation.snapshot.epoch = epoch','/\\ evaluation.snapshot = frozen','Admission'),
          ('stale_broker','/\\ prepared.epoch = epoch /\\ prepared = incumbent','/\\ TRUE','NoStaleCommit'),
          ('forbidden_effect','Required(e, a) /\\ Requested(a) \\subseteq Permitted(e)','Required(e, a)','EffectConfinement'),
          ('created_credit',"credits' = credits - 1","credits' = credits + 1",'BudgetConservation'),
          ('contract_budget_reset','UNCHANGED <<clock, credits, workerSpent, up, crashes, inbox, frozen, evaluation, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>',"credits' = Budget /\\ UNCHANGED <<clock, workerSpent, up, crashes, inbox, frozen, evaluation, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>",'BudgetConservation'),
          ('unbounded_worker',"workerSpent' = [workerSpent EXCEPT ![w] = @ + 1]","workerSpent' = [workerSpent EXCEPT ![w] = @ + 2]",'TypeOK'),
          ('rule_tamper',"epoch' = epoch + 1 /\\ stamp' = stamp + 1","epoch' = epoch + 1 /\\ stamp' = stamp",'ContractIntegrity'),
          ('stale_fallback',"incumbent' = Fallback(epoch + 1)","incumbent' = incumbent",'Admission'),
          ('partial_publish',"published' = prepared","published' = None",'AtomicPublication'),
          ('wrong_winner','evaluation.score > Score(incumbent.artifact)','evaluation.score < Score(incumbent.artifact)','Winner'),
        ]
        for name,before,after,violation in mutations:
            if before not in source:raise ValueError('mutation anchor missing: '+name)
            (directory/'Supervisor.tla').write_text(source.replace(before,after,1))
            # Isolate the named independent safety property, making the intended
            # exploit visible rather than accepting an earlier unrelated failure.
            selected=re.sub(r'INVARIANTS .*\n','INVARIANT '+violation+'\n',config)
            (directory/'Mutant.cfg').write_text(selected)
            run(directory,'Mutant.cfg',name,violation)
        (directory/'Supervisor.tla').write_text(source)
    report['status']='PASS'
except Exception as e:report['error']=str(e)
finally:
    report['elapsed_seconds']=time.monotonic()-started
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':report['status'],'report':str(out/'report.json'),**({'error':report['error']} if 'error' in report else {})}))
raise SystemExit(0 if report['status']=='PASS' else 1)
