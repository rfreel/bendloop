import Base
import ./core/receipt.bend as R
import ./src/counter.bend as Counter

# IO is deliberately outside the proof import graph.
def show(pair: Nat & Nat) -> String:
  (spent,left) = pair
  "spent=" ++ Nat.show(spent) ++ " remaining=" ++ Nat.show(left)

def main() -> IO(Unit):
  IO.print(show(R.view(5n,Counter.batches(5n,2n,4n))))
