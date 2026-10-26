# Reproduce, inspect, recover

## Local

Use Linux x86_64 and Clang 18. Run `python3 scripts/bootstrap.py`, then `python3 scripts/verify.py`. For a quick edit cycle: `.tools/bend/bin/bend PROOF.bend --check-only`. Do not treat this fast check as the final kernel gate.

`--tools /absolute/path` permits an already installed matching tool directory containing `bend/` and `lean-4.34.0-linux/`. `--authority /trusted/checkout` selects its lock, manifest, cases and limits. `--root /candidate` selects source. Run the verifier script itself from the trusted checkout. The candidate is copied before all gates; checking and compilation use one snapshot.

Outputs go to a fresh `.artifacts/<run>/`; an existing output directory is refused. `receipt.json` links source identities, tools, stages and artifact hashes. Inspect proof.log, program.log, fixture.log and negative-control logs for their underlying observations.

## Statuses

- ACCEPTED: every required stage passed for this snapshot.
- REJECTED: a contract, proof, required output or negative-control requirement failed.
- EXHAUSTED: a time, CPU or output allowance ended evaluation.
- ERROR: tool, environment, compilation or infrastructure failure.

An unaccepted run cannot be promoted by its speed or score. The starter has no ranking or benchmark.

## Upgrade

Choose a release deliberately. Verify its published archive hash, inspect changes to Base, kernel, elaboration and CLI, update toolchain.lock and its executable/Base hashes, rerun proofs, executions and negative controls on a fresh worker. Record the new evidence and review any changed meaning. Do not run `bend update` inside acceptance.

## CI and PRs

The workflow checks out candidate and base separately without persisted credentials. On PRs, bootstrap and acceptance scripts come from base. Changes to protected files fail that gate and require an explicit owner-managed contract revision. Workflows and branch permissions are not self-protecting. Do not run candidate code in a privileged pull_request_target job.

## License

No license grant has been selected by the repository owner. Do not publish the package to BendHub until a license is chosen: hub defaults may differ from GitHub's no-license state.
