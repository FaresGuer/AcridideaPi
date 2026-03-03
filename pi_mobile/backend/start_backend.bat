@echo off
echo Starting backend server...
cd /d D:\Locustapp\pi_mobile\backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000
pause

