# Reviewed implementation authority

`frozen.json` preserves the original four-bit semantics, interpreter laws/bridge,
independent tests, certificate laws, and exact native artifact binding. Implementation
proofs and runtime code are checked against these contracts; native identity is additionally
bound by `machine/artifact.json`. Updating a pin requires a separately reviewed change.

Factory installation uses a directory outside the candidate checkout containing reviewed
copies of `check.py`, `frozen.json`, and `stage.py`. Configure `runtime_tests` to execute that
external `stage.py`; keep the interpreter verifier as the `vectors` command. The kernel file
list additionally includes `synthesis/certificates/PROOF.bend` and `synthesis/search/main.bend`.
The latter only checks definitions, not the still-missing universal search laws.

The current factory has this installation. No autonomous provider run was enabled.
The component gate runs the external authority audit, preserved starter gate, certificate
kernel/native/mutation checks, independent search tests, and ELF binding check. The separate
interpreter gate preserves its 14,736 native evaluations and source proofs.

`release.py` remains fail-closed. It cannot be unlocked by editing a JSON status field or
adding a file with a theorem-like name. Replacing it requires reviewing actual completed
law/parser/machine checks. Passing the component gate is a checkpoint, not product completion.
