# Optional formal-factory setup

This adapter follows [DOC_FOR_AGENT.md](https://github.com/Giulio2002/ff/blob/437acfd57c85d1c3bfc6e9c498d30a2ff8f1997b/DOC_FOR_AGENT.md) at the revision recorded in factory/upstream.lock. The live configuration and factory-owned clone must be outside the target checkout.

## Prepare

Complete the README setup and commit the target first. The setup script clones committed content, not your uncommitted edits:

```sh
python3 scripts/setup_factory.py
../bendloop-factory/ff.sh validate
cd ../bendloop-factory/target
../ff.sh check
```

It installs pinned ff source into a dedicated venv, creates its own target clone, generates an external factory.yaml, and validates it. It does not create accounts, start agents, expose a service, or push changes. The generated ff.sh supplies the pinned Bend/Lean paths. Clang 18 must also be on PATH.

## Review before launch

| Field | Concrete draft |
|---|---|
| Program | The bounded counter and certified receipt core in SPEC.md |
| Spec | SPEC.md, spec/counter.bend and the fixed public LAWS.bend |
| Done | Kernel gate, native demonstration, 29 arithmetic cases, three negative controls, clean reproduction |
| Trusted | Components listed in docs/TRUST.md; no custom FFI |
| Language/repository | Bend 2.0.39; public rfreel/bendloop, main |
| Provider | Proposed Codex using its configured default model; no model name is invented |
| Accounts | Proposed machine default login; rotation disabled |
| Work | One worker, 20 minutes per agent attempt, four attempts per backlog item |
| Performance/audit | No benchmark; optimization and automatic audit loops disabled |
| Interface | Localhost only if launched; no public UI |

Confirm the spec, provider/account choice and paid-run allowance with the user. `limits.budget_usd` would only report spend; it is not a hard monetary ceiling. Attempt limits are per item, not a global lifetime cap.

The specify backlog intentionally emits no work: a concrete spec already exists. With `approval: human`, starting the specify phase requests approval rather than drafting or implementing. Approve only after reviewing that exact specification. The current implementation backlog is empty because the starter laws are already implemented; a successful initial run may have no coding work to do. Adapt the approved contract before expecting agents to build a different program.

## Start only after the above decisions

From the factory directory on a persistent machine, with the chosen Codex CLI already authenticated:

```sh
export FF_API_TOKEN="$(openssl rand -hex 32)"
tmux new-session -d -s bendloop './ff.sh run --api 127.0.0.1:8787 > factory.log 2>&1'
./ff.sh status
./ff.sh decisions
# After explicit human approval, answer the specific decision:
# ./ff.sh decide DECISION_ID yes
```

No web UI is enabled by default. A token protects the API. Keep the token out of Git. Account login is interactive; the owner runs it. If rotation is wanted, use the upstream add_login procedure and include the current account as well.

## Operating

Use `ff.sh status`, `ff.sh events --since 15m`, `ff.sh show ID`, and `ff.sh tail ID`. Failed gates return concrete diagnostics to the agent. Do not change the immutable harness to get a green result. Stopping the ff daemon does not necessarily stop its agent processes: use `ff.sh stop RUN_ID --cascade` for each active run before shutting down.

The factory's own `ff check` enforces its FFI and kernel policies and then invokes this repository's runtime gate. Formal-factory can integrate accepted changes into its main branch; enable remote publishing only within the user's authorized run scope. The starter does not configure GitHub branch protection or claim resistance to a malicious host.
