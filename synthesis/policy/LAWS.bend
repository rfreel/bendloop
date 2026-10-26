import Base
import ./types.bend as P
import ./runtime.bend as R
import ./spec.bend as Spec
import ./search.bend as Search
import ./experiment.bend as Experiment
import ./learning.bend as Learning
import ./accounting.bend as Accounting
import ./recursive.bend as Recursive
import ../search/grammar.bend as G
import ../search/runtime.bend as S
import ../interpreter/runtime.bend as I
import ../interpreter/bridge.bend as B

law rank_refines:
  for +priority: P.Priority
  for +n: Nat
  {R.rank(priority,n) == Spec.permutation(priority,n) : Nat}
law rank_involution:
  for +priority: P.Priority
  for n: Nat
  {R.rank(priority,R.rank(priority,n)) == n : Nat}
law rank_injective:
  for +priority: P.Priority
  for +a: Nat
  for +b: Nat
  for equal: {R.rank(priority,a) == R.rank(priority,b) : Nat}
  {a == b : Nat}
law rank_surjective:
  for +priority: P.Priority
  for +target: Nat
  exs source: Nat
  {R.rank(priority,source) == target : Nat}
law priority_refines:
  for p: P.Policy
  for +reference: I.Expr
  {R.priority(p,reference) == Spec.priority(p,B.model(reference)) : P.Priority}
law proposal_refines:
  for +p: P.Policy
  for +task: I.Expr
  for index: Nat
  {R.propose(p,task,index) == Spec.propose(p,B.model(task),index) : Maybe<&2,P.Policy>}
law zero_quota_preserves_state:
  for state: Search.State
  {Search.advance(0n,state) == Done{state} : Result<&2,&1,String,Search.State>}
law resume_composes:
  for a: Nat
  for +b: Nat
  for state: Search.State
  {Search.advance(Nat.add(a,b),state) ==
   Search.continue(Search.advance(a,state),s => Search.advance(b,s)) : Result<&2,&1,String,Search.State>}

law budget_conserved:
  for q: Nat
  for policy: P.Policy
  for reference: I.Expr
  for ops: G.Ops
  for bound: G.Bound
  for +cap: Nat
  for spent: Nat
  for left: Nat
  for best: S.Best<reference>
  for trials: +List<Search.Trial>
  for valid: {Nat.add(spent,left) == cap : Nat}
  {Accounting.total_result(Search.advance(q,Search.State{policy,reference,ops,bound,cap,spent,left,best,trials}),cap) == cap : Nat}

law comparison_gate:
  for new: Experiment.Profile
  for old: Experiment.Profile
  {Experiment.accepts(new,old) == Spec.improves(costs(new),costs(old)) : Bool}
law learning_gate:
  for new: Learning.Profile
  for old: Learning.Profile
  {Learning.accepts(new,old) == Spec.learns(cold(new),cold(old),warm(new),warm(old)) : Bool}
def costs(p: Experiment.Profile) -> +List<Nat>:
  Experiment.Profile{costs,a,i,n,observations} = p
  costs
def cold(p: Learning.Profile) -> +List<Nat>:
  Learning.Profile{cold,warm,p,w,h} = p
  cold
def warm(p: Learning.Profile) -> +List<Nat>:
  Learning.Profile{cold,warm,p,w,h} = p
  warm
law installs_evaluated_policy:
  for old: P.Policy
  for candidate: P.Policy
  for a: Experiment.Profile
  for b: Experiment.Profile
  {Experiment.chosen(Experiment.Comparison{old,candidate,a,b,True{}}) == candidate : P.Policy}
law installs_evaluated_learner:
  for old: P.Policy
  for candidate: P.Policy
  for a: Learning.Profile
  for b: Learning.Profile
  {Learning.chosen(Learning.Comparison{old,candidate,a,b,True{}}) == candidate : P.Policy}

law learning_comparison_gate:
  for +before: P.Policy
  for +proposed: P.Policy
  for +old: Learning.Profile
  for +new: Learning.Profile
  {Learning.compared(before,proposed,Done{old},Done{new}) ==
   Done{Learning.Comparison{before,proposed,old,new,
     Spec.same_knowledge(before,proposed) && Spec.learns(cold(new),cold(old),warm(new),warm(old))}} : Result<&2,&2,String,Learning.Comparison>}

law compares_executed_policies:
  for +old: P.Policy
  for +candidate: P.Policy
  for +tasks: +List<Experiment.Task>
  {Experiment.compare(old,candidate,tasks) ==
   Experiment.compared(old,candidate,Experiment.assess(old,tasks),Experiment.assess(candidate,tasks)) : Result<&2,&2,String,Experiment.Comparison>}
law compares_executed_learners:
  for +old: P.Policy
  for +candidate: P.Policy
  for +episodes: +List<Learning.Episode>
  {Learning.compare(old,candidate,episodes) ==
   Learning.compared(old,candidate,Learning.assess(old,episodes),Learning.assess(candidate,episodes)) : Result<&2,&2,String,Learning.Comparison>}
law zero_adaptation:
  for +p: P.Policy
  for task: Experiment.Task
  for protected: +List<Experiment.Task>
  {Experiment.learn(p,task,protected,0n) == Done{Experiment.Adaptation{p,p,0n,0n,Nil{}}} : Result<&2,&2,String,Experiment.Adaptation>}
law zero_meta_revision:
  for +p: P.Policy
  for episodes: +List<Learning.Episode>
  {Learning.improve(p,episodes,0n) == Done{Learning.Improvement{p,p,0n,0n,Nil{}}} : Result<&2,&2,String,Learning.Improvement>}
law zero_recursive_revision:
  for tasks: +List<Experiment.Task>
  for protected: +List<Experiment.Task>
  for +p: P.Policy
  {Recursive.run(tasks,protected,p,0n) == Done{Recursive.initial(p,0n)} : Result<&2,&2,String,Recursive.Branch>}
