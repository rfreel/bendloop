import Base
import ./types.bend as P
import ./search.bend as Search
import ./experiment.bend as E
import ./learning.bend as L
import ./recursive.bend as Rec
import ../search/render.bend as J

def boolean(b: Bool) -> String:
  match b:
    case False{}: "false"
    case True{}: "true"
def order(m: P.Order) -> String:
  match m:
    case P.ZeroFirst{}: "zero-first"
    case P.OnesFirst{}: "ones-first"
    case P.RootAware{}: "root-aware"
def policy(p: P.Policy) -> String:
  P.Policy{z,o,m} = p
  "{\"zero\":" ++ boolean(z) ++ ",\"ones\":" ++ boolean(o) ++ ",\"order\":\"" ++ order(m) ++ "\"}"
def nat_items(xs: +List<Nat>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: Nat.show(x)
    case Con{x,tail}: Nat.show(x) ++ "," ++ nat_items(tail)
def trial(t: Search.Trial) -> String:
  Search.Trial{rank,source,candidate,checks,equivalent,admitted} = t
  "{\"rank\":" ++ Nat.show(rank) ++ ",\"grammar_rank\":" ++ Nat.show(source) ++
  ",\"candidate\":[" ++ J.tokens(candidate) ++ "],\"checked_inputs\":" ++ Nat.show(checks) ++
  ",\"equivalent\":" ++ boolean(equivalent) ++ ",\"admitted\":" ++ boolean(admitted) ++ "}"
def trials(xs: +List<Search.Trial>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: trial(x)
    case Con{x,tail}: trial(x) ++ "," ++ trials(tail)
def observation(o: Search.Observation) -> String:
  Search.Observation{attempts,left,cost,improved,checks,nodes,history} = o
  "{\"attempts\":" ++ Nat.show(attempts) ++ ",\"remaining\":" ++ Nat.show(left) ++
  ",\"best_cost\":" ++ Nat.show(cost) ++ ",\"improved\":" ++ boolean(improved) ++
  ",\"checked_inputs\":" ++ Nat.show(checks) ++ ",\"verification_nodes\":" ++ Nat.show(nodes) ++
  ",\"trials_newest_first\":[" ++ trials(history) ++ "]}"
def observations(xs: +List<Search.Observation>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: observation(x)
    case Con{x,tail}: observation(x) ++ "," ++ observations(tail)
def profile(p: E.Profile) -> String:
  E.Profile{costs,attempts,checks,nodes,history} = p
  "{\"costs\":[" ++ nat_items(costs) ++ "],\"attempts\":" ++ Nat.show(attempts) ++
  ",\"checked_inputs\":" ++ Nat.show(checks) ++ ",\"verification_nodes\":" ++ Nat.show(nodes) ++
  ",\"observations\":[" ++ observations(history) ++ "]}"
def comparison(c: E.Comparison) -> String:
  E.Comparison{before,proposed,a,b,accepted} = c
  "{\"before\":" ++ policy(before) ++ ",\"proposed\":" ++ policy(proposed) ++
  ",\"old\":" ++ profile(a) ++ ",\"new\":" ++ profile(b) ++ ",\"accepted\":" ++ boolean(accepted) ++ "}"
def revision(t: E.RevisionTrial) -> String:
  E.RevisionTrial{i,c} = t
  "{\"index\":" ++ Nat.show(i) ++ ",\"comparison\":" ++ comparison(c) ++ "}"
def revisions(xs: +List<E.RevisionTrial>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: revision(x)
    case Con{x,tail}: revision(x) ++ "," ++ revisions(tail)
def adaptation(a: E.Adaptation) -> String:
  E.Adaptation{initial,final,count,left,history} = a
  "{\"initial\":" ++ policy(initial) ++ ",\"final\":" ++ policy(final) ++
  ",\"proposed\":" ++ Nat.show(count) ++ ",\"remaining\":" ++ Nat.show(left) ++
  ",\"history_newest_first\":[" ++ revisions(history) ++ "]}"
def episode(e: L.EpisodeResult) -> String:
  L.EpisodeResult{before,after,learned} = e
  "{\"cold\":" ++ profile(before) ++ ",\"after\":" ++ profile(after) ++ ",\"adaptation\":" ++ adaptation(learned) ++ "}"
def episodes(xs: +List<L.EpisodeResult>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: episode(x)
    case Con{x,tail}: episode(x) ++ "," ++ episodes(tail)
def learning_profile(p: L.Profile) -> String:
  L.Profile{cold,after,proposals,L.Work{attempts,checks,nodes},history} = p
  "{\"cold_costs\":[" ++ nat_items(cold) ++ "],\"after_costs\":[" ++ nat_items(after) ++
  "],\"policy_proposals\":" ++ Nat.show(proposals) ++ ",\"candidate_attempts\":" ++ Nat.show(attempts) ++
  ",\"checked_inputs\":" ++ Nat.show(checks) ++ ",\"verification_nodes\":" ++ Nat.show(nodes) ++
  ",\"episodes\":[" ++ episodes(history) ++ "]}"
def learning_comparison(c: L.Comparison) -> String:
  L.Comparison{before,proposed,a,b,accepted} = c
  "{\"before\":" ++ policy(before) ++ ",\"proposed\":" ++ policy(proposed) ++
  ",\"old\":" ++ learning_profile(a) ++ ",\"new\":" ++ learning_profile(b) ++
  ",\"accepted\":" ++ boolean(accepted) ++ "}"
def meta_trial(t: L.Trial) -> String:
  L.Trial{i,c} = t
  "{\"index\":" ++ Nat.show(i) ++ ",\"comparison\":" ++ learning_comparison(c) ++ "}"
def meta_trials(xs: +List<L.Trial>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: meta_trial(x)
    case Con{x,tail}: meta_trial(x) ++ "," ++ meta_trials(tail)
def improvement(i: L.Improvement) -> String:
  L.Improvement{before,after,count,left,history} = i
  "{\"initial\":" ++ policy(before) ++ ",\"final\":" ++ policy(after) ++
  ",\"proposed\":" ++ Nat.show(count) ++ ",\"remaining\":" ++ Nat.show(left) ++
  ",\"history_newest_first\":[" ++ meta_trials(history) ++ "]}"
def cycles(xs: +List<E.Adaptation>) -> String:
  match xs:
    case Nil{}: ""
    case Con{x,Nil{}}: adaptation(x)
    case Con{x,tail}: adaptation(x) ++ "," ++ cycles(tail)
def branch_details(b: Rec.Branch,gain: Nat,effort: L.Work) -> String:
  Rec.Branch{before,after,cap,used,left,accepted,history} = b
  L.Work{attempts,checks,nodes} = effort
  "{\"initial\":" ++ policy(before) ++ ",\"final\":" ++ policy(after) ++
  ",\"cap\":" ++ Nat.show(cap) ++ ",\"proposed\":" ++ Nat.show(used) ++
  ",\"remaining\":" ++ Nat.show(left) ++ ",\"accepted\":" ++ Nat.show(accepted) ++
  ",\"accepted_cost_reduction\":" ++ Nat.show(gain) ++ ",\"candidate_attempts\":" ++ Nat.show(attempts) ++
  ",\"checked_inputs\":" ++ Nat.show(checks) ++ ",\"verification_nodes\":" ++ Nat.show(nodes) ++
  ",\"cycles_newest_first\":[" ++ cycles(history) ++ "]}"
def branch(+b: Rec.Branch) -> String:
  branch_details(b,Rec.gain(b),Rec.work(b))
