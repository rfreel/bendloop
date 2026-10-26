# Hostile-worker coordination model

`Supervisor.tla` models receiver-controlled admission and publication while worker
payloads, epoch claims, review claims, scheduling, replay and withholding are
arbitrary. TLC explores all reachable states in the four checked configurations;
it is not an unbounded proof or a refinement theorem about Bend or the host.

## Run

Use stock Java 17 or later and the jar identified by `toolchain.json`:

```sh
curl -fL https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar \
  -o /tmp/tla2tools.jar
python3 supervisor/tla/check.py --jar /tmp/tla2tools.jar
```

The runner rejects a mismatched jar, preserves complete TLC logs and counterexample
traces under `.artifacts/supervisor-tla-*`, checks positive models including temporal
progress, and requires a specific invariant counterexample from each negative
control. Timeout or parser/runtime failure is an infrastructure error, never a
successful mutation rejection. The jar is not vendored into this repository.

## What the state means

| Model value | Coordination meaning |
| --- | --- |
| `epoch`, `stamp` | Trusted current contract version and authority journal stamp |
| `inbox` | One arbitrary worker message; colluding reviews and claimed epochs are ignored |
| `frozen` | Exact artifact value and receiver-assigned contract version |
| `evaluation` | Receiver recomputation for the exact evaluation snapshot |
| `incumbent`, `pool` | Current qualified fallback/winner and evaluated qualified candidates |
| `prepared` | Proposed publication that may become stale before commitment |
| `published`, `effects`, `outcome` | One atomic durable publication or permitted failure |
| `clock`, `credits`, `workerSpent` | Monotonic deadline, receiver evaluation allowance, per-worker logical compute allowances |
| `up`, `crashes` | Finite host crashes and fair recovery; durable state is preserved |

Artifacts are exact finite values, not mutable IDs. `A` and `B` satisfy different
contract epochs. `X` is functionally invalid and requests a forbidden effect.
`Y` is functionally valid but requests a forbidden effect, independently exercising
effect admission. `base` is a qualified fallback. Scores come from the receiver's
fixed table. Higher scores are better in this model. These finite tables abstract
task-specific receiver checkers; they are not provided by a worker.

The model permits replacing `frozen` while an old evaluation remains outstanding,
so admission must match the actual snapshot. An implementation that disallows
replacement can be stricter. There is no claimed exact transition correspondence
between this model and a separate implementation.

## Checked properties

The invariants check contract stamp consistency, receiver-bound evaluation results and exact frozen/evaluated content binding,
qualified current incumbents, qualified admitted candidates, best admitted score,
current-epoch publication, confined effects, atomic complete publication, exact
winner publication and permitted failure semantics. Bounds are two arbitrary
workers, four candidate artifacts plus fallback, two contract epochs, one evaluation
credit, one logical compute unit per worker, one deadline tick and at most one crash.
Only one nonbaseline artifact is functionally and effect-admissible per epoch,
so score selection coverage compares that output against the qualified baseline;
it does not establish a broad quality/portfolio selection algorithm.
Fallback-present and fallback-absent configurations each run with one credit and
with zero evaluation/worker-compute allowance; all four check `<>Done`.

Progress relies on weak fairness of trusted clock ticks, host recovery,
publication preparation, commit, and permitted failure. No worker fairness,
honesty, response, review, novelty, or improvement assumption is made. Finite
contract updates and crashes prevent perpetual trusted-authority disruption.
Workers can refuse to contribute and the host still delivers a qualified fallback
or a permitted failure. This does not force anyone to invent a better output.

## Boundary assumptions and limitations

- Only receiver code invokes `Evaluate`, `Admit`, `ContractUpdate`, `Prepare`,
  `Commit`, clock and recovery actions. Arbitrary worker payloads enter solely
  through `Submit`. A host that dispatches privileged event tags from worker JSON
  violates this model's provenance assumption.
- The trusted receiver checker and its relation to task intent are assumptions in
  TLA+. Worker-supplied approval bits cannot replace it. Bend proofs must separately
  establish properties of the actual admission operation.
- `Commit` is a single atomic durable transaction. `Crash` preserves its durable
  record, including the outcome and all effects, and restart observes that record.
  This models idempotent acknowledgement retries but does not prove filesystem,
  database, remote-service or journal crash consistency. Partial writes require a
  real broker transaction or a separate implementation model.
- Logical worker compute and evaluation counters are not CPU, memory, dollars or
  network bytes. `Submit` can occur arbitrarily often without spending a credit.
  Deadline fairness prevents it from extending modeled authorization, but host
  quotas, sandboxing, admission-rate and payload-size limits remain necessary.
- Epoch changes invalidate/requalify the fallback and preserve stale prepared and
  evaluation records, exposing races. There are no in-place evaluator changes,
  byte parsers, actual processes, cryptographic collision assumptions, distributed
  leases, rollback to a previous epoch, or real-world side effects in this model.
- TLC uses finite-state enumeration and 64-bit fingerprints. Its reported collision
  estimates are retained in the logs. Passing is evidence for these concrete
  configurations, not a universal TLA+ theorem or proof of the host implementation.

The twelve negative controls remove snapshot identity/freshness at admission, broker revocation,
effect qualification, receiver evidence computation, resource bounds, authority
stamp updates, cumulative credit conservation across contract updates, fallback revocation, publication completeness, or winner ordering. Each must produce the named counterexample.
