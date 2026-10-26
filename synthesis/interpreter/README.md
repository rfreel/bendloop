# Interpreter first

This is the next-step experiment requested after the synthesizer draft, not approval of that entire
draft or completion of its search engine. The public deliverable is a typed Bend interpreter library,
source refinement proof, native witness and independent native execution gate.

Supersedes: proceed directly from a reference model to search -> establish and reuse an executable
interpreter/refinement boundary before adding the search tools.

## Applying the article

[Basis, Ship Your Interpreter](https://www.basis.ai/blog/ship-your-interpreters/) checks readable
semantics against execution of a compiled interpreter, and composes downstream tools with that bridge.
Its [pinned theorem](https://github.com/BasisResearch/ship-your-interpreter/blob/fb07094cff916318c34b07494a7d739f1e53989b/VsaIris/Interp/EndToEnd.lean)
uses a RISC-V machine model and a loading precondition. This repository adopts the reusable boundary
and constructive loading discipline. It has **not** reproduced that machine-code proof.

## What runs

`runtime.bend` contains an independent Expr type, fixed four-Boolean Bits value, evaluator, operation
cost, node size and numeric observation. It imports only Base. It does not call the reference model.
The expression tree represents program syntax; values have a fixed scalar record representation.
`bridge.bend` converts representations on the proof side. `LAWS.bend` states the contract and
`PROOF.bend` discharges it. The reference semantics in ../spec/model.bend is unchanged.

The source theorem holds for all well-formed expressions, including arbitrarily deep finite trees,
and every four-bit input. Termination is enforced by Bend's structural recursion check. Cost here
counts language operators, not CPU instructions or wall time.

```sh
.tools/bend/bin/bend synthesis/interpreter/PROOF.bend --verdict
.tools/bend/bin/bend synthesis/interpreter/main.bend -o /tmp/synth-interpreter
/tmp/synth-interpreter +RTS --threads 1 --gpu off -RTS
# prints 15: NOT(input XOR 5), at input 5
python3 synthesis/interpreter/verify.py --tools .tools
```

Use the public `eval` function with an Expr and Bits from another Bend program for other inputs.
`main.bend` is a concrete native witness, not the planned arbitrary-input JSON CLI.
The native witness imports the exact runtime that the universal theorem covers.

## Boundaries

| Boundary | Evidence now | Still open |
|---|---|---|
| Model Expr/Word4 to runtime Expr/Bits | Total constructive loader and round-trip laws for every model value | Byte parsing and physical machine loading |
| Runtime evaluation to reference semantics | Universal kernel-checked equality, cost/size refinements, transport and reflection of result proofs | None at this typed source boundary |
| Observable numeric value | Universal source theorem relating number(eval) to the reference value | IO, string encoding and process exit behavior proofs |
| Source to emitted C/native executable | Actual compiled differential tests and SHA256 identities | Compiler/runtime/machine-code refinement |
| Certified candidate to search result | Planned in the original draft | Equivalence certificate replay, enumeration and search/budget laws |

`loaded_eval` is a **source representation** theorem. It must not be relabeled an ELF loading theorem.
`result_transport` lets the future certifier reuse the interpreter proof: a reference-result proof
implies the corresponding runtime result. `result_reflect` provides the reverse direction.
These are actual checked implications, not assumed correctness tokens.

## Acceptance for this experiment

The verifier preserves the kernel translation, emitted C for the witness, compiled binaries,
source/tool/artifact hashes, exact expected and observed output, and negative-control logs.
It checks all 918 expressions with at most three nodes, plus three deeper expressions, at all
16 inputs: 14,736 evaluations, and two cost/size observations per expression. The independent oracle
uses Python integer operations; it never supplies runtime answers to the Bend library.

Three isolated mutations must fail the source proof: XOR becoming OR on one bit, a constant ignoring
its value, and NOT becoming identity on one bit. A timeout or infrastructure error is not proof rejection.
These controls demonstrate sensitivity to those defects; they do not establish adversarial completeness.

The verifier uses the repository's existing subprocess resource limits. Reproduction requires the
pinned tools, Clang 18, and the Lean toolchain on PATH for a fresh kernel build. It is an engineering
gate on a trusted host, not an adversarial execution sandbox or a signed release service.

The external factory gate now includes this verifier as its `vectors` command and includes
this PROOF.bend in its checker files. factory-overlay.json records the additive configuration.
The baseline counter checks and human-approval setting are preserved. Existing GitHub CI still
runs the starter gate; making this additional gate required in CI is part of contract activation.

## Next factory obligations

1. Review the unchanged four-bit semantics and the new interpreter source contract together. Freeze
   the reviewed laws, bridge, independent tests and artifact binding in the implementation authority.
2. Build equivalence certificates against this interpreter and compose their soundness with
   `result_transport`; reject a certificate checker disconnected from the actual evaluator.
3. Add deterministic enumeration and bounded search, then JSON input/output with explicit parser scope.
4. For the full Basis-style result, select an ISA/ABI, pin the emitted interpreter artifact, define
   memory/layout/entry state and observable exits, and prove binary execution refines the source.
   Demonstrate nonempty loading conditions and retain separately checked boot/loader assumptions.
   The current x86-64 native tests and BendTT source proof cannot discharge that obligation.

Unlike recovering semantics for an existing implementation, this project is designing a new language.
An execution disagreement is investigated as a model, representation, implementation or toolchain
fault. It does not authorize rewriting the intended semantics merely to match a bug.

The pending specification decision is not treated as accepted by this next-step request. The factory
may gate this explicitly requested experiment while the larger synthesizer contract remains a draft.
