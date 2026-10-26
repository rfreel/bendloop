# RV64I machine target

Supersedes: dynamically linked x86 ELF as proof target -> freestanding RV64I evaluator.
The historical x86 witness binding remains unchanged. The JSON CLI is a separate native host
interface. This new artifact is a proof target with independent emulation evidence, not a
proved replacement for the Bend evaluator yet.

`interpreter.elf.b64` contains an ELF64 little-endian ET_EXEC image with one 224-byte RX
segment at 0x80000000. It has no dynamic loader, relocation processing, allocator, system
calls or threads. Entry `synth4_eval` uses the RISC-V LP64 integer calling convention:

| Register/memory | Entry or exit meaning |
|---|---|
| a0 at entry | Address of little-endian u32 prefix tokens |
| a1 at entry | Number of tokens, 1..63 |
| a2 at entry | Four-bit input, 0..15 |
| a3 at entry | Address of 504 writable scratch bytes, aligned to eight |
| ra | Valid aligned return continuation |
| a0, a1 at return | Result and status; status 0 succeeds, status 2 rejects |

Token storage must be mapped/readable and four-byte aligned. Scratch, tokens and code are
pairwise disjoint and their ranges do not wrap. The evaluator preserves SP and all callee-saved
registers, does not use a call stack, and may overwrite scratch and caller-saved registers.
Observable normal exit is PC=entry ra with a1=0 and a0 equal to the source evaluation.
Invalid domain/token/shape returns a1=2,a0=0. Memory faults are outside the admitted entry
conditions and are not normal source results.

The loop reads prefix tokens backward, evaluating them on the caller's scratch stack.
NOT changes one element; AND/OR/XOR reduce two. Every admitted expression is handled by the
same bytes. No per-expression executable is emitted.

Rebuild:

```sh
clang-18 --target=riscv64-unknown-elf -march=rv64i -mabi=lp64 -nostdlib \
  -fuse-ld=/path/to/ld.lld -Wl,-T,synthesis/machine/rv64/layout.ld \
  -Wl,--build-id=none synthesis/machine/rv64/evaluator.S -o interpreter.elf
```

`target.json` pins the bytes, assembly, linker script, compiler/linker hashes and formal-model
revision. `verify.py` loads those exact bytes in Unicorn 2.1.4 and checks source-oracle results,
return state, callee-saved registers, immutable inputs and every data memory access.
Its concrete entry example demonstrates runnable loading conditions empirically. It is not a
Lean proof that a formal `Loaded` predicate is satisfiable.

Formal backend: the pinned Basis Sail RISC-V model, revision
fb07094cff916318c34b07494a7d739f1e53989b. Its build was attempted with Lean 4.34.0 and failed before
model elaboration: this runner denies `/proc/<namespace PID>/exe`, which Lean uses to locate
itself (`error: failed to locate application`). This is an infrastructure failure, not a rejected
proof. No toolchain binary was patched or substituted to obtain a verdict.

Remaining machine obligations are explicit: prove reverse-prefix stack evaluation refines
Bend's tree evaluator, connect these actual instructions to that stack evaluation in Sail,
construct a checked nonempty initial state, and separately check the loader/boot assumptions.
The host ELF loader/emulator are currently trusted test infrastructure only. Native/emulated
runs and the source BendTT theorems do not discharge these obligations.
