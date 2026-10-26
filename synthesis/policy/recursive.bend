import Base
import ./types.bend as P
import ./experiment.bend as E
import ./learning.bend as L

type Branch is Data:
  Branch{initial: P.Policy, final: P.Policy, cap: Nat, proposed: Nat,
         remaining: Nat, accepted: Nat, cycles: +List<E.Adaptation>}
def accepted_trials(history: +List<E.RevisionTrial>) -> Nat:
  match history:
    case Nil{}: 0n
    case Con{E.RevisionTrial{i,E.Comparison{p,q,a,b,True{}}},tail}: 1n+accepted_trials(tail)
    case Con{E.RevisionTrial{i,E.Comparison{p,q,a,b,False{}}},tail}: accepted_trials(tail)
def accepted(a: E.Adaptation) -> Nat:
  E.Adaptation{old,new,used,left,history} = a
  accepted_trials(history)
def initial(+p: P.Policy,+cap: Nat) -> Branch:
  Branch{p,p,cap,0n,cap,0n,Nil{}}
def extend(state: Branch,+cycle: E.Adaptation) -> Branch:
  Branch{initial,current,cap,spent,left,count,history} = state
  E.Adaptation{old,new,+used,remaining,trials} = cycle
  Branch{initial,new,cap,Nat.add(spent,used),Nat.sub(left,used),Nat.add(count,accepted(cycle)),cycle <> history}
def finished(result: Result<&2,&2,String,E.Adaptation>,state: Branch,
             next: Branch -> Result<&2,&2,String,Branch>) -> Result<&2,&2,String,Branch>:
  match result:
    case Fail{error}: Fail{error}
    case Done{cycle}: next(extend(state,cycle))
def advance(tasks: +List<E.Task>,+protected: +List<E.Task>,state: Branch) -> Result<&2,&2,String,Branch>:
  match tasks state:
    case Nil{} _: Done{state}
    case Con{task,tail} Branch{initial,current,cap,spent,0n,count,history}: Done{state}
    case Con{task,tail} Branch{initial,+current,cap,spent,1n+left,count,history}:
      finished(E.learn(current,task,protected,1n),state,s => advance(tail,protected,s))
def run(tasks: +List<E.Task>,protected: +List<E.Task>,p: P.Policy,cap: Nat) -> Result<&2,&2,String,Branch>:
  advance(tasks,protected,initial(p,cap))

def reductions(a: +List<Nat>,b: +List<Nat>) -> Nat:
  match a b:
    case Con{x,xs} Con{y,ys}: Nat.add(Nat.sub(x,y),reductions(xs,ys))
    case _ _: 0n
def trial_gain(history: +List<E.RevisionTrial>) -> Nat:
  match history:
    case Nil{}: 0n
    case Con{E.RevisionTrial{i,E.Comparison{p,q,E.Profile{a,aa,ai,an,at},E.Profile{b,ba,bi,bn,bt},ok}},tail}:
      match ok:
        case False{}: trial_gain(tail)
        case True{}: Nat.add(reductions(a,b),trial_gain(tail))
def cycle_gain(cycles: +List<E.Adaptation>) -> Nat:
  match cycles:
    case Nil{}: 0n
    case Con{E.Adaptation{old,new,used,left,history},tail}: Nat.add(trial_gain(history),cycle_gain(tail))
def gain(b: Branch) -> Nat:
  Branch{initial,final,cap,used,left,accepted,cycles} = b
  cycle_gain(cycles)
def cycle_work(cycles: +List<E.Adaptation>) -> L.Work:
  match cycles:
    case Nil{}: L.Work{0n,0n,0n}
    case Con{cycle,tail}: L.plus(L.adaptation_work(cycle),cycle_work(tail))
def work(b: Branch) -> L.Work:
  Branch{initial,final,cap,used,left,accepted,cycles} = b
  cycle_work(cycles)
