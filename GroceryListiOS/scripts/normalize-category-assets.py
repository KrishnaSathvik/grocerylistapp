#!/usr/bin/env python3
"""Normalize bundled category PNGs (delegates to normalize-catalog-assets)."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "normalize-catalog-assets.py"


def main() -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--only", "category"],
        check=False,
    )
    raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
