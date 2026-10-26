# Implementation checkpoint

The four-bit specification and interpreter source contract retain their reviewed bytes.
`authority/frozen.json` pins the reviewed contract. The factory-owned external copy is the
acceptance authority; candidate-side edits cannot change it.

Implemented and checked:

- Typed certificates check all sixteen inputs against the actual interpreter evaluator.
  Six public certificate laws include soundness, completeness and composition with
  `result_transport`. Kernel checking and 511 independent native cases pass. Both a
  disconnected-evaluator mutant and a missing-input mutant are rejected.
- Deterministic enumeration orders candidates by size and then prefix tokens. Bounded search
  charges each attempted candidate and retains an evaluator-certified incumbent.
  Independent tests cover 3,136 searches, 918 enumerated expressions and a resume sequence.
- JSON serialization emits search state and portable certificate fields. This is output only.
- The existing fixed native interpreter witness has an exact ELF byte binding. It does not
  expose a general interpreter process entry and has no binary-refinement theorem.

Still required for completion:

1. Universal enumeration, reachable-state, conservation, resume, ranking and status laws.
2. Native JSON stdin parser/schema validation and portable certificate replay, including
   independent rejection tests. No parser exists yet; no byte-to-typed-value proof is claimed.
   The frozen spec requires <=64KiB, exact keys, integer tokens, no duplicate keys, and rejection
   of booleans/floats in integer fields. JSON parsing must stay outside the proof claim until
   a parser bridge is itself proved. Python is only an independent test oracle.
3. A general emitted interpreter entry, concrete ISA semantics, machine loading relation,
   nonempty loading witness, binary execution refinement and separately checked boot/loader
   assumptions. See `machine/OBLIGATION.md`.

The successful component checks are not full acceptance. `authority/release.py` deliberately
returns an incomplete verdict until these obligations have actual checked implementations.
