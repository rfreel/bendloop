import Base
import ./runtime.bend as S
import ./grammar.bend as G
import ../interpreter/runtime.bend as R
import ../certificates/runtime.bend as C

def tokens(expr: R.Expr) -> String:
  match expr:
    case R.Input{}: "0"
    case R.Constant{value}: U32.show((R.number(value) + 1 : U32))
    case R.Not{arg}: "17," ++ tokens(arg)
    case R.And{lhs,rhs}: "18," ++ tokens(lhs) ++ "," ++ tokens(rhs)
    case R.Or{lhs,rhs}: "19," ++ tokens(lhs) ++ "," ++ tokens(rhs)
    case R.Xor{lhs,rhs}: "20," ++ tokens(lhs) ++ "," ++ tokens(rhs)

def op_part(enabled: Bool, token: String, prior: String) -> String:
  match enabled:
    case False{}: prior
    case True{}: prior ++ token ++ ","

# Encode the subset by the sixteen concrete flag cases, with no trailing comma.
def ops(value: G.Ops) -> String:
  match value:
    case G.Ops{False{},False{},False{},False{}}: "[]"
    case G.Ops{False{},False{},False{},True{}}: "[20]"
    case G.Ops{False{},False{},True{},False{}}: "[19]"
    case G.Ops{False{},False{},True{},True{}}: "[19,20]"
    case G.Ops{False{},True{},False{},False{}}: "[18]"
    case G.Ops{False{},True{},False{},True{}}: "[18,20]"
    case G.Ops{False{},True{},True{},False{}}: "[18,19]"
    case G.Ops{False{},True{},True{},True{}}: "[18,19,20]"
    case G.Ops{True{},False{},False{},False{}}: "[17]"
    case G.Ops{True{},False{},False{},True{}}: "[17,20]"
    case G.Ops{True{},False{},True{},False{}}: "[17,19]"
    case G.Ops{True{},False{},True{},True{}}: "[17,19,20]"
    case G.Ops{True{},True{},False{},False{}}: "[17,18]"
    case G.Ops{True{},True{},False{},True{}}: "[17,18,20]"
    case G.Ops{True{},True{},True{},False{}}: "[17,18,19]"
    case G.Ops{True{},True{},True{},True{}}: "[17,18,19,20]"

def outputs(+expr: R.Expr) -> String:
  "[" ++ U32.show(R.number(R.eval(expr,C.input_0()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_1()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_2()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_3()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_4()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_5()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_6()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_7()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_8()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_9()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_10()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_11()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_12()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_13()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_14()))) ++ "," ++ U32.show(R.number(R.eval(expr,C.input_15()))) ++ "]"

def best(+reference: R.Expr, value: S.Best<reference>) -> String:
  match value:
    case S.NoBest{}: "null"
    case S.HaveBest{+candidate,certificate}:
      "{\"candidate\":[" ++ tokens(candidate) ++ "],\"cost\":" ++ Nat.show(R.cost(candidate)) ++
      ",\"nodes\":" ++ Nat.show(R.size(candidate)) ++ ",\"certificate\":{\"schema\":\"bendloop-synth4-v1\",\"reference\":[" ++ tokens(reference) ++
      "],\"candidate\":[" ++ tokens(candidate) ++ "],\"candidate_cost\":" ++ Nat.show(R.cost(candidate)) ++
      ",\"outputs\":" ++ outputs(candidate) ++ "}}"

def fuel_status(left: Nat) -> String:
  match left:
    case 0n: "BudgetExhausted"
    case 1n+p: "Paused"

def status(next: Maybe<&2,G.Code>, left: Nat) -> String:
  match next:
    case None{}: "SpaceExhausted"
    case Some{value}: fuel_status(left)

def state(value: S.State) -> String:
  match value:
    case S.State{+reference,+allowed,+bound,cap,+spent,+left,incumbent}:
      "{\"schema\":\"bendloop-synth4-v1\",\"reference\":[" ++ tokens(reference) ++ "],\"allowed_ops\":" ++ ops(allowed) ++
      ",\"max_nodes\":" ++ Nat.show(G.nodes(bound)) ++ ",\"cap\":" ++ Nat.show(cap) ++ ",\"spent\":" ++ Nat.show(spent) ++
      ",\"left\":" ++ Nat.show(left) ++ ",\"cursor\":" ++ Nat.show(spent) ++ ",\"status\":\"" ++ status(G.at(bound,allowed,U32.from_nat(spent)),left) ++
      "\",\"best\":" ++ best(reference,incumbent) ++ "}"

def result(value: Result<&2,&1,String,S.State>) -> String:
  match value:
    case Fail{error}: "{\"status\":\"InternalError\"}"
    case Done{value}: state(value)
