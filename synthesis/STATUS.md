# Implementation status

The reviewed four-bit semantics, interpreter laws, bridge and independent original oracles
are unchanged. The external factory authority now also enforces the JSON boundary tests,
three search laws, their negative controls and the RV64 artifact binding.

Implemented and checked:

- Typed certificate soundness/completeness composed with `result_transport`; 511 independent
  native cases and disconnected-evaluator/missing-input mutation rejection.
- Deterministic enumeration and bounded search, independently checked over 3,136 searches
  and 918 expressions. `start_valid`, `resume_composes` and `budget_conserved` kernel-check.
  Skipped-charge, created-credit and zero-quota-step mutants fail those laws.
- Native JSON stdin/stdout commands `eval`, `synthesize` and `replay`, including UTF-8, the
  64 KiB limit, schema/type/range/AST validation, certificate recomputation and exit codes.
  The boundary suite includes 224 evals, 3,136 searches, 768 successful replays, frozen fixtures
  and forged/malformed inputs. The replay endpoint now calls the proof-producing typed
  replay operation; arbitrary-byte parsing/rendering is not universally proved.
- Typed replay soundness, exact source/membership/cost/output binding and canonical
  packet completeness kernel-check in `replay/PROOF.bend`. Completeness does not assume
  successful replay. This is not a byte-level serialization theorem.
- Executable finite policy revision, measured adaptation/transfer/retention episodes and
  matched subsequent revision branches live in `policy/`. Rank permutations, interpreter
  refinement, execution-bound comparisons, scoring, zero budgets and search accounting have
  named source laws. Independent native checks cover complete experiment traces and 44,064
  public searches. Read `policy/AUDIT.md` for the remaining semantic and proof findings.
- A freestanding 224-byte RV64I evaluator accepts arbitrary admitted prefix programs through
  one LP64 function entry. Exact ELF reproduction and independent emulation pass, including
  14,720 valid executions, eight invalid cases and memory/register checks. Loading assumptions
  and a concrete runnable entry example are recorded separately from source proofs.

Remaining proof work:

1. Universal enumeration, exact visited-prefix, best-prefix and status laws.
2. Byte-level serialization/replay round-trip and parser/typed-packet bridge. Typed replay
   soundness and canonical packet completeness are now proved; native parser tests are not
   a byte-level proof.
3. Reverse-prefix evaluation refinement to Bend's source evaluator, then actual RV64/Sail
   execution refinement, a proved nonempty loading relation and separately checked boot/loading.

The pinned Sail backend build failed before elaboration because this runner denies Lean's
`/proc/<PID>/exe` lookup. This infrastructure failure does not reject a proof and does not
block the cached BendTT source checker. No compiler/kernel was patched to obtain a pass.

Supersedes: the dynamic x86 fixed-witness ELF as proof target -> the freestanding RV64I
artifact. The historical x86 binding is retained; the x86 JSON CLI remains independently tested.
The full release still fails closed. Passing the component gate does not claim full completion.

The existing external factory authority is unchanged. The new policy contract manifest is a
proposed review identity and does not install itself into that authority. The frozen release
checkpoint remains untouched and conservatively lists replay as a broader unresolved item.
