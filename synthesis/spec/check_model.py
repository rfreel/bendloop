#!/usr/bin/env python3
"""Independent integer oracle versus compiled Bend reference, not a production synthesizer."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


def oracle(tokens, x):
    stream = iter(tokens)
    def step():
        token = next(stream)
        if token == 0:
            return x
        if 1 <= token <= 16:
            return token - 1
        a = step()
        if token == 17:
            return (~a) & 15
        b = step()
        if token == 18:
            return a & b
        if token == 19:
            return a | b
        if token == 20:
            return a ^ b
        raise ValueError('unknown token')
    result = step()
    if next(stream, None) is not None:
        raise ValueError('trailing token')
    return result


def word(n):
    value = 'WNil{}'
    for bit in reversed(range(4)):
        value = 'WCon{' + ('True{}' if n & (1 << bit) else 'False{}') + ',' + value + '}'
    return value


def expression(tokens):
    stream = iter(tokens)
    def step():
        t = next(stream)
        if t == 0:
            return 'M.Input{}'
        if t <= 16:
            return 'M.Constant{' + word(t-1) + '}'
        a = step()
        if t == 17:
            return 'M.Not{' + a + '}'
        return 'M.' + {18: 'And', 19: 'Or', 20: 'Xor'}[t] + '{' + a + ',' + step() + '}'
    return step()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--bend', required=True, type=Path)
    p.add_argument('--cc', default='clang-18')
    p.add_argument('--output', required=True, type=Path)
    args = p.parse_args()
    here = Path(__file__).resolve().parent
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    cases = json.loads((here/'cases.json').read_text())
    rows, expected = [], []
    for case in cases:
        if case['kind'] != 'eval':
            continue
        values = [oracle(case['program'], x) for x in range(16)]
        if values != case['expected_outputs']:
            raise ValueError('draft table disagrees with independent oracle: ' + case['id'])
        for x, value in enumerate(values):
            rows.append('Nat.show(Word.to_nat(4n,M.eval(' + expression(case['program']) + ',' + word(x) + ')))')
            expected.append(str(value))
    source = 'import Base\nimport ./model.bend as M\n\ndef main() -> IO(Unit):\n  IO.print(' + ' ++ "\\n" ++ '.join(rows) + ')\n'
    env = dict(os.environ, CC=args.cc, BEND_NO_TELEMETRY='1')
    with tempfile.TemporaryDirectory(prefix='synth-model-') as tmp:
        work = Path(tmp)
        (work/'model.bend').write_bytes((here/'model.bend').read_bytes())
        (work/'fixture.bend').write_text(source)
        verdict = subprocess.run([str(args.bend.resolve()), 'model.bend', '--verdict'], cwd=work, env=env, capture_output=True, text=True, timeout=180)
        (out/'kernel.log').write_text(verdict.stdout + verdict.stderr)
        if verdict.returncode or verdict.stdout.strip() != 'ALL PROOFS CHECK':
            raise RuntimeError('model kernel check failed; see kernel.log')
        build = subprocess.run([str(args.bend.resolve()), 'fixture.bend', '-o', str(out/'fixture')], cwd=work, env=env, capture_output=True, text=True, timeout=180)
        (out/'build.log').write_text(build.stdout + build.stderr)
        build.check_returncode()
        run = subprocess.run([str(out/'fixture'), '+RTS', '--threads', '1', '--gpu', 'off', '-RTS'], cwd=work, env=env, capture_output=True, text=True, timeout=30)
        run.check_returncode()
    wanted = '\n'.join(expected) + '\n'
    (out/'expected.txt').write_text(wanted)
    (out/'observed.txt').write_text(run.stdout)
    (out/'fixture.bend.txt').write_text(source)
    if run.stdout != wanted:
        raise ValueError('compiled reference disagrees with independent oracle')
    def digest(p):
        return hashlib.sha256(p.read_bytes()).hexdigest()
    report = {'scope': 'reference model only', 'status': 'PASS', 'evaluations': len(expected),
              'sources': {n: digest(here/n) for n in ['model.bend', 'cases.json', 'check_model.py']},
              'artifacts': {p.name: digest(p) for p in out.iterdir() if p.is_file()}}
    (out/'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'status': 'PASS', 'evaluations': len(expected), 'report': str(out/'report.json')}))


if __name__ == '__main__':
    main()
