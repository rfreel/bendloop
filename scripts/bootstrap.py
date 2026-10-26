#!/usr/bin/env python3
"""Install hash-pinned Bend/Lean locally; no root, shell installers or auto-update."""
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

def install():
    if platform.system() != "Linux" or platform.machine() != "x86_64":
        raise SystemExit("This release supports Linux x86_64. Use Ubuntu 24.04 or a Linux VM.")
    lock = json.loads((ROOT / "toolchain.lock").read_text())
    tools = ROOT / ".tools"
    tools.mkdir(exist_ok=True)
    for key, folder in [("bend", "bend"), ("lean", "lean-4.34.0-linux")]:
        entry = lock[key]
        marker = tools / (key + ".sha256")
        if marker.exists() and marker.read_text().strip() == entry["sha256"] and (tools / folder / "bin" / key).is_file():
            print(f"{key}: pinned installation already present", flush=True)
            continue
        with tempfile.TemporaryDirectory(dir=tools) as tmp:
            tmp = Path(tmp)
            archive = tmp / entry["url"].rsplit("/", 1)[1]
            print(f"Downloading {key} {entry['version']}", flush=True)
            with urllib.request.urlopen(entry["url"], timeout=120) as src, archive.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            actual = hashlib.file_digest(archive.open("rb"), "sha256").hexdigest()
            if actual != entry["sha256"]:
                raise SystemExit(f"{key}: archive SHA-256 mismatch")
            # The archive is verified against the release pin before extraction.
            subprocess.run(["tar", "--no-same-owner", "--warning=no-unknown-keyword", "-xf", str(archive), "-C", str(tmp)], check=True)
            target = tools / folder
            if target.exists():
                shutil.rmtree(target)
            shutil.move(str(tmp / folder), target)
            marker.write_text(actual + "\n")
    bend = tools / "bend/bin/bend"
    lean = tools / "lean-4.34.0-linux/bin/lean"
    subprocess.run([str(bend), "version"], check=True)
    subprocess.run([str(lean), "--version"], check=True)
    print("Ready. Run python3 scripts/verify.py", flush=True)

if __name__ == "__main__":
    install()
