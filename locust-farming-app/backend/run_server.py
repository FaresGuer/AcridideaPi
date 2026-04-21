#!/usr/bin/env python
"""
Script de démarrage du backend LocustFarm
"""
import subprocess
import sys
import time
import os

os.chdir(r"C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\locust-farming-app\backend")

print("=" * 60)
print("🚀 Démarrage du serveur LocustFarm Backend")
print("=" * 60)
print()

try:
    print("📦 Lancement de uvicorn...")
    process = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    print("⏳ Attente du démarrage du serveur...")
    time.sleep(3)

    print("\n✅ Serveur actif sur http://localhost:8000")
    print("📚 Documentation: http://localhost:8000/docs")
    print("\nLogs du serveur:")
    print("-" * 60)

    # Afficher les logs en temps réel
    for line in process.stdout:
        print(line, end='')
        sys.stdout.flush()

except KeyboardInterrupt:
    print("\n\n❌ Serveur arrêté")
    process.terminate()
    sys.exit(0)
except Exception as e:
    print(f"❌ Erreur: {e}")
    sys.exit(1)

