# bendloop

A Bend 2 project starter with a reusable, certified core. Your coding agent edits the implementation and its proofs; fixed laws define acceptance. Formal-factory is an optional orchestrator, not a dependency of the program.

## Run the complete example

Supported baseline: Ubuntu 24.04, Linux x86_64, Python 3.11+, Clang 18, tar and zstd. Install prerequisites with your system package manager (`sudo apt-get install clang-18 zstd python3 python3-venv git`).

```sh
git clone https://github.com/rfreel/bendloop.git
cd bendloop
python3 scripts/bootstrap.py
python3 scripts/verify.py
```

The installer checks SHA-256 pins for Bend 2.0.39 and Lean 4.34.0. It downloads about 590 MB and needs approximately 4 GB of disk. It does not install an agent or start a paid run.

An accepted run prints `ACCEPTED` and a receipt path under `.artifacts/`. That directory contains the kernel verdict, emitted BendTT, native executables, full execution logs, negative-control failures, source hashes and tool identities. The example prints:

```text
spent=5 remaining=0
```

The example performs two batches (2 and 4 units) under one allowance of 5. The second batch receives only what remains. Inspect [the specification](SPEC.md), [laws](LAWS.bend), and [core](core/receipt.bend).

## The reusable core

`Receipt<budget>` contains `spent`, `left`, and a proof that `spent + left = budget`. `empty` constructs an untouched allowance; `tick` extends a certified run by one charged unit; `then` combines a receipt with a continuation over its remaining allowance. Composition preserves the accounting proof.

This is an accounting witness, not an unforgeable global token or proof that an external action happened. The counter's separate refinement law ties its returned receipt to the specified computation. Logical tokens do not measure CPU time, wall time or memory.

## Start another project

Read [AUTHORING](docs/AUTHORING.md), replace the counter specification and public laws with the agreed task, and keep the core components that fit. Agents read [AGENTS.md](AGENTS.md). Do not inherit the counter's completion criteria for unrelated applications.

For managed worktrees, gated integration and audit loops, follow [FORMAL_FACTORY](docs/FORMAL_FACTORY.md). Its configuration is generated **outside** the target checkout. The concrete starter specification is ready for review; no factory agent run is authorized by merely passing these tests.

## Map

| Path | Purpose |
|---|---|
| `SPEC.md`, `spec/`, `LAWS.bend` | Human-reviewed meaning and claims |
| `core/` | Reusable certified constructors |
| `src/`, `PROOF.bend`, `proofs/` | Implementation and proofs |
| `main.bend` | Thin native IO demonstration |
| `scripts/`, `acceptance/` | Reproduction and negative controls |
| `toolchain.lock` | Release and checker identities |
| `factory/` | Optional formal-factory configuration template |
| `docs/TRUST.md` | What is proved, tested, and trusted |

No cryptographic security, compiler correctness, full four-operation search engine, or universal correctness beyond the stated laws is claimed.

## Bounded learning experiments

[synthesis/policy](synthesis/policy/README.md) runs an executable finite policy
language that can revise its own proposal ordering, measures adaptation and
transfer, and compares subsequent revision branches. [Typed replay laws](synthesis/replay/README.md)
now bind accepted portable packets to the actual evaluator and claimed fields.
These are component results. [The audit](synthesis/policy/AUDIT.md) records remaining
findings; the full synth4 release still fails closed.

## Receiver-owned supervisor

[supervisor/](supervisor/README.md) adds the bounded TLA+ coordination model,
Bend-proved admission/effect decisions, a fixed-file broker and a durable
observe/act/await interface. The controlled sorting journey preserves duplicate
records, retains failure witnesses and resumes without conversation replay.
Actual hostile process launch fails closed when required OS isolation is absent.
See the explicit [assurance boundary](supervisor/ASSURANCE.md); this does not
complete the original full synth4 release or all cross-domain design stages.
