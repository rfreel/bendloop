import Base
import ./core/receipt.bend as R
import ./src/counter.bend as Counter
import ./spec/counter.bend as Spec

law matches_spec:
  for +budget: Nat
  for work: Nat
  {R.view(budget,Counter.run(budget,work)) == Spec.run(budget,work) : Nat & Nat}

law budget_conserved:
  for +budget: Nat
  for work: Nat
  {R.total(budget,Counter.run(budget,work)) == budget : Nat}

law composition_conserved:
  for +budget: Nat
  for first: Nat
  for second: Nat
  {R.total(budget,Counter.batches(budget,first,second)) == budget : Nat}

# Positive requirements exclude an implementation that always refuses work.
law exact_work_completes:
  for +n: Nat
  {R.view(n,Counter.run(n,n)) == (n,0n) : Nat & Nat}

law empty_work_spends_nothing:
  for +n: Nat
  {R.view(n,Counter.run(n,0n)) == (0n,n) : Nat & Nat}

law sequential_example:
  {R.view(5n,Counter.batches(5n,2n,4n)) == (5n,0n) : Nat & Nat}
