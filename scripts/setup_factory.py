#!/usr/bin/env python3
"""Prepare an external factory clone/config. Never starts agents or touches logins."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PIN = "437acfd57c85d1c3bfc6e9c498d30a2ff8f1997b"

def call(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, default=ROOT.parent / "bendloop-factory")
    parser.add_argument("--tools", type=Path, default=ROOT / ".tools")
    args = parser.parse_args()
    out, tools = args.directory.resolve(), args.tools.resolve()
    if out == ROOT or out.is_relative_to(ROOT):
        parser.error("Live factory state must be outside the target repository")
    if out.exists():
        parser.error("Choose a new directory; existing factory state is never overwritten")
    out.mkdir(parents=True)
    call("git", "clone", "https://github.com/Giulio2002/ff.git", str(out / "ff"))
    call("git", "-C", str(out / "ff"), "checkout", "--detach", PIN)
    call(sys.executable, "-m", "venv", str(out / "venv"))
    pip = str(out / "venv/bin/pip")
    call(pip, "install", "pyyaml==6.0.3")
    call(pip, "install", "--no-deps", str(out / "ff"))
    call("git", "clone", "--no-hardlinks", str(ROOT), str(out / "target"))
    call("git", "-C", str(out / "target"), "remote", "set-url", "origin", "https://github.com/rfreel/bendloop.git")
    # Quote paths using JSON strings, which are valid YAML scalar strings.
    text = (ROOT / "factory/factory.template.yaml").read_text()
    for key, path in {"TARGET":out / "target", "STATE":out / "state", "BEND":tools / "bend/bin/bend"}.items():
        text = text.replace("__" + key + "__", json.dumps(str(path)))
    # A command is parsed by a shell; use shell quoting for its path argument.
    import shlex
    text = text.replace("__TOOLS__", shlex.quote(str(tools)))
    (out / "factory.yaml").write_text(text)
    # PATH is supplied to ff's checker and inherited by agents and cold gates.
    launch = f'''#!/bin/sh
set -eu
export PATH={shlex.quote(str(tools / 'lean-4.34.0-linux/bin'))}:{shlex.quote(str(tools / 'bend/bin'))}:"$PATH"
unset BENDTT BEND_DIR
exec {shlex.quote(str(out / 'venv/bin/ff'))} --config {shlex.quote(str(out / 'factory.yaml'))} "$@"
'''
    (out / "ff.sh").write_text(launch)
    (out / "ff.sh").chmod(0o755)
    call(str(out / "ff.sh"), "validate")
    print(f"Prepared: {out}\nNo agent or daemon started. Review SPEC.md, provider/login and limits before launch.")

if __name__ == "__main__":
    main()
