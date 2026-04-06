import subprocess
import sys

print("Starting backend server...")
subprocess.run([sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"])

