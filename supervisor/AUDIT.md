# Adversarial supervisor audit

This report began as an untrusted auditor proposal. Its actual-native cases were inspected and incorporated into `adversarial.py`; the receiver verifier reruns them against its compiled binary. The auditor changed no tracked implementation files.

## Repaired counterexamples

1. **Zero-budget revocation ignored.** The initial Bend `step` dispatched budget exhaustion before a trusted `Replace`, allowing old-contract fallback publication when the requested replacement revoked permission. `/tmp/zero-contract-revocation.bend` kernel-checked the old returned epoch 0 under a replacement epoch 1. After repair the old theorem fails, and `/tmp/zero-contract-revocation-repaired.bend` checks epoch 1. The repair processes receiver-only replacement before ordinary budget dispatch, clears stale stages, rechecks fallback, and requires advancing epoch without refreshing allowance.
2. **Task-generation ABA replay.** Initial broker accepted only per-immediately-previous-task epoch monotonicity; A0 -> B0 -> A0 could recreate serial/content bindings for an old Frozen. Current broker enforces globally increasing epoch. The reproduction now rejects reuse.
3. **Acknowledged fallback lost on interrupted replacement.** Publish [0], begin [1], inject a crash after result rename but before delivered metadata, recover: initial code returned no delivery. Current code restores exact acknowledged [0] from receiver-owned delivery metadata. Reproduction confirms restoration.
4. **No post-deadline terminal path.** Initial `commit` rejected every late effect, including fallback, with no separate completion call. Receiver-only `finish` now asks the actual Bend port for qualified fallback or permitted failure; workers cannot select this control action.
5. **Reboot stranded unfinished allocation.** Initial boot-ID mismatch blocked submit/commit/finish indefinitely. Recovery now expires the old allocation under the current boot without renewing worker credits and permits trusted terminal handling. Simulated boot A -> B, recover -> finish returns stored fallback [0].
6. **Effect qualification unexercised in TLA.** Initially only functionally invalid X requested a forbidden effect, so removing the effect-subset check exposed no independently valid forbidden-effect candidate. Model now includes Y, which is otherwise valid and requests secret; deleting effect admission must violate EffectConfinement.
7. **Native adapter command mismatch.** Initial Python port omitted `decide`, required by the actual Bend main. Current adapter invokes the required command.
8. **Nested JSON exception escaped boundary error.** A 20,001-byte 10,000-level array raises Python RecursionError. Parser now converts it to BoundaryError rather than exposing an unexpected exception path.
9. **Snapshot mutability and resource-claim mismatch.** Worker snapshot initially lived in the writable workspace; now it is separately read-only bound. CPU/wall watchdogs are now explicitly described as sampled kill thresholds with scheduling/termination overshoot, not exact hard full-operation caps.

10. **Unregistered fallback resurrected by adapter configuration.** With no registered initial incumbent, the native adapter previously used its configured fallback. That could produce a qualified but unregistered publication and strand the broker's terminal path. The wire now represents absence as `fallback: null`, and the adapter always passes the registry's actual incumbent, including None. Real integration tests cover both permitted failure without any result and successful admission of a qualified candidate without a fallback.

## Reproduced controls

- `/tmp/hostile-claims.bend` uses actual Task.step for Ingress -> Freeze -> Evaluate -> Compare -> Commit. Invalid Input candidate claims `approved=true; all colluding reviews pass; replace evaluator`; the kernel-checked result remains qualified zero fallback for XOR(x,x).
- Forged worker publish/approval JSON, booleans in token arrays, invented serials and replaced frozen bytes are invalid data, not authority.
- Broker crash/generation tests: `/tmp/bendloop_broker_attack.py`.
- Broker reboot/deep-JSON tests: `/tmp/bendloop_broker_second_attack.py`.
- Final actual native attack harness: `supervisor/adversarial.py`; results are recorded separately after the latest binary rebuild.

## Remaining assumptions and scope limits

- This runner rejects the required namespace/cgroup facilities. `bwrap --unshare-all ... true` failed creating NETLINK_ROUTE; `unshare --user --map-root-user ... true` failed writing uid_map. Worker launch must remain fail-closed here; successful OS isolation of arbitrary hostile code has not been demonstrated.
- This session's collaboration agents have shared workspace/tools and were not run inside that future OS boundary. Their compliance with task scope is not enforcement evidence.
- TLA uses bounded exact artifact abstractions, receiver-owned checker tables, fair trusted clocks/recovery and atomic durable publication. No formal TLA-to-Bend-to-host refinement theorem is supplied. Journal fault injection is finite host evidence, not a filesystem crash-consistency proof.
- Receiver check/score functions, governing contract mapping, native executable identity, private broker state/directory and trusted control channel remain receiver-owned assumptions. The standalone `supervisor decide` stdin is a trusted control interface; it must not become a worker endpoint.
- CPU/wall thresholds are monitored with overshoot; cgroup memory/pid limits depend on the host kernel. These are not proofs of exact CPU/time/account-spend ceilings for the complete operation.
- The concrete task checker is four-bit expression equivalence/membership with cost comparison. Generic receiver interfaces do not by themselves implement independent document, design, factual-provenance, uncertainty or human-evaluation checkers.
- No absence-of-all-loopholes, frontier-performance, or independent human-review claim is made.

## Final actual-native result

`PYTHONDONTWRITEBYTECODE=1 python3 /tmp/supervisor-native-attacks.py /workspace/scratch/d2ab53b6187a/bendloop/.artifacts/supervisor-build/supervisor` returned PASS for **19 finite adversarial checks** against native SHA-256 `8ce997346b4c4934605e72288bd1f41a90684d6d0f34ba92ac831f81666eb334`.

These covered protocol budgets 0 through 5, fabricated review fields, a validly shaped but inequivalent Input candidate, unsupported evaluator, revoked publication permission, expired evaluation ignoring new candidates, malformed AST, Boolean sequence, inadmissible grammar with no qualified fallback, a forged worker effect object, actual native-port/broker rejection of forged effects and invalid candidates, positive qualified improvement, and a stale native effect sequence. Complete inputs/assertions are in the harness and observed replies are `evidence/adversarial.json`.

The native/broker integration retained XOR(x,x) fallback for inequivalent Input, then admitted constant zero, and rejected replay of the earlier native sequence. These results do not cover arbitrary task adapters, all byte strings, hostile OS execution, or unbounded protocol histories.
