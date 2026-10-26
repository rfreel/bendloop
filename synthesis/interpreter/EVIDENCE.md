# Interpreter experiment evidence

The pinned Bend 2.0.39 kernel accepts all 12 public source laws and four primitive bridge lemmas.
The public laws include both result-transport directions, total loading, round trips, evaluation,
cost, size, numeric observation and a concrete successful program witness.

The third local native run passed:
- 918 exhaustive expressions of size at most three, plus three deeper expressions.
- All 16 inputs per expression: 14,736 output comparisons against independent Python integer semantics.
- 1,842 cost/size comparisons.
- Native witness NOT(x XOR 5) at x=5 printed 15.
- XOR-to-OR, ignored constant value and identity-NOT mutations were each rejected by the kernel.

Two earlier harness builds exposed Bend annotation/quantifier mismatches in the native test entry
points. They were corrected without changing runtime semantics, reference semantics, laws or expected
outputs. Their failed logs remain in the local artifact history. They were not counted as passing runs.

`verify.py` reproduces these checks from a copied source snapshot, preserving complete output,
BendTT, generated C, native binaries and SHA256 identities under .artifacts/. Factory acceptance also
reruns the original counter gate and its controls. No machine-level theorem, parser theorem, search
implementation, speed improvement or global resource bound is claimed by these observations.
