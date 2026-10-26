#!/usr/bin/env python3
"""Audit a candidate against the external reviewed manifest, not its own copy."""
import argparse, hashlib, json
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--authority',type=Path,required=True)
p.add_argument('--root',type=Path,default=Path.cwd())
a=p.parse_args()
manifest=json.loads(a.authority.read_text())
root=a.root.resolve()
errors=[]
for name,expected in manifest['sha256'].items():
 f=root/name
 if f.is_symlink() or not f.is_file() or hashlib.sha256(f.read_bytes()).hexdigest()!=expected:
  errors.append(name)
if errors: raise SystemExit('REJECTED: frozen authority differs: '+', '.join(errors))
print('PASS: reviewed implementation authority matches')
