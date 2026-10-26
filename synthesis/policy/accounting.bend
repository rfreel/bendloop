import Base
import ./types.bend as P
import ./runtime.bend as Policy
import ./search.bend as Search
import ../search/grammar.bend as G
import ../search/runtime.bend as S
import ../search/accounting.bend as A
import ../interpreter/runtime.bend as R

def total(state: Search.State) -> Nat:
  Search.State{policy,reference,ops,bound,cap,spent,left,best,trials} = state
  Nat.add(spent,left)
def total_result(result: Result<&2,&1,String,Search.State>,fallback: Nat) -> Nat:
  match result:
    case Fail{error}: fallback
    case Done{state}: total(state)
def installed(+q: Nat,+policy: P.Policy,+reference: R.Expr,+ops: G.Ops,+bound: G.Bound,+cap: Nat,
              +spent: Nat,+left: Nat,+trials: +List<Search.Trial>,+fallback: Nat,
              pair: S.Best<reference> & Search.Trial,
              valid: {Nat.add(spent,1n+left) == fallback : Nat},
              next: @x: Nat -> @y: Nat -> @b: S.Best<reference> -> @history: +List<Search.Trial> ->
                {Nat.add(x,y) == fallback : Nat} ->
                {total_result(Search.advance(q,Search.State{policy,reference,ops,bound,cap,x,y,b,history}),fallback) == fallback : Nat}) ->
              {total_result(Search.continue(Search.install(policy,reference,ops,bound,cap,spent,left,trials,pair),s => Search.advance(q,s)),fallback) == fallback : Nat}:
  match pair:
    case (best,trial):
      next(1n+spent,left,best,trial <> trials,
        Equal.trans(Nat,1n+Nat.add(spent,left),Nat.add(spent,1n+left),fallback,
          Equal.sym(Nat,Nat.add(spent,1n+left),1n+Nat.add(spent,left),A.add_succ(spent,left)),valid))
def decoded(+q: Nat,+policy: P.Policy,+reference: R.Expr,+ops: G.Ops,+bound: G.Bound,+cap: Nat,
            +spent: Nat,+left: Nat,best: S.Best<reference>,+trials: +List<Search.Trial>,+rank: Nat,+fallback: Nat,
            value: Maybe<&2,R.Expr>,valid: {Nat.add(spent,1n+left) == fallback : Nat},
            next: @x: Nat -> @y: Nat -> @b: S.Best<reference> -> @history: +List<Search.Trial> ->
              {Nat.add(x,y) == fallback : Nat} ->
              {total_result(Search.advance(q,Search.State{policy,reference,ops,bound,cap,x,y,b,history}),fallback) == fallback : Nat}) ->
            {total_result(Search.continue(Search.decoded(policy,reference,ops,bound,cap,spent,left,best,trials,rank,value),s => Search.advance(q,s)),fallback) == fallback : Nat}:
  match value:
    case None{}: {==}
    case Some{+candidate}:
      installed(q,policy,reference,ops,bound,cap,spent,left,trials,fallback,
        Search.consider(reference,candidate,spent,rank,best),valid,next)
def located(+q: Nat,+policy: P.Policy,+reference: R.Expr,+ops: G.Ops,+bound: G.Bound,+cap: Nat,
            +spent: Nat,+left: Nat,best: S.Best<reference>,+trials: +List<Search.Trial>,+rank: Nat,+fallback: Nat,
            value: Maybe<&2,G.Code>,valid: {Nat.add(spent,1n+left) == fallback : Nat},
            next: @x: Nat -> @y: Nat -> @b: S.Best<reference> -> @history: +List<Search.Trial> ->
              {Nat.add(x,y) == fallback : Nat} ->
              {total_result(Search.advance(q,Search.State{policy,reference,ops,bound,cap,x,y,b,history}),fallback) == fallback : Nat}) ->
            {total_result(Search.continue(Search.located(policy,reference,ops,bound,cap,spent,left,best,trials,rank,value),s => Search.advance(q,s)),fallback) == fallback : Nat}:
  match value:
    case None{}: next(spent,1n+left,best,trials,valid)
    case Some{code}: decoded(q,policy,reference,ops,bound,cap,spent,left,best,trials,rank,fallback,G.decode(code),valid,next)
def advance(q: Nat,+policy: P.Policy,+reference: R.Expr,+ops: G.Ops,+bound: G.Bound,+cap: Nat,
            +spent: Nat,+left: Nat,best: S.Best<reference>,+trials: +List<Search.Trial>,+fallback: Nat,
            valid: {Nat.add(spent,left) == fallback : Nat}) ->
            {total_result(Search.advance(q,Search.State{policy,reference,ops,bound,cap,spent,left,best,trials}),fallback) == fallback : Nat}:
  match q left:
    case 0n _: valid
    case 1n+p 0n: advance(p,policy,reference,ops,bound,cap,spent,0n,best,trials,fallback,valid)
    case 1n+ +p 1n+l:
      +rank = Policy.rank(Policy.priority(policy,reference),spent)
      located(p,policy,reference,ops,bound,cap,spent,l,best,trials,rank,fallback,G.at(bound,ops,U32.from_nat(rank)),valid,
        x => y => b => history => evidence => advance(p,policy,reference,ops,bound,cap,x,y,b,history,fallback,evidence))
