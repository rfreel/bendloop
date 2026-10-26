import Base
import ../json/parser.bend as J
import ../json/schema.bend as V
import ./separation.bend as Separation
import ./types.bend as P
import ./experiment.bend as E
import ./learning.bend as L
import ./recursive.bend as Rec
import ./render.bend as Render
import ../search/grammar.bend as G
import ../interpreter/runtime.bend as R

type Reply is Data:
  Reply{code: U32,output: String,diagnostic: String}
type Request is Data:
  Request{policy: P.Policy,training: +List<L.Episode>,validation: +List<L.Episode>,
          cycles: +List<E.Task>,protected: +List<E.Task>,meta_cap: Nat,cycle_cap: Nat}
def invalid(why: String) -> Reply: Reply{2,"{\"status\":\"InvalidInput\"}",why}
def error(why: String) -> Reply: Reply{1,"{\"status\":\"InternalError\"}",why}
def truth(v: J.Value) -> Maybe<&2,Bool>:
  match v:
    case J.JBoolean{x}: Some{x}
    case _: None{}
def order(v: J.Value) -> Maybe<&2,P.Order>:
  match v:
    case J.JText{"zero-first"}: Some{P.ZeroFirst{}}
    case J.JText{"ones-first"}: Some{P.OnesFirst{}}
    case J.JText{"root-aware"}: Some{P.RootAware{}}
    case _: None{}
def policy_fields(z: Maybe<&2,Bool>,o: Maybe<&2,Bool>,m: Maybe<&2,P.Order>) -> Maybe<&2,P.Policy>:
  match z o m:
    case Some{a} Some{b} Some{c}: Some{P.Policy{a,b,c}}
    case _ _ _: None{}
def policy_keys(ok: Bool,+v: J.Value) -> Maybe<&2,P.Policy>:
  match ok:
    case False{}: None{}
    case True{}: policy_fields(truth(V.get("zero",v)),truth(V.get("ones",v)),order(V.get("order",v)))
def policy(+v: J.Value) -> Maybe<&2,P.Policy>:
  policy_keys(V.keys(v,["zero","ones","order"]),v)
def task_ast(v: Maybe<&2,R.Expr>,bound: G.Bound,cap: Nat) -> Maybe<&2,E.Task>:
  match v:
    case None{}: None{}
    case Some{expr}: Some{E.Task{expr,G.Ops{True{},True{},True{},True{}},bound,cap}}
def task_valid(ok: Bool,v: J.Value,bound: G.Bound,cap: Nat) -> Maybe<&2,E.Task>:
  match ok:
    case False{}: None{}
    case True{}: task_ast(V.ast(v),bound,cap)
def task(+v: J.Value,bound: G.Bound,cap: Nat) -> Maybe<&2,E.Task>:
  task_valid(V.int_array(v) && V.array_range(v,0,20,1n,63n),v,bound,cap)
def task_cons(a: Maybe<&2,E.Task>,b: Maybe<&2,+List<E.Task>>) -> Maybe<&2,+List<E.Task>>:
  match a b:
    case Some{x} Some{xs}: Some{x <> xs}
    case _ _: None{}
def task_items(xs: +List<J.Value>,+bound: G.Bound,+cap: Nat) -> Maybe<&2,+List<E.Task>>:
  match xs:
    case Nil{}: Some{Nil{}}
    case Con{x,tail}: task_cons(task(x,bound,cap),task_items(tail,bound,cap))
def task_array(ok: Bool,values: +List<J.Value>,bound: G.Bound,cap: Nat) -> Maybe<&2,+List<E.Task>>:
  match ok:
    case False{}: None{}
    case True{}: task_items(values,bound,cap)
def tasks(v: J.Value,min: Nat,bound: G.Bound,cap: Nat) -> Maybe<&2,+List<E.Task>>:
  match v:
    case J.JItems{+xs}: task_array(Nat.is_ge(List.length(&2,J.Value,xs),min) && Nat.is_le(List.length(&2,J.Value,xs),16n),xs,bound,cap)
    case _: None{}
def episode_fields(t: Maybe<&2,E.Task>,test: Maybe<&2,+List<E.Task>>,protect: Maybe<&2,+List<E.Task>>,budget: Nat) -> Maybe<&2,L.Episode>:
  match t test protect:
    case Some{a} Some{b} Some{c}: Some{L.Episode{a,b,c,budget}}
    case _ _ _: None{}
def episode_valid(ok: Bool,+v: J.Value,+bound: G.Bound,+cap: Nat) -> Maybe<&2,L.Episode>:
  match ok:
    case False{}: None{}
    case True{}:
      episode_fields(task(V.get("training",v),bound,cap),tasks(V.get("transfer",v),1n,bound,cap),
        tasks(V.get("protected",v),0n,bound,cap),U32.to_nat(V.num(V.get("learning_budget",v))))
def episode(+v: J.Value,bound: G.Bound,cap: Nat) -> Maybe<&2,L.Episode>:
  episode_valid(V.keys(v,["training","transfer","protected","learning_budget"]) &&
    V.integer(V.get("learning_budget",v)) && V.range(V.get("learning_budget",v),0,5),v,bound,cap)
def episode_cons(a: Maybe<&2,L.Episode>,b: Maybe<&2,+List<L.Episode>>) -> Maybe<&2,+List<L.Episode>>:
  match a b:
    case Some{x} Some{xs}: Some{x <> xs}
    case _ _: None{}
def episode_items(xs: +List<J.Value>,+bound: G.Bound,+cap: Nat) -> Maybe<&2,+List<L.Episode>>:
  match xs:
    case Nil{}: Some{Nil{}}
    case Con{x,tail}: episode_cons(episode(x,bound,cap),episode_items(tail,bound,cap))
def episode_array(ok: Bool,xs: +List<J.Value>,bound: G.Bound,cap: Nat) -> Maybe<&2,+List<L.Episode>>:
  match ok:
    case False{}: None{}
    case True{}: episode_items(xs,bound,cap)
def episodes(v: J.Value,bound: G.Bound,cap: Nat) -> Maybe<&2,+List<L.Episode>>:
  match v:
    case J.JItems{+xs}: episode_array(Nat.is_ge(List.length(&2,J.Value,xs),1n) && Nat.is_le(List.length(&2,J.Value,xs),8n),xs,bound,cap)
    case _: None{}
def request_fields(p: Maybe<&2,P.Policy>,train: Maybe<&2,+List<L.Episode>>,valid: Maybe<&2,+List<L.Episode>>,
  cycles: Maybe<&2,+List<E.Task>>,guard: Maybe<&2,+List<E.Task>>,meta: Nat,cycle: Nat) -> Maybe<&2,Request>:
  match p train valid cycles guard:
    case Some{p} Some{a} Some{b} Some{c} Some{d}: Some{Request{p,a,b,c,d,meta,cycle}}
    case _ _ _ _ _: None{}
def request_values(+v: J.Value,+bound: G.Bound,+cap: Nat) -> Maybe<&2,Request>:
  request_fields(policy(V.get("policy",v)),episodes(V.get("training",v),bound,cap),episodes(V.get("validation",v),bound,cap),
    tasks(V.get("cycles",v),1n,bound,cap),tasks(V.get("protected",v),0n,bound,cap),
    U32.to_nat(V.num(V.get("meta_budget",v))),U32.to_nat(V.num(V.get("cycle_budget",v))))
def request_valid(ok: Bool,+v: J.Value) -> Maybe<&2,Request>:
  match ok:
    case False{}: None{}
    case True{}: request_values(v,V.bound(V.num(V.get("max_nodes",v))),U32.to_nat(V.num(V.get("candidate_budget",v))))
def request(+v: J.Value) -> Maybe<&2,Request>:
  request_valid(V.keys(v,["policy","training","validation","cycles","protected","max_nodes","candidate_budget","meta_budget","cycle_budget"]) &&
    V.integer(V.get("max_nodes",v)) && V.range(V.get("max_nodes",v),1,7) &&
    V.integer(V.get("candidate_budget",v)) && V.range(V.get("candidate_budget",v),0,128) &&
    V.integer(V.get("meta_budget",v)) && V.range(V.get("meta_budget",v),0,5) &&
    V.integer(V.get("cycle_budget",v)) && V.range(V.get("cycle_budget",v),0,16),v)
def branch_count(b: Rec.Branch) -> Nat:
  Rec.Branch{initial,final,cap,used,left,accepted,history} = b
  accepted
def validation_accepted(c: L.Comparison) -> Bool:
  L.Comparison{old,new,a,b,accepted} = c
  accepted
def branches(learned: L.Improvement,+validation: L.Comparison,
             old: Result<&2,&2,String,Rec.Branch>,new: Result<&2,&2,String,Rec.Branch>) -> Reply:
  match old new:
    case Fail{e} _: error(e)
    case _ Fail{e}: error(e)
    case Done{+a} Done{+b}:
      Reply{0,"{\"schema\":\"bendloop-policy-experiment-v1\",\"training\":" ++ Render.improvement(learned) ++
        ",\"heldout_learning_comparison\":" ++ Render.learning_comparison(validation) ++
        ",\"original_revision_branch\":" ++ Render.branch(a) ++ ",\"revised_revision_branch\":" ++ Render.branch(b) ++
        ",\"observed_recursive_gain\":" ++ Render.boolean(validation_accepted(validation) && Nat.is_gt(Rec.gain(b),Rec.gain(a))) ++ "}",""}
def validated(learned: L.Improvement,+before: P.Policy,+after: P.Policy,+cycles: +List<E.Task>,+guard: +List<E.Task>,+budget: Nat,
              comparison: Result<&2,&2,String,L.Comparison>) -> Reply:
  match comparison:
    case Fail{e}: error(e)
    case Done{c}: branches(learned,c,Rec.run(cycles,guard,before,budget),Rec.run(cycles,guard,after,budget))
def improved(+before: P.Policy,+validation: +List<L.Episode>,cycles: +List<E.Task>,guard: +List<E.Task>,budget: Nat,
             result: Result<&2,&2,String,L.Improvement>) -> Reply:
  match result:
    case Fail{e}: error(e)
    case Done{+i}:
      L.Improvement{initial,+after,used,left,history} = i
      validated(i,before,after,cycles,guard,budget,L.compare(before,after,validation))
def separated(ok: Bool,+p: P.Policy,training: +List<L.Episode>,validation: +List<L.Episode>,cycles: +List<E.Task>,guard: +List<E.Task>,meta: Nat,budget: Nat) -> Reply:
  match ok:
    case False{}: invalid("training, validation and cycle tasks must be structurally disjoint")
    case True{}: improved(p,validation,cycles,guard,budget,L.improve(p,training,meta))
def execute(req: Maybe<&2,Request>) -> Reply:
  match req:
    case None{}: invalid("invalid policy experiment request")
    case Some{Request{p,+training,+validation,+cycles,+guard,meta,budget}}:
      separated(Separation.valid(training,validation,cycles,guard),p,training,validation,cycles,guard,meta,budget)
def parsed(command: String,value: Maybe<&2,J.Value>) -> Reply:
  match command value:
    case "experiment" Some{v}: execute(request(v))
    case _ _: invalid("invalid policy experiment request")
def run(command: String,text: String) -> Reply:
  parsed(command,J.parse(text))
