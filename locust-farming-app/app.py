"""ASGI entrypoint shim for `uvicorn app:app` from repository root."""

from pathlib import Path
import sys


ROOT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = ROOT_DIR / "backend"

# Ensure backend modules like `database` and `models` are importable.
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from main import app
