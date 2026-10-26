import Base
import ../runtime.bend as S
import ./task.bend as T
import ../../synthesis/json/parser.bend as J
import ../../synthesis/json/schema.bend as V
import ./model.bend as R
import ./model.bend as O

type Reply is Data:
  Reply{code: U32,output: String,diagnostic: String}
def invalid(why: String) -> Reply: Reply{2,"{\"kind\":\"invalid\"}",why}
def render_effect(-c: S.Contract<T.Requirements>,task: Nat,epoch: Nat,sequence: Nat,value: S.Effect<T.Requirements,R.Rows,T.check,c>) -> Reply:
  match value:
    case S.NoEffect{}: Reply{0,"{\"kind\":\"none\"}",""}
    case S.Failure{}: Reply{0,"{\"kind\":\"failure\",\"task\":" ++ Nat.show(task) ++ ",\"epoch\":" ++ Nat.show(epoch) ++ ",\"sequence\":" ++ Nat.show(sequence) ++ "}",""}
    case S.Publish{logical_sequence,artifact,qualified,permitted}:
      Reply{0,"{\"kind\":\"publish\",\"task\":" ++ Nat.show(task) ++ ",\"epoch\":" ++ Nat.show(epoch) ++
        ",\"sequence\":" ++ Nat.show(sequence) ++ ",\"artifact\":[" ++ O.tokens(artifact) ++ "]}",""}
def process_effect(-cap: Nat,sequence: Nat,+c: S.Contract<T.Requirements>,spent: Nat,left: Nat,
  conserved: {Nat.add(spent,left) == cap : Nat},mode: S.Mode,stage: S.Stage<T.Requirements,R.Rows,T.check,c>,
  inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>,e: S.Effect<T.Requirements,R.Rows,T.check,c>,
  next: T.State(cap) -> Reply) -> Reply:
  match c e:
    case _ S.NoEffect{}: next(S.State{c,spent,left,conserved,mode,stage,inc})
    case S.Contract{task,epoch,v,p,k} S.Failure{}: render_effect(c,task,epoch,sequence,S.Failure{})
    case S.Contract{task,epoch,v,p,k} S.Publish{n,a,q,permission}: render_effect(c,task,epoch,sequence,S.Publish{n,a,q,permission})
def processed(-cap: Nat,sequence: Nat,result: T.Transition(cap),next: T.State(cap) -> Reply) -> Reply:
  match result:
    case S.Transition{S.State{c,s,l,p,m,stage,inc},e}: process_effect(cap,sequence,c,s,l,p,m,stage,inc,e,next)
def no_effect(-cap: Nat,state: T.State(cap)) -> Reply: Reply{0,"{\"kind\":\"none\"}",""}
def drive(actions: +List<S.Action<T.Requirements,R.Rows>>,-cap: Nat,+sequence: Nat,state: T.State(cap)) -> Reply:
  match actions:
    case Nil{}: no_effect(cap,state)
    case Con{action,tail}: processed(cap,sequence,T.step(cap,state,action),s => drive(tail,cap,sequence,s))
def seeded(+c: S.Contract<T.Requirements>,+cap: Nat,fallback: Maybe<&2,R.Rows>) -> T.State(cap):
  match fallback:
    case None{}: S.State{c,0n,cap,{==},S.Running{},S.Idle{},None{}}
    case Some{a}: T.initial(c,cap,a)
def execute(+c: S.Contract<T.Requirements>,+budget: Nat,sequence: Nat,fallback: Maybe<&2,R.Rows>,candidate: Maybe<&2,R.Rows>,expired: Bool) -> Reply:
  match c candidate expired:
    case S.Contract{+task,+epoch,evaluator,permission,requirements} Some{a} False{}:
      drive([S.Ingress{S.Proposal{task,epoch,a,""}},S.Freeze{},S.Evaluate{},S.Compare{},S.Commit{}],budget,sequence,seeded(c,budget,fallback))
    case _ _ _: drive([S.Expire{}],budget,sequence,seeded(c,budget,fallback))
def numbers(+v: J.Value) -> Bool:
  V.int_array(v) && V.array_range(v,0,20,24n,24n)
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
def boolean(b: Bool) -> String:
  match b:
    case True{}: "true"
    case False{}: "false"
def missing_json(v: Maybe<&2,R.Missing>) -> String:
  match v:
    case None{}: "null"
    case Some{R.Missing{record,expected,observed}}:
      "{\"record\":[" ++ R.record_tokens(record) ++ "],\"expected_count\":" ++ Nat.show(expected) ++ ",\"observed_count\":" ++ Nat.show(observed) ++ "}"
def unordered_json(v: Maybe<&2,R.Unordered>) -> String:
  match v:
    case None{}: "null"
    case Some{R.Unordered{index,left,right}}:
      "{\"left_index\":" ++ Nat.show(index) ++ ",\"left\":[" ++ R.record_tokens(left) ++ "],\"right\":[" ++ R.record_tokens(right) ++ "]}"
def inspection(+reference: R.Rows,value: Maybe<&2,R.Rows>) -> Reply:
  match value:
    case None{}: invalid("inspection requires a candidate")
    case Some{+candidate}:
      Reply{0,"{\"kind\":\"inspection\",\"ordered\":" ++ boolean(R.ordered(candidate)) ++
        ",\"records_preserved\":" ++ boolean(R.preserved(reference,candidate)) ++
        ",\"missing_record\":" ++ missing_json(R.missing(reference,candidate)) ++
        ",\"unordered_pair\":" ++ unordered_json(R.unordered(candidate)) ++ "}",""}
def validated(command: String,+v: J.Value,ref: Maybe<&2,R.Rows>,fallback: Maybe<&2,R.Rows>,candidate: Maybe<&2,R.Rows>) -> Reply:
  match command ref:
    case "inspect" Some{r}: inspection(r,candidate)
    case _ Some{r}:
      execute(S.Contract{U32.to_nat(V.num(V.get("task",v))),U32.to_nat(V.num(V.get("epoch",v))),U32.to_nat(V.num(V.get("evaluator",v))),
        permission(V.get("permission",v)),T.Requirements{r}},
        U32.to_nat(V.num(V.get("budget",v))),U32.to_nat(V.num(V.get("sequence",v))),fallback,candidate,expired(V.get("phase",v)))
    case _ None{}: invalid("reference requires exactly eight records")
def is_null(v: J.Value) -> Bool:
  match v:
    case J.JNull{}: True{}
    case _: False{}
def ops_valid(+v: J.Value) -> Bool:
  V.int_array(v) && V.array_range(v,17,20,0n,0n)
def present(v: Maybe<&2,R.Rows>) -> Bool:
  match v:
    case Some{r}: True{}
    case None{}: False{}
def parse_rows(v: J.Value) -> Maybe<&2,R.Rows>: R.parse(V.tokens(v))
def candidate_valid(command: String,+v: J.Value,good: Bool) -> Reply:
  match good:
    case False{}: invalid("candidate requires exactly eight records")
    case True{}: validated(command,v,parse_rows(V.get("reference",v)),parse_rows(V.get("fallback",v)),parse_rows(V.get("candidate",v)))
def schema(command: String,+v: J.Value,ok: Bool) -> Reply:
  match ok:
    case False{}: invalid("supervisor request schema, range or type")
    case True{}:
      candidate_valid(command,v,(is_null(V.get("candidate",v)) || present(parse_rows(V.get("candidate",v)))) && (is_null(V.get("fallback",v)) || present(parse_rows(V.get("fallback",v)))))
def parsed(command: String,value: Maybe<&2,J.Value>) -> Reply:
  match value:
    case None{}: invalid("JSON syntax")
    case Some{+v}:
      schema(command,v,V.keys(v,["task","epoch","evaluator","permission","reference","allowed_ops","max_nodes","fallback","candidate","budget","sequence","phase"]) &&
        integer(V.get("task",v),4294967295) && integer(V.get("epoch",v),4294967295) && integer(V.get("evaluator",v),4294967295) &&
        integer(V.get("sequence",v),4294967295) && integer(V.get("budget",v),256) &&
        V.integer(V.get("max_nodes",v)) && V.range(V.get("max_nodes",v),7,7) &&
        numbers(V.get("reference",v)) && optional(V.get("fallback",v)) && optional(V.get("candidate",v)) &&
        phase(V.get("phase",v)) && permit(V.get("permission",v)) && ops_valid(V.get("allowed_ops",v)))
def run(command: String,text: String) -> Reply:
  match command:
    case "decide": parsed("decide",J.parse(text))
    case "inspect": parsed("inspect",J.parse(text))
    case _: invalid("usage: supervisor decide")
