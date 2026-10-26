# Receiver-owned host boundary

This directory handles IO and Linux process isolation. It does not implement task
admission in Python. `BendPort` invokes the pinned compiled Bend supervisor; the
receiver owns its executable identity, task contract table, logical transaction
allowance and event construction. A worker can submit only bounded candidate bytes.
It cannot supply a contract, event list, evaluator identity, publication instruction
or an `approved` flag.

The current native adapter uses the four-bit expression task plugin. Incoming JSON
must be an array of 1..63 integer tokens in 0..20, with at most 64 KiB of original
bytes. The broker copies and canonicalizes the array. Bend checks actual AST shape,
equivalence, protected predicates, comparison and authorization. Original byte hashes
are provenance only; the exact canonical token array is the checked artifact. No
hash or review supplied by a worker is accepted as authority.

`Broker.issue` is a trusted control call and installs a strictly advancing global
generation, receiver ingress allowance, absolute monotonic deadline and optional
initial fallback snapshot. Contract updates and publication share an OS file lock.
`submit` charges every arrival, including malformed artifacts, and registers exact
immutable candidate data. `commit` calls Bend while the contract-change lock is held,
checks the returned task/epoch/sequence and exact winner against registered snapshots,
and atomically replaces one fixed `result.bin` through a private directory file
descriptor. It never follows a worker-supplied path. The native decision may select
the receiver fallback rather than the latest candidate.

Only `read_delivered` is the authoritative delivery API. Raw files, old file handles,
staged bytes and worker stdout are not authority channels. Publication uses an exact
acknowledged-artifact record. On a process crash, `recover` discards incomplete writes
or restores the previous acknowledged incumbent. If the acknowledgement was durable,
it restores the sequence guard. It never replays a non-idempotent external action.
Only a local atomic byte replacement is supported; services, payments and arbitrary
filesystem effects need separate transactional adapters and authorization proofs.

At the deadline, a receiver-controlled `finish` call asks Bend for a rechecked
fallback or permitted terminal failure. The native request uses only the current
registered incumbent, including explicit absence; a configured default cannot
resurrect an unregistered fallback. Worker events cannot select this path.
A reboot causes recovery to expire the old allocation and consume remaining ingress
credit under the new boot, without granting new worker time. The terminal path then
rechecks the fallback. The TLA+ model's process-crash coverage should not be read as
an independent proof of this Python reboot recovery behavior.

`WorkerBoundary` requires both a delegated writable cgroup-v2 subtree with memory,
swap, pids, CPU-rate and cgroup-kill controls, and a successful namespace probe. It
attaches the child to its bounded cgroup before exec. Bubblewrap exposes readonly
system binaries, a private writable workspace and a separately readonly task snapshot;
there is no network namespace connection, inherited credentials or authority directory.
Stdout/stderr are bounded arbitrary bytes. Termination kills the whole cgroup and
waits for it to become empty, including detached descendants. There is no unsandboxed
fallback. The worker launcher must run in a dedicated single-threaded process; it
fails closed if Python threads are active, rather than using an unsafe pre-exec
hook in a threaded host. The broker itself serializes both threads and processes.
The trusted native Bend adapter uses `prlimit` without a Python pre-exec hook.

Memory and pid controls rely on Linux cgroups. CPU and wall time are **sampled kill
thresholds**, not exact hard total resource caps: scheduling, polling and termination
can overshoot. The report separates worker wall time from the full operation wall
time including preparation. The supervisor's global budget, checker preparation and
concurrent-worker limits still require receiver accounting. The compiled Bend port is
trusted pure receiver code and has a separate process-group timeout; this timeout is
not used as the hostile-worker isolation mechanism.

On this runner `/sys/fs/cgroup` is read-only, so hostile process execution is disabled
and fails before any worker code executes. A delegated cgroup must be supplied by the
host operator through trusted configuration. Merely installing Bubblewrap is not an
enforcement result. The capability observation records actual prerequisites rather
than assuming they work.

Run the broker tests and capability probe:

```sh
python3 supervisor/host/test_host.py
```

Those tests use a fake **trusted** native callback to test IO, crash behavior, replay
rejection and confinement. They are not admission proofs. The test writes the actual
host capability observation under `.artifacts/supervisor-host-capability.json`.
For native integration, run `test_native.py` with the compiled supervisor executable;
that test does not execute hostile workers or claim a working sandbox on this runner.

```sh
python3 supervisor/host/test_native.py --binary /path/to/compiled-supervisor \
  --sha256 RECEIVER_EXPECTED_EXECUTABLE_SHA256
```

The native integration suite exercises the actual Bend decision and exact broker
publication, including a real valid improvement, inequivalent/malformed candidates,
unknown evaluator, denied effects, retained equal/worse qualified candidates,
deadline fallback and stale generations. Its report is separate from the fake-port
IO tests.

The Python broker, its parent-only dispatcher, contract storage, executable pin,
filesystem/locking/fsync semantics, native compiler/runtime, Linux kernel and host
scheduler remain trusted components. Python object privacy is not a security boundary:
untrusted worker code must never execute inside the broker process or receive these
objects/file descriptors. Candidate generation runs only through the isolated host
boundary. Host state corruption or a caller that can replace the receiver's port or
contract table is outside this guarantee.
