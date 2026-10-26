# Interpreter-first amendment for review

The user requested applying https://www.basis.ai/blog/ship-your-interpreters/ as the next step.
The draft language, enumeration, budget and completion requirements in SPEC.md are unchanged.

Supersedes: only reference-model execution evidence is available -> a separate executable interpreter
and universal source-level refinement bridge are now available as a candidate foundation.

Review ../interpreter/README.md, LAWS.bend, bridge.bend and PROOF.bend alongside this draft.
Before implementation tasks 03 through 06, use the same public runtime evaluator certified by that
bridge; downstream proofs must compose through it. Task 02's evaluator/cost/size obligations have
candidate proofs, but AST byte validation and the full CLI remain unfinished. Task 01 must freeze
the acceptance authority before autonomous implementation. No task is marked fully complete merely
because the original counter gate or this interpreter experiment passes.

The native binary boundary remains tested, not formally verified. Full machine-code refinement is
an explicit future milestone, not a silently satisfied reading of eval_refines. The source model has
not been adjusted to excuse implementation behavior. No human approval flag is set by this amendment.
