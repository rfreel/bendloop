#!/usr/bin/env python3
"""Fast structural backlog; the authoritative gate still checks every proof."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
laws = re.findall(r"^law ([A-Za-z_][A-Za-z_0-9]*):", (root / "LAWS.bend").read_text(), re.M)
proof = (root / "PROOF.bend").read_text() if (root / "PROOF.bend").exists() else ""
for law in laws:
    if not re.search(r"^def Laws\." + re.escape(law) + r"\(", proof, re.M):
        print(f"{law}\tImplement and prove the fixed public law {law}")
if re.search(r"\?[A-Za-z_]", proof):
    print("open-proofs\tComplete the open proof holes without changing the contract")
