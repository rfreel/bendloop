#!/usr/bin/env python3
import argparse,base64,hashlib,importlib.util,json,os,time
from pathlib import Path
D=Path(__file__).resolve().parent;ROOT=D.parents[2]
s=importlib.util.spec_from_file_location('gate',ROOT/'scripts/verify.py');G=importlib.util.module_from_spec(s);s.loader.exec_module(G)
p=argparse.ArgumentParser();p.add_argument('--tools',type=Path,required=True);a=p.parse_args();tools=a.tools.resolve()
m=json.loads((D/'target.json').read_text());cc=tools/'clang18/usr/bin/clang-18';ld=tools/'lean-4.34.0-linux/bin/ld.lld'
assert G.sha(cc)==m['clang_sha256'] and G.sha(ld)==m['linker_sha256']
wheels=list((tools/'wheels').glob('unicorn-2.1.4-*.whl'));assert len(wheels)==1 and G.sha(wheels[0])==m['emulator']['wheel_sha256']
out=ROOT/'.artifacts'/('rv64-'+str(time.time_ns()));out.mkdir(parents=True)
G.run([str(cc),'--target=riscv64-unknown-elf','-march=rv64i','-mabi=lp64','-nostdlib','-fuse-ld='+str(ld),'-Wl,-T,synthesis/machine/rv64/layout.ld','-Wl,--build-id=none','synthesis/machine/rv64/evaluator.S','-o',str(out/'interpreter.elf')],ROOT,dict(os.environ),60,out/'build.log')
assert G.sha(out/'interpreter.elf')==m['artifact_sha256'],'rebuilt ELF differs from pinned bytes'
G.run(['python3',str(D/'verify.py'),'--unicorn',str(tools/'unicorn'),'--output',str(out/'report.json')],ROOT,dict(os.environ),60,out/'emulator.log')
print('PASS: RV64 artifact reproduction and emulation, not formal refinement; '+str(out/'report.json'))
