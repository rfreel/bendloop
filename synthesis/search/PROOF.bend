import Base
import ./LAWS.bend as Laws
import ./runtime.bend as S
import ./accounting.bend as A

def Laws.start_valid(reference,ops,bound,cap):
  {==}

def resume_result(a: Nat, b: Nat, result: Result<&2,&1,String,S.State>, induction: @state: S.State -> {S.advance(Nat.add(a,b),state) == S.continue(S.advance(a,state),s => S.advance(b,s)) : Result<&2,&1,String,S.State>}) ->
  {S.continue(result,s => S.advance(Nat.add(a,b),s)) == S.continue(S.continue(result,s => S.advance(a,s)),s => S.advance(b,s)) : Result<&2,&1,String,S.State>}:
  match result:
    case Fail{error}: {==}
    case Done{state}: induction(state)

def Laws.resume_composes(a,b,state):
  match a:
    case 0n: {==}
    case 1n+p0:
      +p = p0
      resume_result(p,b,S.step(state),s => Laws.resume_composes(p,b,s))

def Laws.budget_conserved(quota,reference,ops,bound,cap,spent,left,best,valid):
  A.advance(quota,reference,ops,bound,cap,spent,left,best,cap,valid)
