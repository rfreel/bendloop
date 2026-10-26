import Base
import ./runtime.bend as S
import ./task.bend as T
import ../synthesis/json/parser.bend as J
import ../synthesis/json/schema.bend as V
import ../synthesis/interpreter/runtime.bend as R
import ../synthesis/search/render.bend as O

type Reply is Data:
  Reply{code: U32,output: String,diagnostic: String}
def invalid(why: String) -> Reply: Reply{2,"{\"kind\":\"invalid\"}",why}
def render_effect(-c: S.Contract<T.Requirements>,task: Nat,epoch: Nat,sequence: Nat,value: S.Effect<T.Requirements,R.Expr,T.check,c>) -> Reply:
  match value:
    case S.NoEffect{}: Reply{0,"{\"kind\":\"none\"}",""}
    case S.Failure{}: Reply{0,"{\"kind\":\"failure\",\"task\":" ++ Nat.show(task) ++ ",\"epoch\":" ++ Nat.show(epoch) ++ ",\"sequence\":" ++ Nat.show(sequence) ++ "}",""}
    case S.Publish{logical_sequence,artifact,qualified,permitted}:
      Reply{0,"{\"kind\":\"publish\",\"task\":" ++ Nat.show(task) ++ ",\"epoch\":" ++ Nat.show(epoch) ++
        ",\"sequence\":" ++ Nat.show(sequence) ++ ",\"artifact\":[" ++ O.tokens(artifact) ++ "]}",""}
def process_effect(-cap: Nat,sequence: Nat,+c: S.Contract<T.Requirements>,spent: Nat,left: Nat,
  conserved: {Nat.add(spent,left) == cap : Nat},mode: S.Mode,stage: S.Stage<T.Requirements,R.Expr,T.check,c>,
  inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>,e: S.Effect<T.Requirements,R.Expr,T.check,c>,
  next: T.State(cap) -> Reply) -> Reply:
  match c e:
    case _ S.NoEffect{}: next(S.State{c,spent,left,conserved,mode,stage,inc})
    case S.Contract{task,epoch,v,p,k} S.Failure{}: render_effect(c,task,epoch,sequence,S.Failure{})
    case S.Contract{task,epoch,v,p,k} S.Publish{n,a,q,permission}: render_effect(c,task,epoch,sequence,S.Publish{n,a,q,permission})
def processed(-cap: Nat,sequence: Nat,result: T.Transition(cap),next: T.State(cap) -> Reply) -> Reply:
  match result:
    case S.Transition{S.State{c,s,l,p,m,stage,inc},e}: process_effect(cap,sequence,c,s,l,p,m,stage,inc,e,next)
def no_effect(-cap: Nat,state: T.State(cap)) -> Reply: Reply{0,"{\"kind\":\"none\"}",""}
def drive(actions: +List<S.Action<T.Requirements,R.Expr>>,-cap: Nat,+sequence: Nat,state: T.State(cap)) -> Reply:
  match actions:
    case Nil{}: no_effect(cap,state)
    case Con{action,tail}: processed(cap,sequence,T.step(cap,state,action),s => drive(tail,cap,sequence,s))
def seeded(+c: S.Contract<T.Requirements>,+cap: Nat,fallback: Maybe<&2,R.Expr>) -> T.State(cap):
  match fallback:
    case None{}: S.State{c,0n,cap,{==},S.Running{},S.Idle{},None{}}
    case Some{a}: T.initial(c,cap,a)
def execute(+c: S.Contract<T.Requirements>,+budget: Nat,sequence: Nat,fallback: Maybe<&2,R.Expr>,candidate: Maybe<&2,R.Expr>,expired: Bool) -> Reply:
  match c candidate expired:
    case S.Contract{+task,+epoch,evaluator,permission,requirements} Some{a} False{}:
      drive([S.Ingress{S.Proposal{task,epoch,a,""}},S.Freeze{},S.Evaluate{},S.Compare{},S.Commit{}],budget,sequence,seeded(c,budget,fallback))
    case _ _ _: drive([S.Expire{}],budget,sequence,seeded(c,budget,fallback))
def numbers(+v: J.Value) -> Bool:
  V.int_array(v) && V.array_range(v,0,20,1n,63n)
def phase(v: J.Value) -> Bool:
  match v:
    case J.JText{"active"}: True{}
    case J.JText{"expired"}: True{}
    case _: False{}
def expired(v: J.Value) -> Bool:
  match v:
    case J.JText{"expired"}: True{}
    case _: False{}
def permit(v: J.Value) -> Bool:
  match v:
    case J.JText{"publish"}: True{}
    case J.JText{"deny"}: True{}
    case _: False{}
def permission(v: J.Value) -> S.Permission:
  match v:
    case J.JText{"publish"}: S.PublishResult{}
    case _: S.Denied{}
def optional(v: J.Value) -> Bool:
  match v:
    case J.JNull{}: True{}
    case _: numbers(v)
def integer(+v: J.Value,hi: U32) -> Bool: V.integer(v) && V.range(v,0,hi)
def validated(+v: J.Value,ref: Maybe<&2,R.Expr>,fallback: Maybe<&2,R.Expr>,candidate: Maybe<&2,R.Expr>) -> Reply:
  match ref:
    case Some{r}:
      execute(S.Contract{U32.to_nat(V.num(V.get("task",v))),U32.to_nat(V.num(V.get("epoch",v))),U32.to_nat(V.num(V.get("evaluator",v))),
        permission(V.get("permission",v)),T.Requirements{r,V.ops(V.get("allowed_ops",v)),V.bound(V.num(V.get("max_nodes",v)))}},
        U32.to_nat(V.num(V.get("budget",v))),U32.to_nat(V.num(V.get("sequence",v))),fallback,candidate,expired(V.get("phase",v)))
    case None{}: invalid("reference AST shape")
def is_null(v: J.Value) -> Bool:
  match v:
    case J.JNull{}: True{}
    case _: False{}
def ops_valid(+v: J.Value) -> Bool:
  V.int_array(v) && V.array_range(v,17,20,0n,4n) && V.ordered(V.tokens(v),16)
def candidate_valid(+v: J.Value,good: Bool) -> Reply:
  match good:
    case False{}: invalid("candidate AST shape")
    case True{}: validated(v,V.ast(V.get("reference",v)),V.ast(V.get("fallback",v)),V.ast(V.get("candidate",v)))
def schema(+v: J.Value,ok: Bool) -> Reply:
  match ok:
    case False{}: invalid("supervisor request schema, range or type")
    case True{}:
      candidate_valid(v,(is_null(V.get("candidate",v)) || V.present(V.ast(V.get("candidate",v)))) && (is_null(V.get("fallback",v)) || V.present(V.ast(V.get("fallback",v)))))
def parsed(value: Maybe<&2,J.Value>) -> Reply:
  match value:
    case None{}: invalid("JSON syntax")
    case Some{+v}:
      schema(v,V.keys(v,["task","epoch","evaluator","permission","reference","allowed_ops","max_nodes","fallback","candidate","budget","sequence","phase"]) &&
        integer(V.get("task",v),4294967295) && integer(V.get("epoch",v),4294967295) && integer(V.get("evaluator",v),4294967295) &&
        integer(V.get("sequence",v),4294967295) && integer(V.get("budget",v),256) &&
        V.integer(V.get("max_nodes",v)) && V.range(V.get("max_nodes",v),1,7) &&
        numbers(V.get("reference",v)) && optional(V.get("fallback",v)) && optional(V.get("candidate",v)) &&
        phase(V.get("phase",v)) && permit(V.get("permission",v)) && ops_valid(V.get("allowed_ops",v)))
def run(command: String,text: String) -> Reply:
  match command:
    case "decide": parsed(J.parse(text))
    case _: invalid("usage: supervisor decide")
