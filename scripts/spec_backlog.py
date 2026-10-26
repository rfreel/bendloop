#!/usr/bin/env python3
"""No drafting jobs: the concrete starter spec is ready for human approval."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
required = ["SPEC.md", "spec/counter.bend", "LAWS.bend"]
missing = [p for p in required if not (root / p).is_file()]
if missing:
    raise SystemExit("Missing review material: " + ", ".join(missing))
