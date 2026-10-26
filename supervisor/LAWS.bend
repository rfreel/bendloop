import Base
import ./runtime.bend as S
import ./task.bend as T
import ../synthesis/interpreter/runtime.bend as R
import ../synthesis/certificates/runtime.bend as C
import ../synthesis/replay/runtime.bend as Replay
import ../synthesis/search/grammar.bend as G

def incumbent_ok(c: S.Contract<T.Requirements>,value: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>) -> Bool:
  match value:
    case None{}: True{}
    case Some{S.Qualified{a,p}}: T.check(c,a)
def stage_ok(c: S.Contract<T.Requirements>,value: S.Stage<T.Requirements,R.Expr,T.check,c>) -> Bool:
  match value:
    case S.Measured{S.Qualified{a,p}}: T.check(c,a)
    case _: True{}
def invariant(-cap: Nat,state: T.State(cap)) -> Type:
  S.State{+c,spent,left,p,mode,stage,inc} = state
  {Nat.add(spent,left) == cap : Nat} & ({incumbent_ok(c,inc) == True{} : Bool} & {stage_ok(c,stage) == True{} : Bool})
def next_state(-cap: Nat,t: T.Transition(cap)) -> T.State(cap):
  S.Transition{s,e} = t
  s
def result_invariant(-cap: Nat,t: T.Transition(cap)) -> Type:
  invariant(cap,next_state(cap,t))
def effect_safe(c: S.Contract<T.Requirements>,e: S.Effect<T.Requirements,R.Expr,T.check,c>) -> Type:
  match e:
    case S.NoEffect{}: Unit
    case S.Failure{}: Unit
    case S.Publish{n,a,q,p}: {T.check(c,a) == True{} : Bool} & {S.permission(T.Requirements,c) == S.PublishResult{} : S.Permission}
def result_safe(-cap: Nat,t: T.Transition(cap)) -> Type:
  match t:
    case S.Transition{s,e}: effect_safe(S.current(T.Requirements,R.Expr,T.check,cap,s),e)
def result_contract(-cap: Nat,t: T.Transition(cap)) -> S.Contract<T.Requirements>:
  S.Transition{s,e} = t
  S.current(T.Requirements,R.Expr,T.check,cap,s)
def candidate(c: S.Contract<T.Requirements>,q: S.Qualified<T.Requirements,R.Expr,T.check,c>) -> R.Expr:
  S.Qualified{a,p} = q
  a
def selected(c: S.Contract<T.Requirements>,q: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>) -> Maybe<&2,R.Expr>:
  match q:
    case None{}: None{}
    case Some{S.Qualified{a,p}}: Some{a}
def preferred(+a: R.Expr,+b: R.Expr,less: Bool) -> R.Expr:
  match less:
    case False{}: b
    case True{}: a

law initial_invariant:
  for +c: S.Contract<T.Requirements>
  for +cap: Nat
  for fallback: R.Expr
  invariant(cap,T.initial(c,cap,fallback))
law step_preserves_invariant:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Expr>
  result_invariant(cap,T.step(cap,state,event))
law every_effect_safe:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Expr>
  result_safe(cap,T.step(cap,state,event))
law actual_checker_sound:
  for +c: S.Contract<T.Requirements>
  for +a: R.Expr
  for ok: {T.check(c,a) == True{} : Bool}
  for input: R.Bits
  {R.eval(T.reference(c),input) == R.eval(a,input) : R.Bits}
law actual_checker_membership:
  for +c: S.Contract<T.Requirements>
  for +a: R.Expr
  for ok: {T.check(c,a) == True{} : Bool}
  {Replay.member(T.request(c),a) == True{} : Bool}
law selection_rule:
  for +c: S.Contract<T.Requirements>
  for +a: R.Expr
  for +b: R.Expr
  for pa: {T.check(c,a) == True{} : Bool}
  for pb: {T.check(c,b) == True{} : Bool}
  {selected(c,S.select(T.Requirements,R.Expr,T.check,T.score,c,S.Qualified{a,pa},Some{S.Qualified{b,pb}})) ==
   Some{preferred(a,b,Nat.is_lt(R.cost(a),R.cost(b)))} : Maybe<&2,R.Expr>}
law empty_incumbent_accepts_qualified:
  for +c: S.Contract<T.Requirements>
  for +a: R.Expr
  for pa: {T.check(c,a) == True{} : Bool}
  {selected(c,S.select(T.Requirements,R.Expr,T.check,T.score,c,S.Qualified{a,pa},None{})) == Some{a} : Maybe<&2,R.Expr>}
law ingress_cannot_change_contract:
  for +cap: Nat
  for +c: S.Contract<T.Requirements>
  for spent: Nat
  for left: Nat
  for p: {Nat.add(spent,left) == cap : Nat}
  for mode: S.Mode
  for stage: S.Stage<T.Requirements,R.Expr,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>
  for message: S.Worker<R.Expr>
  {result_contract(cap,T.step(cap,S.State{c,spent,left,p,mode,stage,inc},S.Ingress{message})) == c : S.Contract<T.Requirements>}

def zero() -> R.Expr: R.Constant{C.input_0()}
def witness_contract(epoch: Nat,permit: S.Permission) -> S.Contract<T.Requirements>:
  S.Contract{1n,epoch,1n,permit,T.Requirements{R.Xor{R.Input{},R.Input{}},G.Ops{True{},True{},True{},True{}},G.N3{}}}
def final_artifact(-cap: Nat,t: T.Transition(cap)) -> Maybe<&2,R.Expr>:
  S.Transition{s,e} = t
  match e:
    case S.Publish{n,a,p,q}: Some{a}
    case _: None{}
law qualified_positive_control:
  {T.check(witness_contract(0n,S.PublishResult{}),zero()) == True{} : Bool}
law zero_budget_revocation:
  {result_contract(0n,T.step(0n,T.initial(witness_contract(0n,S.PublishResult{}),0n,zero()),
    S.Replace{witness_contract(1n,S.Denied{}),zero()})) == witness_contract(1n,S.Denied{}) : S.Contract<T.Requirements>}
law qualified_fallback_publishes:
  {final_artifact(0n,T.step(0n,T.initial(witness_contract(0n,S.PublishResult{}),0n,zero()),S.Commit{})) == Some{zero()} : Maybe<&2,R.Expr>}
law denied_fallback_never_publishes:
  {final_artifact(0n,T.step(0n,T.initial(witness_contract(0n,S.Denied{}),0n,zero()),S.Commit{})) == None{} : Maybe<&2,R.Expr>}
def result_correct(-cap: Nat,t: T.Transition(cap),+input: R.Bits) -> Type:
  S.Transition{s,e} = t
  match e:
    case S.NoEffect{}: Unit
    case S.Failure{}: Unit
    case S.Publish{n,a,q,p}: {R.eval(T.reference(S.current(T.Requirements,R.Expr,T.check,cap,s)),input) == R.eval(a,input) : R.Bits}
def result_member(-cap: Nat,t: T.Transition(cap)) -> Type:
  S.Transition{s,e} = t
  match e:
    case S.NoEffect{}: Unit
    case S.Failure{}: Unit
    case S.Publish{n,a,q,p}: {Replay.member(T.request(S.current(T.Requirements,R.Expr,T.check,cap,s)),a) == True{} : Bool}
def result_mode(-cap: Nat,t: T.Transition(cap)) -> S.Mode:
  S.Transition{S.State{c,spent,left,p,mode,stage,inc},e} = t
  mode
law every_publication_correct:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Expr>
  for input: R.Bits
  result_correct(cap,T.step(cap,state,event),input)
law every_publication_member:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Expr>
  result_member(cap,T.step(cap,state,event))
law untrusted_claims_do_not_qualify:
  for +c: S.Contract<T.Requirements>
  for +task: Nat
  for +epoch: Nat
  for +artifact: R.Expr
  for first: String
  for second: String
  {S.freeze_message(T.Requirements,R.Expr,T.check,c,S.Proposal{task,epoch,artifact,first}) ==
   S.freeze_message(T.Requirements,R.Expr,T.check,c,S.Proposal{task,epoch,artifact,second}) : S.Stage<T.Requirements,R.Expr,T.check,c>}
law frozen_candidate_cannot_be_overwritten:
  for +c: S.Contract<T.Requirements>
  for +artifact: R.Expr
  for message: S.Worker<R.Expr>
  {S.receive(T.Requirements,R.Expr,T.check,c,S.Frozen{artifact},message) == S.Frozen{artifact} : S.Stage<T.Requirements,R.Expr,T.check,c>}
law closed_ingress_inert:
  for +cap: Nat
  for +c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for +p: {Nat.add(spent,left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Expr,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>
  for message: S.Worker<R.Expr>
  {T.step(cap,S.State{c,spent,left,p,S.Finished{},stage,inc},S.Ingress{message}) ==
   S.Transition{S.State{c,spent,left,p,S.Finished{},stage,inc},S.NoEffect{}} : T.Transition(cap)}
law expiry_finishes:
  for +cap: Nat
  for state: T.State(cap)
  {result_mode(cap,T.step(cap,state,S.Expire{})) == S.Finished{} : S.Mode}
def five_steps(-cap: Nat,state: T.State(cap),message: S.Worker<R.Expr>) -> T.Transition(cap):
  s1 = next_state(cap,T.step(cap,state,S.Ingress{message}))
  s2 = next_state(cap,T.step(cap,s1,S.Freeze{}))
  s3 = next_state(cap,T.step(cap,s2,S.Evaluate{}))
  s4 = next_state(cap,T.step(cap,s3,S.Compare{}))
  T.step(cap,s4,S.Commit{})
law actual_admission_positive_control:
  {final_artifact(5n,five_steps(5n,T.initial(witness_contract(0n,S.PublishResult{}),5n,R.Xor{R.Input{},R.Input{}}),
    S.Proposal{1n,0n,zero(),"untrusted fabricated review"})) == Some{zero()} : Maybe<&2,R.Expr>}
def result_spent(-cap: Nat,t: T.Transition(cap)) -> Nat:
  S.Transition{S.State{c,spent,left,p,mode,stage,inc},e} = t
  spent
def result_left(-cap: Nat,t: T.Transition(cap)) -> Nat:
  S.Transition{S.State{c,spent,left,p,mode,stage,inc},e} = t
  left
law running_ingress_charged_once:
  for +cap: Nat
  for c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for p: {Nat.add(spent,1n+left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Expr,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>
  for message: S.Worker<R.Expr>
  {result_spent(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Running{},stage,inc},S.Ingress{message})) == 1n+spent : Nat}
law running_ingress_decrements_allowance:
  for +cap: Nat
  for c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for p: {Nat.add(spent,1n+left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Expr,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>
  for message: S.Worker<R.Expr>
  {result_left(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Running{},stage,inc},S.Ingress{message})) == left : Nat}
law crashed_ingress_decrements_allowance:
  for +cap: Nat
  for c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for p: {Nat.add(spent,1n+left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Expr,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>
  for message: S.Worker<R.Expr>
  {result_left(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Crashed{},stage,inc},S.Ingress{message})) == left : Nat}
def evaluator_id(c: S.Contract<T.Requirements>) -> Nat:
  S.Contract{task,epoch,evaluator,permission,requirements} = c
  evaluator
law actual_checker_namespace:
  for +c: S.Contract<T.Requirements>
  for +a: R.Expr
  for ok: {T.check(c,a) == True{} : Bool}
  {Nat.is_eq(evaluator_id(c),1n) == True{} : Bool}
