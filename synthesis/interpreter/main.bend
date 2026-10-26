import Base
import ./runtime.bend as R

# A native witness through the same public evaluator covered by the source theorem.
# Full JSON parsing and the synthesizer CLI are separate, unfinished obligations.
def main() -> IO(Unit):
  +five = {R.Bits{True{},False{},True{},False{}} : R.Bits}
  expr = {R.Not{R.Xor{R.Input{},R.Constant{five}}} : R.Expr}
  IO.print(U32.show(R.number(R.eval(expr,five))))
