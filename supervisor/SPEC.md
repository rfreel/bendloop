# Supervisor contract

Authorized scope: the owner's receiver-supervisor/TLA+/Bend/hostile-worker request
in this conversation. This adds a coordination and effect boundary without changing
the original four-bit semantics, v1 obligations or external factory authority.

## Inputs and authority

`Contract<K>` contains receiver task identity, strictly advancing contract generation,
evaluator identity, publication permission and task-specific requirements. The initial
state also receives an action allowance and a proposed fallback. `check(contract,a)`
and `score(contract,a)` are fixed receiver code. Worker messages have only task/epoch
claims, an artifact and arbitrary claim text. They contain no proof constructor,
contract-change capability, accepted-state field or effect instruction.

`Action.Ingress` wraps worker data. Freeze, evaluate, compare, commit, replace, expire,
crash and recover are receiver control actions. This distinction is enforced at host
dispatch, not by pretending a public datatype constructor is a security capability.
The native stdin contract/event-building interface is receiver-only. The worker
endpoint accepts token arrays only. Another worker's review is ordinary claim text.

## Pure transitions

The public task API delegates directly to generic `step(state,action)`:

- A matching proposal occupies an idle slot. It cannot overwrite a frozen candidate.
- Freeze binds exact artifact value to the current contract. Evaluation runs the
  receiver checker and constructs live qualification evidence or rejects the proposal.
- Compare installs a measured candidate only if no incumbent exists or the declared
  receiver score is strictly smaller. Equal score keeps the incumbent. No worker-
  provided measurement or Boolean is used.
- Commit/expiry emits only the current qualified incumbent with current publication
  permission, or a permitted failure. The state becomes finished. Ordinary later
  worker events cannot publish again.
- Strictly advancing replacement takes precedence over exhausted/finished handling.
  It clears old pending evidence and rechecks the receiver fallback under the new
  contract. It does not renew action allowance. Rollback/nonadvancing replacement
  is ignored. Only trusted receiver control can request replacement.
- Ordinary events consume one remaining logical action, including rejected or stale
  ingress. At zero allowance the next ordinary event finalizes. A finished state is
  inert. Crash/recovery are protocol events; real unavailable-host progress still
  requires the explicit host fairness/recovery assumptions.

States carry a ledger equality and qualification evidence for measured candidates
and incumbents. Returned publication effects are indexed by the returned state's
contract and carry both qualification and permission evidence. The 23 laws in
`LAWS.bend` target the actual task API, including exact charging and positive controls;
mere conditional refusal is not sufficient.

## Concrete checker and comparison

`task.bend` checks its own evaluator namespace, actual allowed operators/size and
the existing certificate checker over every four-bit input. The resulting source
laws prove membership and equality of actual evaluation for every input. The
receiver constructs the certificate here; it does not trust worker proof text.
Other tasks may validate supplied proof objects instead.

The generic core does not itself know what constitutes a good document, factual
analysis or accessible design. Each new adapter must supply a receiver-controlled
checker, comparison meaning and evidence connecting them to its obligations. Human
judgment requires an authenticated accountable receiver channel. It cannot be filled
in with a worker's approval. The present adapter has a single declared cost measure;
multiobjective nondominated archives and frontier benchmarks are not implemented.

## Effects, budgets and fallback

The present broker supports exactly one effect class: atomic replacement of bounded
canonical artifact bytes in one private directory. No arbitrary worker path, network,
service write or payment is supported. Those need separate brokers and contracts.
Exact canonical arrays are the evaluated artifact; original ingress-byte hashes are
provenance, not proof. Parser/canonicalization/native-compiler correctness is tested,
not universally proved by the pure transition laws.

The host charges every ingress, including malformed messages; bounds bytes and
snapshot count; records an absolute deadline; and serializes generation updates
with effect application. Native effects are bound to current exact registered bytes
and a fresh host effect sequence. Copies of pure state do not create global credits.
The native action allowance is per receiver transaction. Worker cgroup allocation,
global scheduling, checker costs and monetary caps are distinct host obligations.

When no worker helps, a genuinely qualified fallback can be delivered. Without one,
the permitted outcome is failure. No worker honesty or productivity assumption can
force an improvement. An invalid checker or compromised supervisor/host is outside
the conditional guarantee, rather than another form of worker behavior.
