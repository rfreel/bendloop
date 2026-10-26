import Base
import ./LAWS.bend as Laws
import ./core/receipt.bend as R
import ./src/counter.bend as Counter
import ./spec/counter.bend as Spec
import ./proofs/receipt.bend as P

def Laws.matches_spec(budget,work):
  match budget work:
    case 0n _: {==}
    case 1n+n 0n: {==}
    case 1n+n0 1n+w0:
      +n = n0
      +w = w0
      Equal.trans(Nat & Nat,
        R.view(1n+n,R.tick(n,Counter.run(n,w))),
        Spec.bump(R.view(n,Counter.run(n,w))), Spec.bump(Spec.run(n,w)),
        P.tick_view(n,Counter.run(n,w)),
        Equal.cong(Nat & Nat,Nat & Nat,Spec.bump,R.view(n,Counter.run(n,w)),Spec.run(n,w),Laws.matches_spec(n,w)))

def Laws.budget_conserved(budget,work):
  R.conserved(budget,Counter.run(budget,work))

def Laws.composition_conserved(budget,first,second):
  R.conserved(budget,Counter.batches(budget,first,second))

def Laws.exact_work_completes(n):
  Equal.trans(Nat & Nat,R.view(n,Counter.run(n,n)),Spec.run(n,n),(n,0n),
    Laws.matches_spec(n,n),P.spec_exact(n))

def Laws.empty_work_spends_nothing(n):
  match n:
    case 0n: {==}
    case 1n+p: {==}

def Laws.sequential_example():
  {==}
