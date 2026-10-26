# Verification record

## Executed

- Pinned Bend 2.0.39 archive SHA-256 verified; kernel source matched the release.
- `bend PROOF.bend --verdict`: ALL PROOFS CHECK.
- Native example: spent=5 remaining=0.
- 18 single-batch and 11 two-batch cases matched independent Python arithmetic.
- Three negative controls: always refuse, skip the second batch, forged overspent receipt. Each produces a proof rejection.
- Full verification passed in a clean local clone.
- Formal-factory 437acfd57c85d1c3bfc6e9c498d30a2ff8f1997b installed; generated external configuration passed `ff validate`; its own `ff check` passed the FFI policy, kernel recheck and complete native gate.
- [Fresh GitHub runner, initial setup](https://github.com/rfreel/bendloop/actions/runs/40253926382): all steps passed, including downloading pinned tools and building the kernel without the local cache.

The initial gate used textual mutation anchors. The current gate uses independent wrong candidate modules so agent changes to implementation structure do not require harness edits. Local validation passed after that change; see the latest Actions run for the current commit and its downloadable receipt.

## Scope

Universal source-level public run refinement and receipt accounting; finite native output tests and targeted negative controls. Local verification used the existing matching BendTT kernel cache. Fresh Actions verification rebuilt the kernel. Neither proves the native compiler, external IO, specification intent or cryptographic security.

## Factory launch

No agent login, subscription rotation, paid agent run, public web UI, autonomous integration or benchmark was started. The counter starter is already complete. SPEC.md is reviewable, but a first autonomous target and its specification approval remain user decisions. Codex is the proposed provider in the generated configuration, not a confirmed account selection.
