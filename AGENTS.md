# Working in bendloop

Read README.md, SPEC.md, docs/TRUST.md, and `bend guide` from the pinned toolchain before editing.

## Ordinary implementation tasks

- Edit `src/*.bend`, `PROOF.bend`, and `proofs/*.bend` only unless the user explicitly authorizes a contract or core change.
- Preserve `LAWS.bend`, `spec/`, `core/`, `main.bend`, `acceptance/`, tooling, workflow and toolchain pins. The specification never calls the implementation it judges.
- Implement the public API named by the laws. A separate easy-to-prove model is insufficient without a proved bridge to that API.
- No unsafe declarations, holes, unproved axioms, foreign implementations, unpinned dependencies, or replacement checkers. Keep IO outside the proof import graph.
- Run the pinned `bend PROOF.bend --check-only` while iterating. Before claiming completion, run `python3 scripts/verify.py` (or `ff check` in a configured factory worktree).
- Preserve the exact evidence. Do not call timeout, crash, missing tools, or absent evidence a logical rejection. Do not claim that a model-level proof certifies the native compiler.
- Stop after the agreed attempt allowance, success condition, or a concrete blocker. Record the best accepted candidate and the failure reason. Never weaken laws to obtain a pass.
- Every new universal claim needs its proof. Every externally specified behavior needs independently derived execution evidence at its stated scope.

## Contract changes

The owner may authorize revisions. Present the exact changed claims, obtain approval where required, regenerate the protected manifest, and rerun the full gate. SHA-256 records a contract's identity; it does not make that contract right or prevent its owner from changing it.

## Formal-factory

Follow docs/FORMAL_FACTORY.md. Never edit the external live factory.yaml, provider configuration, approval state, or acceptance policy. Do not start or rotate subscriptions without the user's selection. A report of spend is not a spending limit.
