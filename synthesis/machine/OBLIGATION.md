# Machine boundary: open obligation

Selected target: x86-64, System V AMD64 ABI, Linux ELF64 PIE. `artifact.json`
pins the exact emitted bytes stored as `interpreter.elf.b64`. `check_binding.py`
checks byte identity, source hashes, ELF target, segments and executable entry.
This check does not establish compiler correctness, machine execution, or loading satisfiability.
The pinned executable runs the frozen fixed witness. Its process entry does not accept arbitrary
ASTs. A general interpreter entry artifact must replace this witness binding before a general
binary-refinement claim can be discharged. Retain this historical binding when doing so.

## Required formal interface

Choose and pin an executable x86-64 instruction semantics before stating the final theorem.
Define `Loaded(artifact, sourceInput, machineState)` concretely, including:

- Load bias and disjoint mapped intervals for each PT_LOAD segment. Initial bytes equal
  the artifact slice; the remaining memory through memsz is zeroed. Permissions match flags.
- Relocations, the dynamic interpreter and dependent libraries with exact identities, and
  initialized TLS/GOT. The current ELF requires a dynamic loader, not just segment copying.
- Initial RIP at load bias plus the recorded entry, Linux initial stack containing argc,
  argv, envp and auxiliary vector, mapped stack bounds, and the ABI's entry invariants.
- Bend's tagged Term representation, heap allocation/initial contents and worker state.
  Map the source AST and four-bit input to the actual evaluator's argument representation;
  identify the actual generated function entry and return continuation in these bytes.
- Available heap/stack and any arithmetic/address bounds as explicit finite preconditions.
  No unrestricted oracle for evaluator calls, allocation, libc, threads, or system calls.

Define observable exits as process exit code and stdout byte trace (including newline).
Distinguish normal result, resource failure, signal, divergence and I/O failure. A claimed
normal result must decode to the source evaluator's value, not just terminate.
For an evaluator-call theorem, separately define return register, restored stack and permitted
memory effects; then prove the process wrapper transports that result to the observable trace.

Required theorem: concrete execution of the pinned bytes from every `Loaded` state refines the
source interpreter. Provide an explicit finite machine-state witness and a checked proof that
`Loaded` holds, with an example input. This prevents vacuous correctness through impossible
loading conditions. Compiler success, native test output, and source BendTT proofs cannot
replace this theorem or witness.

## Separate boot/loader evidence

Keep checked boot and dynamic-loader traces, exact loader/library hashes and their checking
commands in a separate evidence object. State which host/Linux behavior is assumed. Do not
fold loader success into an unchecked `Loaded` axiom or label a host run a kernel proof.
No formal machine model, loading witness, binary refinement proof or separately checked loader
trace has been supplied in this repository. The full Basis-style claim remains blocked.
