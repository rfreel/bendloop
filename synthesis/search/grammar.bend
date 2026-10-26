import Base
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C

# Experimental implementation. Enumeration/order proofs are required by the release gate.
type Ops is Data:
  Ops{negate: Bool, conjunction: Bool, disjunction: Bool, exclusive_or: Bool}

type Bound is Data:
  N1{}
  N2{}
  N3{}
  N4{}
  N5{}
  N6{}
  N7{}

def nodes(b: Bound) -> Nat:
  match b:
    case N1{}: 1n
    case N2{}: 2n
    case N3{}: 3n
    case N4{}: 4n
    case N5{}: 5n
    case N6{}: 6n
    case N7{}: 7n

def flag(b: Bool) -> U32:
  match b:
    case False{}: 0
    case True{}: 1

def unary(ops: Ops) -> U32:
  match ops:
    case Ops{n,a,o,x}: flag(n)

def binary(ops: Ops) -> U32:
  match ops:
    case Ops{n,a,o,x}: (flag(a) + flag(o) + flag(x) : U32)

def allowed(t: U32, ops: Ops) -> Bool:
  match t ops:
    case 17 Ops{n,a,o,x}: n
    case 18 Ops{n,a,o,x}: a
    case 19 Ops{n,a,o,x}: o
    case 20 Ops{n,a,o,x}: x
    case _ _: True{}

def arity(t: U32) -> Nat:
  match t:
    case 17: 1n
    case 18: 2n
    case 19: 2n
    case 20: 2n
    case _: 0n

# Number of valid suffixes. With n<=7 and the four-operator grammar all counts fit U32.
def count(n: Nat, slots: Nat, +ops: Ops) -> U32:
  match n slots:
    case 0n 0n: 1
    case 0n 1n+s: 0
    case 1n+p 0n: 0
    case 1n+p0 1n+s0:
      +p = p0
      +s = s0
      (17 * count(p,s,ops) + unary(ops) * count(p,1n+s,ops) + binary(ops) * count(p,2n+s,ops) : U32)

def slots_after(slots: Nat, token: U32) -> Nat:
  Nat.add(Nat.sub(slots,1n),arity(token))

def weight_if(ok: Bool, rest: Nat, slots: Nat, ops: Ops) -> U32:
  match ok:
    case False{}: 0
    case True{}: count(rest,slots,ops)

type Pick is Data:
  Pick{token: U32, rank: U32, slots: Nat}

def pick_if(ok: Bool, token: U32, rank: U32, slots: Nat, next: Unit -> Maybe<&2,Pick>) -> Maybe<&2,Pick>:
  match ok:
    case True{}: Some{Pick{token,rank,slots}}
    case False{}: next(Unit{})

def select(fuel: Nat, +token: U32, +rank: U32, +slots: Nat, +rest: Nat, +ops: Ops) -> Maybe<&2,Pick>:
  match fuel:
    case 0n: None{}
    case 1n+n:
      +after = slots_after(slots,token)
      +weight = weight_if(allowed(token,ops),rest,after,ops)
      pick_if(U32.is_lt(rank,weight),token,rank,after,
        u => select(n,(token + 1 : U32),(rank - weight : U32),slots,rest,ops))

def apply_pick(pick: Maybe<&2,Pick>, f: @+pick: Pick -> Maybe<&2,U32>) -> Maybe<&2,U32>:
  match pick:
    case None{}: None{}
    case Some{value}: f(value)

def finish_prefix(slots: Nat, code: U32) -> Maybe<&2,U32>:
  match slots:
    case 0n: Some{code}
    case 1n+p: None{}

def pick_token(pick: Pick) -> U32:
  match pick:
    case Pick{t,r,s}: t

def pick_rank(pick: Pick) -> U32:
  match pick:
    case Pick{t,r,s}: r

def pick_slots(pick: Pick) -> Nat:
  match pick:
    case Pick{t,r,s}: s

def prefix(n: Nat, slots: Nat, rank: U32, code: U32, +ops: Ops) -> Maybe<&2,U32>:
  match n:
    case 0n: finish_prefix(slots,code)
    case 1n+p0:
      +p = p0
      apply_pick(select(21n,0,rank,slots,p,ops),
        +pick => prefix(p,pick_slots(pick),pick_rank(pick),(code * 21 + pick_token(pick) : U32),ops))


type Code is Data:
  Code{length: Nat, value: U32}

def wrap_code(n: Nat, code: Maybe<&2,U32>) -> Maybe<&2,Code>:
  match code:
    case None{}: None{}
    case Some{value}: Some{Code{n,value}}

def locate_if(ok: Bool, +n: Nat, rank: U32, ops: Ops, next: Unit -> Maybe<&2,Code>) -> Maybe<&2,Code>:
  match ok:
    case True{}: wrap_code(n,prefix(n,1n,rank,0,ops))
    case False{}: next(Unit{})

def locate(fuel: Nat, +n: Nat, +rank: U32, +ops: Ops) -> Maybe<&2,Code>:
  match fuel:
    case 0n: None{}
    case 1n+p:
      +weight = count(n,1n,ops)
      locate_if(U32.is_lt(rank,weight),n,rank,ops,
        u => locate(p,1n+n,(rank - weight : U32),ops))

def at(bound: Bound, ops: Ops, index: U32) -> Maybe<&2,Code>:
  locate(nodes(bound),1n,index,ops)

# Sequential syntax tokens, at most seven, are consumed by the AST decoder.
def unpack(n: Nat, +code: U32, tail: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n: tail
    case 1n+p: unpack(p,(code / 21 : U32),Con{(code % 21 : U32),tail})

def constant(token: U32) -> R.Expr:
  match token:
    case 0: R.Input{}
    case 1: R.Constant{C.input_0()}
    case 2: R.Constant{C.input_1()}
    case 3: R.Constant{C.input_2()}
    case 4: R.Constant{C.input_3()}
    case 5: R.Constant{C.input_4()}
    case 6: R.Constant{C.input_5()}
    case 7: R.Constant{C.input_6()}
    case 8: R.Constant{C.input_7()}
    case 9: R.Constant{C.input_8()}
    case 10: R.Constant{C.input_9()}
    case 11: R.Constant{C.input_10()}
    case 12: R.Constant{C.input_11()}
    case 13: R.Constant{C.input_12()}
    case 14: R.Constant{C.input_13()}
    case 15: R.Constant{C.input_14()}
    case _: R.Constant{C.input_15()}

def join(op: U32, lhs: R.Expr, rhs: R.Expr) -> R.Expr:
  match op:
    case 18: R.And{lhs,rhs}
    case 19: R.Or{lhs,rhs}
    case _: R.Xor{lhs,rhs}

def right(op: U32, lhs: R.Expr, result: Maybe<&1,R.Expr & List<&2,U32>>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match result:
    case None{}: None{}
    case Some{pair}:
      (rhs,tail) = pair
      Some{(join(op,lhs,rhs),tail)}

def left(op: U32, result: Maybe<&1,R.Expr & List<&2,U32>>, next: List<&2,U32> -> Maybe<&1,R.Expr & List<&2,U32>>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match result:
    case None{}: None{}
    case Some{pair}:
      (lhs,tail) = pair
      right(op,lhs,next(tail))

def negated(result: Maybe<&1,R.Expr & List<&2,U32>>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match result:
    case None{}: None{}
    case Some{pair}:
      (value,tail) = pair
      Some{(R.Not{value},tail)}

def leaf_if(ok: Bool, token: U32, tail: List<&2,U32>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match ok:
    case True{}: Some{(constant(token),tail)}
    case False{}: None{}

def parse_token(+token: U32, tail: List<&2,U32>, p: List<&2,U32> -> Maybe<&1,R.Expr & List<&2,U32>>, q: List<&2,U32> -> Maybe<&1,R.Expr & List<&2,U32>>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match token:
    case 17: negated(p(tail))
    case 18: left(18,p(tail),q)
    case 19: left(19,p(tail),q)
    case 20: left(20,p(tail),q)
    case _: leaf_if(U32.is_lt(token,17),token,tail)

def parse(fuel: Nat, tokens: List<&2,U32>) -> Maybe<&1,R.Expr & List<&2,U32>>:
  match fuel tokens:
    case 0n _: None{}
    case 1n+p Nil{}: None{}
    case 1n+p0 Con{token,tail}:
      +p = p0
      parse_token(token,tail,xs => parse(p,xs),xs => parse(p,xs))

def end(expr: R.Expr, tail: List<&2,U32>) -> Maybe<&2,R.Expr>:
  match tail:
    case Nil{}: Some{expr}
    case Con{h,t}: None{}

def parsed(result: Maybe<&1,R.Expr & List<&2,U32>>) -> Maybe<&2,R.Expr>:
  match result:
    case None{}: None{}
    case Some{pair}:
      (expr,tail) = pair
      end(expr,tail)

def decode(code: Code) -> Maybe<&2,R.Expr>:
  match code:
    case Code{+n,value}: parsed(parse(n,unpack(n,value,Nil{})))
