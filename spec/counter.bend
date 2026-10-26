import Base

def bump(pair: Nat & Nat) -> Nat & Nat:
  (done,left) = pair
  (1n+done,left)

# Reference semantics: completed units and unspent allowance, no receipt code.
def run(budget: Nat, work: Nat) -> Nat & Nat:
  match budget work:
    case 0n _: (0n,0n)
    case 1n+n 0n: (0n,1n+n)
    case 1n+n 1n+w:
      bump(run(n,w))


