#!/usr/bin/env python3
"""Check that every blueprint parses as YAML (with HA's !input tag) and has the basic blueprint keys.

Usage: python3 scripts/validate.py   (needs: pip install pyyaml)
"""
import pathlib
import sys

import yaml


class Loader(yaml.SafeLoader):
    pass


Loader.add_constructor("!input", lambda loader, node: {"!input": loader.construct_scalar(node)})

errors = 0
for path in sorted(pathlib.Path(__file__).resolve().parent.parent.glob("blueprints/**/*.yaml")):
    try:
        data = yaml.load(path.read_text(encoding="utf-8"), Loader=Loader)
        meta = data["blueprint"]
        for key in ("name", "domain", "input"):
            if key not in meta:
                raise ValueError(f"blueprint.{key} missing")
        print(f"ok    {path.name}")
    except Exception as exc:  # noqa: BLE001
        errors += 1
        print(f"FAIL  {path.name}: {exc}")

sys.exit(1 if errors else 0)
