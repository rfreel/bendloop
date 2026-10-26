#!/usr/bin/env python3
"""Factory-owned component gate. Does not assert full synthesis release acceptance."""
import subprocess,sys
from pathlib import Path
here=Path(__file__).resolve().parent
commands=[
 [sys.executable,str(here/'check.py'),'--authority',str(here/'frozen.json')],
 [sys.executable,'scripts/verify.py','--tools','/tmp/bendloop-tools'],
 [sys.executable,'synthesis/certificates/verify.py','--tools','/tmp/bendloop-tools'],
 [sys.executable,'synthesis/search/verify.py','--tools','/tmp/bendloop-tools'],
 [sys.executable,'synthesis/machine/check_binding.py'],
 [sys.executable,'synthesis/search/check_laws.py','--tools','/tmp/bendloop-tools'],
 [sys.executable,'synthesis/json/check.py','--tools','/tmp/bendloop-tools'],
 [sys.executable,'synthesis/machine/rv64/check.py','--tools','/tmp/bendloop-tools'],
]
for cmd in commands:subprocess.run(cmd,check=True)
print('PASS: component gate only; synthesis/authority/release.py remains INCOMPLETE')
