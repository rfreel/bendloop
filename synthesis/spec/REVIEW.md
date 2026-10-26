# Review the draft

The chat assistant took over the factory's specifier task after the CLI worker stalled.
No synthesizer implementation has been written, and no human approval flag has been set.

## Decisions being proposed

- Unary four-bit expressions; operators NOT, AND, OR, XOR, plus input and all constants.
- A supplied reference AST; deterministic finite search with an explicit size bound and attempt cap.
- Return the cheapest certified strict improvement in the visited prefix; report remaining space/fuel.
- Certificates recompute all 16 inputs and bind the reference, candidate, membership and cost.
- In-process continuation only. Accounting is per history, not a global credit authority.
- The candidate is executable through the verified evaluator. Standalone compilation per candidate,
  probabilistic weighting and a self-improving compiler remain later stages.

SPEC.md is the exact proposed contract. implementation.json contains eight dependency-ordered tasks.
cases.json contains 47 planned tests; search/replay/parser cases are not yet executable against a
production implementation. They are acceptance inputs for the subsequent implementation phase.

## Evidence obtained for this draft

- Bend 2.0.39 kernel recheck accepts the pure reference model.
- A native compiled reference agrees with independent Python bit arithmetic on 14 expressions
  times all 16 inputs: 224 evaluations. No discrepancy was observed.
- Formal-factory `check` accepts both existing PROOF.bend and synthesis/spec/model.bend.
- The original counter's native cases and proof-negative controls remain accepted by its gate.

Reproduce the independent model check after installing the pinned tools and Clang 18:

```sh
PATH="$PWD/.tools/lean-4.34.0-linux/bin:$PATH" python3 synthesis/spec/check_model.py \
  --bend .tools/bend/bin/bend --cc clang-18 --output .artifacts/model-review
```

Use a new output directory on each run. The script preserves kernel/build logs, exact fixture,
expected/observed outputs, and SHA256 identities. It does not run production search, and a successful
model check does not prove the planned synthesizer. The proposed source laws remain implementation
obligations. All claims have the compiler/runtime trust boundary stated in SPEC.md.

The factory's human approval gate stays closed until this exact draft is reviewed. After approval,
the implementation gate and immutable executable laws must be established before implementation starts.
