# Certified bit-vector synthesizer v1

Status: DRAFT FOR HUMAN REVIEW. This file does not approve itself.
Contract identifier: bendloop-synth4-v1.

## Program

A Bend 2 library and native CLI search a finite expression grammar for an implementation
strictly cheaper than a supplied reference, with identical output on every 4-bit input.
The search result includes a replayable equivalence certificate and logical attempt accounting.
Formal-factory builds and checks the implementation after this draft is approved.

The reference is an expression, not a free-form natural-language objective or a truth table in v1.
`model.bend` defines independent executable meaning, operator cost, node size and allowed operators.
It imports only pinned Base. Production code must refine it rather than delegate evaluation to it.

## Expressions and input boundary

Canonical external AST is a flat integer array in prefix order, consumed exactly once:

| Token | Meaning | Arity |
|---|---|---|
| 0 | input x | 0 |
| 1..16 | constant token minus one | 0 |
| 17 | bitwise NOT | 1 |
| 18 | bitwise AND | 2 |
| 19 | bitwise OR | 2 |
| 20 | bitwise XOR | 2 |

Bits are least significant first in `Word(4n)`. External integers are ordinary unsigned
values 0..15. NOT is `(~x) & 15`; binary operators act on the four corresponding bits.
Every expression terminates. Evaluation has no effects. Repeated subexpressions are evaluated
as tree occurrences: there is no common-subexpression sharing discount.

A request has exactly these keys:
`schema` = "bendloop-synth4-v1", `reference` = canonical AST, `allowed_ops` = ascending
unique subset of [17,18,19,20], `max_nodes` = integer 1..7, `budget` = integer 0..1000000.
Input and all 16 constants are always allowed. Allowed operators constrain synthesized candidates,
not the reference. The reference must have 1..63 nodes. Integers exclude booleans and floats.
Reject duplicate/unknown JSON keys, unknown tokens, missing/excess children, trailing tokens,
invalid bounds and invalid types. Do not mask invalid external constants into range.
An invalid request returns `InvalidInput` before search; it is not exhaustion or a proof rejection.
CLI JSON input is limited to 64 KiB. Pure internal APIs use validated types.

## Candidate order, objective and completeness

G is every well-formed expression with size <= max_nodes using only allowed operators.
Order by increasing node count, then lexicographic prefix token sequence (numeric token order).
No symmetry reduction: AND(x,0) and AND(0,x) are distinct grammar members. No duplicates.
A lazy enumerator must produce this exact order without materializing all of G up front.

Cost is the number of operator occurrences; input and constants each cost zero.
A candidate improves the reference only when cost(candidate) < cost(reference).
Among certified improvements, prefer the tuple (cost, node count, prefix token sequence),
ascending. Equal-cost-to-reference rewrites are not improvements. A lower abstract cost
is not a native speed claim. The initial best is absent; the reference is never passed off
as a discovered candidate.

Every enumerated candidate consumes one attempt, even when its cost immediately disqualifies it.
Within an attempt, a candidate is equivalent only if all 16 inputs agree. Early exit on the first
mismatch is permitted. No extra candidate may be evaluated or pre-certified after fuel is gone.
Constructing the next iterator position is bookkeeping, not an additional candidate attempt.
Generation itself, certificate checking and proof checking have separate host limits; the attempt
count is not an instruction, CPU, memory, wall-clock or monetary bound.

After a call, best is exactly the least ranking key among certified strict improvements in the
visited prefix, or absent if none exists. Prefix optimality is required, not global optimality.
Only exhausting G permits a minimum-in-G or no-improvement-in-G statement. Even then this is
not a statement about unrestricted programs or larger grammars.

## Public API and search state

These are semantic signatures; concrete dependent types must preserve their obligations:

- `validate(raw_request) -> ValidRequest | InvalidInput(reason)`.
- `start(ValidRequest) -> State`: cursor=0, spent=0, left=budget, best=absent.
- `advance(State, quota: Nat) -> Report & State`: visits the next
  min(quota, left, number of candidates remaining) candidates.
- `synthesize(ValidRequest) -> Report`: `advance(start(request), request.budget)`.
- `eval(Expr, Word4) -> Word4`, `cost(Expr) -> Nat`.
- `certify(reference, candidate) -> CertifiedEquivalence | Counterexample(input, lhs, rhs)`.
- `replay(request, certificate) -> VerifiedImprovement | InvalidCertificate(reason)`.

State binds the entire validated request, original cap, cursor, spent, left and best.
Constructors are private or carry proofs of validity. `cursor = spent` and `spent + left = cap`.
`advance` never increases cap or left; spent increases by exactly the number actually visited.
The new visited prefix extends the old one. Previously rejected candidates are not retried.
For a valid state, advancing by a then b yields the same final logical state as advancing by a+b.
Calls clamp to remaining fuel and space; quota=0 preserves the state exactly.

A report includes schema, reference, allowed_ops, max_nodes, original cap, spent, left, cursor,
status, and optional best (candidate, cost, node count, certificate).
Status precedence: `SpaceExhausted` if the cursor is at end of G, else `BudgetExhausted`
if left=0, else `Paused`. A best candidate may accompany any status. Status never implies that
no equivalent program exists. If space and budget end together, SpaceExhausted wins.

V1 continuation is an opaque in-process value. There is no serialized-state import, top-up,
parallel branch merge or nested-search API. Reusing a copied state creates another history.
The accounting theorem applies to each history, not their aggregate. Cross-process single-use
credits require a trusted stateful authority and are out of scope. Native CLI `synthesize` uses
one history; library tests exercise chunked advance without pretending to prevent external replay.

## Certificate and executable meaning

A portable certificate contains exactly: schema, reference AST, candidate AST,
candidate_cost, and outputs (16 integers indexed by input 0..15). Replay parses both programs,
compares the embedded reference exactly to the request reference, checks candidate membership
in G, recomputes cost, requires strict improvement, and recomputes both outputs for all inputs.
All three values (reference evaluation, candidate evaluation, claimed table entry) must agree.
A supplied table or hash is never accepted as a proof by itself. Certificate acceptance does
not certify search history, prefix optimality or the number of attempts.

The executable candidate is this AST evaluated by the verified production evaluator.
The initial product need not emit a standalone native binary per candidate. The native CLI
provides `eval`, `synthesize`, and `replay` commands, with JSON via stdin and JSON via stdout.
`eval` accepts exactly `program` and `input`; `replay` accepts exactly `request` and `certificate`.
All structural/domain rules above apply, with candidate size bounded by its request.
Normal results (including exhaustion and valid counterexamples) exit 0. Invalid user input or
invalid certificate exits 2; infrastructure failure exits 1. Diagnostics belong on stderr.
For malformed input, report the first error in this order: size/JSON syntax, duplicate or unknown
keys, schema and field types, numeric ranges/order, AST shape. Within a category use key-name order.

## Required universal source-level laws

| ID | Required claim about the actual public implementation |
|---|---|
| eval_refines | For every Expr and Word4, production eval equals model.eval. |
| cost_refines | Production cost and size equal model.cost and model.size. |
| enumeration | The enumerator visits exactly G in the declared order, without duplication. |
| certification_sound | Every accepted equivalence witness implies equal evaluation for every Word4. |
| certification_complete | Equivalent well-formed programs are certified; unequal ones return a genuine counterexample. |
| replay_sound | Accepted portable certificate implies equivalence, membership and strict improvement. |
| replay_roundtrip | Serializing/replaying a returned best preserves its program and validity. |
| start_valid | Initial state has its declared request/cap, empty visited prefix and no best. |
| advance_exact | Advance visits exactly the specified prefix extension and charges every candidate once. |
| budget_conserved | Every returned state has cursor=spent and spent+left=original cap. |
| resume_composes | Consecutive a,b advances equal one a+b advance in logical state. |
| best_prefix | Returned best is the ranked minimum of all strict equivalent improvements visited. |
| status_exact | Report status follows the defined precedence and remaining space/fuel. |

No assumed axioms, proof holes, unsafe declarations or custom FFI. Use private constructors or
explicit evidence to tie the certificate and ledger to the executed path. An always-refuse
implementation must fail certification_complete, advance_exact and positive native examples.
A Python search or evaluator must never supply production answers; Python may independently test them.
Parser/encoder public behavior requires native tests and a stated formal bridge scope; no claim of
verified arbitrary-byte parsing is made unless that bridge is also proved.

## Evidence and completion

Before implementation, freeze a harness against this draft and its reviewed laws. The current
factory gate only preserves the starter and checks the reference model; it cannot establish completion.
Implementation completes only when:

1. All named laws cover the public APIs and pass pinned Bend 2.0.39 kernel recheck. No missing declarations.
2. The native CLI satisfies cases.json; tests independently evaluate all 16 inputs for each output.
3. Production evaluation matches Python bit arithmetic for every grammar expression of size <=3
   using all four operators, and every one of the 16 inputs. Runtime tests publish the exact count.
4. Search matches an independent exhaustive reference for all 32 operator-set
   and node-bound combinations (16 operator subsets times node bounds 1 and 2), all 14 references tagged `eval` in cases.json, and budgets {0,1,2,16,17,18,40}; resumed quotas include zeros and budget overshoot.
5. Mutations detect forged outputs/cost/reference, skipped inputs, omitted/duplicated candidates,
   skipped charges, reset continuation fuel, always-refuse certification, and incorrect tie/status logic.
6. A clean checkout reproduces kernel verdicts and native outputs. Record source, contract and tool
   SHA256 hashes, commands, timings and failures. Hashes are identities, not proof of correctness.

Use the existing per-process gate allowances initially. A timeout is EXHAUSTED or infrastructure
failure, never logical proof rejection. No speed ratio target and no monetary ceiling are promised.
Any revised allowance or semantic contract requires explicit review, not weakening to get a pass.

## Trusted and deferred

Trust the approved spec's correspondence to intent, pinned Base semantics and Bend elaboration,
BendTT/Lean checking chain, native compiler/runtime, host OS/hardware, and external gate/test harness.
The source laws do not prove the native compiler. IO stays outside the pure proof graph.

Deferred: wider words, multiple variables, arithmetic, shifts, arrays/loops, probabilistic weighting,
LLM candidate generation, global credit ownership, standalone compilation per candidate, and a compiler
that improves its own passes. They are extensions requiring new contracts, not features certified here.
