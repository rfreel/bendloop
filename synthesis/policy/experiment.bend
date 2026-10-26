import Base
import ./types.bend as P
import ./runtime.bend as Policy
import ./search.bend as Search
import ../interpreter/runtime.bend as R
import ../search/grammar.bend as G

type Task is Data:
  Task{reference: R.Expr, ops: G.Ops, bound: G.Bound, cap: Nat}
type Profile is Data:
  Profile{costs: +List<Nat>, attempts: Nat, checked_inputs: Nat, verification_nodes: Nat, observations: +List<Search.Observation>}
type Comparison is Data:
  Comparison{before: P.Policy, proposed: P.Policy, old: Profile, new: Profile, accepted: Bool}
type RevisionTrial is Data:
  RevisionTrial{index: Nat, comparison: Comparison}
type Adaptation is Data:
  Adaptation{initial: P.Policy, final: P.Policy, proposed: Nat, remaining: Nat,
             history: +List<RevisionTrial>}

def task_reference(task: Task) -> R.Expr:
  Task{reference,ops,bound,cap} = task
  reference
def append_observation(+observation: Search.Observation, rest: Profile) -> Profile:
  Search.Observation{attempts,left,cost,improved,inputs,nodes,trials} = observation
  Profile{costs,attempts2,inputs2,nodes2,observations} = rest
  Profile{cost <> costs,Nat.add(attempts,attempts2),Nat.add(inputs,inputs2),Nat.add(nodes,nodes2),observation <> observations}
def combined(observation: Result<&2,&2,String,Search.Observation>, rest: Result<&2,&2,String,Profile>) -> Result<&2,&2,String,Profile>:
  match observation rest:
    case Fail{e} _: Fail{e}
    case _ Fail{e}: Fail{e}
    case Done{a} Done{b}: Done{append_observation(a,b)}
def assess_task(p: P.Policy, task: Task) -> Result<&2,&2,String,Search.Observation>:
  Task{reference,ops,bound,cap} = task
  Search.observed(Search.run(p,reference,ops,bound,cap))
def assess(+p: P.Policy, tasks: +List<Task>) -> Result<&2,&2,String,Profile>:
  match tasks:
    case Nil{}: Done{Profile{Nil{},0n,0n,0n,Nil{}}}
    case Con{task,tail}: combined(assess_task(p,task),assess(p,tail))
def no_worse(a: +List<Nat>, b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x,xs} Con{y,ys}: Nat.is_le(x,y) && no_worse(xs,ys)
    case _ _: False{}
def better(a: +List<Nat>, b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: False{}
    case Con{x,xs} Con{y,ys}: Nat.is_lt(x,y) || better(xs,ys)
    case _ _: False{}
def equal_costs(a: +List<Nat>, b: +List<Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x,xs} Con{y,ys}: Nat.is_eq(x,y) && equal_costs(xs,ys)
    case _ _: False{}
def accepts(a: Profile, b: Profile) -> Bool:
  Profile{+ac,aa,ai,an,at} = a
  Profile{+bc,ba,bi,bn,bt} = b
  no_worse(ac,bc) && better(ac,bc)
def compared(before: P.Policy, proposed: P.Policy, a: Result<&2,&2,String,Profile>, b: Result<&2,&2,String,Profile>) -> Result<&2,&2,String,Comparison>:
  match a b:
    case Fail{e} _: Fail{e}
    case _ Fail{e}: Fail{e}
    case Done{+old} Done{+new}: Done{Comparison{before,proposed,old,new,accepts(new,old)}}
def compare(+before: P.Policy, +proposed: P.Policy, +tasks: +List<Task>) -> Result<&2,&2,String,Comparison>:
  compared(before,proposed,assess(before,tasks),assess(proposed,tasks))
def chosen(comparison: Comparison) -> P.Policy:
  match comparison:
    case Comparison{before,proposed,old,new,True{}}: proposed
    case Comparison{before,proposed,old,new,False{}}: before

def record(initial: P.Policy, +index: Nat, left: Nat, history: +List<RevisionTrial>,
           result: Result<&2,&2,String,Comparison>) -> Result<&2,&2,String,Adaptation>:
  match result:
    case Fail{e}: Fail{e}
    case Done{+comparison}:
      Done{Adaptation{initial,chosen(comparison),1n+index,left,RevisionTrial{index,comparison} <> history}}
def revise_once(initial: P.Policy, current: P.Policy, +task: Task, protected: +List<Task>,
                index: Nat, remaining: Nat, history: +List<RevisionTrial>,
                proposal: Maybe<&2,P.Policy>) -> Result<&2,&2,String,Adaptation>:
  match remaining proposal:
    case _ None{}: Done{Adaptation{initial,current,index,remaining,history}}
    case 0n Some{candidate}: Fail{"revision allowance invariant"}
    case 1n+left Some{candidate}:
      record(initial,index,left,history,compare(current,candidate,task <> protected))
def resume_adaptation(result: Result<&2,&2,String,Adaptation>,
                      next: Adaptation -> Result<&2,&2,String,Adaptation>) -> Result<&2,&2,String,Adaptation>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: next(state)
def adapt(fuel: Nat, +task: Task, +protected: +List<Task>, state: Adaptation) -> Result<&2,&2,String,Adaptation>:
  match fuel state:
    case 0n _: Done{state}
    case 1n+p Adaptation{initial,+current,+index,0n,history}:
      Done{Adaptation{initial,current,index,0n,history}}
    case 1n+p Adaptation{initial,+current,+index,1n+left,history}:
      resume_adaptation(
        revise_once(initial,current,task,protected,index,1n+left,history,
          Policy.propose(current,task_reference(task),index)),
        s => adapt(p,task,protected,s))
def learn(+p: P.Policy, task: Task, protected: +List<Task>, +cap: Nat) -> Result<&2,&2,String,Adaptation>:
  adapt(cap,task,protected,Adaptation{p,p,0n,cap,Nil{}})
