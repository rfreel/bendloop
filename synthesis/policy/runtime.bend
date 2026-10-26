import Base
import ./types.bend as P
import ../interpreter/runtime.bend as R
import ../certificates/equality.bend as E
import ../certificates/runtime.bend as C

# No model, proof module, task name, expected answer, or score is imported.
def bool_same(a: Bool, b: Bool) -> Bool: Bool.not(Bool.xor(a,b))
def bits_same(a: R.Bits, b: R.Bits) -> Bool:
  match a b:
    case R.Bits{a0,a1,a2,a3} R.Bits{b0,b1,b2,b3}:
      bool_same(a0,b0) && bool_same(a1,b1) && bool_same(a2,b2) && bool_same(a3,b3)
def expr_same(a: R.Expr, b: R.Expr) -> Bool:
  match a b:
    case R.Input{} R.Input{}: True{}
    case R.Constant{x} R.Constant{y}: bits_same(x,y)
    case R.Not{x} R.Not{y}: expr_same(x,y)
    case R.And{a,b} R.And{c,d}: expr_same(a,c) && expr_same(b,d)
    case R.Or{a,b} R.Or{c,d}: expr_same(a,c) && expr_same(b,d)
    case R.Xor{a,b} R.Xor{c,d}: expr_same(a,c) && expr_same(b,d)
    case _ _: False{}
def zero_constant(e: R.Expr) -> Bool:
  match e:
    case R.Constant{b}: bits_same(b,C.input_0())
    case _: False{}
def ones_constant(e: R.Expr) -> Bool:
  match e:
    case R.Constant{b}: bits_same(b,C.input_15())
    case _: False{}
def zero_form(e: R.Expr) -> Bool:
  match e:
    case R.Xor{a,b}: expr_same(a,b)
    case R.And{a,b}: zero_constant(a) || zero_constant(b)
    case _: False{}
def ones_form(e: R.Expr) -> Bool:
  match e:
    case R.Or{a,b}: ones_constant(a) || ones_constant(b)
    case R.Not{a}: zero_constant(a)
    case _: False{}
def select(zero: Bool, ones: Bool) -> P.Priority:
  match zero ones:
    case True{} _: P.SeedZero{}
    case False{} True{}: P.SeedOnes{}
    case False{} False{}: P.Original{}
def priority(policy: P.Policy, +reference: R.Expr) -> P.Priority:
  P.Policy{zero,ones,order} = policy
  select(zero && zero_form(reference),ones && ones_form(reference))

# Swap two existing leaf ranks. No candidate is added, omitted or duplicated.
def rank(priority: P.Priority, n: Nat) -> Nat:
  match priority n:
    case P.Original{} _: n
    case P.SeedZero{} 0n: 1n
    case P.SeedZero{} 1n: 0n
    case P.SeedZero{} 2n+p: 2n+p
    case P.SeedOnes{} 0n: 16n
    case P.SeedOnes{} 1n: 1n
    case P.SeedOnes{} 2n: 2n
    case P.SeedOnes{} 3n: 3n
    case P.SeedOnes{} 4n: 4n
    case P.SeedOnes{} 5n: 5n
    case P.SeedOnes{} 6n: 6n
    case P.SeedOnes{} 7n: 7n
    case P.SeedOnes{} 8n: 8n
    case P.SeedOnes{} 9n: 9n
    case P.SeedOnes{} 10n: 10n
    case P.SeedOnes{} 11n: 11n
    case P.SeedOnes{} 12n: 12n
    case P.SeedOnes{} 13n: 13n
    case P.SeedOnes{} 14n: 14n
    case P.SeedOnes{} 15n: 15n
    case P.SeedOnes{} 16n: 0n
    case P.SeedOnes{} 17n+p: 17n+p

def enable_zero(p: P.Policy) -> P.Policy:
  P.Policy{z,o,m} = p
  P.Policy{True{},o,m}
def enable_ones(p: P.Policy) -> P.Policy:
  P.Policy{z,o,m} = p
  P.Policy{z,True{},m}
def with_order(p: P.Policy, m: P.Order) -> P.Policy:
  P.Policy{z,o,old} = p
  P.Policy{z,o,m}
def prefer(p: P.Policy, zero: Bool) -> Maybe<&2,P.Policy>:
  match zero:
    case True{}: Some{enable_zero(p)}
    case False{}: Some{enable_ones(p)}
def by_order(+p: P.Policy, task: R.Expr, index: Nat, order: P.Order) -> Maybe<&2,P.Policy>:
  match index order:
    case 0n P.ZeroFirst{}: Some{enable_zero(p)}
    case 1n P.ZeroFirst{}: Some{enable_ones(p)}
    case 0n P.OnesFirst{}: Some{enable_ones(p)}
    case 1n P.OnesFirst{}: Some{enable_zero(p)}
    case 0n P.RootAware{}: prefer(p,zero_form(task))
    case 1n P.RootAware{}: prefer(p,Bool.not(zero_form(task)))
    case 2n _: Some{with_order(p,P.RootAware{})}
    case 3n _: Some{with_order(p,P.ZeroFirst{})}
    case 4n _: Some{with_order(p,P.OnesFirst{})}
    case _ _: None{}
def propose(+p: P.Policy, task: R.Expr, index: Nat) -> Maybe<&2,P.Policy>:
  P.Policy{z,o,order} = p
  by_order(p,task,index,order)
