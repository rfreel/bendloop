#!/usr/bin/env python3
"""Reproduce a fixed contract on an isolated source snapshot; never search or promote."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import shutil
import signal
import subprocess
import tempfile
import time

class GateError(Exception):
    def __init__(self, status, message):
        self.status, self.message = status, message
        super().__init__(message)

def sha(path):
    with Path(path).open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()

def run(command, cwd, env, timeout, log, expect_rejection=False):
    def limits():
        resource.setrlimit(resource.RLIMIT_CPU, (timeout + 2, timeout + 2))
        resource.setrlimit(resource.RLIMIT_AS, (16 * 1024**3, 16 * 1024**3))
        resource.setrlimit(resource.RLIMIT_FSIZE, (16 * 1024**2, 16 * 1024**2))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    with log.open("wb") as out:
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=out,
                                   stderr=subprocess.STDOUT, start_new_session=True, preexec_fn=limits)
        try:
            rc = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            raise GateError("EXHAUSTED", f"Time limit: {command[0]}")
        finally:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
    text = log.read_text(errors="replace")
    if log.stat().st_size >= 16 * 1024**2 or rc in (-signal.SIGXCPU, -signal.SIGXFSZ):
        raise GateError("EXHAUSTED", "CPU or output allowance exhausted")
    if "BendTT infrastructure:" in text or rc < 0:
        raise GateError("ERROR", f"Tool failure: {text[-1200:]}")
    if expect_rejection:
        if rc == 0 or "SOME PROOFS FAIL" not in text:
            raise GateError("REJECTED", "Negative control did not produce a proof rejection")
    elif rc != 0:
        raise GateError("REJECTED" if "SOME PROOFS FAIL" in text else "ERROR", text[-2000:])
    return text

def audit(root, contract):
    for name, expected in contract["protected_sha256"].items():
        p = root / name
        if not p.is_file() or p.is_symlink() or sha(p) != expected:
            raise GateError("REJECTED", f"Protected contract changed: {name}")
    # This is an explicit local import policy, not a security sandbox.
    for p in root.rglob("*.bend"):
        if any(x.startswith(".") for x in p.relative_to(root).parts):
            continue
        if p.is_symlink():
            raise GateError("REJECTED", f"Symlink source: {p}")
        for target in re.findall(r"^\s*import\s+(\S+)", p.read_text(), re.M):
            if target == "Base":
                continue
            if target.startswith(('"', "0x")) or "@" in target:
                raise GateError("REJECTED", f"Unpinned or foreign import: {target}")
            resolved = (p.parent / target).resolve()
            if not resolved.is_relative_to(root.resolve()) or not resolved.is_file():
                raise GateError("REJECTED", f"Import outside snapshot: {target}")

def fixture(cases):
    rows, expected = [], []
    for b, w in cases["single"]:
        rows.append(f"show(R.view({b}n,Counter.run({b}n,{w}n)))")
        expected.append(f"{min(b,w)},{max(0,b-w)}")
    for b, a, c in cases["batches"]:
        rows.append(f"show(R.view({b}n,Counter.batches({b}n,{a}n,{c}n)))")
        expected.append(f"{min(b,a+c)},{max(0,b-a-c)}")
    source = '''import Base
import ./core/receipt.bend as R
import ./src/counter.bend as Counter

def show(pair: Nat & Nat) -> String:
  (used,left) = pair
  Nat.show(used) ++ "," ++ Nat.show(left)

def main() -> IO(Unit):
  IO.print(''' + ' ++ "\\n" ++ '.join(rows) + ')\n'
    return source, "\n".join(expected) + "\n"

def verify(root, authority, tools, output):
    lock = json.loads((authority / "toolchain.lock").read_text())
    contract = json.loads((authority / "acceptance/protected.json").read_text())
    output.mkdir(parents=True, exist_ok=True)
    receipt = {"status": "ERROR", "contract_sha256": sha(authority / "acceptance/protected.json"),
               "started_unix": time.time(), "stages": []}
    env = {k: v for k, v in os.environ.items() if k not in ("BENDTT", "BEND_DIR", "NODE_OPTIONS", "BUN_OPTIONS", "CPATH", "C_INCLUDE_PATH", "PYTHONPATH")}
    bend = (tools / "bend/bin/bend").resolve()
    leanbin = (tools / "lean-4.34.0-linux/bin").resolve()
    cc = shutil.which("clang-18") or shutil.which("clang")
    if cc:
        env["CC"] = cc
    env["PATH"] = str(leanbin) + os.pathsep + env.get("PATH", "")
    env["BEND_NO_TELEMETRY"] = "1"
    try:
        if not bend.is_file() or not cc:
            raise GateError("ERROR", "Run bootstrap and install clang-18 first")
        if sha(bend) != lock["bend"]["binary_sha256"]:
            raise GateError("ERROR", "Bend executable differs from the pinned release")
        kernel = tools / "bend/bend2/bendtt.lean"
        base = tools / "bend/bend2/base.bend"
        if sha(kernel) != lock["bend"]["kernel_source_sha256"] or sha(base) != lock["bend"]["base_sha256"]:
            raise GateError("ERROR", "Kernel or Base differs from the pinned release")
        version = run([str(bend), "version"], root, env, 10, output / "version.log")
        if version.strip() != "2.0.39" and version.strip() != "bend 2.0.39" and version.strip() != "Bend 2.0.39":
            raise GateError("ERROR", "Unexpected Bend version: " + version)
        compiler = run([cc, "--version"], root, env, 10, output / "compiler.log")
        if not re.search(r"clang version 18\.", compiler):
            raise GateError("ERROR", "This baseline requires clang 18")
        receipt["tools"] = {"bend_sha256": sha(bend), "base_sha256": sha(base),
                            "kernel_source_sha256": sha(kernel), "clang_sha256": sha(cc), "clang_version": compiler.strip()}
        # Copy before checking, building or hashing: every later stage uses this same snapshot.
        with tempfile.TemporaryDirectory(prefix="bendloop-") as temp:
            snapshot = Path(temp) / "source"
            shutil.copytree(root, snapshot, symlinks=True,
                            ignore=shutil.ignore_patterns(".git", ".tools", ".artifacts", "__pycache__"))
            if any(p.is_symlink() for p in snapshot.rglob("*")):
                raise GateError("REJECTED", "Snapshot contains a symlink")
            audit(snapshot, contract)
            receipt["sources"] = {str(p.relative_to(snapshot)): sha(p) for p in sorted(snapshot.rglob("*")) if p.is_file()}
            receipt["stages"].append("contract")
            text = run([str(bend), "PROOF.bend", "--verdict"], snapshot, env,
                       lock["proof_timeout_seconds"], output / "proof.log")
            if text.strip() != "ALL PROOFS CHECK":
                raise GateError("ERROR", "Missing exact kernel verdict")
            receipt["stages"].append("kernel")
            kernel_key = hashlib.sha256((lock["lean"]["version"] + "\0").encode() + kernel.read_bytes()).hexdigest()[:16]
            cached = Path.home() / ".bend/bendtt" / kernel_key / "bendtt"
            if cached.is_file():
                receipt["tools"]["kernel_binary_sha256"] = sha(cached)
            run([str(bend), "PROOF.bend", "-o", str(output / "PROOF.bendtt")], snapshot, env,
                lock["proof_timeout_seconds"], output / "translation.log")
            for entry, binary in [("main.bend", "program"), ("fixture.bend", "fixture")]:
                cases = json.loads((authority / "acceptance/cases.json").read_text())
                if entry == "fixture.bend":
                    code, expected = fixture(cases)
                    (snapshot / entry).write_text(code)
                else:
                    expected = cases["main_stdout"]
                run([str(bend), entry, "-o", str(output / binary)], snapshot, env,
                    lock["build_timeout_seconds"], output / (binary + "-build.log"))
                observed = run([str(output / binary), "+RTS", "--threads", "1", "--gpu", "off", "-RTS"], snapshot, env,
                               lock["execution_timeout_seconds"], output / (binary + ".log"))
                if observed != expected:
                    raise GateError("REJECTED", f"Execution mismatch: {binary}")
                receipt["stages"].append(binary)
            candidate = snapshot / "src/counter.bend"
            original = candidate.read_text()
            mutations = {
                "always_refuse": ("R.tick(n,run(n,w))", "R.empty(1n+n)"),
                "reset_composition": ("remaining => run(remaining,second)", "remaining => R.empty(remaining)")}
            for name, (old, new) in mutations.items():
                if original.count(old) != 1:
                    raise GateError("ERROR", f"Update the reviewed mutation anchor: {name}")
                candidate.write_text(original.replace(old, new))
                run([str(bend), "PROOF.bend", "--verdict"], snapshot, env,
                    lock["proof_timeout_seconds"], output / (name + ".log"), expect_rejection=True)
                candidate.write_text(original)
                receipt["stages"].append("rejected:" + name)
            (snapshot / "forged.bend").write_text('''import Base
import ./core/receipt.bend as R

def forge() -> R.Receipt<0n>:
  R.Receipt{1n,0n,{==}}
''')
            run([str(bend), "forged.bend", "--verdict"], snapshot, env,
                lock["proof_timeout_seconds"], output / "forged.log", expect_rejection=True)
            receipt["stages"].append("rejected:forged_receipt")
        receipt["status"] = "ACCEPTED"
    except GateError as e:
        receipt.update(status=e.status, reason=e.message)
    except (OSError, ValueError, KeyError) as e:
        receipt.update(status="ERROR", reason=str(e))
    finally:
        receipt["finished_unix"] = time.time()
        receipt["artifacts"] = {p.name: sha(p) for p in sorted(output.iterdir()) if p.is_file() and p.name != "receipt.json"}
        (output / "receipt.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(receipt["status"] + (": " + receipt["reason"] if "reason" in receipt else ""), flush=True)
    print(output / "receipt.json", flush=True)
    return 0 if receipt["status"] == "ACCEPTED" else 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--authority", type=Path, help="Trusted baseline checkout; defaults to root for local use")
    parser.add_argument("--tools", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    authority = (args.authority or root).resolve()
    tools = (args.tools or authority / ".tools").resolve()
    output = (args.output or root / ".artifacts" / str(time.time_ns())).resolve()
    if output.exists():
        parser.error("Output must be a new directory")
    raise SystemExit(verify(root, authority, tools, output))
