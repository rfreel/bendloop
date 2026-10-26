# Synthesizer factory run

[BRIEF.md](BRIEF.md) is the requested first-release assignment. Formal-factory's specifier writes the
contract; the chat assistant configures and supervises the factory rather than writing the program.

Use the existing pinned formal-factory installation. Render factory.template.yaml outside the target
with SYNTH_TARGET (factory-owned clone), SYNTH_STATE (new state directory), SYNTH_TOOLS (pinned tools)
and SYNTH_CODEX (authenticated Codex executable). Use absolute paths. Keep credentials out of git.
The configured worker is Codex, with the machine-default account and no account rotation.

Run `ff --config /path/to/factory.yaml validate`, then `ff --config /path/to/factory.yaml run --loops specify`.
Use `status`, `runs`, and `events` with the same config to observe actual progress. The stock factory
supports detached agents; stopping the daemon alone does not stop an agent. Use `ff stop RUN_ID` (cascade is the default in the pinned CLI).

One specifier, at most two attempts for the one contract item, 20 minutes per attempt. The allowance
bounds agent attempts, not dollars. No monetary ceiling is asserted. No public API or web UI is enabled.
Factory integration is local to its clone; remote publishing needs separate authenticated transport.

The draft completeness check only requests human review. It is not a semantic verifier. The starter
kernel/runtime gate remains mandatory, and model.bend is kernel-checked once present. This phase does
not claim proof of a synthesizer that has not been implemented.

After reviewing the exact draft, freeze its semantics, laws, independent fixtures and acceptance
harness; set the implementation backlog to those reviewed obligations, add the synthesizer proof
entry and native checks to the gate, and enable implementation. Approval of a high-level idea must
not silently approve an unseen formal specification. Existing starter acceptance remains intact.
