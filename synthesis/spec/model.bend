import Base

# Independent reference semantics only. Production must prove its own evaluator refines this.
# Word(4n) represents exactly four bits, least significant bit first.
type Expr is Data:
  Input{}
  Constant{value: Word(4n)}
  Not{arg: Expr}
  And{lhs: Expr, rhs: Expr}
  Or{lhs: Expr, rhs: Expr}
  Xor{lhs: Expr, rhs: Expr}

type Ops is Data:
  Ops{negate: Bool, conjunction: Bool, disjunction: Bool, exclusive_or: Bool}

def eval(expr: Expr, +input: Word(4n)) -> Word(4n):
  match expr:
    case Input{}: input
    case Constant{value}: value
    case Not{arg}: Word.not(4n,eval(arg,input))
    case And{lhs,rhs}: Word.and(4n,eval(lhs,input),eval(rhs,input))
    case Or{lhs,rhs}: Word.or(4n,eval(lhs,input),eval(rhs,input))
    case Xor{lhs,rhs}: Word.xor(4n,eval(lhs,input),eval(rhs,input))

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

def allows(expr: Expr, +ops: Ops) -> Bool:
  match expr ops:
    case Input{} _: True{}
    case Constant{value} _: True{}
    case Not{arg} Ops{n,a,o,x}:
      Bool.and(n,allows(arg,Ops{n,a,o,x}))
    case And{lhs,rhs} Ops{n,a,o,x}:
      Bool.and(a,Bool.and(allows(lhs,Ops{n,a,o,x}),allows(rhs,Ops{n,a,o,x})))
    case Or{lhs,rhs} Ops{n,a,o,x}:
      Bool.and(o,Bool.and(allows(lhs,Ops{n,a,o,x}),allows(rhs,Ops{n,a,o,x})))
    case Xor{lhs,rhs} Ops{n,a,o,x}:
      Bool.and(x,Bool.and(allows(lhs,Ops{n,a,o,x}),allows(rhs,Ops{n,a,o,x})))
