# What each check establishes

| Boundary | Evidence | Limit |
| --- | --- | --- |
| Coordination | Four bounded TLA+ safety/liveness configurations, 411,510 distinct states, twelve intended counterexample controls | Finite model; explicit fairness, durable atomic commit and receiver action provenance assumptions |
| Actual pure decisions | Pinned Bend kernel checks 23 expression laws and 30 sorting laws about exported task steps and actual checkers | Source-level proof for this task instantiation, not compiler/host correctness or every future domain checker |
| Native behavior | Independent complete replies and multi-step traces, malformed inputs, positive and semantic mutation controls | Finite execution evidence; parser/serialization bridge is not universally proved |
| Effect boundary | Actual compiled BendPort/broker integration and crash, stale generation, replay and concurrency tests | Python, filesystem, locking and recovery are trusted/tested host components, not formally verified here |
| Worker isolation | Real namespace/cgroup capability probes and fail-closed launcher | Prerequisites denied on this runner; no successful hostile OS execution demonstrated |
| Agent interface | Authenticated journal/reopen, semantic-basis/idempotency, failure/witness and condition-wait tests; bounded fresh-agent trials | Python facade is tested, not kernel-proved; no usability-superiority or all-requirements claim |
| Better outputs | A real smaller equivalent expression is independently admitted | No frontier-quality, general RSI, unfamiliar-task distribution or statistical superiority claim |

TLA+ and Bend are related by an explicit design map, not a formal refinement proof.
TLA's arbitrary artifact values abstract the receiver's real task checker; its
qualified pool/incumbent corresponds to measured qualification and incumbent state.
TLA permits frozen replacement races that the implementation disallows, so its
snapshot guards are a deliberate overapproximation. TLA evaluation credits and
worker-compute counters are separate from Bend's per-event action allowance. Both
are separate from physical resource enforcement. Equal counts in different units
are not an implementation correspondence theorem.

TLA's durable atomic commit abstracts the broker's authoritative `read_delivered`
interface. The Python broker journals and restores the last acknowledged artifact
after interrupted replacement. Finite fault-injection tests check selected crash
points and simulated reboot; no filesystem crash-consistency proof is supplied.
Public raw staged files are not an authorized publication interface.

The receiver must control contracts, checker/code identities, native stdin, private
state directory, trusted event channels, deployment and sandbox privileges. Those
are host-enforced prerequisites, not properties that a worker can grant with data.
The checked source transition cannot authenticate its caller or sandbox processes.
Publishing this repository manifest does not install external authority or branch
protection. The proposed contract identity must be adopted outside candidate control.

An adversarial agent generated attacks, and the receiver inspected and reproduced
the meaningful ones through the kernel, native execution and broker tests. Those
agents had shared workspace/tools in this session. Their observance of task scope
is not evidence that an actually malicious process was confined. The launcher
correctly refuses to run that process on the current host.

The revised package's first P1 journey is exercised on exactly eight fixed records.
Its complete wrong-candidate/recovery/right-candidate path uses actual native Bend
and the broker. Two fresh agents read only the initial WorkView and independently
found missing dispatch/expansion guidance. The revised view added those operations;
a third fresh agent reconstructed the qualified baseline, the duplicate-count
witness and a concrete next invocation. The receiver inspected that proposed
candidate and admitted it through the real checker/broker. This is finite interface
comprehension evidence, not a benchmark of general agent ergonomics. The HMAC key
and authoritative journal were not part of the worker view.

Full physical aggregate reservations, hostile driving-agent RPC, private release
fixtures, cross-process wait notification, domain-general qualitative evaluation,
reusable-capability retrieval and the remaining design stages remain open. The
metadata facade is a controlled driving-agent interface; hostile runtime worker
messages still enter only the separately bounded artifact channel.
