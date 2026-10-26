import Base
import ./runtime.bend as S
import ./grammar.bend as G
import ../interpreter/runtime.bend as R

def total(state: S.State) -> Nat:
  match state:
    case S.State{reference,ops,bound,cap,spent,left,best}: Nat.add(spent,left)

def total_result(result: Result<&2,&1,String,S.State>, fallback: Nat) -> Nat:
  match result:
    case Fail{error}: fallback
    case Done{state}: total(state)

def add_succ(a: Nat, b: Nat) -> {Nat.add(a,1n+b) == 1n+Nat.add(a,b) : Nat}:
  match a:
    case 0n: {==}
    case 1n+p: Equal.cong(Nat,Nat,n => 1n+n,Nat.add(p,1n+b),1n+Nat.add(p,b),add_succ(p,b))

def decoded(q: Nat, +reference: R.Expr, +ops: G.Ops, +bound: G.Bound, +cap: Nat, +spent: Nat, +left: Nat, -best: S.Best<reference>, +fallback: Nat, value: Maybe<&2,R.Expr>, valid: {Nat.add(spent,1n+left) == fallback : Nat}, next: @x: Nat -> @y: Nat -> @-b: S.Best<reference> -> {Nat.add(x,y) == fallback : Nat} -> {total_result(S.advance(q,S.State{reference,ops,bound,cap,x,y,b}),fallback) == fallback : Nat}) -> {total_result(S.continue(S.decoded(reference,ops,bound,cap,spent,left,best,value),s => S.advance(q,s)),fallback) == fallback : Nat}:
  match value:
    case None{}: {==}
    case Some{+candidate}:
      next(1n+spent,left,S.consider(reference,candidate,best),Equal.trans(Nat,1n+Nat.add(spent,left),Nat.add(spent,1n+left),fallback,Equal.sym(Nat,Nat.add(spent,1n+left),1n+Nat.add(spent,left),add_succ(spent,left)),valid))

def located(+q: Nat, +reference: R.Expr, +ops: G.Ops, +bound: G.Bound, +cap: Nat, +spent: Nat, +left: Nat, -best: S.Best<reference>, +fallback: Nat, value: Maybe<&2,G.Code>, valid: {Nat.add(spent,1n+left) == fallback : Nat}, next: @x: Nat -> @y: Nat -> @-b: S.Best<reference> -> {Nat.add(x,y) == fallback : Nat} -> {total_result(S.advance(q,S.State{reference,ops,bound,cap,x,y,b}),fallback) == fallback : Nat}) -> {total_result(S.continue(S.located(reference,ops,bound,cap,spent,left,best,value),s => S.advance(q,s)),fallback) == fallback : Nat}:
  match value:
    case None{}: next(spent,1n+left,best,valid)
    case Some{code}: decoded(q,reference,ops,bound,cap,spent,left,best,fallback,G.decode(code),valid,next)

def advance(q: Nat, +reference: R.Expr, +ops: G.Ops, +bound: G.Bound, +cap: Nat, +spent: Nat, +left: Nat, -best: S.Best<reference>, +fallback: Nat, valid: {Nat.add(spent,left) == fallback : Nat}) -> {total_result(S.advance(q,S.State{reference,ops,bound,cap,spent,left,best}),fallback) == fallback : Nat}:
  match q left:
    case 0n _: valid
    case 1n+p 0n: advance(p,reference,ops,bound,cap,spent,0n,best,fallback,valid)
    case 1n+p0 1n+l:
      +p = p0
      located(p,reference,ops,bound,cap,spent,l,best,fallback,G.at(bound,ops,U32.from_nat(spent)),valid,x => y => b => v => advance(p,reference,ops,bound,cap,x,y,b,fallback,v))
