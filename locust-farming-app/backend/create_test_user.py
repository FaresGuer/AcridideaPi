#!/usr/bin/env python
"""
Script pour créer un compte de test dans la base de données
"""
import sys
sys.path.insert(0, r"C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\locust-farming-app\backend")

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import models
import database
from auth import get_password_hash

# Créer les tables
models.Base.metadata.create_all(bind=database.engine)

# Créer une session
db = database.SessionLocal()

try:
    # Vérifier si l'utilisateur existe déjà
    existing_user = db.query(models.User).filter(models.User.email == "test@locustfarm.com").first()

    if existing_user:
        print("✅ Utilisateur de test existe déjà")
        print(f"   Email: test@locustfarm.com")
        print(f"   Password: test123")
    else:
        # Créer un nouvel utilisateur
        hashed_password = get_password_hash("test123")
        new_user = models.User(
            email="test@locustfarm.com",
            hashed_password=hashed_password,
            full_name="Utilisateur Test",
            is_active=True,
            role="farmer"
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        print("✅ Compte de test créé avec succès!")
        print()
        print("=" * 50)
        print("📧 Identifiants de connexion:")
        print("=" * 50)
        print(f"Email:    test@locustfarm.com")
        print(f"Password: test123")
        print("=" * 50)
        print()
        print("💡 Utilisez ces identifiants pour vous connecter à l'application Flutter")

except Exception as e:
    print(f"❌ Erreur: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
    print("\n✨ Script terminé")

