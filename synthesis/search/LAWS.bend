import Base
import ./runtime.bend as S
import ./grammar.bend as G
import ./accounting.bend as A
import ../interpreter/runtime.bend as R

law start_valid:
  for reference: R.Expr
  for ops: G.Ops
  for bound: G.Bound
  for +cap: Nat
  {S.start(reference,ops,bound,cap) == S.State{reference,ops,bound,cap,0n,cap,S.NoBest{}} : S.State}

law resume_composes:
  for a: Nat
  for +b: Nat
  for state: S.State
  {S.advance(Nat.add(a,b),state) == S.continue(S.advance(a,state),s => S.advance(b,s)) : Result<&2,&1,String,S.State>}

law budget_conserved:
  for quota: Nat
  for reference: R.Expr
  for ops: G.Ops
  for bound: G.Bound
  for +cap: Nat
  for spent: Nat
  for left: Nat
  for -best: S.Best<reference>
  for valid: {Nat.add(spent,left) == cap : Nat}
  {A.total_result(S.advance(quota,S.State{reference,ops,bound,cap,spent,left,best}),cap) == cap : Nat}
