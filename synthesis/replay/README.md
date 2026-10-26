# Typed portable replay

`runtime.bend` validates an untrusted typed packet against a separately supplied
request. Its accepted constructor requires exact reference AST identity, allowed
operators and size, strict cost reduction, the exact claimed candidate cost,
evaluation equivalence on all sixteen inputs, and all sixteen claimed output rows.
The JSON replay endpoint calls this checker after its existing schema validation.

`LAWS.bend` and `PROOF.bend` prove properties of that actual operation. Acceptance
implies equivalence at every input and the other packet obligations. Conversely,
`canonical_roundtrip` proves acceptance of a canonical packet for any genuinely
equivalent, smaller, admitted candidate. It does not assume a successful replay.
The positive XOR-to-zero witness prevents an always-refusing checker from passing
the complete contract. Mutation controls include aliasing the final output row and
forging canonical cost.

```sh
bend synthesis/replay/PROOF.bend --verdict
python3 synthesis/policy/verify.py --tools /path/to/tools
python3 synthesis/json/check.py --tools /path/to/tools
```

These are typed source theorems. They do not prove arbitrary JSON bytes parse to
the intended packet, that rendering and parsing are inverses, that the native
compiler preserves the checker, or that the operating system runs the pinned
binary correctly. Those boundaries retain their separate test/proof status.
