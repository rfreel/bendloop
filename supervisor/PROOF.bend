import Base
import ./LAWS.bend as L
import ./runtime.bend as S
import ./task.bend as T
import ../synthesis/interpreter/runtime.bend as R
import ../synthesis/certificates/runtime.bend as C
import ../synthesis/certificates/equality.bend as E
import ../synthesis/replay/runtime.bend as Replay

def incumbent_valid(+c: S.Contract<T.Requirements>,value: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>) -> {L.incumbent_ok(c,value) == True{} : Bool}:
  match value:
    case None{}: {==}
    case Some{S.Qualified{a,p}}: p
def stage_valid(+c: S.Contract<T.Requirements>,value: S.Stage<T.Requirements,R.Expr,T.check,c>) -> {L.stage_ok(c,value) == True{} : Bool}:
  match value:
    case S.Measured{S.Qualified{a,p}}: p
    case S.Idle{}: {==}
    case S.Offered{message}: {==}
    case S.Frozen{a}: {==}
def state_valid(-cap: Nat,state: T.State(cap)) -> L.invariant(cap,state):
  match state:
    case S.State{+c,spent,left,p,mode,stage,inc}: (p,(incumbent_valid(c,inc),stage_valid(c,stage)))
def transition_valid(-cap: Nat,t: T.Transition(cap)) -> L.result_invariant(cap,t):
  match t:
    case S.Transition{s,e}: state_valid(cap,s)
def safe_effect(+c: S.Contract<T.Requirements>,effect: S.Effect<T.Requirements,R.Expr,T.check,c>) -> L.effect_safe(c,effect):
  match effect:
    case S.NoEffect{}: Unit{}
    case S.Failure{}: Unit{}
    case S.Publish{n,a,q,p}: (q,p)
def safe_transition(-cap: Nat,t: T.Transition(cap)) -> L.result_safe(cap,t):
  match t:
    case S.Transition{s,e}: safe_effect(S.current(T.Requirements,R.Expr,T.check,cap,s),e)
def L.initial_invariant(c,cap,fallback): state_valid(cap,T.initial(c,cap,fallback))
def L.step_preserves_invariant(cap,state,event): transition_valid(cap,T.step(cap,state,event))
def L.every_effect_safe(cap,state,event): safe_transition(cap,T.step(cap,state,event))

def certify_sound(+reference: R.Expr,+a: R.Expr,result: C.Check<reference,a>,ok: {T.certified(reference,a,result) == True{} : Bool},+input: R.Bits) -> {R.eval(reference,input) == R.eval(a,input) : R.Bits}:
  match result:
    case C.Equivalent{certificate}: C.sound(reference,a,certificate,input)
    case C.Different{x,refute}: Empty.absurd({R.eval(reference,input) == R.eval(a,input) : R.Bits},E.false_true(ok))
def check_if_sound(+reference: R.Expr,+a: R.Expr,member: Bool,ok: {T.check_if(member,reference,a) == True{} : Bool},+input: R.Bits) -> {R.eval(reference,input) == R.eval(a,input) : R.Bits}:
  match member:
    case False{}: Empty.absurd({R.eval(reference,input) == R.eval(a,input) : R.Bits},E.false_true(ok))
    case True{}: certify_sound(reference,a,C.certify(reference,a),ok,input)
def L.actual_checker_sound(c,a,ok,input): check_if_sound(T.reference(c),a,T.supported(c) && Replay.member(T.request(c),a),ok,input)
def check_if_member(+reference: R.Expr,+a: R.Expr,member: Bool,ok: {T.check_if(member,reference,a) == True{} : Bool}) -> {member == True{} : Bool}:
  match member:
    case True{}: {==}
    case False{}: Empty.absurd({False{} == True{} : Bool},E.false_true(ok))
def right_true(a: Bool,b: Bool,p: {a && b == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}: p
    case False{}: Empty.absurd({b == True{} : Bool},E.false_true(p))
def L.actual_checker_membership(c,a,ok):
  right_true(T.supported(c),Replay.member(T.request(c),a),check_if_member(T.reference(c),a,T.supported(c) && Replay.member(T.request(c),a),ok))
def selected_if(+c: S.Contract<T.Requirements>,+a: R.Expr,+b: R.Expr,pa: {T.check(c,a) == True{} : Bool},pb: {T.check(c,b) == True{} : Bool},less: Bool) ->
  {L.selected(c,Some{S.select_if(T.Requirements,R.Expr,T.check,c,S.Qualified{a,pa},S.Qualified{b,pb},less)}) == Some{L.preferred(a,b,less)} : Maybe<&2,R.Expr>}:
  match less:
    case True{}: {==}
    case False{}: {==}
def L.selection_rule(c,a,b,pa,pb): selected_if(c,a,b,pa,pb,Nat.is_lt(R.cost(a),R.cost(b)))
def L.empty_incumbent_accepts_qualified(c,a,pa): {==}
def L.qualified_positive_control(): {==}
def L.zero_budget_revocation(): {==}
def L.qualified_fallback_publishes(): {==}
def L.denied_fallback_never_publishes(): {==}
def finish_permission_contract(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>,
  permit: S.Permission,eq: {S.permission(T.Requirements,c) == permit : S.Permission}) ->
  {L.result_contract(cap,S.finish_permission(T.Requirements,R.Expr,T.check,cap,c,spent,left,p,inc,permit,eq)) == c : S.Contract<T.Requirements>}:
  match inc permit:
    case None{} S.Denied{}: {==}
    case None{} S.PublishResult{}: {==}
    case Some{S.Qualified{a,q}} S.Denied{}: {==}
    case Some{S.Qualified{a,q}} S.PublishResult{}: {==}
def finish_contract(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>) ->
  {L.result_contract(cap,S.finish(T.Requirements,R.Expr,T.check,cap,c,spent,left,p,inc)) == c : S.Contract<T.Requirements>}:
  finish_permission_contract(cap,c,spent,left,p,inc,S.permission(T.Requirements,c),{==})
def L.ingress_cannot_change_contract(cap,c,spent,left,p,mode,stage,inc,message):
  match left mode:
    case 0n S.Finished{}: {==}
    case 0n S.Running{}: finish_contract(cap,c,spent,0n,p,inc)
    case 0n S.Crashed{}: finish_contract(cap,c,spent,0n,p,inc)
    case 1n+rest S.Finished{}: {==}
    case 1n+rest S.Running{}: {==}
    case 1n+rest S.Crashed{}: {==}
def correct_transition(-cap: Nat,t: T.Transition(cap),+input: R.Bits) -> L.result_correct(cap,t,input):
  match t:
    case S.Transition{s,e}:
      match e:
        case S.NoEffect{}: Unit{}
        case S.Failure{}: Unit{}
        case S.Publish{n,+a,q,p}: L.actual_checker_sound(S.current(T.Requirements,R.Expr,T.check,cap,s),a,q,input)
def member_transition(-cap: Nat,t: T.Transition(cap)) -> L.result_member(cap,t):
  match t:
    case S.Transition{s,e}:
      match e:
        case S.NoEffect{}: Unit{}
        case S.Failure{}: Unit{}
        case S.Publish{n,+a,q,p}: L.actual_checker_membership(S.current(T.Requirements,R.Expr,T.check,cap,s),a,q)
def L.every_publication_correct(cap,state,event,input): correct_transition(cap,T.step(cap,state,event),input)
def L.every_publication_member(cap,state,event): member_transition(cap,T.step(cap,state,event))
def L.untrusted_claims_do_not_qualify(c,task,epoch,artifact,first,second): {==}
def L.frozen_candidate_cannot_be_overwritten(c,artifact,message):
  match message:
    case S.Proposal{t,e,a,claims}: {==}
def L.closed_ingress_inert(cap,c,spent,left,p,stage,inc,message):
  match left:
    case 0n: {==}
    case 1n+rest: {==}
def finish_permission_mode(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>,
  permit: S.Permission,eq: {S.permission(T.Requirements,c) == permit : S.Permission}) ->
  {L.result_mode(cap,S.finish_permission(T.Requirements,R.Expr,T.check,cap,c,spent,left,p,inc,permit,eq)) == S.Finished{} : S.Mode}:
  match inc permit:
    case None{} S.Denied{}: {==}
    case None{} S.PublishResult{}: {==}
    case Some{S.Qualified{a,q}} S.Denied{}: {==}
    case Some{S.Qualified{a,q}} S.PublishResult{}: {==}
def finish_mode(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Expr,T.check,c>>) ->
  {L.result_mode(cap,S.finish(T.Requirements,R.Expr,T.check,cap,c,spent,left,p,inc)) == S.Finished{} : S.Mode}:
  finish_permission_mode(cap,c,spent,left,p,inc,S.permission(T.Requirements,c),{==})
def L.expiry_finishes(cap,state):
  match state:
    case S.State{c,spent,left,p,S.Finished{},stage,inc}: {==}
    case S.State{+c,+spent,0n,p,S.Running{},stage,inc}: finish_mode(cap,c,spent,0n,p,inc)
    case S.State{+c,+spent,0n,p,S.Crashed{},stage,inc}: finish_mode(cap,c,spent,0n,p,inc)
    case S.State{+c,+spent,1n+remaining,p,S.Running{},stage,inc}:
      +left = remaining
      finish_mode(cap,c,1n+spent,left,S.charged(spent,left,cap,p),inc)
    case S.State{+c,+spent,1n+remaining,p,S.Crashed{},stage,inc}:
      +left = remaining
      finish_mode(cap,c,1n+spent,left,S.charged(spent,left,cap,p),inc)
def L.actual_admission_positive_control(): {==}
def L.running_ingress_charged_once(cap,c,spent,left,p,stage,inc,message): {==}
def L.running_ingress_decrements_allowance(cap,c,spent,left,p,stage,inc,message): {==}
def L.crashed_ingress_decrements_allowance(cap,c,spent,left,p,stage,inc,message): {==}
def left_true(a: Bool,b: Bool,p: {a && b == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}: {==}
    case False{}: Empty.absurd({False{} == True{} : Bool},E.false_true(p))
def supported_identity(+c: S.Contract<T.Requirements>) -> {T.supported(c) == Nat.is_eq(L.evaluator_id(c),1n) : Bool}:
  match c:
    case S.Contract{task,epoch,evaluator,permission,requirements}: {==}
def L.actual_checker_namespace(c,a,ok):
  %supported_identity(c) : {_ == True{} : Bool}
  left_true(T.supported(c),Replay.member(T.request(c),a),check_if_member(T.reference(c),a,T.supported(c) && Replay.member(T.request(c),a),ok))
