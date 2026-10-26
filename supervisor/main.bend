import Base
import ./driver.bend as A
import ../synthesis/json/utf8.bend as U

def exit_reply(code: U32, diagnostic: String) -> IO(Unit):
  IO.bind(Unit,Unit,IO.print_err(diagnostic),u => IO.exit(code))

def emit(reply: A.Reply) -> IO(Unit):
  match reply:
    case A.Reply{0,output,diagnostic}: IO.print(output)
    case A.Reply{code,output,diagnostic}: IO.bind(Unit,Unit,IO.print(output),u => exit_reply(code,diagnostic))

def decoded(command: String, text: Maybe<&2,String>) -> IO(Unit):
  match text:
    case None{}: emit(A.invalid("JSON syntax: invalid UTF-8"))
    case Some{s}: emit(A.run(command,s))

def finished(file: File, command: String, data: String) -> IO(Unit):
  IO.bind(Unit,Unit,File.close(file),u => decoded(command,U.decode(65537n,data,"")))

def bounded(ok: Bool, file: File, command: String, size: U32, data: String, next: File -> String -> U32 -> String -> IO(Unit)) -> IO(Unit):
  match ok:
    case True{}: next(file,command,size,data)
    case False{}: IO.bind(Unit,Unit,File.close(file),u => emit(A.invalid("input exceeds 65536 bytes")))

def chunk(file: File, command: String, size: U32, data: String, bytes: List<&2,U32>, next: File -> String -> U32 -> String -> IO(Unit)) -> IO(Unit):
  match bytes:
    case Nil{}: finished(file,command,data)
    case Con{h,t}:
      +xs = {Con{h,t} : List<&2,U32>}
      +total = (size + U32.from_nat(List.length(&2,U32,xs)) : U32)
      bounded(U32.is_le(total,65536),file,command,total,data ++ U.bytes(xs),next)

def read_value(file: File, command: String, size: U32, data: String, result: Result<&1,&1,U32 & String,List<&2,U32>>, next: File -> String -> U32 -> String -> IO(Unit)) -> IO(Unit):
  match result:
    case Fail{error}: IO.bind(Unit,Unit,File.close(file),u => emit(A.Reply{1,"{\"status\":\"InternalError\"}","stdin read failed"}))
    case Done{xs}: chunk(file,command,size,data,xs,next)

def read_result(command: String, size: U32, data: String, got: File & Result<&1,&1,U32 & String,List<&2,U32>>, next: File -> String -> U32 -> String -> IO(Unit)) -> IO(Unit):
  (file,result) = got
  read_value(file,command,size,data,result,next)

def read(fuel: Nat, file: File, command: String, +size: U32, data: String) -> IO(Unit):
  match fuel:
    case 0n: IO.bind(Unit,Unit,File.close(file),u => emit(A.invalid("input read allowance exhausted")))
    case 1n+p:
      IO.bind(File & Result<&1,&1,U32 & String,List<&2,U32>>,Unit,File.read_bytes(file,(65537 - size : U32)),r => read_result(command,size,data,r,f => cmd => n => s => read(p,f,cmd,n,s)))

def opened(command: String, result: Result<&1,&1,U32 & String,File>) -> IO(Unit):
  match result:
    case Fail{error}: emit(A.Reply{1,"{\"status\":\"InternalError\"}","stdin open failed"})
    case Done{file}: read(65538n,file,command,0,"")

def command(args: List<&1,String>) -> IO(Unit):
  match args:
    case Con{exe,Con{cmd,Nil{}}}: IO.bind(Result<&1,&1,U32 & String,File>,Unit,File.open("/dev/stdin","r"),r => opened(cmd,r))
    case _: emit(A.invalid("usage: supervisor decide"))

def main() -> IO(Unit):
  IO.bind(List<&1,String>,Unit,IO.args(),command)
