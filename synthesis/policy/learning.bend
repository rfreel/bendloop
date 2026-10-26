import Base
import ./types.bend as P
import ./runtime.bend as Policy
import ./experiment.bend as E
import ../interpreter/runtime.bend as R

type Episode is Data:
  Episode{training: E.Task, transfer: +List<E.Task>, protected: +List<E.Task>, budget: Nat}
type EpisodeResult is Data:
  EpisodeResult{before: E.Profile, after: E.Profile, adaptation: E.Adaptation}
type Work is Data:
  Work{attempts: Nat, inputs: Nat, nodes: Nat}
type Profile is Data:
  Profile{cold: +List<Nat>, after: +List<Nat>, proposals: Nat,
          work: Work, episodes: +List<EpisodeResult>}
type Comparison is Data:
  Comparison{before: P.Policy, proposed: P.Policy, old: Profile, new: Profile, accepted: Bool}
type Trial is Data:
  Trial{index: Nat, comparison: Comparison}
type Improvement is Data:
  Improvement{initial: P.Policy, final: P.Policy, proposed: Nat, remaining: Nat, history: +List<Trial>}

def append(xs: +List<Nat>, +ys: +List<Nat>) -> +List<Nat>:
  match xs:
    case Nil{}: ys
    case Con{x,tail}: x <> append(tail,ys)
def final(a: E.Adaptation) -> P.Policy:
  E.Adaptation{old,new,count,left,history} = a
  new
def after_learning(+a: E.Adaptation, before: E.Profile, after: Result<&2,&2,String,E.Profile>) -> Result<&2,&2,String,EpisodeResult>:
  match after:
    case Fail{e}: Fail{e}
    case Done{profile}: Done{EpisodeResult{before,profile,a}}
def learned(before: Result<&2,&2,String,E.Profile>, +transfer: +List<E.Task>, value: Result<&2,&2,String,E.Adaptation>) -> Result<&2,&2,String,EpisodeResult>:
  match before value:
    case Fail{e} _: Fail{e}
    case _ Fail{e}: Fail{e}
    case Done{profile} Done{+a}: after_learning(a,profile,E.assess(final(a),transfer))
def episode(+p: P.Policy, ep: Episode) -> Result<&2,&2,String,EpisodeResult>:
  Episode{training,+transfer,protected,budget} = ep
  learned(E.assess(p,transfer),transfer,E.learn(p,training,protected,budget))
def work(a: E.Profile) -> Work:
  E.Profile{costs,attempts,inputs,nodes,trials} = a
  Work{attempts,inputs,nodes}
def plus(a: Work,b: Work) -> Work:
  Work{aa,ai,an} = a
  Work{ba,bi,bn} = b
  Work{Nat.add(aa,ba),Nat.add(ai,bi),Nat.add(an,bn)}
def trial_work(history: +List<E.RevisionTrial>) -> Work:
  match history:
    case Nil{}: Work{0n,0n,0n}
    case Con{E.RevisionTrial{i,E.Comparison{p,q,a,b,accepted}},tail}:
      plus(plus(work(a),work(b)),trial_work(tail))
def adaptation_work(a: E.Adaptation) -> Work:
  E.Adaptation{old,new,count,left,history} = a
  trial_work(history)
def episode_proposals(a: E.Adaptation) -> Nat:
  E.Adaptation{old,new,count,left,history} = a
  count
def joined(+ep: EpisodeResult, rest: Profile) -> Profile:
  EpisodeResult{+before,+after,+a} = ep
  E.Profile{cold,ba,bi,bn,btrials} = before
  E.Profile{warm,aa,ai,an,atrials} = after
  Profile{cold2,warm2,proposals,effort,episodes} = rest
  Profile{append(cold,cold2),append(warm,warm2),Nat.add(episode_proposals(a),proposals),
    plus(plus(work(before),work(after)),plus(adaptation_work(a),effort)),ep <> episodes}
def combine(a: Result<&2,&2,String,EpisodeResult>, b: Result<&2,&2,String,Profile>) -> Result<&2,&2,String,Profile>:
  match a b:
    case Fail{e} _: Fail{e}
    case _ Fail{e}: Fail{e}
    case Done{ep} Done{tail}: Done{joined(ep,tail)}
def assess(+p: P.Policy, episodes: +List<Episode>) -> Result<&2,&2,String,Profile>:
  match episodes:
    case Nil{}: Done{Profile{Nil{},Nil{},0n,Work{0n,0n,0n},Nil{}}}
    case Con{ep,tail}: combine(episode(p,ep),assess(p,tail))
def accepts(a: Profile,b: Profile) -> Bool:
  Profile{ac,+aw,ap,ae,ah} = a
  Profile{bc,+bw,bp,be,bh} = b
  E.equal_costs(ac,bc) && E.no_worse(aw,bw) && E.better(aw,bw)
def same_knowledge(a: P.Policy,b: P.Policy) -> Bool:
  P.Policy{az,ao,am} = a
  P.Policy{bz,bo,bm} = b
  Bool.not(Bool.xor(az,bz)) && Bool.not(Bool.xor(ao,bo))
def compared(+before: P.Policy,+proposed: P.Policy,a: Result<&2,&2,String,Profile>,b: Result<&2,&2,String,Profile>) -> Result<&2,&2,String,Comparison>:
  match a b:
    case Fail{e} _: Fail{e}
    case _ Fail{e}: Fail{e}
    case Done{+old} Done{+new}: Done{Comparison{before,proposed,old,new,same_knowledge(before,proposed) && accepts(new,old)}}
def compare(+before: P.Policy,+proposed: P.Policy,+episodes: +List<Episode>) -> Result<&2,&2,String,Comparison>:
  compared(before,proposed,assess(before,episodes),assess(proposed,episodes))
def chosen(comparison: Comparison) -> P.Policy:
  match comparison:
    case Comparison{before,proposed,old,new,True{}}: proposed
    case Comparison{before,proposed,old,new,False{}}: before
def context(episodes: +List<Episode>) -> R.Expr:
  match episodes:
    case Nil{}: R.Input{}
    case Con{Episode{task,transfer,protected,budget},tail}: E.task_reference(task)
def record(initial: P.Policy,+index: Nat,left: Nat,history: +List<Trial>,result: Result<&2,&2,String,Comparison>) -> Result<&2,&2,String,Improvement>:
  match result:
    case Fail{e}: Fail{e}
    case Done{+comparison}:
      Done{Improvement{initial,chosen(comparison),1n+index,left,Trial{index,comparison} <> history}}
def propose_once(initial: P.Policy,current: P.Policy,episodes: +List<Episode>,index: Nat,remaining: Nat,
                 history: +List<Trial>,proposal: Maybe<&2,P.Policy>) -> Result<&2,&2,String,Improvement>:
  match remaining proposal:
    case _ None{}: Done{Improvement{initial,current,index,remaining,history}}
    case 0n Some{candidate}: Fail{"meta revision allowance invariant"}
    case 1n+left Some{candidate}: record(initial,index,left,history,compare(current,candidate,episodes))
def resume(result: Result<&2,&2,String,Improvement>,next: Improvement -> Result<&2,&2,String,Improvement>) -> Result<&2,&2,String,Improvement>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: next(state)
def advance(fuel: Nat,+episodes: +List<Episode>,state: Improvement) -> Result<&2,&2,String,Improvement>:
  match fuel state:
    case 0n _: Done{state}
    case 1n+p Improvement{initial,current,index,0n,history}: Done{Improvement{initial,current,index,0n,history}}
    case 1n+p Improvement{initial,+current,+index,1n+left,history}:
      resume(propose_once(initial,current,episodes,index,1n+left,history,
        Policy.propose(current,context(episodes),index)),s => advance(p,episodes,s))
def improve(+p: P.Policy,episodes: +List<Episode>,+cap: Nat) -> Result<&2,&2,String,Improvement>:
  advance(cap,episodes,Improvement{p,p,0n,cap,Nil{}})
