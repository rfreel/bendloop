import Base
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C
import ../certificates/equality.bend as E
import ../search/grammar.bend as G

type Request is Data:
  Request{reference: R.Expr, ops: G.Ops, bound: G.Bound}
type Table is Data:
  Table{v0: R.Bits,v1: R.Bits,v2: R.Bits,v3: R.Bits,v4: R.Bits,v5: R.Bits,v6: R.Bits,v7: R.Bits,v8: R.Bits,v9: R.Bits,v10: R.Bits,v11: R.Bits,v12: R.Bits,v13: R.Bits,v14: R.Bits,v15: R.Bits}
type Packet is Data:
  Packet{reference: R.Expr,candidate: R.Expr,cost: Nat,outputs: Table}
def reference(r: Request) -> R.Expr:
  Request{r,o,b} = r
  r
def embedded(p: Packet) -> R.Expr:
  Packet{r,c,k,t} = p
  r
def candidate(p: Packet) -> R.Expr:
  Packet{r,c,k,t} = p
  c
def claimed_cost(p: Packet) -> Nat:
  Packet{r,c,k,t} = p
  k
def outputs(p: Packet) -> Table:
  Packet{r,c,k,t} = p
  t
def allowed(e: R.Expr,+ops: G.Ops) -> Bool:
  match e ops:
    case R.Input{} _: True{}
    case R.Constant{b} _: True{}
    case R.Not{x} G.Ops{n,a,o,z}: n && allowed(x,ops)
    case R.And{x,y} G.Ops{n,a,o,z}: a && allowed(x,ops) && allowed(y,ops)
    case R.Or{x,y} G.Ops{n,a,o,z}: o && allowed(x,ops) && allowed(y,ops)
    case R.Xor{x,y} G.Ops{n,a,o,z}: z && allowed(x,ops) && allowed(y,ops)
def member(r: Request,+e: R.Expr) -> Bool:
  Request{ref,ops,bound} = r
  allowed(e,ops) && Nat.is_le(R.size(e),G.nodes(bound))
def tag(e: R.Expr) -> U32:
  match e:
    case R.Input{}: 0
    case R.Constant{v}: 1
    case R.Not{x}: 2
    case R.And{x,y}: 3
    case R.Or{x,y}: 4
    case R.Xor{x,y}: 5
def is_tag(+n: U32,e: R.Expr) -> Bool: U32.is_eq(n,tag(e))
def value(e: R.Expr) -> R.Bits:
  match e:
    case R.Constant{v}: v
    case _: C.input_0()
def left(e: R.Expr) -> R.Expr:
  match e:
    case R.Not{x}: x
    case R.And{x,y}: x
    case R.Or{x,y}: x
    case R.Xor{x,y}: x
    case _: R.Input{}
def right(e: R.Expr) -> R.Expr:
  match e:
    case R.And{x,y}: y
    case R.Or{x,y}: y
    case R.Xor{x,y}: y
    case _: R.Input{}
def constant(+a: R.Bits,+b: R.Bits,d: E.Decision<{a == b : R.Bits}>) -> E.Decision<{R.Constant{a} == R.Constant{b} : R.Expr}>:
  match d:
    case E.Yes{p}: E.Yes{Equal.cong(R.Bits,R.Expr,x => R.Constant{x},a,b,p)}
    case E.No{no}: E.No{p => no(Equal.cong(R.Expr,R.Bits,value,R.Constant{a},R.Constant{b},p))}
def eq_not(+a: R.Expr,+b: R.Expr,x: E.Decision<{a == b : R.Expr}>) -> E.Decision<{R.Not{a} == R.Not{b} : R.Expr}>:
  match x:
    case E.Yes{p}: E.Yes{Equal.cong(R.Expr,R.Expr,e => R.Not{e},a,b,p)}
    case E.No{no}: E.No{p => no(Equal.cong(R.Expr,R.Expr,left,R.Not{a},R.Not{b},p))}
def eq_and(+a: R.Expr,+b: R.Expr,+c: R.Expr,+d: R.Expr,
  x: E.Decision<{a == c : R.Expr}>,y: E.Decision<{b == d : R.Expr}>) -> E.Decision<{R.And{a,b} == R.And{c,d} : R.Expr}>:
  match x y:
    case E.Yes{p} E.Yes{q}:
      %p : E.Decision<{R.And{a,b} == R.And{_,d} : R.Expr}>
      %q : E.Decision<{R.And{a,b} == R.And{a,_} : R.Expr}>
      E.Yes{{==}}
    case E.No{no} _: E.No{p => no(Equal.cong(R.Expr,R.Expr,left,R.And{a,b},R.And{c,d},p))}
    case _ E.No{no}: E.No{p => no(Equal.cong(R.Expr,R.Expr,right,R.And{a,b},R.And{c,d},p))}
def eq_or(+a: R.Expr,+b: R.Expr,+c: R.Expr,+d: R.Expr,
  x: E.Decision<{a == c : R.Expr}>,y: E.Decision<{b == d : R.Expr}>) -> E.Decision<{R.Or{a,b} == R.Or{c,d} : R.Expr}>:
  match x y:
    case E.Yes{p} E.Yes{q}:
      %p : E.Decision<{R.Or{a,b} == R.Or{_,d} : R.Expr}>
      %q : E.Decision<{R.Or{a,b} == R.Or{a,_} : R.Expr}>
      E.Yes{{==}}
    case E.No{no} _: E.No{p => no(Equal.cong(R.Expr,R.Expr,left,R.Or{a,b},R.Or{c,d},p))}
    case _ E.No{no}: E.No{p => no(Equal.cong(R.Expr,R.Expr,right,R.Or{a,b},R.Or{c,d},p))}
def eq_xor(+a: R.Expr,+b: R.Expr,+c: R.Expr,+d: R.Expr,
  x: E.Decision<{a == c : R.Expr}>,y: E.Decision<{b == d : R.Expr}>) -> E.Decision<{R.Xor{a,b} == R.Xor{c,d} : R.Expr}>:
  match x y:
    case E.Yes{p} E.Yes{q}:
      %p : E.Decision<{R.Xor{a,b} == R.Xor{_,d} : R.Expr}>
      %q : E.Decision<{R.Xor{a,b} == R.Xor{a,_} : R.Expr}>
      E.Yes{{==}}
    case E.No{no} _: E.No{p => no(Equal.cong(R.Expr,R.Expr,left,R.Xor{a,b},R.Xor{c,d},p))}
    case _ E.No{no}: E.No{p => no(Equal.cong(R.Expr,R.Expr,right,R.Xor{a,b},R.Xor{c,d},p))}
def identity(+a: R.Expr,+b: R.Expr) -> E.Decision<{a == b : R.Expr}>:
  match a b:
    case R.Input{} R.Input{}:
      E.Yes{{==}}
    case R.Input{} R.Constant{vb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(0,e),a,b,p))}
    case R.Input{} R.Not{xb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(0,e),a,b,p))}
    case R.Input{} R.And{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(0,e),a,b,p))}
    case R.Input{} R.Or{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(0,e),a,b,p))}
    case R.Input{} R.Xor{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(0,e),a,b,p))}
    case R.Constant{va} R.Input{}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(1,e),a,b,p))}
    case R.Constant{va} R.Constant{vb}:
      constant(va,vb,E.decide(va,vb))
    case R.Constant{va} R.Not{xb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(1,e),a,b,p))}
    case R.Constant{va} R.And{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(1,e),a,b,p))}
    case R.Constant{va} R.Or{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(1,e),a,b,p))}
    case R.Constant{va} R.Xor{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(1,e),a,b,p))}
    case R.Not{xa} R.Input{}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(2,e),a,b,p))}
    case R.Not{xa} R.Constant{vb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(2,e),a,b,p))}
    case R.Not{xa} R.Not{xb}:
      eq_not(xa,xb,identity(xa,xb))
    case R.Not{xa} R.And{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(2,e),a,b,p))}
    case R.Not{xa} R.Or{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(2,e),a,b,p))}
    case R.Not{xa} R.Xor{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(2,e),a,b,p))}
    case R.And{xa,ya} R.Input{}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(3,e),a,b,p))}
    case R.And{xa,ya} R.Constant{vb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(3,e),a,b,p))}
    case R.And{xa,ya} R.Not{xb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(3,e),a,b,p))}
    case R.And{xa,ya} R.And{xb,yb}:
      eq_and(xa,ya,xb,yb,identity(xa,xb),identity(ya,yb))
    case R.And{xa,ya} R.Or{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(3,e),a,b,p))}
    case R.And{xa,ya} R.Xor{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(3,e),a,b,p))}
    case R.Or{xa,ya} R.Input{}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(4,e),a,b,p))}
    case R.Or{xa,ya} R.Constant{vb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(4,e),a,b,p))}
    case R.Or{xa,ya} R.Not{xb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(4,e),a,b,p))}
    case R.Or{xa,ya} R.And{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(4,e),a,b,p))}
    case R.Or{xa,ya} R.Or{xb,yb}:
      eq_or(xa,ya,xb,yb,identity(xa,xb),identity(ya,yb))
    case R.Or{xa,ya} R.Xor{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(4,e),a,b,p))}
    case R.Xor{xa,ya} R.Input{}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(5,e),a,b,p))}
    case R.Xor{xa,ya} R.Constant{vb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(5,e),a,b,p))}
    case R.Xor{xa,ya} R.Not{xb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(5,e),a,b,p))}
    case R.Xor{xa,ya} R.And{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(5,e),a,b,p))}
    case R.Xor{xa,ya} R.Or{xb,yb}:
      E.No{p => E.true_false(Equal.cong(R.Expr,Bool,e => is_tag(5,e),a,b,p))}
    case R.Xor{xa,ya} R.Xor{xb,yb}:
      eq_xor(xa,ya,xb,yb,identity(xa,xb),identity(ya,yb))
type Matches<-candidate: R.Expr,-table: Table> is Type:
  Matches{p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},p11: {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits},p12: {R.eval(candidate,C.input_12()) == row_12(table) : R.Bits},p13: {R.eval(candidate,C.input_13()) == row_13(table) : R.Bits},p14: {R.eval(candidate,C.input_14()) == row_14(table) : R.Bits},p15: {R.eval(candidate,C.input_15()) == row_15(table) : R.Bits}}
def row_0(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v0
def row_1(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v1
def row_2(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v2
def row_3(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v3
def row_4(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v4
def row_5(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v5
def row_6(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v6
def row_7(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v7
def row_8(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v8
def row_9(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v9
def row_10(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v10
def row_11(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v11
def row_12(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v12
def row_13(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v13
def row_14(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v14
def row_15(t: Table) -> R.Bits:
  Table{v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15} = t
  v15
def matches_0(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p0
def matches_1(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p1
def matches_2(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p2
def matches_3(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p3
def matches_4(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p4
def matches_5(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p5
def matches_6(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p6
def matches_7(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p7
def matches_8(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p8
def matches_9(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p9
def matches_10(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p10
def matches_11(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p11
def matches_12(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_12()) == row_12(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p12
def matches_13(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_13()) == row_13(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p13
def matches_14(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_14()) == row_14(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p14
def matches_15(-candidate: R.Expr,-table: Table,proof: Matches<candidate,table>) -> {R.eval(candidate,C.input_15()) == row_15(table) : R.Bits}:
  Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15} = proof
  p15
def table_15(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},
  p11: {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits},
  p12: {R.eval(candidate,C.input_12()) == row_12(table) : R.Bits},
  p13: {R.eval(candidate,C.input_13()) == row_13(table) : R.Bits},
  p14: {R.eval(candidate,C.input_14()) == row_14(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_15()) == row_15(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_15(candidate,table,proof))}
    case E.Yes{p15}: E.Yes{Matches{p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15}}
def table_14(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},
  p11: {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits},
  p12: {R.eval(candidate,C.input_12()) == row_12(table) : R.Bits},
  p13: {R.eval(candidate,C.input_13()) == row_13(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_14()) == row_14(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_14(candidate,table,proof))}
    case E.Yes{p14}: table_15(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,E.decide(R.eval(candidate,C.input_15()),row_15(table)))
def table_13(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},
  p11: {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits},
  p12: {R.eval(candidate,C.input_12()) == row_12(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_13()) == row_13(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_13(candidate,table,proof))}
    case E.Yes{p13}: table_14(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,E.decide(R.eval(candidate,C.input_14()),row_14(table)))
def table_12(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},
  p11: {R.eval(candidate,C.input_11()) == row_11(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_12()) == row_12(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_12(candidate,table,proof))}
    case E.Yes{p12}: table_13(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,E.decide(R.eval(candidate,C.input_13()),row_13(table)))
def table_11(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  p10: {R.eval(candidate,C.input_10()) == row_10(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_11()) == row_11(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_11(candidate,table,proof))}
    case E.Yes{p11}: table_12(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,E.decide(R.eval(candidate,C.input_12()),row_12(table)))
def table_10(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  p9: {R.eval(candidate,C.input_9()) == row_9(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_10()) == row_10(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_10(candidate,table,proof))}
    case E.Yes{p10}: table_11(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,E.decide(R.eval(candidate,C.input_11()),row_11(table)))
def table_9(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  p8: {R.eval(candidate,C.input_8()) == row_8(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_9()) == row_9(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_9(candidate,table,proof))}
    case E.Yes{p9}: table_10(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,E.decide(R.eval(candidate,C.input_10()),row_10(table)))
def table_8(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  p7: {R.eval(candidate,C.input_7()) == row_7(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_8()) == row_8(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_8(candidate,table,proof))}
    case E.Yes{p8}: table_9(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,p8,E.decide(R.eval(candidate,C.input_9()),row_9(table)))
def table_7(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  p6: {R.eval(candidate,C.input_6()) == row_6(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_7()) == row_7(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_7(candidate,table,proof))}
    case E.Yes{p7}: table_8(candidate,table,p0,p1,p2,p3,p4,p5,p6,p7,E.decide(R.eval(candidate,C.input_8()),row_8(table)))
def table_6(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  p5: {R.eval(candidate,C.input_5()) == row_5(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_6()) == row_6(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_6(candidate,table,proof))}
    case E.Yes{p6}: table_7(candidate,table,p0,p1,p2,p3,p4,p5,p6,E.decide(R.eval(candidate,C.input_7()),row_7(table)))
def table_5(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  p4: {R.eval(candidate,C.input_4()) == row_4(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_5()) == row_5(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_5(candidate,table,proof))}
    case E.Yes{p5}: table_6(candidate,table,p0,p1,p2,p3,p4,p5,E.decide(R.eval(candidate,C.input_6()),row_6(table)))
def table_4(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  p3: {R.eval(candidate,C.input_3()) == row_3(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_4()) == row_4(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_4(candidate,table,proof))}
    case E.Yes{p4}: table_5(candidate,table,p0,p1,p2,p3,p4,E.decide(R.eval(candidate,C.input_5()),row_5(table)))
def table_3(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  p2: {R.eval(candidate,C.input_2()) == row_2(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_3()) == row_3(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_3(candidate,table,proof))}
    case E.Yes{p3}: table_4(candidate,table,p0,p1,p2,p3,E.decide(R.eval(candidate,C.input_4()),row_4(table)))
def table_2(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  p1: {R.eval(candidate,C.input_1()) == row_1(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_2()) == row_2(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_2(candidate,table,proof))}
    case E.Yes{p2}: table_3(candidate,table,p0,p1,p2,E.decide(R.eval(candidate,C.input_3()),row_3(table)))
def table_1(+candidate: R.Expr,+table: Table,p0: {R.eval(candidate,C.input_0()) == row_0(table) : R.Bits},
  decision: E.Decision<{R.eval(candidate,C.input_1()) == row_1(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_1(candidate,table,proof))}
    case E.Yes{p1}: table_2(candidate,table,p0,p1,E.decide(R.eval(candidate,C.input_2()),row_2(table)))
def table_0(+candidate: R.Expr,+table: Table,decision: E.Decision<{R.eval(candidate,C.input_0()) == row_0(table) : R.Bits}>) -> E.Decision<Matches<candidate,table>>:
  match decision:
    case E.No{no}: E.No{proof => no(matches_0(candidate,table,proof))}
    case E.Yes{p0}: table_1(candidate,table,p0,E.decide(R.eval(candidate,C.input_1()),row_1(table)))
type Verdict<-r: Request,-p: Packet> is Type:
  Accepted{source: {embedded(p) == reference(r) : R.Expr},
    membership: {member(r,candidate(p)) == True{} : Bool},
    strict: {Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))) == True{} : Bool},
    cost: {Nat.is_eq(R.cost(candidate(p)),claimed_cost(p)) == True{} : Bool},
    equivalence: C.Certificate<reference(r),candidate(p)>,table: Matches<candidate(p),outputs(p)>}
  Invalid{reason: String}
def table_result(+r: Request,+p: Packet,
  source: {embedded(p) == reference(r) : R.Expr},
  membership: {member(r,candidate(p)) == True{} : Bool},
  strict: {Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))) == True{} : Bool},
  cost: {Nat.is_eq(R.cost(candidate(p)),claimed_cost(p)) == True{} : Bool},equivalence: C.Certificate<reference(r),candidate(p)>,
  result: E.Decision<Matches<candidate(p),outputs(p)>>) -> Verdict<r,p>:
  match result:
    case E.No{no}: Invalid{"claimed outputs differ"}
    case E.Yes{table}: Accepted{source,membership,strict,cost,equivalence,table}
def equivalent(+r: Request,+p: Packet,
  source: {embedded(p) == reference(r) : R.Expr},
  membership: {member(r,candidate(p)) == True{} : Bool},
  strict: {Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))) == True{} : Bool},
  cost: {Nat.is_eq(R.cost(candidate(p)),claimed_cost(p)) == True{} : Bool},result: C.Check<reference(r),candidate(p)>) -> Verdict<r,p>:
  match result:
    case C.Different{input,refute}: Invalid{"programs differ"}
    case C.Equivalent{certificate}:
      table_result(r,p,source,membership,strict,cost,certificate,
        table_0(candidate(p),outputs(p),E.decide(R.eval(candidate(p),C.input_0()),row_0(outputs(p)))))
def check_cost(+r: Request,+p: Packet,source: {embedded(p) == reference(r) : R.Expr},membership: {member(r,candidate(p)) == True{} : Bool},strict: {Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))) == True{} : Bool},decision: E.Decision<{Nat.is_eq(R.cost(candidate(p)),claimed_cost(p)) == True{} : Bool}>) -> Verdict<r,p>:
  match decision:
    case E.No{no}: Invalid{"claimed cost differs"}
    case E.Yes{cost}: equivalent(r,p,source,membership,strict,cost,C.certify(reference(r),candidate(p)))
def check_strict(+r: Request,+p: Packet,source: {embedded(p) == reference(r) : R.Expr},membership: {member(r,candidate(p)) == True{} : Bool},decision: E.Decision<{Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))) == True{} : Bool}>) -> Verdict<r,p>:
  match decision:
    case E.No{no}: Invalid{"not a strict improvement"}
    case E.Yes{strict}: check_cost(r,p,source,membership,strict,E.decide_bool(Nat.is_eq(R.cost(candidate(p)),claimed_cost(p)),True{}))
def check_membership(+r: Request,+p: Packet,source: {embedded(p) == reference(r) : R.Expr},decision: E.Decision<{member(r,candidate(p)) == True{} : Bool}>) -> Verdict<r,p>:
  match decision:
    case E.No{no}: Invalid{"candidate outside grammar"}
    case E.Yes{membership}: check_strict(r,p,source,membership,E.decide_bool(Nat.is_lt(R.cost(candidate(p)),R.cost(reference(r))),True{}))
def check_source(+r: Request,+p: Packet,d: E.Decision<{embedded(p) == reference(r) : R.Expr}>) -> Verdict<r,p>:
  match d:
    case E.No{no}: Invalid{"embedded reference differs"}
    case E.Yes{source}: check_membership(r,p,source,E.decide_bool(member(r,candidate(p)),True{}))
def replay(+r: Request,+p: Packet) -> Verdict<r,p>:
  check_source(r,p,identity(embedded(p),reference(r)))
def accepted(-r: Request,-p: Packet,v: Verdict<r,p>) -> Bool:
  match v:
    case Accepted{s,m,l,c,e,t}: True{}
    case Invalid{why}: False{}
def canonical(+r: R.Expr,+c: R.Expr) -> Packet:
  Packet{r,c,R.cost(c),Table{R.eval(c,C.input_0()),R.eval(c,C.input_1()),R.eval(c,C.input_2()),R.eval(c,C.input_3()),R.eval(c,C.input_4()),R.eval(c,C.input_5()),R.eval(c,C.input_6()),R.eval(c,C.input_7()),R.eval(c,C.input_8()),R.eval(c,C.input_9()),R.eval(c,C.input_10()),R.eval(c,C.input_11()),R.eval(c,C.input_12()),R.eval(c,C.input_13()),R.eval(c,C.input_14()),R.eval(c,C.input_15())}}
