# Factory launch observation

The factory configuration validated and its existing kernel/runtime gate passed.
Codex CLI 0.164.0 was installed; `codex login status` reported a ChatGPT login.

The actual specify worker `specifier-1025-190607-c520` started under formal-factory,
but produced no transcript, stderr, specification files, or model response during
approximately two minutes of observation. Worker child processes included sandbox
filesystem helpers; the exact startup failure was not established. No claim of a
completed specification or implementation is made.

The specify loop was paused and the worker stopped through `ff stop`. Factory status
confirmed zero running agents and one blocked backlog item. No manual implementation
was substituted. Reported factory spend is $0; the empty usage report is not an
independent billing audit.

Before resuming, establish that the Codex worker can complete a bounded task on the
execution host. Then reopen `synth-contract` and resume the specify loop. The drafted
contract still requires human review before implementation is enabled. The setup
and brief are reproducible from this directory; runtime state remains on the host.
