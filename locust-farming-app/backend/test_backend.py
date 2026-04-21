#!/usr/bin/env python
"""Test du backend"""
import subprocess
import time
import requests
import sys

print("🚀 Test du backend LocustFarm")
print("="*50)

# Démarrer uvicorn
print("📦 Démarrage d'uvicorn...")
process = subprocess.Popen(
    [sys.executable, "-m", "uvicorn", "main:app", "--port", "8000"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

# Attendre que le serveur démarre
time.sleep(5)

print("⏳ Test de la connexion...")
try:
    response = requests.get("http://localhost:8000/")
    print(f"✅ Backend répond: {response.json()}")

    # Test de connexion
    print("\n🔐 Test de connexion...")
    login_data = {
        "username": "test@locustfarm.com",
        "password": "test123"
    }
    response = requests.post(
        "http://localhost:8000/token",
        data=login_data,
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    if response.status_code == 200:
        print(f"✅ Connexion réussie!")
        print(f"   Token: {response.json()['access_token'][:50]}...")
    else:
        print(f"❌ Erreur de connexion: {response.status_code}")
        print(f"   {response.text}")

except Exception as e:
    print(f"❌ Erreur: {e}")

print("\n" + "="*50)
print("✨ Backend prêt sur http://localhost:8000")
print("📚 Documentation: http://localhost:8000/docs")
print("\nAppuyez sur Ctrl+C pour arrêter...")

# Garder le serveur actif
try:
    process.wait()
except KeyboardInterrupt:
    print("\n\n❌ Arrêt du serveur...")
    process.terminate()

