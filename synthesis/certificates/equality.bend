import Base
import ../interpreter/runtime.bend as R

type Decision<-P: Type> is Type:
  Yes{proof: P}
  No{refute: P -> Empty}

def distinguish(b: Bool) -> Type:
  match b:
    case False{}: Unit
    case True{}: Empty

def false_true(e: {False{} == True{} : Bool}) -> Empty:
  %e : distinguish(_)
  Unit{}

def true_false(e: {True{} == False{} : Bool}) -> Empty:
  false_true(Equal.sym(Bool,True{},False{},e))

def decide_bool(+a: Bool, +b: Bool) -> Decision<{a == b : Bool}>:
  match a b:
    case False{} False{}: Yes{{==}}
    case True{} True{}: Yes{{==}}
    case False{} True{}: No{false_true}
    case True{} False{}: No{true_false}

def b0(a: R.Bits) -> Bool:
  match a:
    case R.Bits{x,y,z,w}: x

def b1(a: R.Bits) -> Bool:
  match a:
    case R.Bits{x,y,z,w}: y

def b2(a: R.Bits) -> Bool:
  match a:
    case R.Bits{x,y,z,w}: z

def b3(a: R.Bits) -> Bool:
  match a:
    case R.Bits{x,y,z,w}: w

law assemble:
  for +a: R.Bits
  for +b: R.Bits
  for p0: {b0(a) == b0(b) : Bool}
  for p1: {b1(a) == b1(b) : Bool}
  for p2: {b2(a) == b2(b) : Bool}
  for p3: {b3(a) == b3(b) : Bool}
  {a == b : R.Bits}

def assemble(a,b,p0,p1,p2,p3):
  match a b:
    case R.Bits{a0,a1,a2,a3} R.Bits{c0,c1,c2,c3}:
      %p3 : {R.Bits{a0,a1,a2,a3} == R.Bits{c0,c1,c2,_} : R.Bits}
      %p2 : {R.Bits{a0,a1,a2,a3} == R.Bits{c0,c1,_,a3} : R.Bits}
      %p1 : {R.Bits{a0,a1,a2,a3} == R.Bits{c0,_,a2,a3} : R.Bits}
      %p0 : {R.Bits{a0,a1,a2,a3} == R.Bits{_,a1,a2,a3} : R.Bits}
      {==}

def combine(+a: R.Bits, +b: R.Bits,
  d0: Decision<{b0(a) == b0(b) : Bool}>,
  d1: Decision<{b1(a) == b1(b) : Bool}>,
  d2: Decision<{b2(a) == b2(b) : Bool}>,
  d3: Decision<{b3(a) == b3(b) : Bool}>) -> Decision<{a == b : R.Bits}>:
  match d0 d1 d2 d3:
    case Yes{p0} Yes{p1} Yes{p2} Yes{p3}: Yes{assemble(a,b,p0,p1,p2,p3)}
    case No{refute} _ _ _: No{eq => refute(Equal.cong(R.Bits,Bool,b0,a,b,eq))}
    case _ No{refute} _ _: No{eq => refute(Equal.cong(R.Bits,Bool,b1,a,b,eq))}
    case _ _ No{refute} _: No{eq => refute(Equal.cong(R.Bits,Bool,b2,a,b,eq))}
    case _ _ _ No{refute}: No{eq => refute(Equal.cong(R.Bits,Bool,b3,a,b,eq))}

def decide(+a: R.Bits, +b: R.Bits) -> Decision<{a == b : R.Bits}>:
  combine(a,b,decide_bool(b0(a),b0(b)),decide_bool(b1(a),b1(b)),decide_bool(b2(a),b2(b)),decide_bool(b3(a),b3(b)))
