# Executable policy revision contract

Authorized by the owner's instruction "Do all that" following the repository-specific
proposal in the conversation. This is a separate extension; synth4-v1 and its
release blockers are not silently weakened or marked complete.

## Meaning

Candidates remain the existing four-bit expression ASTs, interpreted and certified
by synthesis/interpreter and synthesis/certificates. A policy is a total, finite
Bend data program selecting a permutation of the existing grammar's ranks.
Input, constant zero and constant fifteen are always grammar members. Moving one
of those leaf candidates to the front swaps two ranks; the rest of the grammar
is unchanged. The legacy API retains its specified canonical order.

Rules recognize expression structure, not task names or stored answer tables:
zero-producing forms include XOR(e,e) and AND(e,0); all-ones-producing forms
include OR(e,15) and NOT(0). Candidate admission always recomputes equivalence
through the existing certificate checker, even when a rule suggests an answer.
A rule does not grant authority to change the evaluator, contract or budget.

Policies may enable these rule families and choose how to order proposals for
subsequent policies. A fixed interpreter defines that behavior. Revisions are
actual Policy values produced by the same bounded, measured improvement operation.

## Quality and accounting

The evaluator executes both policies on the exact same reference ASTs and caps.
It computes each candidate attempt, certificate outcome and achieved expression
cost. Scores are derived from executions; no supplied score or valid/safe Boolean
is accepted. Learning trajectories include cold-start results and outcomes after
fixed proposal budgets. Learning-process acceptance also requires identical starting
rule flags, so preloaded rule knowledge cannot be mislabeled faster learning. Training,
validation and later-cycle problem ASTs are distinct; protected problems cannot overlap them.
Structural separation alone does not prove family novelty or prior-exposure absence. Retention is checked on the declared protected tasks.
Every normally completed proposed revision and rejected attempt is recorded and charged.
An infrastructure error is reported separately and is not a complete partial ledger.

Logical counters are separately reported for policy proposals, candidate attempts
and sixteen-input verification work. They are defined semantic units, not CPU,
wall-clock, memory or monetary measurements. No external failed work is hidden
behind a claimed hard physical resource limit.

Separate reports identify expression improvement, policy improvement, learning
process improvement, and gains across subsequent revision cycles. A branch
comparison records concrete policies at every cycle and uses fresh, structurally
different tasks. It does not extrapolate beyond the observed families and cycles.

## Universal obligations

- Policy rank mappings are involutions, hence injective and surjective on the
  declared finite grammar; all affected ranks are admitted leaves.
- The production policy interpreter refines an independently stated reference.
- Each returned expression carries equivalence to the actual supplied reference.
- Zero budgets perform no candidate/revision attempts.
- Actual proposal/candidate traces determine results and costs; continuations
  preserve the remaining allowance.
- Policy acceptance installs the evaluated Policy value and preserves protected
  outcomes; positive examples exclude an implementation that always refuses.

## Existing prerequisites remain required

The original universal enumeration, exact visited prefix, best prefix, status,
byte-level portable replay/serialization, RV64 execution/loading and boot/loader obligations
remain required. Component checks must not unlock the full release while any is
missing. The pinned compiler/kernel and external execution boundary remain explicit.
