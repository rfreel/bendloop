import Base
import ./parser.bend as J
import ../replay/runtime.bend as Replay
import ../certificates/runtime.bend as C
import ./schema.bend as V
import ../interpreter/runtime.bend as R
import ../search/runtime.bend as S
import ../search/grammar.bend as G
import ../search/render.bend as O

type Reply is Data:
  Reply{code: U32, output: String, diagnostic: String}

def invalid(why: String) -> Reply:
  Reply{2,"{\"status\":\"InvalidInput\"}",why}

def gate(ok: Bool, why: String, next: Unit -> Reply) -> Reply:
  match ok:
    case False{}: invalid(why)
    case True{}: next(Unit{})

def errors(error: String, next: Unit -> Reply) -> Reply:
  match error:
    case "": next(Unit{})
    case _: invalid(error)

def invalid_certificate(why: String) -> Reply:
  Reply{2,"{\"status\":\"InvalidCertificate\"}",why}

def cert_gate(ok: Bool, why: String, next: Unit -> Reply) -> Reply:
  match ok:
    case False{}: invalid_certificate(why)
    case True{}: next(Unit{})

def cert_errors(error: String, next: Unit -> Reply) -> Reply:
  match error:
    case "": next(Unit{})
    case _: invalid_certificate(error)

def bits(value: R.Expr) -> R.Bits:
  match value:
    case R.Constant{b}: b
    case _: C.input_0()

def eval_expr(input: U32, parsed: Maybe<&2,R.Expr>) -> Reply:
  match parsed:
    case None{}: invalid("AST shape")
    case Some{expr}: Reply{0,"{\"status\":\"Evaluated\",\"output\":" ++ U32.show(R.number(R.eval(expr,bits(G.constant((input + 1 : U32)))))) ++ "}",""}

def eval(+v: J.Value) -> Reply:
  errors(V.key_error(v,["input","program"]),u =>
    errors(V.error_if(V.integer(V.get("input",v)),"type: input",u => V.error_if(V.int_array(V.get("program",v)),"type: program",u => "")),u =>
      errors(V.error_if(V.range(V.get("input",v),0,15),"range: input",u => V.error_if(V.array_range(V.get("program",v),0,20,1n,63n),"range: program",u => "")),u =>
        eval_expr(V.num(V.get("input",v)),V.ast(V.get("program",v))))))

def search_result(value: Result<&2,&1,String,S.State>) -> Reply:
  match value:
    case Fail{error}: Reply{1,"{\"status\":\"InternalError\"}",error}
    case Done{state}: Reply{0,O.state(state),""}

def search_expr(+v: J.Value, expr: Maybe<&2,R.Expr>) -> Reply:
  match expr:
    case None{}: invalid("AST shape")
    case Some{ref}: search_result(S.synthesize(ref,V.ops(V.get("allowed_ops",v)),V.bound(V.num(V.get("max_nodes",v))),U32.to_nat(V.num(V.get("budget",v)))))

def synthesize(+v: J.Value) -> Reply:
  errors(V.key_error(v,["schema","reference","allowed_ops","max_nodes","budget"]),u =>
    errors(V.request_type_error(v),u =>
      errors(V.request_range_error(v),u => search_expr(v,V.ast(V.get("reference",v))))))

def table(values: List<&2,U32>) -> Maybe<&2,Replay.Table>:
  match values:
    case Con{v0,Con{v1,Con{v2,Con{v3,Con{v4,Con{v5,Con{v6,Con{v7,Con{v8,Con{v9,Con{v10,Con{v11,Con{v12,Con{v13,Con{v14,Con{v15,Nil{}}}}}}}}}}}}}}}}}: Some{Replay.Table{bits(G.constant((v0 + 1 : U32))),bits(G.constant((v1 + 1 : U32))),bits(G.constant((v2 + 1 : U32))),bits(G.constant((v3 + 1 : U32))),bits(G.constant((v4 + 1 : U32))),bits(G.constant((v5 + 1 : U32))),bits(G.constant((v6 + 1 : U32))),bits(G.constant((v7 + 1 : U32))),bits(G.constant((v8 + 1 : U32))),bits(G.constant((v9 + 1 : U32))),bits(G.constant((v10 + 1 : U32))),bits(G.constant((v11 + 1 : U32))),bits(G.constant((v12 + 1 : U32))),bits(G.constant((v13 + 1 : U32))),bits(G.constant((v14 + 1 : U32))),bits(G.constant((v15 + 1 : U32)))}}
    case _: None{}
def verdict(-r: Replay.Request,-p: Replay.Packet,result: Replay.Verdict<r,p>) -> Reply:
  match result:
    case Replay.Accepted{source,membership,strict,cost,equivalence,table}: Reply{0,"{\"status\":\"VerifiedImprovement\"}",""}
    case Replay.Invalid{why}: invalid_certificate(why)
def checked_packet(+r: Replay.Request,+p: Replay.Packet) -> Reply:
  verdict(r,p,Replay.replay(r,p))
def replay_table(+req: J.Value,ref: R.Expr,embedded: R.Expr,cand: R.Expr,cost: Nat,table: Maybe<&2,Replay.Table>) -> Reply:
  match table:
    case None{}: invalid_certificate("outputs shape")
    case Some{values}:
      checked_packet(Replay.Request{ref,V.ops(V.get("allowed_ops",req)),V.bound(V.num(V.get("max_nodes",req)))},
        Replay.Packet{embedded,cand,cost,values})
def replay_exprs(+req: J.Value,+cert: J.Value,ref: Maybe<&2,R.Expr>,embedded: Maybe<&2,R.Expr>,cand: Maybe<&2,R.Expr>) -> Reply:
  match ref embedded cand:
    case Some{r} Some{e} Some{c}:
      replay_table(req,r,e,c,U32.to_nat(V.num(V.get("candidate_cost",cert))),table(V.tokens(V.get("outputs",cert))))
    case _ _ _: invalid_certificate("AST shape")

def replay_fields(+req: J.Value, +cert: J.Value) -> Reply:
  cert_errors(V.key_error(cert,["schema","reference","candidate","candidate_cost","outputs"]),u => errors(V.key_error(req,["schema","reference","allowed_ops","max_nodes","budget"]),u => cert_errors(V.certificate_type_error(cert),u => errors(V.request_type_error(req),u => cert_errors(V.certificate_range_error(cert),u => errors(V.request_range_error(req),u => cert_gate(V.present(V.ast(V.get("candidate",cert))),"AST: certificate.candidate",u => cert_gate(V.present(V.ast(V.get("reference",cert))),"AST: certificate.reference",u => gate(V.present(V.ast(V.get("reference",req))),"AST: request.reference",u => replay_exprs(req,cert,V.ast(V.get("reference",req)),V.ast(V.get("reference",cert)),V.ast(V.get("candidate",cert))))))))))))

def replay(+v: J.Value) -> Reply:
  errors(V.key_error(v,["request","certificate"]),u => replay_fields(V.get("request",v),V.get("certificate",v)))

def dispatch(command: String, value: J.Value) -> Reply:
  match command:
    case "eval": eval(value)
    case "synthesize": synthesize(value)
    case "replay": replay(value)
    case _: invalid("expected eval, synthesize or replay")

def parsed(command: String, value: Maybe<&2,J.Value>) -> Reply:
  match value:
    case None{}: invalid("JSON syntax")
    case Some{v}: dispatch(command,v)

def run(command: String, text: String) -> Reply:
  parsed(command,J.parse(text))
