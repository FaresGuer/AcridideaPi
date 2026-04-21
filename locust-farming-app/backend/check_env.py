import sys
import os
import fastapi

print(f"Python version: {sys.version}")
print(f"Python executable: {sys.executable}")
print(f"FastAPI version: {fastapi.__version__}")
print(f"FastAPI location: {os.path.dirname(fastapi.__file__)}")

try:
    from fastapi.security import OAuth2PasswordBearer
    print("fastapi.security import: SUCCESS")
except ImportError as e:
    print(f"fastapi.security import: FAILED - {e}")

print("\nSearch paths (sys.path):")
for path in sys.path:
    print(f"  - {path}")
