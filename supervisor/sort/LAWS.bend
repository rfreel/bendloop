import Base
import ../runtime.bend as S
import ./task.bend as T
import ./model.bend as R
import ./spec.bend as Spec

def incumbent_ok(c: S.Contract<T.Requirements>,value: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>) -> Bool:
  match value:
    case None{}: True{}
    case Some{S.Qualified{a,p}}: T.check(c,a)
def stage_ok(c: S.Contract<T.Requirements>,value: S.Stage<T.Requirements,R.Rows,T.check,c>) -> Bool:
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
def effect_safe(c: S.Contract<T.Requirements>,e: S.Effect<T.Requirements,R.Rows,T.check,c>) -> Type:
  match e:
    case S.NoEffect{}: Unit
    case S.Failure{}: Unit
    case S.Publish{n,a,q,p}: {T.check(c,a) == True{} : Bool} & {S.permission(T.Requirements,c) == S.PublishResult{} : S.Permission}
def result_safe(-cap: Nat,t: T.Transition(cap)) -> Type:
  match t:
    case S.Transition{s,e}: effect_safe(S.current(T.Requirements,R.Rows,T.check,cap,s),e)
def result_contract(-cap: Nat,t: T.Transition(cap)) -> S.Contract<T.Requirements>:
  S.Transition{s,e} = t
  S.current(T.Requirements,R.Rows,T.check,cap,s)
def candidate(c: S.Contract<T.Requirements>,q: S.Qualified<T.Requirements,R.Rows,T.check,c>) -> R.Rows:
  S.Qualified{a,p} = q
  a
def selected(c: S.Contract<T.Requirements>,q: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>) -> Maybe<&2,R.Rows>:
  match q:
    case None{}: None{}
    case Some{S.Qualified{a,p}}: Some{a}
def preferred(+a: R.Rows,+b: R.Rows,less: Bool) -> R.Rows:
  match less:
    case False{}: b
    case True{}: a

law initial_invariant:
  for +c: S.Contract<T.Requirements>
  for +cap: Nat
  for fallback: R.Rows
  invariant(cap,T.initial(c,cap,fallback))
law step_preserves_invariant:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Rows>
  result_invariant(cap,T.step(cap,state,event))
law every_effect_safe:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Rows>
  result_safe(cap,T.step(cap,state,event))
law selection_rule:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for +b: R.Rows
  for pa: {T.check(c,a) == True{} : Bool}
  for pb: {T.check(c,b) == True{} : Bool}
  {selected(c,S.select(T.Requirements,R.Rows,T.check,T.score,c,S.Qualified{a,pa},Some{S.Qualified{b,pb}})) ==
   Some{preferred(a,b,Nat.is_lt(R.quality(a),R.quality(b)))} : Maybe<&2,R.Rows>}
law empty_incumbent_accepts_qualified:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for pa: {T.check(c,a) == True{} : Bool}
  {selected(c,S.select(T.Requirements,R.Rows,T.check,T.score,c,S.Qualified{a,pa},None{})) == Some{a} : Maybe<&2,R.Rows>}
law ingress_cannot_change_contract:
  for +cap: Nat
  for +c: S.Contract<T.Requirements>
  for spent: Nat
  for left: Nat
  for p: {Nat.add(spent,left) == cap : Nat}
  for mode: S.Mode
  for stage: S.Stage<T.Requirements,R.Rows,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>
  for message: S.Worker<R.Rows>
  {result_contract(cap,T.step(cap,S.State{c,spent,left,p,mode,stage,inc},S.Ingress{message})) == c : S.Contract<T.Requirements>}

def final_artifact(-cap: Nat,t: T.Transition(cap)) -> Maybe<&2,R.Rows>:
  S.Transition{s,e} = t
  match e:
    case S.Publish{n,a,p,q}: Some{a}
    case _: None{}
def result_mode(-cap: Nat,t: T.Transition(cap)) -> S.Mode:
  S.Transition{S.State{c,spent,left,p,mode,stage,inc},e} = t
  mode
law untrusted_claims_do_not_qualify:
  for +c: S.Contract<T.Requirements>
  for +task: Nat
  for +epoch: Nat
  for +artifact: R.Rows
  for first: String
  for second: String
  {S.freeze_message(T.Requirements,R.Rows,T.check,c,S.Proposal{task,epoch,artifact,first}) ==
   S.freeze_message(T.Requirements,R.Rows,T.check,c,S.Proposal{task,epoch,artifact,second}) : S.Stage<T.Requirements,R.Rows,T.check,c>}
law frozen_candidate_cannot_be_overwritten:
  for +c: S.Contract<T.Requirements>
  for +artifact: R.Rows
  for message: S.Worker<R.Rows>
  {S.receive(T.Requirements,R.Rows,T.check,c,S.Frozen{artifact},message) == S.Frozen{artifact} : S.Stage<T.Requirements,R.Rows,T.check,c>}
law closed_ingress_inert:
  for +cap: Nat
  for +c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for +p: {Nat.add(spent,left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Rows,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>
  for message: S.Worker<R.Rows>
  {T.step(cap,S.State{c,spent,left,p,S.Finished{},stage,inc},S.Ingress{message}) ==
   S.Transition{S.State{c,spent,left,p,S.Finished{},stage,inc},S.NoEffect{}} : T.Transition(cap)}
law expiry_finishes:
  for +cap: Nat
  for state: T.State(cap)
  {result_mode(cap,T.step(cap,state,S.Expire{})) == S.Finished{} : S.Mode}
def five_steps(-cap: Nat,state: T.State(cap),message: S.Worker<R.Rows>) -> T.Transition(cap):
  s1 = next_state(cap,T.step(cap,state,S.Ingress{message}))
  s2 = next_state(cap,T.step(cap,s1,S.Freeze{}))
  s3 = next_state(cap,T.step(cap,s2,S.Evaluate{}))
  s4 = next_state(cap,T.step(cap,s3,S.Compare{}))
  T.step(cap,s4,S.Commit{})
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
  for stage: S.Stage<T.Requirements,R.Rows,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>
  for message: S.Worker<R.Rows>
  {result_spent(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Running{},stage,inc},S.Ingress{message})) == 1n+spent : Nat}
law running_ingress_decrements_allowance:
  for +cap: Nat
  for c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for p: {Nat.add(spent,1n+left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Rows,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>
  for message: S.Worker<R.Rows>
  {result_left(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Running{},stage,inc},S.Ingress{message})) == left : Nat}
law crashed_ingress_decrements_allowance:
  for +cap: Nat
  for c: S.Contract<T.Requirements>
  for +spent: Nat
  for +left: Nat
  for p: {Nat.add(spent,1n+left) == cap : Nat}
  for stage: S.Stage<T.Requirements,R.Rows,T.check,c>
  for inc: Maybe<&1,S.Qualified<T.Requirements,R.Rows,T.check,c>>
  for message: S.Worker<R.Rows>
  {result_left(cap,T.step(cap,S.State{c,spent,1n+left,p,S.Crashed{},stage,inc},S.Ingress{message})) == left : Nat}
def evaluator_id(c: S.Contract<T.Requirements>) -> Nat:
  S.Contract{task,epoch,evaluator,permission,requirements} = c
  evaluator
law checker_ordered:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for ok: {T.check(c,a) == True{} : Bool}
  {R.ordered(a) == True{} : Bool}
law checker_preserved:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for ok: {T.check(c,a) == True{} : Bool}
  {R.preserved(T.reference(c),a) == True{} : Bool}
law checker_namespace:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for ok: {T.check(c,a) == True{} : Bool}
  {Nat.is_eq(evaluator_id(c),2n) == True{} : Bool}
def result_correct(-cap: Nat,t: T.Transition(cap)) -> Type:
  S.Transition{s,e} = t
  match e:
    case S.NoEffect{}: Unit
    case S.Failure{}: Unit
    case S.Publish{n,+a,q,p}:
      {R.ordered(a) && R.preserved(T.reference(S.current(T.Requirements,R.Rows,T.check,cap,s)),a) == True{} : Bool}
law every_publication_sorted_and_preserved:
  for +cap: Nat
  for state: T.State(cap)
  for event: S.Action<T.Requirements,R.Rows>
  result_correct(cap,T.step(cap,state,event))
def reference_rows() -> R.Rows: R.Rows{R.Record{2n,2n,12n},R.Record{1n,1n,11n},R.Record{1n,1n,11n},R.Record{3n,3n,13n},R.Record{0n,0n,10n},R.Record{2n,4n,14n},R.Record{4n,5n,15n},R.Record{3n,6n,16n}}
def sorted_rows() -> R.Rows: R.Rows{R.Record{0n,0n,10n},R.Record{1n,1n,11n},R.Record{1n,1n,11n},R.Record{2n,2n,12n},R.Record{2n,4n,14n},R.Record{3n,3n,13n},R.Record{3n,6n,16n},R.Record{4n,5n,15n}}
def lost_duplicate_rows() -> R.Rows: R.Rows{R.Record{0n,0n,10n},R.Record{1n,1n,11n},R.Record{1n,9n,11n},R.Record{2n,2n,12n},R.Record{2n,4n,14n},R.Record{3n,3n,13n},R.Record{3n,6n,16n},R.Record{4n,5n,15n}}
def witness_contract(epoch: Nat,permit: S.Permission) -> S.Contract<T.Requirements>:
  S.Contract{1n,epoch,2n,permit,T.Requirements{reference_rows()}}
law duplicate_preserving_positive:
  {T.check(witness_contract(0n,S.PublishResult{}),sorted_rows()) == True{} : Bool}
law lost_duplicate_rejected:
  {T.check(witness_contract(0n,S.PublishResult{}),lost_duplicate_rows()) == False{} : Bool}
law lost_duplicate_count_witness:
  {R.count(reference_rows(),R.Record{1n,1n,11n}) == 2n : Nat} &
  {R.count(lost_duplicate_rows(),R.Record{1n,1n,11n}) == 1n : Nat}
law actual_admission_positive_control:
  {final_artifact(5n,five_steps(5n,T.initial(witness_contract(0n,S.PublishResult{}),5n,reference_rows()),
    S.Proposal{1n,0n,sorted_rows(),"fabricated worker review"})) == Some{sorted_rows()} : Maybe<&2,R.Rows>}
law zero_budget_revocation:
  {result_contract(0n,T.step(0n,T.initial(witness_contract(0n,S.PublishResult{}),0n,sorted_rows()),
    S.Replace{witness_contract(1n,S.Denied{}),sorted_rows()})) == witness_contract(1n,S.Denied{}) : S.Contract<T.Requirements>}
law whole_record_identity_sound:
  for +a: R.Record
  for +b: R.Record
  for +ok: {R.same(a,b) == True{} : Bool}
  {a == b : R.Record}
law whole_record_identity_complete:
  for +a: R.Record
  for +b: R.Record
  for same: {a == b : R.Record}
  {R.same(a,b) == True{} : Bool}
law whole_record_identity_reflexive:
  for +a: R.Record
  {R.same(a,a) == True{} : Bool}
law checked_reference_multiplicities:
  for +c: S.Contract<T.Requirements>
  for +a: R.Rows
  for ok: {T.check(c,a) == True{} : Bool}
  for +slot: R.Slot
  {R.count(T.reference(c),R.record_at(T.reference(c),slot)) == R.count(a,R.record_at(T.reference(c),slot)) : Nat}
law lost_duplicate_diagnostic:
  {R.missing(reference_rows(),lost_duplicate_rows()) == Some{R.Missing{R.Record{1n,1n,11n},2n,1n}} : Maybe<&2,R.Missing>}
law unsorted_pair_diagnostic:
  {R.unordered(reference_rows()) == Some{R.Unordered{0n,R.Record{2n,2n,12n},R.Record{1n,1n,11n}}} : Maybe<&2,R.Unordered>}
law multiplicity_refines_position_count:
  for +rows: R.Rows
  for +record: R.Record
  {R.count(rows,record) == Spec.count(rows,record) : Nat}
law ordering_refines_adjacent_date_contract:
  for +rows: R.Rows
  {R.ordered(rows) == Spec.ordered(rows) : Bool}
