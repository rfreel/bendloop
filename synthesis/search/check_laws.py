#!/usr/bin/env python3
import argparse,importlib.util,json,os,shutil,tempfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
s=importlib.util.spec_from_file_location('gate',ROOT/'scripts/verify.py');G=importlib.util.module_from_spec(s);s.loader.exec_module(G)
p=argparse.ArgumentParser();p.add_argument('--tools',type=Path,required=True);p.add_argument('--output',type=Path);a=p.parse_args()
out=(a.output or ROOT/'.artifacts'/('search-laws-'+str(time.time_ns()))).resolve();out.mkdir(parents=True,exist_ok=False)
bend=a.tools.resolve()/'bend/bin/bend';env=dict(os.environ);env['PATH']=str(a.tools.resolve()/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH']
G.run([str(bend),'synthesis/search/PROOF.bend','--verdict'],ROOT,env,180,out/'kernel.log')
mutations=[('skipped_charge','1n+spent,left,consider','spent,left,consider'),('credit_creation','spent,1n+left,best','spent,2n+left,best'),('zero_quota_steps','case 0n: Done{state}','case 0n: step(state)')]
for name,old,new in mutations:
 with tempfile.TemporaryDirectory(prefix='search-law-mutant-') as d:
  root=Path(d);shutil.copytree(ROOT/'synthesis',root/'synthesis',ignore=shutil.ignore_patterns('__pycache__'))
  f=root/'synthesis/search/runtime.bend';text=f.read_text();assert old in text;f.write_text(text.replace(old,new,1))
  G.run([str(bend),'synthesis/search/PROOF.bend','--verdict'],root,env,180,out/(name+'.log'),expect_rejection=True)
report={'status':'PASS','laws':['start_valid','resume_composes','budget_conserved'],'rejected_mutations':[x[0] for x in mutations],'sources':{str(p.relative_to(ROOT)):G.sha(p) for p in (ROOT/'synthesis/search').glob('*.bend')}}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'status':'PASS','report':str(out/'report.json')}))
