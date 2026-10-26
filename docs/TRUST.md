# Evidence and trust boundary

## Formal scope

Bend's checker plus the BendTT kernel check the source-level propositions imported by PROOF.bend. The gate requires the exact `ALL PROOFS CHECK` verdict with success exit status. The public run refinement is universal over Nat inputs. Receipt conservation is universal for well-formed receipts, including two-batch results. The specific two-batch success example is a closed-instance theorem.

## Finite execution evidence

The native program and 29 cases are checked against Python arithmetic (min and subtraction). This tests actual compiled output. The three negative controls establish that these particular defects are detected. Neither constitutes universal native-code conformance.

## Trusted components

The specification and its correspondence to human intent; Python/gate; pinned Bend executable and Base; source-to-BendTT elaboration; Lean and kernel build; Clang/runtime/linker/system libraries; OS and hardware. Artifact hashes identify bytes and evidence; they are not proofs of meaning, authenticity by themselves, or reproducible-build guarantees.

Bend's kernel cache is identified by the kernel source and Lean version; the gate records the actual cached kernel executable hash. A fresh CI worker builds it from the pinned Lean distribution. A compromised host or poisoned preexisting kernel cache is outside this starter's protection. Use a clean worker for authoritative results.

## Authority

Local verification uses the checkout's protected manifest. Its owner can change both hashes and files. This is drift detection, not an independent enforcement service. PR verification uses the base revision's scripts, lock and manifest; normal candidate changes cannot legitimately change those files. Branch protection, reviewer requirements and permissions must be configured by the repository owner; merely including CODEOWNERS does not enable them.

Formal-factory additionally keeps its live configuration outside the target and freezes spec/ and the declared harness. It is not an OS sandbox. Run untrusted submissions on disposable hosts without credentials.

The local verifier applies wall time, CPU, 16 GiB virtual address-space and 16 MiB file-size limits to each subprocess and kills its process group. Native checks use one CPU worker and GPU off; Bend reserves about 8 GiB of virtual heap plus worker stack space even for small programs. The address-space limit is not a physical-RAM limit. It does not prevent a malicious process from escaping its process group or enforce an account spending ceiling. Factory budgets are reporting thresholds unless a separate enforcement mechanism is installed.
