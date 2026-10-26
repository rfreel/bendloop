import Base
import ../interpreter/runtime.bend as R
import ./equality.bend as E

def input_0() -> R.Bits:
  R.Bits{False{},False{},False{},False{}}

def input_1() -> R.Bits:
  R.Bits{True{},False{},False{},False{}}

def input_2() -> R.Bits:
  R.Bits{False{},True{},False{},False{}}

def input_3() -> R.Bits:
  R.Bits{True{},True{},False{},False{}}

def input_4() -> R.Bits:
  R.Bits{False{},False{},True{},False{}}

def input_5() -> R.Bits:
  R.Bits{True{},False{},True{},False{}}

def input_6() -> R.Bits:
  R.Bits{False{},True{},True{},False{}}

def input_7() -> R.Bits:
  R.Bits{True{},True{},True{},False{}}

def input_8() -> R.Bits:
  R.Bits{False{},False{},False{},True{}}

def input_9() -> R.Bits:
  R.Bits{True{},False{},False{},True{}}

def input_10() -> R.Bits:
  R.Bits{False{},True{},False{},True{}}

def input_11() -> R.Bits:
  R.Bits{True{},True{},False{},True{}}

def input_12() -> R.Bits:
  R.Bits{False{},False{},True{},True{}}

def input_13() -> R.Bits:
  R.Bits{True{},False{},True{},True{}}

def input_14() -> R.Bits:
  R.Bits{False{},True{},True{},True{}}

def input_15() -> R.Bits:
  R.Bits{True{},True{},True{},True{}}

type Certificate<-reference: R.Expr, -candidate: R.Expr> is Type:
  Certificate{
    p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits}
    p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits}
    p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits}
    p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits}
    p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits}
    p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits}
    p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits}
    p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits}
    p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits}
    p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits}
    p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits}
    p11: {R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits}
    p12: {R.eval(reference,input_12()) == R.eval(candidate,input_12()) : R.Bits}
    p13: {R.eval(reference,input_13()) == R.eval(candidate,input_13()) : R.Bits}
    p14: {R.eval(reference,input_14()) == R.eval(candidate,input_14()) : R.Bits}
    p15: {R.eval(reference,input_15()) == R.eval(candidate,input_15()) : R.Bits}
  }

type Check<-reference: R.Expr, -candidate: R.Expr> is Type:
  Equivalent{certificate: Certificate<reference,candidate>}
  Different{input: R.Bits, refute: {R.eval(reference,input) == R.eval(candidate,input) : R.Bits} -> Empty}

def step_15(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits},
  p11: {R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits},
  p12: {R.eval(reference,input_12()) == R.eval(candidate,input_12()) : R.Bits},
  p13: {R.eval(reference,input_13()) == R.eval(candidate,input_13()) : R.Bits},
  p14: {R.eval(reference,input_14()) == R.eval(candidate,input_14()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_15()) == R.eval(candidate,input_15()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_15(),refute}
    case E.Yes{p15}:
      Equivalent{Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}

def step_14(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits},
  p11: {R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits},
  p12: {R.eval(reference,input_12()) == R.eval(candidate,input_12()) : R.Bits},
  p13: {R.eval(reference,input_13()) == R.eval(candidate,input_13()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_14()) == R.eval(candidate,input_14()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_14(),refute}
    case E.Yes{p14}:
      step_15(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,E.decide(R.eval(reference,input_15()),R.eval(candidate,input_15())))

def step_13(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits},
  p11: {R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits},
  p12: {R.eval(reference,input_12()) == R.eval(candidate,input_12()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_13()) == R.eval(candidate,input_13()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_13(),refute}
    case E.Yes{p13}:
      step_14(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,E.decide(R.eval(reference,input_14()),R.eval(candidate,input_14())))

def step_12(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits},
  p11: {R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_12()) == R.eval(candidate,input_12()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_12(),refute}
    case E.Yes{p12}:
      step_13(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,E.decide(R.eval(reference,input_13()),R.eval(candidate,input_13())))

def step_11(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  p10: {R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_11()) == R.eval(candidate,input_11()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_11(),refute}
    case E.Yes{p11}:
      step_12(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,E.decide(R.eval(reference,input_12()),R.eval(candidate,input_12())))

def step_10(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  p9: {R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_10()) == R.eval(candidate,input_10()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_10(),refute}
    case E.Yes{p10}:
      step_11(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,E.decide(R.eval(reference,input_11()),R.eval(candidate,input_11())))

def step_9(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  p8: {R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_9()) == R.eval(candidate,input_9()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_9(),refute}
    case E.Yes{p9}:
      step_10(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,E.decide(R.eval(reference,input_10()),R.eval(candidate,input_10())))

def step_8(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  p7: {R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_8()) == R.eval(candidate,input_8()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_8(),refute}
    case E.Yes{p8}:
      step_9(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,p8,E.decide(R.eval(reference,input_9()),R.eval(candidate,input_9())))

def step_7(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  p6: {R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_7()) == R.eval(candidate,input_7()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_7(),refute}
    case E.Yes{p7}:
      step_8(reference,candidate,p0,p1,p2,p3,p4,p5,p6,p7,E.decide(R.eval(reference,input_8()),R.eval(candidate,input_8())))

def step_6(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  p5: {R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_6()) == R.eval(candidate,input_6()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_6(),refute}
    case E.Yes{p6}:
      step_7(reference,candidate,p0,p1,p2,p3,p4,p5,p6,E.decide(R.eval(reference,input_7()),R.eval(candidate,input_7())))

def step_5(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  p4: {R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_5()) == R.eval(candidate,input_5()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_5(),refute}
    case E.Yes{p5}:
      step_6(reference,candidate,p0,p1,p2,p3,p4,p5,E.decide(R.eval(reference,input_6()),R.eval(candidate,input_6())))

def step_4(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  p3: {R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_4()) == R.eval(candidate,input_4()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_4(),refute}
    case E.Yes{p4}:
      step_5(reference,candidate,p0,p1,p2,p3,p4,E.decide(R.eval(reference,input_5()),R.eval(candidate,input_5())))

def step_3(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  p2: {R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_3()) == R.eval(candidate,input_3()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_3(),refute}
    case E.Yes{p3}:
      step_4(reference,candidate,p0,p1,p2,p3,E.decide(R.eval(reference,input_4()),R.eval(candidate,input_4())))

def step_2(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  p1: {R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_2()) == R.eval(candidate,input_2()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_2(),refute}
    case E.Yes{p2}:
      step_3(reference,candidate,p0,p1,p2,E.decide(R.eval(reference,input_3()),R.eval(candidate,input_3())))

def step_1(+reference: R.Expr, +candidate: R.Expr,
  p0: {R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits},
  decision: E.Decision<{R.eval(reference,input_1()) == R.eval(candidate,input_1()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_1(),refute}
    case E.Yes{p1}:
      step_2(reference,candidate,p0,p1,E.decide(R.eval(reference,input_2()),R.eval(candidate,input_2())))

def step_0(+reference: R.Expr, +candidate: R.Expr,
  decision: E.Decision<{R.eval(reference,input_0()) == R.eval(candidate,input_0()) : R.Bits}>) -> Check<reference,candidate>:
  match decision:
    case E.No{refute}: Different{input_0(),refute}
    case E.Yes{p0}:
      step_1(reference,candidate,p0,E.decide(R.eval(reference,input_1()),R.eval(candidate,input_1())))

def certify(+reference: R.Expr, +candidate: R.Expr) -> Check<reference,candidate>:
  step_0(reference,candidate,E.decide(R.eval(reference,input_0()),R.eval(candidate,input_0())))

def accepted(-reference: R.Expr, -candidate: R.Expr, result: Check<reference,candidate>) -> Bool:
  match result:
    case Equivalent{certificate}: True{}
    case Different{input,refute}: False{}

law sound:
  for +reference: R.Expr
  for +candidate: R.Expr
  for certificate: Certificate<reference,candidate>
  for +input: R.Bits
  {R.eval(reference,input) == R.eval(candidate,input) : R.Bits}

def sound(reference,candidate,certificate,input):
  match certificate input:
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},False{},False{},False{}}: p0
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},False{},False{},False{}}: p1
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},True{},False{},False{}}: p2
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},True{},False{},False{}}: p3
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},False{},True{},False{}}: p4
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},False{},True{},False{}}: p5
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},True{},True{},False{}}: p6
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},True{},True{},False{}}: p7
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},False{},False{},True{}}: p8
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},False{},False{},True{}}: p9
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},True{},False{},True{}}: p10
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},True{},False{},True{}}: p11
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},False{},True{},True{}}: p12
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},False{},True{},True{}}: p13
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{False{},True{},True{},True{}}: p14
    case Certificate{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} R.Bits{True{},True{},True{},True{}}: p15

law complete_result:
  for +reference: R.Expr
  for +candidate: R.Expr
  for result: Check<reference,candidate>
  for all: @+input: R.Bits -> {R.eval(reference,input) == R.eval(candidate,input) : R.Bits}
  {accepted(reference,candidate,result) == True{} : Bool}

def complete_result(reference,candidate,result,all):
  match result:
    case Equivalent{certificate}: {==}
    case Different{input,refute}:
      Empty.absurd({False{} == True{} : Bool},refute(all(input)))
