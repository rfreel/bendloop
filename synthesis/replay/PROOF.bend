import Base
import ./runtime.bend as P
import ./LAWS.bend as Laws
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C
import ../certificates/equality.bend as E

def sound(+r: P.Request,+p: P.Packet,+input: R.Bits,result: P.Verdict<r,p>,
  yes: {P.accepted(r,p,result) == True{} : Bool}) ->
  {R.eval(P.reference(r),input) == R.eval(P.candidate(p),input) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,t}: C.sound(P.reference(r),P.candidate(p),e,input)
    case P.Invalid{why}: Empty.absurd({R.eval(P.reference(r),input) == R.eval(P.candidate(p),input) : R.Bits},E.false_true(yes))
def Laws.replay_sound(r,p,input,yes): sound(r,p,input,P.replay(r,p),yes)
def membership(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {P.member(r,P.candidate(p)) == True{} : Bool}:
  match result:
    case P.Accepted{s,m,l,c,e,t}: m
    case P.Invalid{why}: Empty.absurd({P.member(r,P.candidate(p)) == True{} : Bool},E.false_true(yes))
def Laws.replay_membership(r,p,yes): membership(r,p,P.replay(r,p),yes)
def strict(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool}:
  match result:
    case P.Accepted{s,m,l,c,e,t}: l
    case P.Invalid{why}: Empty.absurd({Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},E.false_true(yes))
def Laws.replay_strict(r,p,yes): strict(r,p,P.replay(r,p),yes)
def source(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {P.embedded(p) == P.reference(r) : R.Expr}:
  match result:
    case P.Accepted{s,m,l,c,e,t}: s
    case P.Invalid{why}: Empty.absurd({P.embedded(p) == P.reference(r) : R.Expr},E.false_true(yes))
def Laws.replay_source(r,p,yes): source(r,p,P.replay(r,p),yes)
def cost(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool}:
  match result:
    case P.Accepted{s,m,l,c,e,t}: c
    case P.Invalid{why}: Empty.absurd({Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},E.false_true(yes))
def Laws.replay_cost(r,p,yes): cost(r,p,P.replay(r,p),yes)
def output_0(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_0()) == P.row_0(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p0
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_0()) == P.row_0(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_0(r,p,yes): output_0(r,p,P.replay(r,p),yes)
def output_1(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_1()) == P.row_1(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p1
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_1()) == P.row_1(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_1(r,p,yes): output_1(r,p,P.replay(r,p),yes)
def output_2(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_2()) == P.row_2(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p2
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_2()) == P.row_2(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_2(r,p,yes): output_2(r,p,P.replay(r,p),yes)
def output_3(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_3()) == P.row_3(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p3
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_3()) == P.row_3(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_3(r,p,yes): output_3(r,p,P.replay(r,p),yes)
def output_4(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_4()) == P.row_4(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p4
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_4()) == P.row_4(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_4(r,p,yes): output_4(r,p,P.replay(r,p),yes)
def output_5(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_5()) == P.row_5(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p5
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_5()) == P.row_5(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_5(r,p,yes): output_5(r,p,P.replay(r,p),yes)
def output_6(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_6()) == P.row_6(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p6
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_6()) == P.row_6(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_6(r,p,yes): output_6(r,p,P.replay(r,p),yes)
def output_7(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_7()) == P.row_7(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p7
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_7()) == P.row_7(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_7(r,p,yes): output_7(r,p,P.replay(r,p),yes)
def output_8(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_8()) == P.row_8(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p8
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_8()) == P.row_8(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_8(r,p,yes): output_8(r,p,P.replay(r,p),yes)
def output_9(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_9()) == P.row_9(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p9
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_9()) == P.row_9(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_9(r,p,yes): output_9(r,p,P.replay(r,p),yes)
def output_10(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_10()) == P.row_10(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p10
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_10()) == P.row_10(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_10(r,p,yes): output_10(r,p,P.replay(r,p),yes)
def output_11(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_11()) == P.row_11(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p11
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_11()) == P.row_11(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_11(r,p,yes): output_11(r,p,P.replay(r,p),yes)
def output_12(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_12()) == P.row_12(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p12
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_12()) == P.row_12(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_12(r,p,yes): output_12(r,p,P.replay(r,p),yes)
def output_13(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_13()) == P.row_13(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p13
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_13()) == P.row_13(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_13(r,p,yes): output_13(r,p,P.replay(r,p),yes)
def output_14(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_14()) == P.row_14(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p14
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_14()) == P.row_14(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_14(r,p,yes): output_14(r,p,P.replay(r,p),yes)
def output_15(+r: P.Request,+p: P.Packet,result: P.Verdict<r,p>,yes: {P.accepted(r,p,result) == True{} : Bool}) -> {R.eval(P.candidate(p),C.input_15()) == P.row_15(P.outputs(p)) : R.Bits}:
  match result:
    case P.Accepted{s,m,l,c,e,P.Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}: p15
    case P.Invalid{why}: Empty.absurd({R.eval(P.candidate(p),C.input_15()) == P.row_15(P.outputs(p)) : R.Bits},E.false_true(yes))
def Laws.replay_output_15(r,p,yes): output_15(r,p,P.replay(r,p),yes)
def Laws.positive_zero_rewrite(): {==}

def complete_table(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,result: E.Decision<P.Matches<P.candidate(p),P.outputs(p)>>) ->
  {P.accepted(r,p,P.table_result(r,p,source,membership,strict,cost,certificate,result)) == True{} : Bool}:
  match result:
    case E.Yes{proof}: {==}
    case E.No{no}: Empty.absurd({False{} == True{} : Bool},no(expected))
def complete_equivalent(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,result: C.Check<P.reference(r),P.candidate(p)>) ->
  {P.accepted(r,p,P.equivalent(r,p,source,membership,strict,cost,result)) == True{} : Bool}:
  match result:
    case C.Equivalent{proof}:
      complete_table(r,p,source,membership,strict,cost,proof,expected,
        P.table_0(P.candidate(p),P.outputs(p),E.decide(R.eval(P.candidate(p),C.input_0()),P.row_0(P.outputs(p)))))
    case C.Different{input,refute}:
      Empty.absurd({False{} == True{} : Bool},refute(C.sound(P.reference(r),P.candidate(p),certificate,input)))
def complete_cost(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,decision: E.Decision<{Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool}>) ->
  {P.accepted(r,p,P.check_cost(r,p,source,membership,strict,decision)) == True{} : Bool}:
  match decision:
    case E.No{no}: Empty.absurd({False{} == True{} : Bool},no(cost))
    case E.Yes{actual}:
      complete_equivalent(r,p,source,membership,strict,actual,certificate,expected,C.certify(P.reference(r),P.candidate(p)))
def complete_strict(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,decision: E.Decision<{Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool}>) ->
  {P.accepted(r,p,P.check_strict(r,p,source,membership,decision)) == True{} : Bool}:
  match decision:
    case E.No{no}: Empty.absurd({False{} == True{} : Bool},no(strict))
    case E.Yes{actual}:
      complete_cost(r,p,source,membership,actual,cost,certificate,expected,E.decide_bool(Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)),True{}))
def complete_membership(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,decision: E.Decision<{P.member(r,P.candidate(p)) == True{} : Bool}>) ->
  {P.accepted(r,p,P.check_membership(r,p,source,decision)) == True{} : Bool}:
  match decision:
    case E.No{no}: Empty.absurd({False{} == True{} : Bool},no(membership))
    case E.Yes{actual}:
      complete_strict(r,p,source,actual,strict,cost,certificate,expected,E.decide_bool(Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))),True{}))
def complete_source(+r: P.Request,+p: P.Packet,source: {P.embedded(p) == P.reference(r) : R.Expr},membership: {P.member(r,P.candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(P.candidate(p)),R.cost(P.reference(r))) == True{} : Bool},cost: {Nat.is_eq(R.cost(P.candidate(p)),P.claimed_cost(p)) == True{} : Bool},certificate: C.Certificate<P.reference(r),P.candidate(p)>,expected: P.Matches<P.candidate(p),P.outputs(p)>,decision: E.Decision<{P.embedded(p) == P.reference(r) : R.Expr}>) ->
  {P.accepted(r,p,P.check_source(r,p,decision)) == True{} : Bool}:
  match decision:
    case E.No{no}: Empty.absurd({False{} == True{} : Bool},no(source))
    case E.Yes{actual}:
      complete_membership(r,p,actual,membership,strict,cost,certificate,expected,E.decide_bool(P.member(r,P.candidate(p)),True{}))
def nat_same(n: Nat) -> {Nat.is_eq(n,n) == True{} : Bool}:
  match n:
    case 0n: {==}
    case 1n+p: nat_same(p)
def Laws.canonical_roundtrip(reference,candidate,ops,bound,membership,strict,certificate):
  complete_source(P.Request{reference,ops,bound},P.canonical(reference,candidate),
    {==},membership,strict,nat_same(R.cost(candidate)),certificate,
    P.Matches{{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==},{==}},
    P.identity(P.embedded(P.canonical(reference,candidate)),P.reference(P.Request{reference,ops,bound})))
