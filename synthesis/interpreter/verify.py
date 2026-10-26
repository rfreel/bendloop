#!/usr/bin/env python3
"""Kernel + native differential evidence for the interpreter, not a binary refinement proof."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
spec = importlib.util.spec_from_file_location('gate_support', ROOT/'scripts/verify.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def expressions(n):
    if n == 1:
        return [(i,) for i in range(17)]
    result = [(17,) + e for e in expressions(n-1)]
    for left in range(1, n-1):
        for op in [18, 19, 20]:
            result.extend((op,) + a + b for a in expressions(left) for b in expressions(n-1-left))
    return sorted(result)


def evaluate(tokens, x):
    stream = iter(tokens)
    def go():
        t = next(stream)
        if t == 0: return x
        if t <= 16: return t-1
        a = go()
        if t == 17: return (~a) & 15
        b = go()
        if t == 18: return a & b
        if t == 19: return a | b
        if t == 20: return a ^ b
        raise ValueError(t)
    return go()


def bits(n):
    return 'R.Bits{' + ','.join('True{}' if n & (1 << i) else 'False{}' for i in range(4)) + '}'


def ast(tokens):
    stream = iter(tokens)
    def go():
        t = next(stream)
        if t == 0: return 'R.Input{}'
        if t <= 16: return 'R.Constant{' + bits(t-1) + '}'
        a = go()
        if t == 17: return 'R.Not{' + a + '}'
        return 'R.' + {18:'And',19:'Or',20:'Xor'}[t] + '{' + a + ',' + go() + '}'
    return go()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tools', type=Path, default=ROOT/'.tools')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    tools = args.tools.resolve()
    out = (args.output or ROOT/'.artifacts'/('interpreter-'+str(time.time_ns()))).resolve()
    out.mkdir(parents=True, exist_ok=False)
    report = {'scope':'Bend source refinement plus finite native evidence; no ISA proof', 'status':'ERROR', 'stages':[]}
    env = {k:v for k,v in os.environ.items() if k not in ['BENDTT','BEND_DIR','NODE_OPTIONS','BUN_OPTIONS','CPATH','C_INCLUDE_PATH','PYTHONPATH']}
    env['PATH'] = str(tools/'lean-4.34.0-linux/bin') + os.pathsep + env.get('PATH','')
    env['BEND_NO_TELEMETRY'] = '1'
    cc = shutil.which('clang-18')
    if cc: env['CC'] = cc
    bend = tools/'bend/bin/bend'
    try:
        lock = json.loads((ROOT/'toolchain.lock').read_text())
        if gate.sha(bend) != lock['bend']['binary_sha256']:
            raise ValueError('unpinned Bend binary')
        for name,key in [('base.bend','base_sha256'),('bendtt.lean','kernel_source_sha256')]:
            if gate.sha(tools/'bend/bend2'/name) != lock['bend'][key]:
                raise ValueError('unpinned '+name)
        if not cc: raise ValueError('clang-18 is required')
        report['tools'] = {'bend':gate.sha(bend),'clang':gate.sha(cc),'toolchain_lock':gate.sha(ROOT/'toolchain.lock')}
        report['sources'] = {str(p.relative_to(ROOT)):gate.sha(p) for p in sorted(HERE.glob('*')) if p.is_file()}
        report['sources']['synthesis/spec/model.bend'] = gate.sha(HERE.parent/'spec/model.bend')
        with tempfile.TemporaryDirectory(prefix='interpreter-check-') as tmp:
            snapshot = Path(tmp)
            shutil.copytree(HERE,snapshot/'interpreter',ignore=shutil.ignore_patterns('__pycache__'))
            (snapshot/'spec').mkdir()
            shutil.copy2(HERE.parent/'spec/model.bend',snapshot/'spec/model.bend')
            work = snapshot/'interpreter'
            def run(cmd,name,timeout=180,reject=False):
                return gate.run([str(x) for x in cmd],work,env,timeout,out/(name+'.log'),expect_rejection=reject)
            text = run([bend,'PROOF.bend','--verdict'],'kernel')
            if text.strip() != 'ALL PROOFS CHECK': raise ValueError('missing kernel verdict')
            report['stages'].append('kernel')
            run([bend,'PROOF.bend','-o',out/'PROOF.bendtt'],'translation')
            run([bend,'main.bend','-o',out/'interpreter-demo.c'],'emit-c')
            run([bend,'main.bend','-o',out/'interpreter-demo'],'build-demo')
            rts = ['+RTS','--threads','1','--gpu','off','-RTS']
            if run([out/'interpreter-demo',*rts],'demo',30) != '15\n':
                raise ValueError('native witness mismatch')
            programs = [e for n in range(1,4) for e in expressions(n)]
            extra = [(17,20,0,6),(18,17,0,19,0,6),(20,18,0,6,19,0,11)]
            programs += extra
            expected = []
            for e in programs:
                values = [str(evaluate(e,x)) for x in range(16)]
                expected.append(','.join(values+[str(sum(t>=17 for t in e)),str(len(e))]))
            cols = ['U32.show(R.number(R.eval(expr,'+bits(x)+')))' for x in range(16)]
            cols += ['Nat.show(R.cost(expr))','Nat.show(R.size(expr))']
            fixture = ('import Base\nimport ./runtime.bend as R\n\ndef emit(+expr: R.Expr) -> IO(Unit):\n  IO.print(' + ' ++ "," ++ '.join(cols) + ')\n\ndef main() -> IO(Unit):\n  List.for_each(&2,R.Expr,x => emit(x),[' + ','.join(ast(e) for e in programs) + '])\n')
            (work/'fixture.bend').write_text(fixture)
            (out/'fixture.bend.txt').write_text(fixture)
            run([bend,'fixture.bend','-o',out/'fixture'],'build-fixture')
            observed = run([out/'fixture',*rts],'fixture',30)
            expected_text = '\n'.join(expected)+'\n'
            (out/'expected.txt').write_text(expected_text)
            if observed != expected_text: raise ValueError('native differential mismatch')
            report.update(expressions=len(programs),exhaustive_size_le_3=len(programs)-len(extra),evaluations=len(programs)*16,cost_size_checks=len(programs)*2)
            report['stages'].append('native-independent-oracle')
            runtime = work/'runtime.bend'
            original = runtime.read_text()
            mutations = {
                'xor_is_or':('Bool.xor(a0,b0)','Bool.or(a0,b0)'),
                'constant_ignores_value':('case Constant{value}: value','case Constant{value}: input'),
                'not_is_identity':('Bool.not(a0)','a0'),
            }
            for name,(old,new) in mutations.items():
                if old not in original: raise ValueError('missing mutation anchor: '+name)
                runtime.write_text(original.replace(old,new,1))
                run([bend,'PROOF.bend','--verdict'],name,reject=True)
                runtime.write_text(original)
                report['stages'].append('rejected:'+name)
        report['status']='PASS'
    except gate.GateError as e:
        report.update(status=e.status,reason=e.message)
    except (OSError,ValueError) as e:
        report.update(status='ERROR',reason=str(e))
    report['artifacts']={p.name:gate.sha(p) for p in sorted(out.iterdir()) if p.is_file()}
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'status':report['status'],'report':str(out/'report.json'), 'reason':report.get('reason')}))
    return 0 if report['status']=='PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
