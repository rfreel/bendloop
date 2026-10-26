import Base
import ../runtime.bend as S
import ./model.bend as M

type Requirements is Data:
  Requirements{reference: M.Rows}
def reference(c: S.Contract<Requirements>) -> M.Rows:
  S.Contract{task,epoch,evaluator,permission,Requirements{rows}} = c
  rows
def supported(c: S.Contract<Requirements>) -> Bool:
  S.Contract{task,epoch,evaluator,permission,requirements} = c
  Nat.is_eq(evaluator,2n)
def check(c0: S.Contract<Requirements>,a0: M.Rows) -> Bool:
  +c = c0
  +a = a0
  supported(c) && M.ordered(a) && M.preserved(reference(c),a)
def score(c: S.Contract<Requirements>,a: M.Rows) -> Nat: M.quality(a)
def State(-cap: Nat) -> Type: S.State<Requirements,M.Rows,check,cap>
def Transition(-cap: Nat) -> Type: S.Transition<Requirements,M.Rows,check,cap>
def initial(+c: S.Contract<Requirements>,+cap: Nat,fallback: M.Rows) -> State(cap):
  S.seed(Requirements,M.Rows,check,c,cap,fallback)
def step(-cap: Nat,state: State(cap),action: S.Action<Requirements,M.Rows>) -> Transition(cap):
  S.step(Requirements,M.Rows,check,score,cap,state,action)
