# Receiver-owned supervisor

The first revised-design milestone is now a controlled sorting journey over eight
records, with duplicate preservation, useful rejection feedback and durable handoff.
`interface.py` provides `Task.observe`, `Task.act` and condition-based
`Task.await_events`. `run_controlled_sort` runs one goal/input through a deliberately
wrong producer, the actual native checker, checkpoint/reopen and a correct producer,
returning usable `{date,id,value}` records with receipt/evidence identities.
Receiver deployment supplies the executable and hash; workers supply only artifacts.

```python
from supervisor.interface import run_controlled_sort
result = run_controlled_sort(task_directory,
    "Sort the eight records by date, preserving every record and duplicate.",
    records, receiver_sort_executable, receiver_expected_sha256)
```

The action interface exposes schemas, semantic read dependencies, costs, bounds,
expected findings and recovery paths. Default views show recent receipts and exact
failure witnesses; `observe(focus=id)` expands claims, evidence, artifacts or receipts.
Receipt states distinguish rejected candidates, inconclusive checker failures,
cancellation and unknown effects. Lost acknowledgements require local reconciliation
before another publication. A wait timeout never means the job was cancelled.

`DESIGN_SOURCE.json` binds the supplied design package's exact contents. Every one
of its eighteen requirements has an explicit scoped status in
`interface.REQUIREMENT_STATUS`; this milestone is not all eighteen requirements or
all eight implementation stages. The facade/journal/projector is tested Python,
not a new kernel-proved reducer or a general cross-process RPC service.


The supervisor accepts candidates, not worker authority. `runtime.bend` contains
the generic pure transition function. Its receiver-selected artifact type,
requirements type, checker and quality function are compile-time parameters.
`task.bend` instantiates it with the existing real four-bit expression evaluator:
admission requires evaluator identity 1, grammar membership and equivalence at
all sixteen inputs. Lower operator cost wins; ties keep the incumbent.

```sh
bend supervisor/PROOF.bend --verdict
CC=clang-18 bend supervisor/main.bend -o /tmp/bendloop-supervisor
python3 supervisor/verify.py --tools /path/to/tools
python3 supervisor/tla/check.py --jar /path/to/tla2tools.jar
```

The pinned Bend/tool directory is the existing project's bootstrap layout. TLC's
official download and SHA-256 identity are in `tla/toolchain.json`. The supervisor
gate builds a clean source snapshot, checks both task adapters' actual transition proofs and IO
entries, compiles native code, compares outputs and protocol traces to independent
bit arithmetic, tests semantic mutations, then runs actual native/broker and interface integration. Sorting commands and
its 30 source laws are in [sort/README.md](sort/README.md).
The root starter gate remains a separate check.

`examples/improve.json` is a **receiver control request**, not a worker request:

```sh
/tmp/bendloop-supervisor decide +RTS --threads 1 --gpu off -RTS \
  < supervisor/examples/improve.json
```

It emits the selected artifact `[1]`, constant zero, after independently checking
equivalence to XOR(input,input). Fabricated review fields are invalid input. This
is a finite correctness example, not a frontier performance claim.

Worker ingress is only `Broker.submit(bytes)` in `host/broker.py`. The bytes must
be a bounded token array. Workers cannot call `issue`, `finish`, change the native
contract table, supply events or write production files. `BendPort` constructs the
receiver control request itself and calls the pinned native executable. The broker
rechecks the exact selected canonical bytes, current task/generation and effect
sequence under the same lock as contract changes, then publishes one fixed file.
The authoritative read interface is `read_delivered`, not raw temporary files.

For example, receiver code can create `BendPort(binary, expected_sha256, contracts)`,
then `Broker(private_directory, port)`, call `issue` with an initial snapshot, and
pass worker bytes only to `submit` followed by `commit`. The executable hash and
contract table must come from receiver deployment, not from the worker. Real
integration examples with all constructor arguments are in `host/test_native.py`.
`fallback: null` represents absence; an absent fallback cannot be resurrected from
adapter configuration. At expiry, `finish` yields a checked fallback or failure.

Hostile process execution additionally requires `WorkerBoundary` and an operator-
delegated writable cgroup-v2 subtree. It attaches a worker before exec, removes
network and authority paths, caps output, applies memory/pid controls and kills all
descendants. CPU/wall limits are sampled kill thresholds with possible overshoot.
The launcher requires a dedicated single-threaded process. There is no unsandboxed
fallback. This runner denies the necessary cgroup/namespace facilities, so actual
hostile worker execution is disabled here. This session's adversarial collaboration
agents had shared tools and were **not** isolated by this implementation.

Read [SPEC.md](SPEC.md) for the executable contract, [ASSURANCE.md](ASSURANCE.md)
for the model/implementation/host boundaries, and [AUDIT.md](AUDIT.md) for repaired
counterexamples and unresolved assumptions. The broader synth4 release still has
its original open proofs; this addition does not unlock that release.
