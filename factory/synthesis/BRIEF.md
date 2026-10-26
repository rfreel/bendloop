# Factory assignment: proof-producing bit-vector synthesis

The owner requested the proposed synthesizer and explicitly directed formal-factory to do the work.
This is the specification phase, not permission to implement before the drafted contract is reviewed.

Draft a reviewable first release in `synthesis/spec/`:
- Unary, total 4-bit programs. Input and output are integers 0 through 15.
- Expressions: input, constants 0 through 15, NOT, AND, OR, XOR. Define exact masking semantics.
- Public synthesis input: reference program or truth table, allowed operations, candidate-attempt budget,
  and an explicit finite grammar/size bound. Define malformed inputs and unsupported operations.
- Deterministic enumeration and deterministic cost/tie-breaking. Return a strictly cheaper equivalent
  executable candidate with an independently checkable certificate, or an honest exhausted/no-improvement
  result. Keep a supplied reference separate from improvements discovered by search.
- Equivalence must cover all 16 inputs. Formal source laws must connect certificate acceptance to
  the actual evaluator, not a disconnected proof-only model. Specify certificate encoding and replay.
- Charge every attempted candidate, including rejected candidates; shared budget across resumed/nested
  searches cannot reset. Define continuation state, zero-budget behavior, and accounting invariants.
- Fewer abstract operations is a cost improvement, not a claim of faster native execution.
- Do not claim global optimality or impossibility unless the declared finite grammar was exhausted.
- Ranking may only select certified candidates. Initial ranking is deterministic instruction cost;
  probabilistic explanation weighting and a self-improving compiler remain later scope.

Required draft files:
1. synthesis/spec/SPEC.md: exact API, semantics, law statements, exclusions, trust boundary and done criteria.
2. synthesis/spec/model.bend: independent executable reference semantics; must check on Bend 2.0.39.
3. synthesis/spec/cases.json: nonempty concrete independent test vectors, including failures and boundaries.
4. synthesis/spec/implementation.json: nonempty array of tasks with `id` and `description`, dependencies
   and acceptance requirements stated in descriptions. Include certificate replay, budget composition,
   native CLI, differential testing, malicious certificate mutations, and kernel verification.

Read the pinned `bend guide` and Base before choosing representations. Reuse core/receipt.bend where
appropriate, but it only proves accounting, not unique global ownership or actual CPU consumption.
Keep the production implementation in Bend, no FFI, unsafe declarations, assumed axioms or holes.
A later implementation phase must freeze these reviewed files and separately establish its acceptance
harness and public laws. The current counter gate checks preservation of the starter only; passing it
is not evidence that this new synthesizer exists or meets its specification.

Edit only synthesis/spec/. Do not implement the synthesizer during this phase. Leave the original
counter/core/harness untouched. Produce the draft for human review; never mark human approval yourself.
