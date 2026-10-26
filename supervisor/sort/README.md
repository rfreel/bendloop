# Controlled-worker record sorting adapter

This is the bounded sorting task for the first complete supervisor journey. An
artifact is exactly eight records. Each record has three whole-number fields:
`[date_key, id, value]`. The wire representation is their flat 24-integer array;
all wire integers are in 0..20. The production representation is a fixed `Rows`
record containing eight fixed `Record` values, not a linked-list work queue.
Parsing lists are confined to the JSON boundary.

The receiver requires nondecreasing date keys and preservation of every whole
record's multiplicity. Equality compares all three fields, so duplicate rows,
repeated IDs and changed payload values are not collapsed. The eight-row output
has the same fixed cardinality as the reference. This adapter does not claim to
sort arbitrary-length input or interpret calendar date strings.

`task.bend` instantiates the actual generic supervisor with evaluator identity 2.
It computes eligibility itself. Worker declarations, review text and scores are
not acceptance inputs. Publication still requires receiver-owned permission and
a current-contract-qualified artifact through `runtime.bend`.

For eligible alternatives only, fewer same-date ID inversions is the receiver's
chosen preference. That is an implementation preference, not an additional
mandatory user sorting obligation, a stable-sort guarantee or a performance claim.
An equal-quality incumbent is retained.

```sh
CC=clang-18 bend supervisor/sort/main.bend -o /tmp/bendloop-sort
/tmp/bendloop-sort decide +RTS --threads 1 --gpu off -RTS \
  < supervisor/sort/example.json
/tmp/bendloop-sort inspect +RTS --threads 1 --gpu off -RTS \
  < supervisor/sort/example.json
bend supervisor/sort/PROOF.bend --verdict
```

`decide` uses the same receiver-owned request shape as the expression adapter,
with `evaluator: 2`, `allowed_ops: []`, `max_nodes: 7` and flat record arrays for
`reference`, optional `fallback`, and optional `candidate`. The `max_nodes` value
is a reserved wire field in this adapter and is not a sorting-size allowance.
Only the trusted host constructs this request. Worker ingress supplies only the
candidate array. `inspect` returns task-predicate observations for repair: an
incorrect multiplicity includes the exact record and expected/observed counts;
an ordering failure includes the first adjacent date inversion. Inspection is
not a publication effect or authority to alter the contract.

The source laws cover the actual specialized `Task.step`, its typed invariants,
authorized effects, eligibility, comparison and exact ingress charging. They
also prove whole-record identity soundness/completeness, actual multiplicity
refinement to an independently arranged eight-position count, and date-order
refinement to the independent no-adjacent-inversion predicate in `spec.bend`.
For any of the eight reference positions, an accepted candidate has equal exact
multiplicity of that whole record. Positive admission, lost-duplicate rejection,
count diagnostics and revocation controls are checked.

No general unbounded permutation-relation theorem, parser correctness, native
compiler correctness, host confinement or TLA-to-Bend refinement is claimed by
these source laws. The host tests and TLA checks retain their separate scopes.
