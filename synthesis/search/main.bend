import Base
import ./runtime.bend as S
import ./grammar.bend as G
import ./render.bend as J
import ../interpreter/runtime.bend as R

# Typed API demonstration; JSON input and portable replay are still required for release.
def main() -> IO(Unit):
  IO.print(J.result(S.synthesize(R.Xor{R.Input{},R.Input{}},G.Ops{True{},True{},True{},True{}},G.N3{},2n)))
