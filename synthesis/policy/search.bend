import Base
import ./types.bend as P
import ./runtime.bend as Policy
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C
import ../search/grammar.bend as G
import ../search/runtime.bend as S

type Trial is Data:
  Trial{rank: Nat, grammar_rank: Nat, candidate: R.Expr,
        checked_inputs: Nat, equivalent: Bool, admitted: Bool}
type State is Type:
  State{policy: P.Policy, reference: R.Expr, ops: G.Ops, bound: G.Bound,
        cap: Nat, spent: Nat, left: Nat, best: S.Best<reference>, trials: +List<Trial>}
type Observation is Data:
  Observation{attempts: Nat, remaining: Nat, best_cost: Nat, improved: Bool,
              checked_inputs: Nat, verification_nodes: Nat, trials: +List<Trial>}

def start(policy: P.Policy, reference: R.Expr, ops: G.Ops, bound: G.Bound, +cap: Nat) -> State:
  State{policy,reference,ops,bound,cap,0n,cap,S.NoBest{},Nil{}}
def result(+reference: R.Expr, +candidate: R.Expr, +rank: Nat, grammar_rank: Nat,
           old: S.Best<reference>, checked: C.Check<reference,candidate>) -> S.Best<reference> & Trial:
  match checked:
    case C.Equivalent{certificate}:
      (S.HaveBest{candidate,certificate},Trial{rank,grammar_rank,candidate,16n,True{},True{}})
    case C.Different{input,refute}:
      (old,Trial{rank,grammar_rank,candidate,1n+U32.to_nat(R.number(input)),False{},False{}})
def consider_if(ok: Bool, +reference: R.Expr, +candidate: R.Expr, rank: Nat,
                grammar_rank: Nat, old: S.Best<reference>) -> S.Best<reference> & Trial:
  match ok:
    case False{}: (old,Trial{rank,grammar_rank,candidate,0n,False{},False{}})
    case True{}: result(reference,candidate,rank,grammar_rank,old,C.certify(reference,candidate))
def consider(+reference: R.Expr, +candidate: R.Expr, rank: Nat, grammar_rank: Nat,
             old: S.Best<reference>) -> S.Best<reference> & Trial:
  match old:
    case S.NoBest{}:
      consider_if(Nat.is_lt(R.cost(candidate),R.cost(reference)),reference,candidate,rank,grammar_rank,S.NoBest{})
    case S.HaveBest{+previous,certificate}:
      consider_if(Nat.is_lt(R.cost(candidate),R.cost(previous)),reference,candidate,rank,grammar_rank,S.HaveBest{previous,certificate})
def install(policy: P.Policy, reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat,
            spent: Nat, left: Nat, trials: +List<Trial>,
            pair: S.Best<reference> & Trial) -> Result<&2,&1,String,State>:
  (best,trial) = pair
  Done{State{policy,reference,ops,bound,cap,1n+spent,left,best,trial <> trials}}
def decoded(policy: P.Policy, +reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat,
            +spent: Nat, left: Nat, best: S.Best<reference>, trials: +List<Trial>, rank: Nat,
            value: Maybe<&2,R.Expr>) -> Result<&2,&1,String,State>:
  match value:
    case None{}: Fail{"policy grammar/decoder disagreement"}
    case Some{+candidate}:
      install(policy,reference,ops,bound,cap,spent,left,trials,consider(reference,candidate,spent,rank,best))
def located(policy: P.Policy, +reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat,
            spent: Nat, left: Nat, best: S.Best<reference>, trials: +List<Trial>, rank: Nat,
            value: Maybe<&2,G.Code>) -> Result<&2,&1,String,State>:
  match value:
    case None{}: Done{State{policy,reference,ops,bound,cap,spent,1n+left,best,trials}}
    case Some{code}: decoded(policy,reference,ops,bound,cap,spent,left,best,trials,rank,G.decode(code))
def spend(+policy: P.Policy, +reference: R.Expr, +ops: G.Ops, +bound: G.Bound, cap: Nat,
          +spent: Nat, left: Nat, best: S.Best<reference>, trials: +List<Trial>) -> Result<&2,&1,String,State>:
  match left:
    case 0n: Done{State{policy,reference,ops,bound,cap,spent,0n,best,trials}}
    case 1n+remaining:
      +rank = Policy.rank(Policy.priority(policy,reference),spent)
      located(policy,reference,ops,bound,cap,spent,remaining,best,trials,rank,G.at(bound,ops,U32.from_nat(rank)))
def step(state: State) -> Result<&2,&1,String,State>:
  State{policy,reference,ops,bound,cap,spent,left,best,trials} = state
  spend(policy,reference,ops,bound,cap,spent,left,best,trials)
def continue(result: Result<&2,&1,String,State>, next: State -> Result<&2,&1,String,State>) -> Result<&2,&1,String,State>:
  match result:
    case Fail{error}: Fail{error}
    case Done{state}: next(state)
def advance(quota: Nat, state: State) -> Result<&2,&1,String,State>:
  match quota:
    case 0n: Done{state}
    case 1n+p: continue(step(state),s => advance(p,s))
def run(policy: P.Policy, reference: R.Expr, ops: G.Ops, bound: G.Bound, +cap: Nat) -> Result<&2,&1,String,State>:
  advance(cap,start(policy,reference,ops,bound,cap))

def count_join(+inputs: Nat, reference_size: Nat, candidate: R.Expr, totals: Nat & Nat) -> Nat & Nat:
  (checks,nodes) = totals
  (Nat.add(inputs,checks),Nat.add(Nat.mul(inputs,Nat.add(reference_size,R.size(candidate))),nodes))
def counts(trials: +List<Trial>, +reference_size: Nat) -> Nat & Nat:
  match trials:
    case Nil{}: (0n,0n)
    case Con{Trial{rank,source,candidate,+inputs,eq,admitted},tail}:
      count_join(inputs,reference_size,candidate,counts(tail,reference_size))
def observation(attempts: Nat, remaining: Nat, cost: Nat, improved: Bool,
                trials: +List<Trial>, totals: Nat & Nat) -> Observation:
  (checks,nodes) = totals
  Observation{attempts,remaining,cost,improved,checks,nodes,trials}
def observe_best(+reference: R.Expr, attempts: Nat, remaining: Nat, +trials: +List<Trial>, best: S.Best<reference>) -> Observation:
  match best:
    case S.NoBest{}:
      observation(attempts,remaining,R.cost(reference),False{},trials,counts(trials,R.size(reference)))
    case S.HaveBest{candidate,certificate}:
      observation(attempts,remaining,R.cost(candidate),True{},trials,counts(trials,R.size(reference)))
def observe(state: State) -> Observation:
  State{policy,reference,ops,bound,cap,spent,left,best,trials} = state
  observe_best(reference,spent,left,trials,best)
def observed(result: Result<&2,&1,String,State>) -> Result<&2,&2,String,Observation>:
  match result:
    case Fail{error}: Fail{error}
    case Done{state}: Done{observe(state)}
