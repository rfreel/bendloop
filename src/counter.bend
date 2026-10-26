import Base
import ../core/receipt.bend as R

# Each completed unit costs one logical token.
def run(+budget: Nat, work: Nat) -> R.Receipt<budget>:
  match budget work:
    case 0n _: R.empty(0n)
    case 1n+n 0n: R.empty(1n+n)
    case 1n+n 1n+w: R.tick(n,run(n,w))

def batches(+budget: Nat, first: Nat, second: Nat) -> R.Receipt<budget>:
  R.then(budget,run(budget,first), remaining => run(remaining,second))
