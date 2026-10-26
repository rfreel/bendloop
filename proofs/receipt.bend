import Base
import ../core/receipt.bend as R
import ../spec/counter.bend as Spec

law tick_view:
  for n: Nat
  for receipt: R.Receipt<n>
  {R.view(1n+n,R.tick(n,receipt)) == Spec.bump(R.view(n,receipt)) : Nat & Nat}

def tick_view(n,receipt):
  match receipt:
    case R.Receipt{used,left,balance}: {==}

law spec_exact:
  for +n: Nat
  {Spec.run(n,n) == (n,0n) : Nat & Nat}

def spec_exact(n):
  match n:
    case 0n: {==}
    case 1n+p:
      %spec_exact(p) : {Spec.bump(Spec.run(p,p)) == Spec.bump(_) : Nat & Nat}
      {==}
