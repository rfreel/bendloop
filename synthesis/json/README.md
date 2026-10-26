# Native JSON interface

Build with the pinned Bend and Clang toolchain:

```sh
bend synthesis/json/main.bend -o synth4
printf '%s' '{"program":[20,0,6],"input":5}' | ./synth4 eval +RTS --threads 1 --gpu off -RTS
printf '%s' '{"schema":"bendloop-synth4-v1","reference":[20,0,0],"allowed_ops":[],"max_nodes":1,"budget":2}' | ./synth4 synthesize +RTS --threads 1 --gpu off -RTS
```

`replay` consumes `{"request": <request>, "certificate": <returned certificate>}`.
The checker recomputes both programs' outputs using the actual production evaluator,
checks all sixteen entries, reference identity, grammar membership, cost and strict improvement.
Accepted replay returns `VerifiedImprovement`; a false certificate returns `InvalidCertificate`.
Malformed input returns `InvalidInput`. Results exit 0, invalid input/certificates exit 2,
and input infrastructure failures exit 1. Diagnostics go to stderr.

Scope: one UTF-8 JSON value followed only by JSON whitespace, at most 65,536 input bytes,
read to EOF including short reads. Exact command-specific keys; duplicate keys are detected
after escape decoding. JSON number syntax is parsed separately from integer schema checks,
so booleans, fractions and exponents are rejected in integer fields. `-0` denotes zero.
Raw UTF-8 must encode Unicode scalar values. Escaped UTF-16 code units are retained; permitted
keys and schema strings are ASCII, so surrogate-containing names/values cannot be admitted.
The pure AST decoder consumes every prefix token and enforces the frozen node/token bounds.

Errors are selected by category: syntax/size, keys, types/schema, ranges/order, AST shape;
field checks within each object use key-name order. Certificate validity is checked afterward.
No universal arbitrary-byte parser, encoder round-trip or portable replay theorem is claimed.
Bend definition checking and the independent native suite are separate evidence.

Run `python3 synthesis/json/check.py --tools /path/to/pinned-tools` with Clang 18 on PATH.
The suite checks all 32 operator-set/node-bound combinations, all 14 references and seven
budgets through stdin, replays each returned improvement, exercises the frozen fixtures,
and checks malformed/forged inputs and the byte boundary.
