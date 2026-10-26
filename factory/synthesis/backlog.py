#!/usr/bin/env python3
"""Draft completeness only. Semantic approval belongs to the human, never this script."""
import json
from pathlib import Path

root = Path.cwd() / 'synthesis/spec'
required = ['SPEC.md', 'model.bend', 'cases.json', 'implementation.json']
missing = [name for name in required if not (root / name).is_file() or not (root / name).read_text().strip()]
if not missing:
    try:
        cases = json.loads((root / 'cases.json').read_text())
        tasks = json.loads((root / 'implementation.json').read_text())
        if not isinstance(cases, list) or not cases:
            missing.append('nonempty cases array')
        if not isinstance(tasks, list) or not tasks or any(
            not isinstance(t, dict) or not t.get('id') or not t.get('description') for t in tasks
        ):
            missing.append('implementation tasks with id and description')
    except (ValueError, OSError):
        missing.append('valid JSON')
if missing:
    print('synth-contract\tDraft the synthesizer contract from factory/synthesis/BRIEF.md; missing: ' + ', '.join(missing))
