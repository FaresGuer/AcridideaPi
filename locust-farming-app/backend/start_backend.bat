@echo off
cd /d "%~dp0"
echo Starting backend...
set "PYTHON_EXE=python"
if exist "%~dp0..\.venv\Scripts\python.exe" set "PYTHON_EXE=%~dp0..\.venv\Scripts\python.exe"

"%PYTHON_EXE%" -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
