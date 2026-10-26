import Base
import ./types.bend as P
import ../spec/model.bend as M

# Reference semantics import no production policy or production evaluator.
def pick(zero: Bool, at_target: Bool, n: Nat, target: Nat) -> Nat:
  match zero at_target:
    case True{} _: target
    case False{} True{}: 0n
    case False{} False{}: n
def permutation(priority: P.Priority, +n: Nat) -> Nat:
  match priority:
    case P.Original{}: n
    case P.SeedZero{}: pick(Nat.is_eq(n,0n),Nat.is_eq(n,1n),n,1n)
    case P.SeedOnes{}: pick(Nat.is_eq(n,0n),Nat.is_eq(n,16n),n,16n)
def word_same(a: Word(4n), b: Word(4n)) -> Bool:
  match a b:
    case WCon{a0,WCon{a1,WCon{a2,WCon{a3,WNil{}}}}} WCon{b0,WCon{b1,WCon{b2,WCon{b3,WNil{}}}}}:
      Bool.not(Bool.xor(a0,b0)) && Bool.not(Bool.xor(a1,b1)) &&
      Bool.not(Bool.xor(a2,b2)) && Bool.not(Bool.xor(a3,b3))
def zero() -> Word(4n): WCon{False{},WCon{False{},WCon{False{},WCon{False{},WNil{}}}}}
def ones() -> Word(4n): WCon{True{},WCon{True{},WCon{True{},WCon{True{},WNil{}}}}}
def expr_same(a: M.Expr, b: M.Expr) -> Bool:
  match a b:
    case M.Input{} M.Input{}: True{}
    case M.Constant{x} M.Constant{y}: word_same(x,y)
    case M.Not{x} M.Not{y}: expr_same(x,y)
    case M.And{a,b} M.And{c,d}: expr_same(a,c) && expr_same(b,d)
    case M.Or{a,b} M.Or{c,d}: expr_same(a,c) && expr_same(b,d)
    case M.Xor{a,b} M.Xor{c,d}: expr_same(a,c) && expr_same(b,d)
    case _ _: False{}
def zero_constant(e: M.Expr) -> Bool:
  match e:
    case M.Constant{b}: word_same(b,zero())
    case _: False{}
def ones_constant(e: M.Expr) -> Bool:
  match e:
    case M.Constant{b}: word_same(b,ones())
    case _: False{}
def zero_form(e: M.Expr) -> Bool:
  match e:
    case M.Xor{a,b}: expr_same(a,b)
    case M.And{a,b}: zero_constant(a) || zero_constant(b)
    case _: False{}
def ones_form(e: M.Expr) -> Bool:
  match e:
    case M.Or{a,b}: ones_constant(a) || ones_constant(b)
    case M.Not{a}: zero_constant(a)
    case _: False{}
def select(z: Bool, o: Bool) -> P.Priority:
  match z o:
    case True{} _: P.SeedZero{}
    case False{} True{}: P.SeedOnes{}
    case False{} False{}: P.Original{}
def priority(p: P.Policy, +reference: M.Expr) -> P.Priority:
  P.Policy{z,o,order} = p
  select(z && zero_form(reference),o && ones_form(reference))
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
def propose_order(+p: P.Policy, task: M.Expr, index: Nat, m: P.Order) -> Maybe<&2,P.Policy>:
  match index m:
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
def propose(+p: P.Policy, task: M.Expr, index: Nat) -> Maybe<&2,P.Policy>:
  P.Policy{z,o,m} = p
  propose_order(p,task,index,m)

def no_worse(a: +List<Nat>,b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x,xs} Con{y,ys}: Nat.is_le(x,y) && no_worse(xs,ys)
    case _ _: False{}
def better(a: +List<Nat>,b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: False{}
    case Con{x,xs} Con{y,ys}: Nat.is_lt(x,y) || better(xs,ys)
    case _ _: False{}
def equal_costs(a: +List<Nat>,b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x,xs} Con{y,ys}: Nat.is_eq(x,y) && equal_costs(xs,ys)
    case _ _: False{}
def improves(+a: +List<Nat>,+b: +List<Nat>) -> Bool:
  no_worse(a,b) && better(a,b)
def learns(ac: +List<Nat>,bc: +List<Nat>,+aw: +List<Nat>,+bw: +List<Nat>) -> Bool:
  equal_costs(ac,bc) && no_worse(aw,bw) && better(aw,bw)

def same_knowledge(a: P.Policy,b: P.Policy) -> Bool:
  P.Policy{az,ao,am} = a
  P.Policy{bz,bo,bm} = b
  Bool.not(Bool.xor(az,bz)) && Bool.not(Bool.xor(ao,bo))
