import Base
import ./LAWS.bend as Laws
import ./types.bend as P
import ./runtime.bend as R
import ./spec.bend as S
import ./search.bend as Search
import ./experiment.bend as Experiment
import ./learning.bend as Learning
import ./accounting.bend as Accounting
import ../interpreter/runtime.bend as I
import ../interpreter/bridge.bend as B

def Laws.rank_refines(priority,n):
  match priority n:
    case P.Original{} _: {==}
    case P.SeedZero{} 0n: {==}
    case P.SeedZero{} 1n: {==}
    case P.SeedZero{} 2n+p: {==}
    case P.SeedOnes{} 0n: {==}
    case P.SeedOnes{} 1n: {==}
    case P.SeedOnes{} 2n: {==}
    case P.SeedOnes{} 3n: {==}
    case P.SeedOnes{} 4n: {==}
    case P.SeedOnes{} 5n: {==}
    case P.SeedOnes{} 6n: {==}
    case P.SeedOnes{} 7n: {==}
    case P.SeedOnes{} 8n: {==}
    case P.SeedOnes{} 9n: {==}
    case P.SeedOnes{} 10n: {==}
    case P.SeedOnes{} 11n: {==}
    case P.SeedOnes{} 12n: {==}
    case P.SeedOnes{} 13n: {==}
    case P.SeedOnes{} 14n: {==}
    case P.SeedOnes{} 15n: {==}
    case P.SeedOnes{} 16n: {==}
    case P.SeedOnes{} 17n+p: {==}

def Laws.rank_involution(priority,n):
  match priority n:
    case P.Original{} _: {==}
    case P.SeedZero{} 0n: {==}
    case P.SeedZero{} 1n: {==}
    case P.SeedZero{} 2n+p: {==}
    case P.SeedOnes{} 0n: {==}
    case P.SeedOnes{} 1n: {==}
    case P.SeedOnes{} 2n: {==}
    case P.SeedOnes{} 3n: {==}
    case P.SeedOnes{} 4n: {==}
    case P.SeedOnes{} 5n: {==}
    case P.SeedOnes{} 6n: {==}
    case P.SeedOnes{} 7n: {==}
    case P.SeedOnes{} 8n: {==}
    case P.SeedOnes{} 9n: {==}
    case P.SeedOnes{} 10n: {==}
    case P.SeedOnes{} 11n: {==}
    case P.SeedOnes{} 12n: {==}
    case P.SeedOnes{} 13n: {==}
    case P.SeedOnes{} 14n: {==}
    case P.SeedOnes{} 15n: {==}
    case P.SeedOnes{} 16n: {==}
    case P.SeedOnes{} 17n+p: {==}
def Laws.rank_injective(priority,a,b,equal):
  Equal.trans(Nat,a,R.rank(priority,R.rank(priority,a)),b,
    Equal.sym(Nat,R.rank(priority,R.rank(priority,a)),a,Laws.rank_involution(priority,a)),
    Equal.trans(Nat,R.rank(priority,R.rank(priority,a)),R.rank(priority,R.rank(priority,b)),b,
      Equal.cong(Nat,Nat,n => R.rank(priority,n),R.rank(priority,a),R.rank(priority,b),equal),
      Laws.rank_involution(priority,b)))
def Laws.rank_surjective(priority,target):
  (R.rank(priority,target),Laws.rank_involution(priority,target))
def and_eq(-a: Bool, -b: Bool, -c: Bool, -d: Bool,
  x: {a == b : Bool}, y: {c == d : Bool}) -> {a && c == b && d : Bool}:
  %x : {a && c == _ && d : Bool}
  %y : {a && c == a && _ : Bool}
  {==}
def or_eq(-a: Bool, -b: Bool, -c: Bool, -d: Bool,
  x: {a == b : Bool}, y: {c == d : Bool}) -> {a || c == b || d : Bool}:
  %x : {a || c == _ || d : Bool}
  %y : {a || c == a || _ : Bool}
  {==}
def expr_same(+a: I.Expr, +b: I.Expr) ->
  {R.expr_same(a,b) == S.expr_same(B.model(a),B.model(b)) : Bool}:
  match a b:
    case I.Input{} I.Input{}:
      {==}
    case I.Input{} I.Constant{xb}:
      {==}
    case I.Input{} I.Not{xb}:
      {==}
    case I.Input{} I.And{xb,yb}:
      {==}
    case I.Input{} I.Or{xb,yb}:
      {==}
    case I.Input{} I.Xor{xb,yb}:
      {==}
    case I.Constant{xa} I.Input{}:
      {==}
    case I.Constant{I.Bits{a0,a1,a2,a3}} I.Constant{I.Bits{b0,b1,b2,b3}}:
      {==}
    case I.Constant{xa} I.Not{xb}:
      {==}
    case I.Constant{xa} I.And{xb,yb}:
      {==}
    case I.Constant{xa} I.Or{xb,yb}:
      {==}
    case I.Constant{xa} I.Xor{xb,yb}:
      {==}
    case I.Not{xa} I.Input{}:
      {==}
    case I.Not{xa} I.Constant{xb}:
      {==}
    case I.Not{xa} I.Not{xb}:
      expr_same(xa,xb)
    case I.Not{xa} I.And{xb,yb}:
      {==}
    case I.Not{xa} I.Or{xb,yb}:
      {==}
    case I.Not{xa} I.Xor{xb,yb}:
      {==}
    case I.And{xa,ya} I.Input{}:
      {==}
    case I.And{xa,ya} I.Constant{xb}:
      {==}
    case I.And{xa,ya} I.Not{xb}:
      {==}
    case I.And{xa,ya} I.And{xb,yb}:
      and_eq(R.expr_same(xa,xb),S.expr_same(B.model(xa),B.model(xb)),R.expr_same(ya,yb),S.expr_same(B.model(ya),B.model(yb)),expr_same(xa,xb),expr_same(ya,yb))
    case I.And{xa,ya} I.Or{xb,yb}:
      {==}
    case I.And{xa,ya} I.Xor{xb,yb}:
      {==}
    case I.Or{xa,ya} I.Input{}:
      {==}
    case I.Or{xa,ya} I.Constant{xb}:
      {==}
    case I.Or{xa,ya} I.Not{xb}:
      {==}
    case I.Or{xa,ya} I.And{xb,yb}:
      {==}
    case I.Or{xa,ya} I.Or{xb,yb}:
      and_eq(R.expr_same(xa,xb),S.expr_same(B.model(xa),B.model(xb)),R.expr_same(ya,yb),S.expr_same(B.model(ya),B.model(yb)),expr_same(xa,xb),expr_same(ya,yb))
    case I.Or{xa,ya} I.Xor{xb,yb}:
      {==}
    case I.Xor{xa,ya} I.Input{}:
      {==}
    case I.Xor{xa,ya} I.Constant{xb}:
      {==}
    case I.Xor{xa,ya} I.Not{xb}:
      {==}
    case I.Xor{xa,ya} I.And{xb,yb}:
      {==}
    case I.Xor{xa,ya} I.Or{xb,yb}:
      {==}
    case I.Xor{xa,ya} I.Xor{xb,yb}:
      and_eq(R.expr_same(xa,xb),S.expr_same(B.model(xa),B.model(xb)),R.expr_same(ya,yb),S.expr_same(B.model(ya),B.model(yb)),expr_same(xa,xb),expr_same(ya,yb))
def zero_constant(e: I.Expr) -> {R.zero_constant(e) == S.zero_constant(B.model(e)) : Bool}:
  match e:
    case I.Input{}: {==}
    case I.Constant{I.Bits{b0,b1,b2,b3}}: {==}
    case I.Not{x}: {==}
    case I.And{x,y}: {==}
    case I.Or{x,y}: {==}
    case I.Xor{x,y}: {==}
def ones_constant(e: I.Expr) -> {R.ones_constant(e) == S.ones_constant(B.model(e)) : Bool}:
  match e:
    case I.Input{}: {==}
    case I.Constant{I.Bits{b0,b1,b2,b3}}: {==}
    case I.Not{x}: {==}
    case I.And{x,y}: {==}
    case I.Or{x,y}: {==}
    case I.Xor{x,y}: {==}
def zero_form(+e: I.Expr) -> {R.zero_form(e) == S.zero_form(B.model(e)) : Bool}:
  match e:
    case I.Xor{a,b}: expr_same(a,b)
    case I.And{+a,+b}: or_eq(R.zero_constant(a),S.zero_constant(B.model(a)),R.zero_constant(b),S.zero_constant(B.model(b)),zero_constant(a),zero_constant(b))
    case I.Input{}: {==}
    case I.Constant{b}: {==}
    case I.Not{x}: {==}
    case I.Or{a,b}: {==}
def ones_form(+e: I.Expr) -> {R.ones_form(e) == S.ones_form(B.model(e)) : Bool}:
  match e:
    case I.Or{+a,+b}: or_eq(R.ones_constant(a),S.ones_constant(B.model(a)),R.ones_constant(b),S.ones_constant(B.model(b)),ones_constant(a),ones_constant(b))
    case I.Not{x}: zero_constant(x)
    case I.Input{}: {==}
    case I.Constant{b}: {==}
    case I.And{a,b}: {==}
    case I.Xor{a,b}: {==}
def select(z: Bool,o: Bool) -> {R.select(z,o) == S.select(z,o) : P.Priority}:
  match z o:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} True{}: {==}
    case False{} False{}: {==}
def selects(a: Bool,-b: Bool,c: Bool,-d: Bool,
  x: {a == b : Bool},y: {c == d : Bool}) -> {R.select(a,c) == S.select(b,d) : P.Priority}:
  %x : {R.select(a,c) == S.select(_,d) : P.Priority}
  %y : {R.select(a,c) == S.select(a,_) : P.Priority}
  select(a,c)
def Laws.priority_refines(p,reference):
  match p:
    case P.Policy{z,o,m}:
      selects(z && R.zero_form(reference),z && S.zero_form(B.model(reference)),
        o && R.ones_form(reference),o && S.ones_form(B.model(reference)),
        and_eq(z,z,R.zero_form(reference),S.zero_form(B.model(reference)),{==},zero_form(reference)),
        and_eq(o,o,R.ones_form(reference),S.ones_form(B.model(reference)),{==},ones_form(reference)))
def prefer(p: P.Policy,z: Bool) -> {R.prefer(p,z) == S.prefer(p,z) : Maybe<&2,P.Policy>}:
  match p z:
    case P.Policy{a,b,m} True{}: {==}
    case P.Policy{a,b,m} False{}: {==}
def ordered(+p: P.Policy,+task: I.Expr,index: Nat,m: P.Order) ->
  {R.by_order(p,task,index,m) == S.propose_order(p,B.model(task),index,m) : Maybe<&2,P.Policy>}:
  match p index m:
    case P.Policy{a,b,old} 0n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 0n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 0n P.RootAware{}:
      %zero_form(task) : {R.prefer(p,R.zero_form(task)) == S.prefer(p,_) : Maybe<&2,P.Policy>}
      prefer(p,R.zero_form(task))
    case P.Policy{a,b,old} 1n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 1n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 1n P.RootAware{}:
      %zero_form(task) : {R.prefer(p,Bool.not(R.zero_form(task))) == S.prefer(p,Bool.not(_)) : Maybe<&2,P.Policy>}
      prefer(p,Bool.not(R.zero_form(task)))
    case P.Policy{a,b,old} 2n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 2n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 2n P.RootAware{}:
      {==}
    case P.Policy{a,b,old} 3n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 3n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 3n P.RootAware{}:
      {==}
    case P.Policy{a,b,old} 4n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 4n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 4n P.RootAware{}:
      {==}
    case P.Policy{a,b,old} 5n+n P.ZeroFirst{}:
      {==}
    case P.Policy{a,b,old} 5n+n P.OnesFirst{}:
      {==}
    case P.Policy{a,b,old} 5n+n P.RootAware{}:
      {==}
def Laws.proposal_refines(p,task,index):
  match p:
    case P.Policy{z,o,m}: ordered(p,task,index,m)
def Laws.zero_quota_preserves_state(state): {==}
def resume_result(a: Nat,b: Nat,result: Result<&2,&1,String,Search.State>,
  next: @state: Search.State -> {Search.advance(Nat.add(a,b),state) == Search.continue(Search.advance(a,state),s => Search.advance(b,s)) : Result<&2,&1,String,Search.State>}) ->
  {Search.continue(result,s => Search.advance(Nat.add(a,b),s)) == Search.continue(Search.continue(result,s => Search.advance(a,s)),s => Search.advance(b,s)) : Result<&2,&1,String,Search.State>}:
  match result:
    case Fail{e}: {==}
    case Done{s}: next(s)
def Laws.resume_composes(a,b,state):
  match a:
    case 0n: {==}
    case 1n++p: resume_result(p,b,Search.step(state),s => Laws.resume_composes(p,b,s))

def Laws.budget_conserved(q,policy,reference,ops,bound,cap,spent,left,best,trials,valid):
  Accounting.advance(q,policy,reference,ops,bound,cap,spent,left,best,trials,cap,valid)

def no_worse(+a: +List<Nat>,+b: +List<Nat>) -> {Experiment.no_worse(a,b) == S.no_worse(a,b) : Bool}:
  match a b:
    case Nil{} Nil{}: {==}
    case Con{x,xs} Con{y,ys}: and_eq(Nat.is_le(x,y),Nat.is_le(x,y),Experiment.no_worse(xs,ys),S.no_worse(xs,ys),{==},no_worse(xs,ys))
    case Nil{} Con{y,ys}: {==}
    case Con{x,xs} Nil{}: {==}
def better(+a: +List<Nat>,+b: +List<Nat>) -> {Experiment.better(a,b) == S.better(a,b) : Bool}:
  match a b:
    case Nil{} Nil{}: {==}
    case Con{x,xs} Con{y,ys}: or_eq(Nat.is_lt(x,y),Nat.is_lt(x,y),Experiment.better(xs,ys),S.better(xs,ys),{==},better(xs,ys))
    case Nil{} Con{y,ys}: {==}
    case Con{x,xs} Nil{}: {==}
def equal_costs(+a: +List<Nat>,+b: +List<Nat>) -> {Experiment.equal_costs(a,b) == S.equal_costs(a,b) : Bool}:
  match a b:
    case Nil{} Nil{}: {==}
    case Con{x,xs} Con{y,ys}: and_eq(Nat.is_eq(x,y),Nat.is_eq(x,y),Experiment.equal_costs(xs,ys),S.equal_costs(xs,ys),{==},equal_costs(xs,ys))
    case Nil{} Con{y,ys}: {==}
    case Con{x,xs} Nil{}: {==}
def Laws.comparison_gate(new,old):
  match new old:
    case Experiment.Profile{+a,aa,ai,an,at} Experiment.Profile{+b,ba,bi,bn,bt}:
      and_eq(Experiment.no_worse(a,b),S.no_worse(a,b),Experiment.better(a,b),S.better(a,b),no_worse(a,b),better(a,b))
def Laws.learning_gate(new,old):
  match new old:
    case Learning.Profile{+ac,+aw,ap,ae,at} Learning.Profile{+bc,+bw,bp,be,bt}:
      and_eq(Experiment.equal_costs(ac,bc) && Experiment.no_worse(aw,bw),S.equal_costs(ac,bc) && S.no_worse(aw,bw),Experiment.better(aw,bw),S.better(aw,bw),
        and_eq(Experiment.equal_costs(ac,bc),S.equal_costs(ac,bc),Experiment.no_worse(aw,bw),S.no_worse(aw,bw),equal_costs(ac,bc),no_worse(aw,bw)),better(aw,bw))
def Laws.installs_evaluated_policy(old,candidate,a,b): {==}
def Laws.installs_evaluated_learner(old,candidate,a,b): {==}

def knowledge(a: P.Policy,b: P.Policy) -> {Learning.same_knowledge(a,b) == S.same_knowledge(a,b) : Bool}:
  match a b:
    case P.Policy{az,ao,am} P.Policy{bz,bo,bm}: {==}
def Laws.learning_comparison_gate(before,proposed,old,new):
  %Laws.learning_gate(new,old) : {Learning.compared(before,proposed,Done{old},Done{new}) ==
    Done{Learning.Comparison{before,proposed,old,new,S.same_knowledge(before,proposed) && _}} : Result<&2,&2,String,Learning.Comparison>}
  %knowledge(before,proposed) : {Learning.compared(before,proposed,Done{old},Done{new}) ==
    Done{Learning.Comparison{before,proposed,old,new,_ && Learning.accepts(new,old)}} : Result<&2,&2,String,Learning.Comparison>}
  {==}

def Laws.compares_executed_policies(old,candidate,tasks): {==}
def Laws.compares_executed_learners(old,candidate,episodes): {==}
def Laws.zero_adaptation(p,task,protected): {==}
def Laws.zero_meta_revision(p,episodes): {==}
def Laws.zero_recursive_revision(tasks,protected,p):
  match tasks:
    case Nil{}: {==}
    case Con{task,tail}: {==}
