import Base

# Evidence is tied to the allowance; there is no unchecked constructor.
type Receipt<budget: Nat> is Type:
  Receipt{spent: Nat, left: Nat, balance: {Nat.add(spent, left) == budget : Nat}}

def empty(+budget: Nat) -> Receipt<budget>:
  Receipt{0n, budget, {==}}

def tick(n: Nat, receipt: Receipt<n>) -> Receipt<1n+n>:
  match receipt:
    case Receipt{spent, left, balance}:
      Receipt{1n+spent, left, Equal.cong(Nat, Nat, x => 1n+x, Nat.add(spent,left), n, balance)}

def spent(n: Nat, receipt: Receipt<n>) -> Nat:
  match receipt:
    case Receipt{used, _, _}: used

def left(n: Nat, receipt: Receipt<n>) -> Nat:
  match receipt:
    case Receipt{_, remaining, _}: remaining

law add_assoc:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.add(Nat.add(a,b),c) == Nat.add(a,Nat.add(b,c)) : Nat}

def add_assoc(a,b,c):
  match a:
    case 0n: {==}
    case 1n+p:
      %add_assoc(p,b,c) : {1n+Nat.add(Nat.add(p,b),c) == 1n+_ : Nat}
      {==}

def merge(+n: Nat, +used: Nat, +remaining: Nat,
          balance: {Nat.add(used,remaining) == n : Nat},
          second: Receipt<remaining>) -> Receipt<n>:
  match second:
    case Receipt{u, l, balance2}:
      +used2 = u
      +left2 = l
      Receipt{Nat.add(used,used2), left2,
        Equal.trans(Nat,
          Nat.add(Nat.add(used,used2),left2),
          Nat.add(used,Nat.add(used2,left2)), n,
          add_assoc(used,used2,left2),
          Equal.trans(Nat, Nat.add(used,Nat.add(used2,left2)), Nat.add(used,remaining), n,
            Equal.cong(Nat,Nat,x => Nat.add(used,x),Nat.add(used2,left2),remaining,balance2), balance))}

# The continuation receives only the unspent allowance.
def then(n: Nat, first: Receipt<n>, next: @remaining:Nat -> Receipt<remaining>) -> Receipt<n>:
  match first:
    case Receipt{used, r, balance}:
      +remaining = r
      merge(n,used,remaining,balance,next(remaining))


def view(n: Nat, receipt: Receipt<n>) -> Nat & Nat:
  match receipt:
    case Receipt{used, remaining, _}: (used, remaining)

def total(n: Nat, receipt: Receipt<n>) -> Nat:
  match receipt:
    case Receipt{used, remaining, _}: Nat.add(used,remaining)

law conserved:
  for n: Nat
  for receipt: Receipt<n>
  {total(n,receipt) == n : Nat}

def conserved(n,receipt):
  match receipt:
    case Receipt{used, remaining, balance}: balance
