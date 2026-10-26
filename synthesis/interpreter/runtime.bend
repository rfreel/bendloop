import Base

# The executable interpreter imports no specification or proof module.
# Fixed four-field scalar state; source-level total operations.
type Bits is Data:
  Bits{b0: Bool, b1: Bool, b2: Bool, b3: Bool}

def negate(a: Bits) -> Bits:
  match a:
    case Bits{a0,a1,a2,a3}:
      Bits{Bool.not(a0),Bool.not(a1),Bool.not(a2),Bool.not(a3)}

def conjunction(a: Bits, b: Bits) -> Bits:
  match a b:
    case Bits{a0,a1,a2,a3} Bits{b0,b1,b2,b3}:
      Bits{Bool.and(a0,b0),Bool.and(a1,b1),Bool.and(a2,b2),Bool.and(a3,b3)}

def disjunction(a: Bits, b: Bits) -> Bits:
  match a b:
    case Bits{a0,a1,a2,a3} Bits{b0,b1,b2,b3}:
      Bits{Bool.or(a0,b0),Bool.or(a1,b1),Bool.or(a2,b2),Bool.or(a3,b3)}

def exclusive_or(a: Bits, b: Bits) -> Bits:
  match a b:
    case Bits{a0,a1,a2,a3} Bits{b0,b1,b2,b3}:
      Bits{Bool.xor(a0,b0),Bool.xor(a1,b1),Bool.xor(a2,b2),Bool.xor(a3,b3)}

type Expr is Data:
  Input{}
  Constant{value: Bits}
  Not{arg: Expr}
  And{lhs: Expr, rhs: Expr}
  Or{lhs: Expr, rhs: Expr}
  Xor{lhs: Expr, rhs: Expr}

def eval(expr: Expr, +input: Bits) -> Bits:
  match expr:
    case Input{}: input
    case Constant{value}: value
    case Not{arg}: negate(eval(arg,input))
    case And{lhs,rhs}: conjunction(eval(lhs,input),eval(rhs,input))
    case Or{lhs,rhs}: disjunction(eval(lhs,input),eval(rhs,input))
    case Xor{lhs,rhs}: exclusive_or(eval(lhs,input),eval(rhs,input))

def cost(expr: Expr) -> Nat:
  match expr:
    case Input{}: 0n
    case Constant{value}: 0n
    case Not{arg}: 1n+cost(arg)
    case And{lhs,rhs}: 1n+Nat.add(cost(lhs),cost(rhs))
    case Or{lhs,rhs}: 1n+Nat.add(cost(lhs),cost(rhs))
    case Xor{lhs,rhs}: 1n+Nat.add(cost(lhs),cost(rhs))

def size(expr: Expr) -> Nat:
  match expr:
    case Input{}: 1n
    case Constant{value}: 1n
    case Not{arg}: 1n+size(arg)
    case And{lhs,rhs}: 1n+Nat.add(size(lhs),size(rhs))
    case Or{lhs,rhs}: 1n+Nat.add(size(lhs),size(rhs))
    case Xor{lhs,rhs}: 1n+Nat.add(size(lhs),size(rhs))

def digit(b: Bool) -> U32:
  match b:
    case False{}: 0
    case True{}: 1

def number(v: Bits) -> U32:
  match v:
    case Bits{b0,b1,b2,b3}:
      (digit(b0) + 2 * digit(b1) + 4 * digit(b2) + 8 * digit(b3) : U32)
