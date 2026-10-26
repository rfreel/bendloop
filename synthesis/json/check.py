#!/usr/bin/env python3
import argparse,importlib.util,os,shutil,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
s=importlib.util.spec_from_file_location('gate',ROOT/'scripts/verify.py');G=importlib.util.module_from_spec(s);s.loader.exec_module(G)
p=argparse.ArgumentParser();p.add_argument('--tools',type=Path,required=True);a=p.parse_args()
tools=a.tools.resolve();out=ROOT/'.artifacts'/('json-'+str(time.time_ns()));out.mkdir(parents=True)
env=dict(os.environ);env['PATH']=str(tools/'lean-4.34.0-linux/bin')+os.pathsep+env['PATH'];env['CC']=shutil.which('clang-18') or 'clang-18'
bend=tools/'bend/bin/bend'
G.run([str(bend),'synthesis/json/main.bend','--verdict'],ROOT,env,180,out/'kernel.log')
G.run([str(bend),'synthesis/json/main.bend','-o',str(out/'synth4')],ROOT,env,180,out/'build.log')
G.run(['python3','synthesis/json/verify.py','--binary',str(out/'synth4'),'--output',str(out/'report.json')],ROOT,env,180,out/'native.log')
print('PASS: JSON boundary suite; '+str(out/'report.json'))
