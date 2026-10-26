# Starter specification for approval

Status: concrete starter specification; not yet approved for an autonomous formal-factory run.

## Program and interface

A pure bounded counter in Bend 2, with a small reusable receipt library and a thin native demonstration.

- `Counter.run(budget, work)` returns `Receipt<budget>`.
- `Counter.batches(budget, first, second)` runs the second batch using the first batch's remaining allowance.
- `Receipt<n>` contains natural-number `spent`, natural-number `left`, and evidence that `spent + left = n`.
- A unit of completed work costs one logical token. `run(b,w)` completes `min(b,w)` units and leaves `max(0,b-w)` tokens. Zero budget is a normal exhausted result, not a failure or successful completion of outstanding work.
- `main.bend` demonstrates `batches(5,2,4)` and prints `spent=5 remaining=0`.

## Executable meaning

`spec/counter.bend` is the independent reference calculation. It does not import the production implementation or receipt library. The public law `matches_spec` quantifies over every natural-number budget and work request.

## Required laws

1. `matches_spec`: public run output equals the reference pair.
2. `budget_conserved`: one run conserves its allowance.
3. `composition_conserved`: two batches conserve their shared allowance.
4. `exact_work_completes`: a request equal to its allowance completes in full.
5. `empty_work_spends_nothing`: empty work preserves the entire allowance.
6. `sequential_example`: the two-batch example spends exactly five.

The core also proves associativity of natural-number addition and conservation for any well-formed receipt. The full two-batch functional equation is covered by finite independent cases, not a separate universal theorem in this starter.

## Done when

The frozen contract audit passes; every imported proof passes Bend 2.0.39 `--verdict`; the emitted BendTT is preserved; the native example and 29 independent arithmetic cases agree; always-refuse, ignored-second-batch, and forged-receipt negative controls are rejected by the checker. The gate must reproduce from a clean checkout.

No speed target. No probability model or weighting algorithm. No agent search interpreter. No assertion that the logical allowance bounds checker/runtime resource consumption.

## Trusted

Bend/Lean release provenance, the source-to-BendTT translation, Base's modeled primitives, the native compiler/runtime, OS/hardware, and the Python acceptance harness. No custom FFI is allowed. IO provided by Base is used only by the demonstration and execution fixtures, outside the proof graph. See docs/TRUST.md.
