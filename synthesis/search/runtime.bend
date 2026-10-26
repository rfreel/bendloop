import Base
import ./grammar.bend as G
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C

# Every incumbent carries evaluator-bound equivalence. Prefix/ranking laws remain separate.
type Best<-reference: R.Expr> is Type:
  NoBest{}
  HaveBest{candidate: R.Expr, certificate: C.Certificate<reference,candidate>}

def accept_result(+reference: R.Expr, candidate: R.Expr, old: Best<reference>, result: C.Check<reference,candidate>) -> Best<reference>:
  match result:
    case C.Equivalent{certificate}: HaveBest{candidate,certificate}
    case C.Different{input,refute}: old

def consider_if(ok: Bool, +reference: R.Expr, +candidate: R.Expr, old: Best<reference>) -> Best<reference>:
  match ok:
    case False{}: old
    case True{}: accept_result(reference,candidate,old,C.certify(reference,candidate))

def consider(+reference: R.Expr, +candidate: R.Expr, best: Best<reference>) -> Best<reference>:
  match best:
    case NoBest{}: consider_if(Nat.is_lt(R.cost(candidate),R.cost(reference)),reference,candidate,NoBest{})
    case HaveBest{+previous,certificate}:
      consider_if(Nat.is_lt(R.cost(candidate),R.cost(previous)),reference,candidate,HaveBest{previous,certificate})

type State is Type:
  State{reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat, spent: Nat, left: Nat, best: Best<reference>}

def start(reference: R.Expr, ops: G.Ops, bound: G.Bound, +cap: Nat) -> State:
  State{reference,ops,bound,cap,0n,cap,NoBest{}}

def decoded(+reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat, spent: Nat, left: Nat, best: Best<reference>, value: Maybe<&2,R.Expr>) -> Result<&2,&1,String,State>:
  match value:
    case None{}: Fail{"internal grammar/decoder disagreement"}
    case Some{candidate}:
      Done{State{reference,ops,bound,cap,1n+spent,left,consider(reference,candidate,best)}}

def located(+reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat, spent: Nat, left: Nat, best: Best<reference>, value: Maybe<&2,G.Code>) -> Result<&2,&1,String,State>:
  match value:
    case None{}: Done{State{reference,ops,bound,cap,spent,1n+left,best}}
    case Some{code}: decoded(reference,ops,bound,cap,spent,left,best,G.decode(code))

def spend(+reference: R.Expr, +ops: G.Ops, +bound: G.Bound, cap: Nat, +spent: Nat, left: Nat, best: Best<reference>) -> Result<&2,&1,String,State>:
  match left:
    case 0n: Done{State{reference,ops,bound,cap,spent,0n,best}}
    case 1n+remaining:
      located(reference,ops,bound,cap,spent,remaining,best,G.at(bound,ops,U32.from_nat(spent)))

def step(state: State) -> Result<&2,&1,String,State>:
  match state:
    case State{reference,ops,bound,cap,spent,left,best}: spend(reference,ops,bound,cap,spent,left,best)

def continue(result: Result<&2,&1,String,State>, next: State -> Result<&2,&1,String,State>) -> Result<&2,&1,String,State>:
  match result:
    case Fail{error}: Fail{error}
    case Done{state}: next(state)

def advance(quota: Nat, state: State) -> Result<&2,&1,String,State>:
  match quota:
    case 0n: Done{state}
    case 1n+p: continue(step(state),s => advance(p,s))

def synthesize(reference: R.Expr, ops: G.Ops, bound: G.Bound, +budget: Nat) -> Result<&2,&1,String,State>:
  advance(budget,start(reference,ops,bound,budget))
