# Decisions

- Architecture: ordinary project shell plus reusable certified components. The existing agent performs search; no custom search engine.
- Language: stock Bend 2.0.39; Lean 4.34.0 rechecks through BendTT. Baseline platform is Linux x86_64 and Clang 18.
- First component: additive budget receipts and sequential composition. Probability weight and termination potential are distinct; no evidential weighting is implemented here.
- Specification: public counter behavior and accounting are explicit in SPEC.md. Factory specification approval is still a human decision.
- Acceptance: formal source claims and finite native observations are recorded separately; neither substitutes for the other.
- Optional orchestration: formal-factory, pinned to the recorded source revision. Live configuration lives outside the target repository.
- No custom FFI, benchmark, hosted UI, auto-updating toolchain, or unspecified paid run.

Supersedes: building a custom reusable search runner -> use the ordinary coding loop, optionally managed by formal-factory.
