from __future__ import annotations

import subprocess
import sys
from shutil import which
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def run(command: list[str]) -> None:
    completed = subprocess.run(command, cwd=ROOT)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)


def main() -> int:
    flutter = which("flutter") or which("flutter.bat")
    if flutter is None:
        raise SystemExit("flutter executable not found in PATH")

    run([sys.executable, "tool/optimize_assets.py"])
    run([flutter, "build", "web", *sys.argv[1:]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
