import Base
import ../runtime.bend as S
import ./task.bend as T
import ./model.bend as R

import ./LAWS.bend as L
import ./spec.bend as Spec
import ../../synthesis/certificates/equality.bend as E

def incumbent_valid(+c: S.Contract<T.Requirements>,value: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>) -> {L.incumbent_ok(c,value) == True{} : Bool}:
  match value:
    case None{}: {==}
    case Some{S.Qualified{a,p}}: p
def stage_valid(+c: S.Contract<T.Requirements>,value: S.Stage<T.Requirements,R.Rows,T.check,c>) -> {L.stage_ok(c,value) == True{} : Bool}:
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
def safe_effect(+c: S.Contract<T.Requirements>,effect: S.Effect<T.Requirements,R.Rows,T.check,c>) -> L.effect_safe(c,effect):
  match effect:
    case S.NoEffect{}: Unit{}
    case S.Failure{}: Unit{}
    case S.Publish{n,a,q,p}: (q,p)
def safe_transition(-cap: Nat,t: T.Transition(cap)) -> L.result_safe(cap,t):
  match t:
    case S.Transition{s,e}: safe_effect(S.current(T.Requirements,R.Rows,T.check,cap,s),e)
def L.initial_invariant(c,cap,fallback): state_valid(cap,T.initial(c,cap,fallback))
def L.step_preserves_invariant(cap,state,event): transition_valid(cap,T.step(cap,state,event))
def L.every_effect_safe(cap,state,event): safe_transition(cap,T.step(cap,state,event))

def selected_if(+c: S.Contract<T.Requirements>,+a: R.Rows,+b: R.Rows,pa: {T.check(c,a) == True{} : Bool},pb: {T.check(c,b) == True{} : Bool},less: Bool) ->
  {L.selected(c,Some{S.select_if(T.Requirements,R.Rows,T.check,c,S.Qualified{a,pa},S.Qualified{b,pb},less)}) == Some{L.preferred(a,b,less)} : Maybe<&2,R.Rows>}:
  match less:
    case True{}: {==}
    case False{}: {==}
def L.selection_rule(c,a,b,pa,pb): selected_if(c,a,b,pa,pb,Nat.is_lt(R.quality(a),R.quality(b)))
def L.empty_incumbent_accepts_qualified(c,a,pa): {==}
def finish_permission_contract(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>,
  permit: S.Permission,eq: {S.permission(T.Requirements,c) == permit : S.Permission}) ->
  {L.result_contract(cap,S.finish_permission(T.Requirements,R.Rows,T.check,cap,c,spent,left,p,inc,permit,eq)) == c : S.Contract<T.Requirements>}:
  match inc permit:
    case None{} S.Denied{}: {==}
    case None{} S.PublishResult{}: {==}
    case Some{S.Qualified{a,q}} S.Denied{}: {==}
    case Some{S.Qualified{a,q}} S.PublishResult{}: {==}
def finish_contract(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>) ->
  {L.result_contract(cap,S.finish(T.Requirements,R.Rows,T.check,cap,c,spent,left,p,inc)) == c : S.Contract<T.Requirements>}:
  finish_permission_contract(cap,c,spent,left,p,inc,S.permission(T.Requirements,c),{==})
def L.ingress_cannot_change_contract(cap,c,spent,left,p,mode,stage,inc,message):
  match left mode:
    case 0n S.Finished{}: {==}
    case 0n S.Running{}: finish_contract(cap,c,spent,0n,p,inc)
    case 0n S.Crashed{}: finish_contract(cap,c,spent,0n,p,inc)
    case 1n+rest S.Finished{}: {==}
    case 1n+rest S.Running{}: {==}
    case 1n+rest S.Crashed{}: {==}
def L.untrusted_claims_do_not_qualify(c,task,epoch,artifact,first,second): {==}
def L.frozen_candidate_cannot_be_overwritten(c,artifact,message):
  match message:
    case S.Proposal{t,e,a,claims}: {==}
def L.closed_ingress_inert(cap,c,spent,left,p,stage,inc,message):
  match left:
    case 0n: {==}
    case 1n+rest: {==}
def finish_permission_mode(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>,
  permit: S.Permission,eq: {S.permission(T.Requirements,c) == permit : S.Permission}) ->
  {L.result_mode(cap,S.finish_permission(T.Requirements,R.Rows,T.check,cap,c,spent,left,p,inc,permit,eq)) == S.Finished{} : S.Mode}:
  match inc permit:
    case None{} S.Denied{}: {==}
    case None{} S.PublishResult{}: {==}
    case Some{S.Qualified{a,q}} S.Denied{}: {==}
    case Some{S.Qualified{a,q}} S.PublishResult{}: {==}
def finish_mode(-cap: Nat,+c: S.Contract<T.Requirements>,+spent: Nat,+left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>) ->
  {L.result_mode(cap,S.finish(T.Requirements,R.Rows,T.check,cap,c,spent,left,p,inc)) == S.Finished{} : S.Mode}:
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
def L.running_ingress_charged_once(cap,c,spent,left,p,stage,inc,message): {==}
def L.running_ingress_decrements_allowance(cap,c,spent,left,p,stage,inc,message): {==}
def L.crashed_ingress_decrements_allowance(cap,c,spent,left,p,stage,inc,message): {==}
def right_true(a: Bool,b: Bool,p: {a && b == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}: p
    case False{}: Empty.absurd({b == True{} : Bool},E.false_true(p))
def left_true(a: Bool,b: Bool,p: {a && b == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}: {==}
    case False{}: Empty.absurd({False{} == True{} : Bool},E.false_true(p))
def L.checker_ordered(c,a,ok): right_true(T.supported(c),R.ordered(a),left_true(T.supported(c) && R.ordered(a),R.preserved(T.reference(c),a),ok))
def L.checker_preserved(c,a,ok): right_true(T.supported(c) && R.ordered(a),R.preserved(T.reference(c),a),ok)
def supported_identity(+c: S.Contract<T.Requirements>) -> {T.supported(c) == Nat.is_eq(L.evaluator_id(c),2n) : Bool}:
  match c:
    case S.Contract{task,epoch,evaluator,permission,requirements}: {==}
def L.checker_namespace(c,a,ok):
  %supported_identity(c) : {_ == True{} : Bool}
  left_true(T.supported(c),R.ordered(a),left_true(T.supported(c) && R.ordered(a),R.preserved(T.reference(c),a),ok))
def mandatory_true(supported: Bool,ordered: Bool,preserved: Bool,ok: {supported && ordered && preserved == True{} : Bool}) -> {ordered && preserved == True{} : Bool}:
  match supported:
    case True{}: ok
    case False{}: Empty.absurd({ordered && preserved == True{} : Bool},E.false_true(ok))
def correct_transition(-cap: Nat,t: T.Transition(cap)) -> L.result_correct(cap,t):
  match t:
    case S.Transition{S.State{+c,spent,left,conserved,mode,stage,inc},e}:
      match e:
        case S.NoEffect{}: Unit{}
        case S.Failure{}: Unit{}
        case S.Publish{n,+a,q,p}: mandatory_true(T.supported(c),R.ordered(a),R.preserved(T.reference(c),a),q)
def L.every_publication_sorted_and_preserved(cap,state,event): correct_transition(cap,T.step(cap,state,event))
def L.duplicate_preserving_positive(): {==}
def L.lost_duplicate_rejected(): {==}
def L.lost_duplicate_count_witness(): ({==},{==})
def L.actual_admission_positive_control(): {==}
def L.zero_budget_revocation(): {==}
def nat_equal_sound(+a: Nat,+b: Nat,ok: {Nat.is_eq(a,b) == True{} : Bool}) -> {a == b : Nat}:
  match a b:
    case 0n 0n: {==}
    case 0n 1n+bp: Empty.absurd({0n == 1n+bp : Nat},E.false_true(ok))
    case 1n+ap 0n: Empty.absurd({1n+ap == 0n : Nat},E.false_true(ok))
    case 1n+ap 1n+bp: Equal.cong(Nat,Nat,n => 1n+n,ap,bp,nat_equal_sound(ap,bp,ok))
def record_assembled(+ad: Nat,+ai: Nat,+av: Nat,+bd: Nat,+bi: Nat,+bv: Nat,
  pd: {ad == bd : Nat},pi: {ai == bi : Nat},pv: {av == bv : Nat}) -> {R.Record{ad,ai,av} == R.Record{bd,bi,bv} : R.Record}:
  %pv : {R.Record{ad,ai,av} == R.Record{bd,bi,_} : R.Record}
  %pi : {R.Record{ad,ai,av} == R.Record{bd,_,av} : R.Record}
  %pd : {R.Record{ad,ai,av} == R.Record{_,ai,av} : R.Record}
  {==}
def L.whole_record_identity_sound(a,b,ok):
  match a b:
    case R.Record{+ad,+ai,+av} R.Record{+bd,+bi,+bv}:
      record_assembled(ad,ai,av,bd,bi,bv,
        nat_equal_sound(ad,bd,left_true(Nat.is_eq(ad,bd),Nat.is_eq(ai,bi),left_true(Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi),Nat.is_eq(av,bv),ok))),
        nat_equal_sound(ai,bi,right_true(Nat.is_eq(ad,bd),Nat.is_eq(ai,bi),left_true(Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi),Nat.is_eq(av,bv),ok))),
        nat_equal_sound(av,bv,right_true(Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi),Nat.is_eq(av,bv),ok)))
def nat_equal_reflexive(+a: Nat) -> {Nat.is_eq(a,a) == True{} : Bool}:
  match a:
    case 0n: {==}
    case 1n+ap: nat_equal_reflexive(ap)
def and_true(+a: Bool,+b: Bool,pa: {a == True{} : Bool},pb: {b == True{} : Bool}) -> {a && b == True{} : Bool}:
  Equal.trans(Bool,a && b,b,True{},Equal.cong(Bool,Bool,x => x && b,a,True{},pa),pb)
def L.whole_record_identity_reflexive(a):
  match a:
    case R.Record{+d,+i,+v}:
      and_true(Nat.is_eq(d,d) && Nat.is_eq(i,i),Nat.is_eq(v,v),
        and_true(Nat.is_eq(d,d),Nat.is_eq(i,i),nat_equal_reflexive(d),nat_equal_reflexive(i)),nat_equal_reflexive(v))
def L.whole_record_identity_complete(a,b,same):
  %same : {R.same(a,_) == True{} : Bool}
  L.whole_record_identity_reflexive(a)
def L.lost_duplicate_diagnostic(): {==}
def L.unsorted_pair_diagnostic(): {==}
def conjunct_0(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a0 == True{} : Bool}:
  left_true(a0,a1,left_true(a0 && a1,a2,left_true(a0 && a1 && a2,a3,left_true(a0 && a1 && a2 && a3,a4,left_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok)))))))
def conjunct_1(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a1 == True{} : Bool}:
  right_true(a0,a1,left_true(a0 && a1,a2,left_true(a0 && a1 && a2,a3,left_true(a0 && a1 && a2 && a3,a4,left_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok)))))))
def conjunct_2(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a2 == True{} : Bool}:
  right_true(a0 && a1,a2,left_true(a0 && a1 && a2,a3,left_true(a0 && a1 && a2 && a3,a4,left_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok))))))
def conjunct_3(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a3 == True{} : Bool}:
  right_true(a0 && a1 && a2,a3,left_true(a0 && a1 && a2 && a3,a4,left_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok)))))
def conjunct_4(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a4 == True{} : Bool}:
  right_true(a0 && a1 && a2 && a3,a4,left_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok))))
def conjunct_5(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a5 == True{} : Bool}:
  right_true(a0 && a1 && a2 && a3 && a4,a5,left_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok)))
def conjunct_6(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a6 == True{} : Bool}:
  right_true(a0 && a1 && a2 && a3 && a4 && a5,a6,left_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok))
def conjunct_7(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool,ok: {a0 && a1 && a2 && a3 && a4 && a5 && a6 && a7 == True{} : Bool}) -> {a7 == True{} : Bool}:
  right_true(a0 && a1 && a2 && a3 && a4 && a5 && a6,a7,ok)
def preserved_counts(+reference: R.Rows,+candidate: R.Rows,slot: R.Slot,ok: {R.preserved(reference,candidate) == True{} : Bool}) ->
  {R.count(reference,R.record_at(reference,slot)) == R.count(candidate,R.record_at(reference,slot)) : Nat}:
  match reference slot:
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot0{}:
      nat_equal_sound(R.count(reference,r0),R.count(candidate,r0),conjunct_0(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot1{}:
      nat_equal_sound(R.count(reference,r1),R.count(candidate,r1),conjunct_1(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot2{}:
      nat_equal_sound(R.count(reference,r2),R.count(candidate,r2),conjunct_2(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot3{}:
      nat_equal_sound(R.count(reference,r3),R.count(candidate,r3),conjunct_3(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot4{}:
      nat_equal_sound(R.count(reference,r4),R.count(candidate,r4),conjunct_4(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot5{}:
      nat_equal_sound(R.count(reference,r5),R.count(candidate,r5),conjunct_5(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot6{}:
      nat_equal_sound(R.count(reference,r6),R.count(candidate,r6),conjunct_6(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} R.Slot7{}:
      nat_equal_sound(R.count(reference,r7),R.count(candidate,r7),conjunct_7(Nat.is_eq(R.count(reference,r0),R.count(candidate,r0)),Nat.is_eq(R.count(reference,r1),R.count(candidate,r1)),Nat.is_eq(R.count(reference,r2),R.count(candidate,r2)),Nat.is_eq(R.count(reference,r3),R.count(candidate,r3)),Nat.is_eq(R.count(reference,r4),R.count(candidate,r4)),Nat.is_eq(R.count(reference,r5),R.count(candidate,r5)),Nat.is_eq(R.count(reference,r6),R.count(candidate,r6)),Nat.is_eq(R.count(reference,r7),R.count(candidate,r7)),ok))
def L.checked_reference_multiplicities(c,a,ok,slot):
  preserved_counts(T.reference(c),a,slot,L.checker_preserved(c,a,ok))
def reverse_conjunction(+a: Bool,+b: Bool,+c: Bool) -> {a && b && c == c && b && a : Bool}:
  match a b c:
    case False{} False{} False{}: {==}
    case False{} False{} True{}: {==}
    case False{} True{} False{}: {==}
    case False{} True{} True{}: {==}
    case True{} False{} False{}: {==}
    case True{} False{} True{}: {==}
    case True{} True{} False{}: {==}
    case True{} True{} True{}: {==}
def matches_refines(+a: R.Record,+b: R.Record) -> {R.same(a,b) == Spec.matches(a,b) : Bool}:
  match a b:
    case R.Record{ad,ai,av} R.Record{bd,bi,bv}: reverse_conjunction(Nat.is_eq(ad,bd),Nat.is_eq(ai,bi),Nat.is_eq(av,bv))
def position_sum(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool,+a7: Bool) -> {Nat.add(R.flag(a0),Nat.add(R.flag(a1),Nat.add(R.flag(a2),Nat.add(R.flag(a3),Nat.add(R.flag(a4),Nat.add(R.flag(a5),Nat.add(R.flag(a6),R.flag(a7)))))))) == Nat.add(Nat.add(Nat.add(Spec.indicator(a0),Spec.indicator(a1)),Nat.add(Spec.indicator(a2),Spec.indicator(a3))),Nat.add(Nat.add(Spec.indicator(a4),Spec.indicator(a5)),Nat.add(Spec.indicator(a6),Spec.indicator(a7)))) : Nat}:
  match a0 a1 a2 a3 a4 a5 a6 a7:
    case False{} False{} False{} False{} False{} False{} False{} False{}: {==}
    case False{} False{} False{} False{} False{} False{} False{} True{}: {==}
    case False{} False{} False{} False{} False{} False{} True{} False{}: {==}
    case False{} False{} False{} False{} False{} False{} True{} True{}: {==}
    case False{} False{} False{} False{} False{} True{} False{} False{}: {==}
    case False{} False{} False{} False{} False{} True{} False{} True{}: {==}
    case False{} False{} False{} False{} False{} True{} True{} False{}: {==}
    case False{} False{} False{} False{} False{} True{} True{} True{}: {==}
    case False{} False{} False{} False{} True{} False{} False{} False{}: {==}
    case False{} False{} False{} False{} True{} False{} False{} True{}: {==}
    case False{} False{} False{} False{} True{} False{} True{} False{}: {==}
    case False{} False{} False{} False{} True{} False{} True{} True{}: {==}
    case False{} False{} False{} False{} True{} True{} False{} False{}: {==}
    case False{} False{} False{} False{} True{} True{} False{} True{}: {==}
    case False{} False{} False{} False{} True{} True{} True{} False{}: {==}
    case False{} False{} False{} False{} True{} True{} True{} True{}: {==}
    case False{} False{} False{} True{} False{} False{} False{} False{}: {==}
    case False{} False{} False{} True{} False{} False{} False{} True{}: {==}
    case False{} False{} False{} True{} False{} False{} True{} False{}: {==}
    case False{} False{} False{} True{} False{} False{} True{} True{}: {==}
    case False{} False{} False{} True{} False{} True{} False{} False{}: {==}
    case False{} False{} False{} True{} False{} True{} False{} True{}: {==}
    case False{} False{} False{} True{} False{} True{} True{} False{}: {==}
    case False{} False{} False{} True{} False{} True{} True{} True{}: {==}
    case False{} False{} False{} True{} True{} False{} False{} False{}: {==}
    case False{} False{} False{} True{} True{} False{} False{} True{}: {==}
    case False{} False{} False{} True{} True{} False{} True{} False{}: {==}
    case False{} False{} False{} True{} True{} False{} True{} True{}: {==}
    case False{} False{} False{} True{} True{} True{} False{} False{}: {==}
    case False{} False{} False{} True{} True{} True{} False{} True{}: {==}
    case False{} False{} False{} True{} True{} True{} True{} False{}: {==}
    case False{} False{} False{} True{} True{} True{} True{} True{}: {==}
    case False{} False{} True{} False{} False{} False{} False{} False{}: {==}
    case False{} False{} True{} False{} False{} False{} False{} True{}: {==}
    case False{} False{} True{} False{} False{} False{} True{} False{}: {==}
    case False{} False{} True{} False{} False{} False{} True{} True{}: {==}
    case False{} False{} True{} False{} False{} True{} False{} False{}: {==}
    case False{} False{} True{} False{} False{} True{} False{} True{}: {==}
    case False{} False{} True{} False{} False{} True{} True{} False{}: {==}
    case False{} False{} True{} False{} False{} True{} True{} True{}: {==}
    case False{} False{} True{} False{} True{} False{} False{} False{}: {==}
    case False{} False{} True{} False{} True{} False{} False{} True{}: {==}
    case False{} False{} True{} False{} True{} False{} True{} False{}: {==}
    case False{} False{} True{} False{} True{} False{} True{} True{}: {==}
    case False{} False{} True{} False{} True{} True{} False{} False{}: {==}
    case False{} False{} True{} False{} True{} True{} False{} True{}: {==}
    case False{} False{} True{} False{} True{} True{} True{} False{}: {==}
    case False{} False{} True{} False{} True{} True{} True{} True{}: {==}
    case False{} False{} True{} True{} False{} False{} False{} False{}: {==}
    case False{} False{} True{} True{} False{} False{} False{} True{}: {==}
    case False{} False{} True{} True{} False{} False{} True{} False{}: {==}
    case False{} False{} True{} True{} False{} False{} True{} True{}: {==}
    case False{} False{} True{} True{} False{} True{} False{} False{}: {==}
    case False{} False{} True{} True{} False{} True{} False{} True{}: {==}
    case False{} False{} True{} True{} False{} True{} True{} False{}: {==}
    case False{} False{} True{} True{} False{} True{} True{} True{}: {==}
    case False{} False{} True{} True{} True{} False{} False{} False{}: {==}
    case False{} False{} True{} True{} True{} False{} False{} True{}: {==}
    case False{} False{} True{} True{} True{} False{} True{} False{}: {==}
    case False{} False{} True{} True{} True{} False{} True{} True{}: {==}
    case False{} False{} True{} True{} True{} True{} False{} False{}: {==}
    case False{} False{} True{} True{} True{} True{} False{} True{}: {==}
    case False{} False{} True{} True{} True{} True{} True{} False{}: {==}
    case False{} False{} True{} True{} True{} True{} True{} True{}: {==}
    case False{} True{} False{} False{} False{} False{} False{} False{}: {==}
    case False{} True{} False{} False{} False{} False{} False{} True{}: {==}
    case False{} True{} False{} False{} False{} False{} True{} False{}: {==}
    case False{} True{} False{} False{} False{} False{} True{} True{}: {==}
    case False{} True{} False{} False{} False{} True{} False{} False{}: {==}
    case False{} True{} False{} False{} False{} True{} False{} True{}: {==}
    case False{} True{} False{} False{} False{} True{} True{} False{}: {==}
    case False{} True{} False{} False{} False{} True{} True{} True{}: {==}
    case False{} True{} False{} False{} True{} False{} False{} False{}: {==}
    case False{} True{} False{} False{} True{} False{} False{} True{}: {==}
    case False{} True{} False{} False{} True{} False{} True{} False{}: {==}
    case False{} True{} False{} False{} True{} False{} True{} True{}: {==}
    case False{} True{} False{} False{} True{} True{} False{} False{}: {==}
    case False{} True{} False{} False{} True{} True{} False{} True{}: {==}
    case False{} True{} False{} False{} True{} True{} True{} False{}: {==}
    case False{} True{} False{} False{} True{} True{} True{} True{}: {==}
    case False{} True{} False{} True{} False{} False{} False{} False{}: {==}
    case False{} True{} False{} True{} False{} False{} False{} True{}: {==}
    case False{} True{} False{} True{} False{} False{} True{} False{}: {==}
    case False{} True{} False{} True{} False{} False{} True{} True{}: {==}
    case False{} True{} False{} True{} False{} True{} False{} False{}: {==}
    case False{} True{} False{} True{} False{} True{} False{} True{}: {==}
    case False{} True{} False{} True{} False{} True{} True{} False{}: {==}
    case False{} True{} False{} True{} False{} True{} True{} True{}: {==}
    case False{} True{} False{} True{} True{} False{} False{} False{}: {==}
    case False{} True{} False{} True{} True{} False{} False{} True{}: {==}
    case False{} True{} False{} True{} True{} False{} True{} False{}: {==}
    case False{} True{} False{} True{} True{} False{} True{} True{}: {==}
    case False{} True{} False{} True{} True{} True{} False{} False{}: {==}
    case False{} True{} False{} True{} True{} True{} False{} True{}: {==}
    case False{} True{} False{} True{} True{} True{} True{} False{}: {==}
    case False{} True{} False{} True{} True{} True{} True{} True{}: {==}
    case False{} True{} True{} False{} False{} False{} False{} False{}: {==}
    case False{} True{} True{} False{} False{} False{} False{} True{}: {==}
    case False{} True{} True{} False{} False{} False{} True{} False{}: {==}
    case False{} True{} True{} False{} False{} False{} True{} True{}: {==}
    case False{} True{} True{} False{} False{} True{} False{} False{}: {==}
    case False{} True{} True{} False{} False{} True{} False{} True{}: {==}
    case False{} True{} True{} False{} False{} True{} True{} False{}: {==}
    case False{} True{} True{} False{} False{} True{} True{} True{}: {==}
    case False{} True{} True{} False{} True{} False{} False{} False{}: {==}
    case False{} True{} True{} False{} True{} False{} False{} True{}: {==}
    case False{} True{} True{} False{} True{} False{} True{} False{}: {==}
    case False{} True{} True{} False{} True{} False{} True{} True{}: {==}
    case False{} True{} True{} False{} True{} True{} False{} False{}: {==}
    case False{} True{} True{} False{} True{} True{} False{} True{}: {==}
    case False{} True{} True{} False{} True{} True{} True{} False{}: {==}
    case False{} True{} True{} False{} True{} True{} True{} True{}: {==}
    case False{} True{} True{} True{} False{} False{} False{} False{}: {==}
    case False{} True{} True{} True{} False{} False{} False{} True{}: {==}
    case False{} True{} True{} True{} False{} False{} True{} False{}: {==}
    case False{} True{} True{} True{} False{} False{} True{} True{}: {==}
    case False{} True{} True{} True{} False{} True{} False{} False{}: {==}
    case False{} True{} True{} True{} False{} True{} False{} True{}: {==}
    case False{} True{} True{} True{} False{} True{} True{} False{}: {==}
    case False{} True{} True{} True{} False{} True{} True{} True{}: {==}
    case False{} True{} True{} True{} True{} False{} False{} False{}: {==}
    case False{} True{} True{} True{} True{} False{} False{} True{}: {==}
    case False{} True{} True{} True{} True{} False{} True{} False{}: {==}
    case False{} True{} True{} True{} True{} False{} True{} True{}: {==}
    case False{} True{} True{} True{} True{} True{} False{} False{}: {==}
    case False{} True{} True{} True{} True{} True{} False{} True{}: {==}
    case False{} True{} True{} True{} True{} True{} True{} False{}: {==}
    case False{} True{} True{} True{} True{} True{} True{} True{}: {==}
    case True{} False{} False{} False{} False{} False{} False{} False{}: {==}
    case True{} False{} False{} False{} False{} False{} False{} True{}: {==}
    case True{} False{} False{} False{} False{} False{} True{} False{}: {==}
    case True{} False{} False{} False{} False{} False{} True{} True{}: {==}
    case True{} False{} False{} False{} False{} True{} False{} False{}: {==}
    case True{} False{} False{} False{} False{} True{} False{} True{}: {==}
    case True{} False{} False{} False{} False{} True{} True{} False{}: {==}
    case True{} False{} False{} False{} False{} True{} True{} True{}: {==}
    case True{} False{} False{} False{} True{} False{} False{} False{}: {==}
    case True{} False{} False{} False{} True{} False{} False{} True{}: {==}
    case True{} False{} False{} False{} True{} False{} True{} False{}: {==}
    case True{} False{} False{} False{} True{} False{} True{} True{}: {==}
    case True{} False{} False{} False{} True{} True{} False{} False{}: {==}
    case True{} False{} False{} False{} True{} True{} False{} True{}: {==}
    case True{} False{} False{} False{} True{} True{} True{} False{}: {==}
    case True{} False{} False{} False{} True{} True{} True{} True{}: {==}
    case True{} False{} False{} True{} False{} False{} False{} False{}: {==}
    case True{} False{} False{} True{} False{} False{} False{} True{}: {==}
    case True{} False{} False{} True{} False{} False{} True{} False{}: {==}
    case True{} False{} False{} True{} False{} False{} True{} True{}: {==}
    case True{} False{} False{} True{} False{} True{} False{} False{}: {==}
    case True{} False{} False{} True{} False{} True{} False{} True{}: {==}
    case True{} False{} False{} True{} False{} True{} True{} False{}: {==}
    case True{} False{} False{} True{} False{} True{} True{} True{}: {==}
    case True{} False{} False{} True{} True{} False{} False{} False{}: {==}
    case True{} False{} False{} True{} True{} False{} False{} True{}: {==}
    case True{} False{} False{} True{} True{} False{} True{} False{}: {==}
    case True{} False{} False{} True{} True{} False{} True{} True{}: {==}
    case True{} False{} False{} True{} True{} True{} False{} False{}: {==}
    case True{} False{} False{} True{} True{} True{} False{} True{}: {==}
    case True{} False{} False{} True{} True{} True{} True{} False{}: {==}
    case True{} False{} False{} True{} True{} True{} True{} True{}: {==}
    case True{} False{} True{} False{} False{} False{} False{} False{}: {==}
    case True{} False{} True{} False{} False{} False{} False{} True{}: {==}
    case True{} False{} True{} False{} False{} False{} True{} False{}: {==}
    case True{} False{} True{} False{} False{} False{} True{} True{}: {==}
    case True{} False{} True{} False{} False{} True{} False{} False{}: {==}
    case True{} False{} True{} False{} False{} True{} False{} True{}: {==}
    case True{} False{} True{} False{} False{} True{} True{} False{}: {==}
    case True{} False{} True{} False{} False{} True{} True{} True{}: {==}
    case True{} False{} True{} False{} True{} False{} False{} False{}: {==}
    case True{} False{} True{} False{} True{} False{} False{} True{}: {==}
    case True{} False{} True{} False{} True{} False{} True{} False{}: {==}
    case True{} False{} True{} False{} True{} False{} True{} True{}: {==}
    case True{} False{} True{} False{} True{} True{} False{} False{}: {==}
    case True{} False{} True{} False{} True{} True{} False{} True{}: {==}
    case True{} False{} True{} False{} True{} True{} True{} False{}: {==}
    case True{} False{} True{} False{} True{} True{} True{} True{}: {==}
    case True{} False{} True{} True{} False{} False{} False{} False{}: {==}
    case True{} False{} True{} True{} False{} False{} False{} True{}: {==}
    case True{} False{} True{} True{} False{} False{} True{} False{}: {==}
    case True{} False{} True{} True{} False{} False{} True{} True{}: {==}
    case True{} False{} True{} True{} False{} True{} False{} False{}: {==}
    case True{} False{} True{} True{} False{} True{} False{} True{}: {==}
    case True{} False{} True{} True{} False{} True{} True{} False{}: {==}
    case True{} False{} True{} True{} False{} True{} True{} True{}: {==}
    case True{} False{} True{} True{} True{} False{} False{} False{}: {==}
    case True{} False{} True{} True{} True{} False{} False{} True{}: {==}
    case True{} False{} True{} True{} True{} False{} True{} False{}: {==}
    case True{} False{} True{} True{} True{} False{} True{} True{}: {==}
    case True{} False{} True{} True{} True{} True{} False{} False{}: {==}
    case True{} False{} True{} True{} True{} True{} False{} True{}: {==}
    case True{} False{} True{} True{} True{} True{} True{} False{}: {==}
    case True{} False{} True{} True{} True{} True{} True{} True{}: {==}
    case True{} True{} False{} False{} False{} False{} False{} False{}: {==}
    case True{} True{} False{} False{} False{} False{} False{} True{}: {==}
    case True{} True{} False{} False{} False{} False{} True{} False{}: {==}
    case True{} True{} False{} False{} False{} False{} True{} True{}: {==}
    case True{} True{} False{} False{} False{} True{} False{} False{}: {==}
    case True{} True{} False{} False{} False{} True{} False{} True{}: {==}
    case True{} True{} False{} False{} False{} True{} True{} False{}: {==}
    case True{} True{} False{} False{} False{} True{} True{} True{}: {==}
    case True{} True{} False{} False{} True{} False{} False{} False{}: {==}
    case True{} True{} False{} False{} True{} False{} False{} True{}: {==}
    case True{} True{} False{} False{} True{} False{} True{} False{}: {==}
    case True{} True{} False{} False{} True{} False{} True{} True{}: {==}
    case True{} True{} False{} False{} True{} True{} False{} False{}: {==}
    case True{} True{} False{} False{} True{} True{} False{} True{}: {==}
    case True{} True{} False{} False{} True{} True{} True{} False{}: {==}
    case True{} True{} False{} False{} True{} True{} True{} True{}: {==}
    case True{} True{} False{} True{} False{} False{} False{} False{}: {==}
    case True{} True{} False{} True{} False{} False{} False{} True{}: {==}
    case True{} True{} False{} True{} False{} False{} True{} False{}: {==}
    case True{} True{} False{} True{} False{} False{} True{} True{}: {==}
    case True{} True{} False{} True{} False{} True{} False{} False{}: {==}
    case True{} True{} False{} True{} False{} True{} False{} True{}: {==}
    case True{} True{} False{} True{} False{} True{} True{} False{}: {==}
    case True{} True{} False{} True{} False{} True{} True{} True{}: {==}
    case True{} True{} False{} True{} True{} False{} False{} False{}: {==}
    case True{} True{} False{} True{} True{} False{} False{} True{}: {==}
    case True{} True{} False{} True{} True{} False{} True{} False{}: {==}
    case True{} True{} False{} True{} True{} False{} True{} True{}: {==}
    case True{} True{} False{} True{} True{} True{} False{} False{}: {==}
    case True{} True{} False{} True{} True{} True{} False{} True{}: {==}
    case True{} True{} False{} True{} True{} True{} True{} False{}: {==}
    case True{} True{} False{} True{} True{} True{} True{} True{}: {==}
    case True{} True{} True{} False{} False{} False{} False{} False{}: {==}
    case True{} True{} True{} False{} False{} False{} False{} True{}: {==}
    case True{} True{} True{} False{} False{} False{} True{} False{}: {==}
    case True{} True{} True{} False{} False{} False{} True{} True{}: {==}
    case True{} True{} True{} False{} False{} True{} False{} False{}: {==}
    case True{} True{} True{} False{} False{} True{} False{} True{}: {==}
    case True{} True{} True{} False{} False{} True{} True{} False{}: {==}
    case True{} True{} True{} False{} False{} True{} True{} True{}: {==}
    case True{} True{} True{} False{} True{} False{} False{} False{}: {==}
    case True{} True{} True{} False{} True{} False{} False{} True{}: {==}
    case True{} True{} True{} False{} True{} False{} True{} False{}: {==}
    case True{} True{} True{} False{} True{} False{} True{} True{}: {==}
    case True{} True{} True{} False{} True{} True{} False{} False{}: {==}
    case True{} True{} True{} False{} True{} True{} False{} True{}: {==}
    case True{} True{} True{} False{} True{} True{} True{} False{}: {==}
    case True{} True{} True{} False{} True{} True{} True{} True{}: {==}
    case True{} True{} True{} True{} False{} False{} False{} False{}: {==}
    case True{} True{} True{} True{} False{} False{} False{} True{}: {==}
    case True{} True{} True{} True{} False{} False{} True{} False{}: {==}
    case True{} True{} True{} True{} False{} False{} True{} True{}: {==}
    case True{} True{} True{} True{} False{} True{} False{} False{}: {==}
    case True{} True{} True{} True{} False{} True{} False{} True{}: {==}
    case True{} True{} True{} True{} False{} True{} True{} False{}: {==}
    case True{} True{} True{} True{} False{} True{} True{} True{}: {==}
    case True{} True{} True{} True{} True{} False{} False{} False{}: {==}
    case True{} True{} True{} True{} True{} False{} False{} True{}: {==}
    case True{} True{} True{} True{} True{} False{} True{} False{}: {==}
    case True{} True{} True{} True{} True{} False{} True{} True{}: {==}
    case True{} True{} True{} True{} True{} True{} False{} False{}: {==}
    case True{} True{} True{} True{} True{} True{} False{} True{}: {==}
    case True{} True{} True{} True{} True{} True{} True{} False{}: {==}
    case True{} True{} True{} True{} True{} True{} True{} True{}: {==}
def count_matches(+rows: R.Rows,+record: R.Record) -> {R.count(rows,record) == Spec.count(rows,record) : Nat}:
  match rows:
    case R.Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7}:
      %matches_refines(r0,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(_),Spec.indicator(Spec.matches(r1,record))),Nat.add(Spec.indicator(Spec.matches(r2,record)),Spec.indicator(Spec.matches(r3,record)))),Nat.add(Nat.add(Spec.indicator(Spec.matches(r4,record)),Spec.indicator(Spec.matches(r5,record))),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r1,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(_)),Nat.add(Spec.indicator(Spec.matches(r2,record)),Spec.indicator(Spec.matches(r3,record)))),Nat.add(Nat.add(Spec.indicator(Spec.matches(r4,record)),Spec.indicator(Spec.matches(r5,record))),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r2,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(_),Spec.indicator(Spec.matches(r3,record)))),Nat.add(Nat.add(Spec.indicator(Spec.matches(r4,record)),Spec.indicator(Spec.matches(r5,record))),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r3,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(R.same(r2,record)),Spec.indicator(_))),Nat.add(Nat.add(Spec.indicator(Spec.matches(r4,record)),Spec.indicator(Spec.matches(r5,record))),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r4,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(R.same(r2,record)),Spec.indicator(R.same(r3,record)))),Nat.add(Nat.add(Spec.indicator(_),Spec.indicator(Spec.matches(r5,record))),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r5,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(R.same(r2,record)),Spec.indicator(R.same(r3,record)))),Nat.add(Nat.add(Spec.indicator(R.same(r4,record)),Spec.indicator(_)),Nat.add(Spec.indicator(Spec.matches(r6,record)),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r6,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(R.same(r2,record)),Spec.indicator(R.same(r3,record)))),Nat.add(Nat.add(Spec.indicator(R.same(r4,record)),Spec.indicator(R.same(r5,record))),Nat.add(Spec.indicator(_),Spec.indicator(Spec.matches(r7,record))))) : Nat}
      %matches_refines(r7,record) : {R.count(rows,record) == Nat.add(Nat.add(Nat.add(Spec.indicator(R.same(r0,record)),Spec.indicator(R.same(r1,record))),Nat.add(Spec.indicator(R.same(r2,record)),Spec.indicator(R.same(r3,record)))),Nat.add(Nat.add(Spec.indicator(R.same(r4,record)),Spec.indicator(R.same(r5,record))),Nat.add(Spec.indicator(R.same(r6,record)),Spec.indicator(_)))) : Nat}
      position_sum(R.same(r0,record),R.same(r1,record),R.same(r2,record),R.same(r3,record),R.same(r4,record),R.same(r5,record),R.same(r6,record),R.same(r7,record))
def L.multiplicity_refines_position_count(rows,record): count_matches(rows,record)
def le_not_gt(+c: Cmp) -> {Cmp.is_le(c) == Bool.not(Cmp.is_gt(c)) : Bool}:
  match c:
    case LT{}: {==}
    case EQ{}: {==}
    case GT{}: {==}
def de_morgan7(+a0: Bool,+a1: Bool,+a2: Bool,+a3: Bool,+a4: Bool,+a5: Bool,+a6: Bool) -> {Bool.not(a0) && Bool.not(a1) && Bool.not(a2) && Bool.not(a3) && Bool.not(a4) && Bool.not(a5) && Bool.not(a6) == Bool.not(a0 || a1 || a2 || a3 || a4 || a5 || a6) : Bool}:
  match a0 a1 a2 a3 a4 a5 a6:
    case False{} False{} False{} False{} False{} False{} False{}: {==}
    case False{} False{} False{} False{} False{} False{} True{}: {==}
    case False{} False{} False{} False{} False{} True{} False{}: {==}
    case False{} False{} False{} False{} False{} True{} True{}: {==}
    case False{} False{} False{} False{} True{} False{} False{}: {==}
    case False{} False{} False{} False{} True{} False{} True{}: {==}
    case False{} False{} False{} False{} True{} True{} False{}: {==}
    case False{} False{} False{} False{} True{} True{} True{}: {==}
    case False{} False{} False{} True{} False{} False{} False{}: {==}
    case False{} False{} False{} True{} False{} False{} True{}: {==}
    case False{} False{} False{} True{} False{} True{} False{}: {==}
    case False{} False{} False{} True{} False{} True{} True{}: {==}
    case False{} False{} False{} True{} True{} False{} False{}: {==}
    case False{} False{} False{} True{} True{} False{} True{}: {==}
    case False{} False{} False{} True{} True{} True{} False{}: {==}
    case False{} False{} False{} True{} True{} True{} True{}: {==}
    case False{} False{} True{} False{} False{} False{} False{}: {==}
    case False{} False{} True{} False{} False{} False{} True{}: {==}
    case False{} False{} True{} False{} False{} True{} False{}: {==}
    case False{} False{} True{} False{} False{} True{} True{}: {==}
    case False{} False{} True{} False{} True{} False{} False{}: {==}
    case False{} False{} True{} False{} True{} False{} True{}: {==}
    case False{} False{} True{} False{} True{} True{} False{}: {==}
    case False{} False{} True{} False{} True{} True{} True{}: {==}
    case False{} False{} True{} True{} False{} False{} False{}: {==}
    case False{} False{} True{} True{} False{} False{} True{}: {==}
    case False{} False{} True{} True{} False{} True{} False{}: {==}
    case False{} False{} True{} True{} False{} True{} True{}: {==}
    case False{} False{} True{} True{} True{} False{} False{}: {==}
    case False{} False{} True{} True{} True{} False{} True{}: {==}
    case False{} False{} True{} True{} True{} True{} False{}: {==}
    case False{} False{} True{} True{} True{} True{} True{}: {==}
    case False{} True{} False{} False{} False{} False{} False{}: {==}
    case False{} True{} False{} False{} False{} False{} True{}: {==}
    case False{} True{} False{} False{} False{} True{} False{}: {==}
    case False{} True{} False{} False{} False{} True{} True{}: {==}
    case False{} True{} False{} False{} True{} False{} False{}: {==}
    case False{} True{} False{} False{} True{} False{} True{}: {==}
    case False{} True{} False{} False{} True{} True{} False{}: {==}
    case False{} True{} False{} False{} True{} True{} True{}: {==}
    case False{} True{} False{} True{} False{} False{} False{}: {==}
    case False{} True{} False{} True{} False{} False{} True{}: {==}
    case False{} True{} False{} True{} False{} True{} False{}: {==}
    case False{} True{} False{} True{} False{} True{} True{}: {==}
    case False{} True{} False{} True{} True{} False{} False{}: {==}
    case False{} True{} False{} True{} True{} False{} True{}: {==}
    case False{} True{} False{} True{} True{} True{} False{}: {==}
    case False{} True{} False{} True{} True{} True{} True{}: {==}
    case False{} True{} True{} False{} False{} False{} False{}: {==}
    case False{} True{} True{} False{} False{} False{} True{}: {==}
    case False{} True{} True{} False{} False{} True{} False{}: {==}
    case False{} True{} True{} False{} False{} True{} True{}: {==}
    case False{} True{} True{} False{} True{} False{} False{}: {==}
    case False{} True{} True{} False{} True{} False{} True{}: {==}
    case False{} True{} True{} False{} True{} True{} False{}: {==}
    case False{} True{} True{} False{} True{} True{} True{}: {==}
    case False{} True{} True{} True{} False{} False{} False{}: {==}
    case False{} True{} True{} True{} False{} False{} True{}: {==}
    case False{} True{} True{} True{} False{} True{} False{}: {==}
    case False{} True{} True{} True{} False{} True{} True{}: {==}
    case False{} True{} True{} True{} True{} False{} False{}: {==}
    case False{} True{} True{} True{} True{} False{} True{}: {==}
    case False{} True{} True{} True{} True{} True{} False{}: {==}
    case False{} True{} True{} True{} True{} True{} True{}: {==}
    case True{} False{} False{} False{} False{} False{} False{}: {==}
    case True{} False{} False{} False{} False{} False{} True{}: {==}
    case True{} False{} False{} False{} False{} True{} False{}: {==}
    case True{} False{} False{} False{} False{} True{} True{}: {==}
    case True{} False{} False{} False{} True{} False{} False{}: {==}
    case True{} False{} False{} False{} True{} False{} True{}: {==}
    case True{} False{} False{} False{} True{} True{} False{}: {==}
    case True{} False{} False{} False{} True{} True{} True{}: {==}
    case True{} False{} False{} True{} False{} False{} False{}: {==}
    case True{} False{} False{} True{} False{} False{} True{}: {==}
    case True{} False{} False{} True{} False{} True{} False{}: {==}
    case True{} False{} False{} True{} False{} True{} True{}: {==}
    case True{} False{} False{} True{} True{} False{} False{}: {==}
    case True{} False{} False{} True{} True{} False{} True{}: {==}
    case True{} False{} False{} True{} True{} True{} False{}: {==}
    case True{} False{} False{} True{} True{} True{} True{}: {==}
    case True{} False{} True{} False{} False{} False{} False{}: {==}
    case True{} False{} True{} False{} False{} False{} True{}: {==}
    case True{} False{} True{} False{} False{} True{} False{}: {==}
    case True{} False{} True{} False{} False{} True{} True{}: {==}
    case True{} False{} True{} False{} True{} False{} False{}: {==}
    case True{} False{} True{} False{} True{} False{} True{}: {==}
    case True{} False{} True{} False{} True{} True{} False{}: {==}
    case True{} False{} True{} False{} True{} True{} True{}: {==}
    case True{} False{} True{} True{} False{} False{} False{}: {==}
    case True{} False{} True{} True{} False{} False{} True{}: {==}
    case True{} False{} True{} True{} False{} True{} False{}: {==}
    case True{} False{} True{} True{} False{} True{} True{}: {==}
    case True{} False{} True{} True{} True{} False{} False{}: {==}
    case True{} False{} True{} True{} True{} False{} True{}: {==}
    case True{} False{} True{} True{} True{} True{} False{}: {==}
    case True{} False{} True{} True{} True{} True{} True{}: {==}
    case True{} True{} False{} False{} False{} False{} False{}: {==}
    case True{} True{} False{} False{} False{} False{} True{}: {==}
    case True{} True{} False{} False{} False{} True{} False{}: {==}
    case True{} True{} False{} False{} False{} True{} True{}: {==}
    case True{} True{} False{} False{} True{} False{} False{}: {==}
    case True{} True{} False{} False{} True{} False{} True{}: {==}
    case True{} True{} False{} False{} True{} True{} False{}: {==}
    case True{} True{} False{} False{} True{} True{} True{}: {==}
    case True{} True{} False{} True{} False{} False{} False{}: {==}
    case True{} True{} False{} True{} False{} False{} True{}: {==}
    case True{} True{} False{} True{} False{} True{} False{}: {==}
    case True{} True{} False{} True{} False{} True{} True{}: {==}
    case True{} True{} False{} True{} True{} False{} False{}: {==}
    case True{} True{} False{} True{} True{} False{} True{}: {==}
    case True{} True{} False{} True{} True{} True{} False{}: {==}
    case True{} True{} False{} True{} True{} True{} True{}: {==}
    case True{} True{} True{} False{} False{} False{} False{}: {==}
    case True{} True{} True{} False{} False{} False{} True{}: {==}
    case True{} True{} True{} False{} False{} True{} False{}: {==}
    case True{} True{} True{} False{} False{} True{} True{}: {==}
    case True{} True{} True{} False{} True{} False{} False{}: {==}
    case True{} True{} True{} False{} True{} False{} True{}: {==}
    case True{} True{} True{} False{} True{} True{} False{}: {==}
    case True{} True{} True{} False{} True{} True{} True{}: {==}
    case True{} True{} True{} True{} False{} False{} False{}: {==}
    case True{} True{} True{} True{} False{} False{} True{}: {==}
    case True{} True{} True{} True{} False{} True{} False{}: {==}
    case True{} True{} True{} True{} False{} True{} True{}: {==}
    case True{} True{} True{} True{} True{} False{} False{}: {==}
    case True{} True{} True{} True{} True{} False{} True{}: {==}
    case True{} True{} True{} True{} True{} True{} False{}: {==}
    case True{} True{} True{} True{} True{} True{} True{}: {==}
def order_comparisons(+c0: Cmp,+c1: Cmp,+c2: Cmp,+c3: Cmp,+c4: Cmp,+c5: Cmp,+c6: Cmp) -> {Cmp.is_le(c0) && Cmp.is_le(c1) && Cmp.is_le(c2) && Cmp.is_le(c3) && Cmp.is_le(c4) && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}:
  %Equal.sym(Bool,Cmp.is_le(c0),Bool.not(Cmp.is_gt(c0)),le_not_gt(c0)) : {_ && Cmp.is_le(c1) && Cmp.is_le(c2) && Cmp.is_le(c3) && Cmp.is_le(c4) && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c1),Bool.not(Cmp.is_gt(c1)),le_not_gt(c1)) : {Bool.not(Cmp.is_gt(c0)) && _ && Cmp.is_le(c2) && Cmp.is_le(c3) && Cmp.is_le(c4) && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c2),Bool.not(Cmp.is_gt(c2)),le_not_gt(c2)) : {Bool.not(Cmp.is_gt(c0)) && Bool.not(Cmp.is_gt(c1)) && _ && Cmp.is_le(c3) && Cmp.is_le(c4) && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c3),Bool.not(Cmp.is_gt(c3)),le_not_gt(c3)) : {Bool.not(Cmp.is_gt(c0)) && Bool.not(Cmp.is_gt(c1)) && Bool.not(Cmp.is_gt(c2)) && _ && Cmp.is_le(c4) && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c4),Bool.not(Cmp.is_gt(c4)),le_not_gt(c4)) : {Bool.not(Cmp.is_gt(c0)) && Bool.not(Cmp.is_gt(c1)) && Bool.not(Cmp.is_gt(c2)) && Bool.not(Cmp.is_gt(c3)) && _ && Cmp.is_le(c5) && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c5),Bool.not(Cmp.is_gt(c5)),le_not_gt(c5)) : {Bool.not(Cmp.is_gt(c0)) && Bool.not(Cmp.is_gt(c1)) && Bool.not(Cmp.is_gt(c2)) && Bool.not(Cmp.is_gt(c3)) && Bool.not(Cmp.is_gt(c4)) && _ && Cmp.is_le(c6) == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  %Equal.sym(Bool,Cmp.is_le(c6),Bool.not(Cmp.is_gt(c6)),le_not_gt(c6)) : {Bool.not(Cmp.is_gt(c0)) && Bool.not(Cmp.is_gt(c1)) && Bool.not(Cmp.is_gt(c2)) && Bool.not(Cmp.is_gt(c3)) && Bool.not(Cmp.is_gt(c4)) && Bool.not(Cmp.is_gt(c5)) && _ == Bool.not(Cmp.is_gt(c0) || Cmp.is_gt(c1) || Cmp.is_gt(c2) || Cmp.is_gt(c3) || Cmp.is_gt(c4) || Cmp.is_gt(c5) || Cmp.is_gt(c6)) : Bool}
  de_morgan7(Cmp.is_gt(c0),Cmp.is_gt(c1),Cmp.is_gt(c2),Cmp.is_gt(c3),Cmp.is_gt(c4),Cmp.is_gt(c5),Cmp.is_gt(c6))
def L.ordering_refines_adjacent_date_contract(rows):
  match rows:
    case R.Rows{R.Record{+d0,i0,v0},R.Record{+d1,i1,v1},R.Record{+d2,i2,v2},R.Record{+d3,i3,v3},R.Record{+d4,i4,v4},R.Record{+d5,i5,v5},R.Record{+d6,i6,v6},R.Record{+d7,i7,v7}}:
      order_comparisons(Nat.cmp(d0,d1),Nat.cmp(d1,d2),Nat.cmp(d2,d3),Nat.cmp(d3,d4),Nat.cmp(d4,d5),Nat.cmp(d5,d6),Nat.cmp(d6,d7))
