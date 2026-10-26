import Base
import ../synthesis/certificates/equality.bend as Equality

type Permission is Data:
  Denied{}
  PublishResult{}
type Contract<-K: Data> is Data:
  Contract{task: Nat,epoch: Nat,evaluator: Nat,permission: Permission,requirements: K}
type Worker<-A: Data> is Data:
  Proposal{task: Nat,epoch: Nat,artifact: A,claims: String}
type Action<-K: Data,-A: Data> is Data:
  Ingress{message: Worker<A>}
  Freeze{}
  Evaluate{}
  Compare{}
  Commit{}
  Replace{contract: Contract<K>,fallback: A}
  Expire{}
  Crash{}
  Recover{}
type Mode is Data:
  Running{}
  Crashed{}
  Finished{}
type Qualified<-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-c: Contract<K>> is Type:
  Qualified{artifact: A,proof: {check(c,artifact) == True{} : Bool}}
type Stage<-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-c: Contract<K>> is Type:
  Idle{}
  Offered{message: Worker<A>}
  Frozen{artifact: A}
  Measured{qualified: Qualified<K,A,check,c>}
type State<-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-cap: Nat> is Type:
  State{contract: Contract<K>,spent: Nat,left: Nat,
    conserved: {Nat.add(spent,left) == cap : Nat},mode: Mode,
    stage: Stage<K,A,check,contract>,incumbent: Maybe<&1,Qualified<K,A,check,contract>>}
def permission(-K: Data,c: Contract<K>) -> Permission:
  Contract{task,epoch,evaluator,p,requirements} = c
  p

type Effect<-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-c: Contract<K>> is Type:
  NoEffect{}
  Failure{}
  Publish{sequence: Nat,artifact: A,qualified: {check(c,artifact) == True{} : Bool},
    permitted: {permission(K,c) == PublishResult{} : Permission}}
def current(-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-cap: Nat,state: State<K,A,check,cap>) -> Contract<K>:
  State{c,s,l,p,m,stage,incumbent} = state
  c
type Transition<-K: Data,-A: Data,-check: Contract<K> -> A -> Bool,-cap: Nat> is Type:
  Transition{state: State<K,A,check,cap>,effect: Effect<K,A,check,current(K,A,check,cap,state)>}
def qualify_decided(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,
  +c: Contract<K>,a: A,d: Equality.Decision<{check(c,a) == True{} : Bool}>) -> Maybe<&1,Qualified<K,A,check,c>>:
  match d:
    case Equality.Yes{p}: Some{Qualified{a,p}}
    case Equality.No{refute}: None{}
def qualify(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,+a: A) -> Maybe<&1,Qualified<K,A,check,c>>:
  qualify_decided(K,A,check,c,a,Equality.decide_bool(check(c,a),True{}))
def seed(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,+cap: Nat,fallback: A) -> State<K,A,check,cap>:
  State{c,0n,cap,{==},Running{},Idle{},qualify(K,A,check,c,fallback)}
def unchanged(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-cap: Nat,state: State<K,A,check,cap>) -> Transition<K,A,check,cap>:
  Transition{state,NoEffect{}}
def finish_permission(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-cap: Nat,
  +c: Contract<K>,+spent: Nat,left: Nat,p: {Nat.add(spent,left) == cap : Nat},incumbent: Maybe<&1,Qualified<K,A,check,c>>,
  permit: Permission,equal: {permission(K,c) == permit : Permission}) -> Transition<K,A,check,cap>:
  match incumbent permit:
    case None{} _: Transition{State{c,spent,left,p,Finished{},Idle{},None{}},Failure{}}
    case Some{Qualified{a,q}} Denied{}: Transition{State{c,spent,left,p,Finished{},Idle{},None{}},Failure{}}
    case Some{Qualified{+a,+q}} PublishResult{}:
      Transition{State{c,spent,left,p,Finished{},Idle{},Some{Qualified{a,q}}},Publish{spent,a,q,equal}}
def finish(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-cap: Nat,+c: Contract<K>,spent: Nat,left: Nat,
  p: {Nat.add(spent,left) == cap : Nat},incumbent: Maybe<&1,Qualified<K,A,check,c>>) -> Transition<K,A,check,cap>:
  finish_permission(K,A,check,cap,c,spent,left,p,incumbent,permission(K,c),{==})
def same_task(-K: Data,+c: Contract<K>,task: Nat,epoch: Nat) -> Bool:
  Contract{t,e,v,p,k} = c
  Nat.is_eq(t,task) && Nat.is_eq(e,epoch)
def offered(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-c: Contract<K>,message: Worker<A>,ok: Bool) -> Stage<K,A,check,c>:
  match ok:
    case False{}: Idle{}
    case True{}: Offered{message}
def frozen_if(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-c: Contract<K>,a: A,ok: Bool) -> Stage<K,A,check,c>:
  match ok:
    case False{}: Idle{}
    case True{}: Frozen{a}
def freeze_message(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,message: Worker<A>) -> Stage<K,A,check,c>:
  match message:
    case Proposal{task,epoch,a,claims}: frozen_if(K,A,check,c,a,same_task(K,c,task,epoch))
def evaluated(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-c: Contract<K>,q: Maybe<&1,Qualified<K,A,check,c>>) -> Stage<K,A,check,c>:
  match q:
    case None{}: Idle{}
    case Some{value}: Measured{value}
def select_if(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-c: Contract<K>,
  candidate: Qualified<K,A,check,c>,old: Qualified<K,A,check,c>,better: Bool) -> Qualified<K,A,check,c>:
  match better:
    case False{}: old
    case True{}: candidate
def select(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,
  +c: Contract<K>,candidate: Qualified<K,A,check,c>,old: Maybe<&1,Qualified<K,A,check,c>>) -> Maybe<&1,Qualified<K,A,check,c>>:
  match candidate old:
    case _ None{}: Some{candidate}
    case Qualified{+a,p} Some{Qualified{+b,q}}:
      Some{select_if(K,A,check,c,Qualified{a,p},Qualified{b,q},Nat.is_lt(score(c,a),score(c,b)))}
def receive(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,stage: Stage<K,A,check,c>,+message: Worker<A>) -> Stage<K,A,check,c>:
  match stage message:
    case Idle{} Proposal{task,epoch,a,claims}: offered(K,A,check,c,message,same_task(K,c,task,epoch))
    case _ _: stage
def freeze(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,stage: Stage<K,A,check,c>) -> Stage<K,A,check,c>:
  match stage:
    case Offered{message}: freeze_message(K,A,check,c,message)
    case _: stage
def evaluate(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,+c: Contract<K>,stage: Stage<K,A,check,c>) -> Stage<K,A,check,c>:
  match stage:
    case Frozen{a}: evaluated(K,A,check,c,qualify(K,A,check,c,a))
    case _: stage
def compared(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,-cap: Nat,
  +c: Contract<K>,spent: Nat,left: Nat,p: {Nat.add(spent,left) == cap : Nat},stage: Stage<K,A,check,c>,inc: Maybe<&1,Qualified<K,A,check,c>>) -> State<K,A,check,cap>:
  match stage:
    case Measured{candidate}: State{c,spent,left,p,Running{},Idle{},select(K,A,check,score,c,candidate,inc)}
    case _: State{c,spent,left,p,Running{},stage,inc}
def running(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,-cap: Nat,
  +c: Contract<K>,spent: Nat,left: Nat,p: {Nat.add(spent,left) == cap : Nat},stage: Stage<K,A,check,c>,inc: Maybe<&1,Qualified<K,A,check,c>>,
  action: Action<K,A>) -> Transition<K,A,check,cap>:
  match action:
    case Ingress{m}: unchanged(K,A,check,cap,State{c,spent,left,p,Running{},receive(K,A,check,c,stage,m),inc})
    case Freeze{}: unchanged(K,A,check,cap,State{c,spent,left,p,Running{},freeze(K,A,check,c,stage),inc})
    case Evaluate{}: unchanged(K,A,check,cap,State{c,spent,left,p,Running{},evaluate(K,A,check,c,stage),inc})
    case Compare{}: unchanged(K,A,check,cap,compared(K,A,check,score,cap,c,spent,left,p,stage,inc))
    case Commit{}: finish(K,A,check,cap,c,spent,left,p,inc)
    case Expire{}: finish(K,A,check,cap,c,spent,left,p,inc)
    case Replace{+next,fallback}: unchanged(K,A,check,cap,State{next,spent,left,p,Running{},Idle{},qualify(K,A,check,next,fallback)})
    case Crash{}: unchanged(K,A,check,cap,State{c,spent,left,p,Crashed{},stage,inc})
    case Recover{}: unchanged(K,A,check,cap,State{c,spent,left,p,Running{},stage,inc})
def operate(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,-cap: Nat,
  +c: Contract<K>,spent: Nat,left: Nat,p: {Nat.add(spent,left) == cap : Nat},mode: Mode,
  stage: Stage<K,A,check,c>,inc: Maybe<&1,Qualified<K,A,check,c>>,action: Action<K,A>) -> Transition<K,A,check,cap>:
  match mode action:
    case Running{} _: running(K,A,check,score,cap,c,spent,left,p,stage,inc,action)
    case Finished{} _: unchanged(K,A,check,cap,State{c,spent,left,p,Finished{},stage,inc})
    case Crashed{} Recover{}: unchanged(K,A,check,cap,State{c,spent,left,p,Running{},stage,inc})
    case Crashed{} Expire{}: finish(K,A,check,cap,c,spent,left,p,inc)
    case Crashed{} _: unchanged(K,A,check,cap,State{c,spent,left,p,Crashed{},stage,inc})
def add_succ(a: Nat,b: Nat) -> {Nat.add(a,1n+b) == 1n+Nat.add(a,b) : Nat}:
  match a:
    case 0n: {==}
    case 1n+p: Equal.cong(Nat,Nat,n => 1n+n,Nat.add(p,1n+b),1n+Nat.add(p,b),add_succ(p,b))
def charged(+spent: Nat,+left: Nat,-cap: Nat,p: {Nat.add(spent,1n+left) == cap : Nat}) -> {Nat.add(1n+spent,left) == cap : Nat}:
  Equal.trans(Nat,1n+Nat.add(spent,left),Nat.add(spent,1n+left),cap,
    Equal.sym(Nat,Nat.add(spent,1n+left),1n+Nat.add(spent,left),add_succ(spent,left)),p)
def epoch(-K: Data,c: Contract<K>) -> Nat:
  Contract{task,epoch,evaluator,permission,requirements} = c
  epoch
def replace_if(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-cap: Nat,
  state: State<K,A,check,cap>,+next: Contract<K>,fallback: A,ok: Bool) -> Transition<K,A,check,cap>:
  match state ok:
    case _ False{}: unchanged(K,A,check,cap,state)
    case State{c,spent,left,p,mode,stage,inc} True{}:
      unchanged(K,A,check,cap,State{next,spent,left,p,Running{},Idle{},qualify(K,A,check,next,fallback)})
def replace(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,-cap: Nat,
  state: State<K,A,check,cap>,+next: Contract<K>,fallback: A) -> Transition<K,A,check,cap>:
  match state:
    case State{+c,spent,left,p,mode,stage,inc}:
      replace_if(K,A,check,cap,State{c,spent,left,p,mode,stage,inc},next,fallback,Nat.is_lt(epoch(K,c),epoch(K,next)))
def budgeted(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,-cap: Nat,
  state: State<K,A,check,cap>,action: Action<K,A>) -> Transition<K,A,check,cap>:
  match state:
    case State{c,spent,left,p,Finished{},stage,inc}: unchanged(K,A,check,cap,state)
    case State{+c,+spent,0n,p,mode,stage,inc}: finish(K,A,check,cap,c,spent,0n,p,inc)
    case State{+c,+spent,1n+remaining,p,mode,stage,inc}:
      +left = remaining
      operate(K,A,check,score,cap,c,1n+spent,left,charged(spent,left,cap,p),mode,stage,inc,action)
def step(~K: Data,~A: Data,~check: Contract<K> -> A -> Bool,~score: Contract<K> -> A -> Nat,-cap: Nat,
  state: State<K,A,check,cap>,action: Action<K,A>) -> Transition<K,A,check,cap>:
  match action:
    case Replace{next,fallback}: replace(K,A,check,cap,state,next,fallback)
    case _: budgeted(K,A,check,score,cap,state,action)
