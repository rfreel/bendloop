import Base
import ./runtime.bend as S
import ../synthesis/interpreter/runtime.bend as R
import ../synthesis/search/grammar.bend as G
import ../synthesis/certificates/runtime.bend as C
import ../synthesis/replay/runtime.bend as Replay

type Requirements is Data:
  Requirements{reference: R.Expr,ops: G.Ops,bound: G.Bound}
def request(c: S.Contract<Requirements>) -> Replay.Request:
  S.Contract{task,epoch,evaluator,permission,Requirements{reference,ops,bound}} = c
  Replay.Request{reference,ops,bound}
def reference(c: S.Contract<Requirements>) -> R.Expr:
  S.Contract{task,epoch,evaluator,permission,Requirements{reference,ops,bound}} = c
  reference
def certified(-reference: R.Expr,-candidate: R.Expr,result: C.Check<reference,candidate>) -> Bool:
  match result:
    case C.Different{input,refute}: False{}
    case C.Equivalent{certificate}: True{}
def check_if(ok: Bool,+reference: R.Expr,+a: R.Expr) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: certified(reference,a,C.certify(reference,a))
def supported(c: S.Contract<Requirements>) -> Bool:
  S.Contract{task,epoch,evaluator,permission,requirements} = c
  Nat.is_eq(evaluator,1n)
def check(c0: S.Contract<Requirements>,a0: R.Expr) -> Bool:
  +c = c0
  +a = a0
  check_if(supported(c) && Replay.member(request(c),a),reference(c),a)
def score(c: S.Contract<Requirements>,a: R.Expr) -> Nat: R.cost(a)
def State(-cap: Nat) -> Type: S.State<Requirements,R.Expr,check,cap>
def Transition(-cap: Nat) -> Type: S.Transition<Requirements,R.Expr,check,cap>
def initial(+c: S.Contract<Requirements>,+cap: Nat,fallback: R.Expr) -> State(cap):
  S.seed(Requirements,R.Expr,check,c,cap,fallback)
def step(-cap: Nat,state: State(cap),action: S.Action<Requirements,R.Expr>) -> Transition(cap):
  S.step(Requirements,R.Expr,check,score,cap,state,action)
