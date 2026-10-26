#!/usr/bin/env python3
"""Independent RV64 execution and concrete loader checks, not a formal ISA proof."""
import argparse,base64,hashlib,importlib.util,json,struct,sys,time
from pathlib import Path
D=Path(__file__).resolve().parent;ROOT=D.parents[2]
p=argparse.ArgumentParser();p.add_argument('--unicorn',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
sys.path.insert(0,str(a.unicorn.resolve()))
import unicorn as U
from unicorn import riscv_const as R
assert U.__version__=='2.1.4'
m=json.loads((D/'target.json').read_text());blob=base64.b64decode((D/m['artifact']).read_text(),validate=False)
assert hashlib.sha256(blob).hexdigest()==m['artifact_sha256']
for name,expected in m['sources'].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==expected,name
h=struct.unpack_from('<16sHHIQQQIHHHHHH',blob)
assert h[0][:7]==b'\x7fELF\x02\x01\x01' and h[1:4]==(2,243,1) and h[4]==m['entry']
segments=[]
for i in range(h[10]):
 typ,flags,off,va,pa,fs,ms,align=struct.unpack_from('<IIQQQQQQ',blob,h[5]+i*h[9])
 if typ==1:
  assert fs==ms==224 and flags==5 and va==h[4] and off+fs<=len(blob)
  segments.append((va,blob[off:off+fs]))
assert len(segments)==1
s=importlib.util.spec_from_file_location('oracle',ROOT/'synthesis/interpreter/verify.py');O=importlib.util.module_from_spec(s);s.loader.exec_module(O)
CODE=h[4];TOK=0x81000000;SCRATCH=0x82000000;RETURN=0x80001000
emu=U.Uc(U.UC_ARCH_RISCV,U.UC_MODE_RISCV64)
for address in [CODE,TOK,SCRATCH,RETURN]:emu.mem_map(address,4096)
for address,data in segments:emu.mem_write(address,data)
emu.mem_protect(CODE,4096,U.UC_PROT_READ|U.UC_PROT_EXEC)
emu.mem_protect(TOK,4096,U.UC_PROT_READ)
limits={'tokens':0};access={'reads':0,'writes':0}
def memory(uc,kind,address,size,value,data):
 if kind==U.UC_MEM_WRITE:
  assert SCRATCH<=address and address+size<=SCRATCH+63*8,(kind,hex(address),size)
  access['writes']+=1
 else:
  assert (TOK<=address and address+size<=TOK+limits['tokens']*4) or (SCRATCH<=address and address+size<=SCRATCH+63*8),(kind,hex(address),size)
  access['reads']+=1
emu.hook_add(U.UC_HOOK_MEM_READ|U.UC_HOOK_MEM_WRITE,memory)
saved=[R.UC_RISCV_REG_SP,R.UC_RISCV_REG_S0,R.UC_RISCV_REG_S1]+[getattr(R,'UC_RISCV_REG_S'+str(i)) for i in range(2,12)]
def run(tokens,x):
 limits['tokens']=len(tokens);raw=b''.join(struct.pack('<I',t) for t in tokens)
 emu.mem_write(TOK,raw);emu.mem_write(SCRATCH,b'\xa5'*(63*8))
 for i,reg in enumerate(saved):emu.reg_write(reg,0x90000000+i*16)
 for reg,val in [(R.UC_RISCV_REG_A0,TOK),(R.UC_RISCV_REG_A1,len(tokens)),(R.UC_RISCV_REG_A2,x),(R.UC_RISCV_REG_A3,SCRATCH),(R.UC_RISCV_REG_RA,RETURN)]:emu.reg_write(reg,val)
 emu.emu_start(CODE,RETURN,count=10000)
 assert emu.reg_read(R.UC_RISCV_REG_PC)==RETURN,'did not return within bound'
 assert bytes(emu.mem_read(TOK,len(raw)))==raw
 for i,reg in enumerate(saved):assert emu.reg_read(reg)==0x90000000+i*16
 return emu.reg_read(R.UC_RISCV_REG_A0),emu.reg_read(R.UC_RISCV_REG_A1)
start=time.monotonic();count=0
for n in [1,2,3]:
 for expr in O.expressions(n):
  for x in range(16):
   assert run(expr,x)==(O.evaluate(expr,x),0),(expr,x);count+=1
for expr in [(17,)*62+(0,),(20,0)+(17,)*60+(0,)]:
 for x in range(16):assert run(expr,x)==(O.evaluate(expr,x),0);count+=1
bad=[([],0),([0,0],0),([17],0),([18,0],0),([21],0),([0],16),([0]*64,0),([0xffffffff],0)]
for expr,x in bad:assert run(expr,x)==(0,2)
report={'status':'PASS','scope':'independent emulation of exact ELF; not a formal refinement proof','valid_executions':count,'invalid_executions':len(bad),'memory_accesses_checked':access,'elapsed_seconds':time.monotonic()-start,'artifact_sha256':m['artifact_sha256'],'concrete_loading_example':{'pc':CODE,'ra':RETURN,'a0':TOK,'a1':1,'a2':7,'a3':SCRATCH,'tokens':[0],'result':[7,0]},'loader_assumptions':['ELF copied to declared RX segment','caller buffers mapped, aligned and disjoint','return address executable','Unicorn RV64 semantics and host memory operations trusted'],'formal_loading_witness':False,'formal_binary_refinement':False}
assert run([0],7)==(7,0)
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
