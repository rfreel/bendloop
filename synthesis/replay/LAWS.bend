import Base
import ./runtime.bend as P
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C
import ../search/grammar.bend as G

law replay_sound:
  for +r: P.Request
  for +p: P.Packet
  for +input: R.Bits
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.reference(r),input) == R.eval(P.candidate(p),input) : R.Bits}
law replay_membership:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {P.member(r,P.candidate(p)) == True{} : Bool}
law replay_strict:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool}
law replay_source:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {P.embedded(p) == P.reference(r) : R.Expr}
law replay_cost:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool}
law replay_output_0:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_0()) == P.row_0(P.outputs(p)) : R.Bits}
law replay_output_1:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_1()) == P.row_1(P.outputs(p)) : R.Bits}
law replay_output_2:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_2()) == P.row_2(P.outputs(p)) : R.Bits}
law replay_output_3:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_3()) == P.row_3(P.outputs(p)) : R.Bits}
law replay_output_4:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_4()) == P.row_4(P.outputs(p)) : R.Bits}
law replay_output_5:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_5()) == P.row_5(P.outputs(p)) : R.Bits}
law replay_output_6:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_6()) == P.row_6(P.outputs(p)) : R.Bits}
law replay_output_7:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_7()) == P.row_7(P.outputs(p)) : R.Bits}
law replay_output_8:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_8()) == P.row_8(P.outputs(p)) : R.Bits}
law replay_output_9:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_9()) == P.row_9(P.outputs(p)) : R.Bits}
law replay_output_10:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_10()) == P.row_10(P.outputs(p)) : R.Bits}
law replay_output_11:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_11()) == P.row_11(P.outputs(p)) : R.Bits}
law replay_output_12:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_12()) == P.row_12(P.outputs(p)) : R.Bits}
law replay_output_13:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_13()) == P.row_13(P.outputs(p)) : R.Bits}
law replay_output_14:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_14()) == P.row_14(P.outputs(p)) : R.Bits}
law replay_output_15:
  for +r: P.Request
  for +p: P.Packet
  for yes: {P.accepted(r,p,P.replay(r,p)) == True{} : Bool}
  {R.eval(P.candidate(p),C.input_15()) == P.row_15(P.outputs(p)) : R.Bits}
law positive_zero_rewrite:
  {P.accepted(P.Request{R.Xor{R.Input{},R.Input{}},G.Ops{True{},True{},True{},True{}},G.N1{}},
    P.canonical(R.Xor{R.Input{},R.Input{}},R.Constant{C.input_0()}),
    P.replay(P.Request{R.Xor{R.Input{},R.Input{}},G.Ops{True{},True{},True{},True{}},G.N1{}},
      P.canonical(R.Xor{R.Input{},R.Input{}},R.Constant{C.input_0()}))) == True{} : Bool}

law canonical_roundtrip:
  for +reference: R.Expr
  for +candidate: R.Expr
  for +ops: G.Ops
  for +bound: G.Bound
  for membership: {P.member(P.Request{reference,ops,bound},candidate) == True{} : Bool}
  for strict: {Nat.is_lt(R.cost(candidate),R.cost(reference)) == True{} : Bool}
  for certificate: C.Certificate<reference,candidate>
  {P.accepted(P.Request{reference,ops,bound},P.canonical(reference,candidate),
    P.replay(P.Request{reference,ops,bound},P.canonical(reference,candidate))) == True{} : Bool}
