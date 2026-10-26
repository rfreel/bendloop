#!/usr/bin/env python3
"""Checks artifact identity/ELF structure only; does not prove machine behavior."""
import base64,hashlib,json,struct
from pathlib import Path
D=Path(__file__).resolve().parent;ROOT=D.parents[1]
m=json.loads((D/'artifact.json').read_text())
b=base64.b64decode((D/m['artifact']).read_text().strip(),validate=True)
assert hashlib.sha256(b).hexdigest()==m['sha256'], 'artifact digest differs'
assert len(b)==m['bytes'], 'artifact length differs'
h=struct.unpack_from('<16sHHIQQQIHHHHHH',b)
assert h[0][:7]==b'\x7fELF\x02\x01\x01' and h[1:4]==(3,62,1), 'wrong ELF target'
assert h[4]==m['entry_offset'], 'entry differs'
segments=[]
for i in range(h[10]):
 t,flags,off,va,pa,fs,ms,align=struct.unpack_from('<IIQQQQQQ',b,h[5]+i*h[9])
 if t==1:
  assert fs<=ms and off+fs<=len(b), 'invalid segment extent'
  assert align and not align&(align-1) and off%align==va%align, 'invalid alignment'
  segments.append(dict(offset=off,vaddr=va,filesz=fs,memsz=ms,flags=flags,align=align))
assert segments==m['load_segments'], 'segments differ'
assert any(s['flags']&1 and s['vaddr']<=h[4]<s['vaddr']+s['memsz'] for s in segments), 'entry not executable'
for name,digest in m['sources'].items():
 assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest, 'bound source differs: '+name
print('PASS: artifact identity and ELF structure; binary refinement NOT proved')
