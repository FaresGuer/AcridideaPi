# 🚀 GUIDE DE DÉMARRAGE - LocustFarm Flutter App

## ⚠️ PROBLÈME ACTUEL
L'erreur "Not Found" lors du login indique que le backend ne fonctionne pas correctement.

## ✅ SOLUTION - ÉTAPES À SUIVRE MANUELLEMENT

### ÉTAPE 1: Démarrer le Backend

1. **Ouvrez PowerShell** (ou CMD)

2. **Naviguez au dossier backend:**
```powershell
cd "C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\locust-farming-app\backend"
```

3. **Lancez le serveur:**
```powershell
python simple_main.py
```

4. **Attendez de voir ce message:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

5. **Testez que ça fonctionne:**
   - Ouvrez votre navigateur
   - Allez à: `http://localhost:8000/`
   - Vous devriez voir: `{"message":"Locust Farming API is running","status":"ok"}`

---

### ÉTAPE 2: Vérifier l'Application Flutter

1. **L'application Flutter devrait déjà être ouverte dans Chrome**

2. **Si ce n'est pas le cas, ouvrez un nouveau PowerShell et lancez:**
```powershell
cd "C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\flutter_app"
flutter run -d chrome
```

---

### ÉTAPE 3: Se Connecter

Une fois le backend actif ET l'app Flutter ouverte:

1. **Cliquez sur "Commencer"** dans l'app

2. **Utilisez ces identifiants:**
   - **Email:** `test@locustfarm.com`
   - **Password:** `test123`

3. **Cliquez sur "Connexion"**

---

## 🔍 DÉPANNAGE

### Si vous voyez toujours "Not Found":

1. **Vérifiez que le backend est actif:**
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:8000/" -Method GET
   ```
   Résultat attendu: `message` et `status: ok`

2. **Testez le login directement:**
   ```powershell
   $body = @{username="test@locustfarm.com"; password="test123"}
   Invoke-RestMethod -Uri "http://localhost:8000/token" -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
   ```
   Résultat attendu: `access_token` et `token_type: bearer`

3. **Si ça ne fonctionne pas, redémarrez tout:**
   - Fermez PowerShell avec le backend (Ctrl+C)
   - Tuez Python: `taskkill /F /IM python.exe`
   - Recommencez à l'ÉTAPE 1

---

## 📋 RÉSUMÉ DES FICHIERS MODIFIÉS

### Backend:
- ✅ `simple_main.py` - Backend minimaliste sans dépendances complexes
- ✅ `database.py` - Changé de MySQL à SQLite
- ✅ Utilisateur de test créé

### Flutter:
- ✅ `lib/core/api_service.dart` - Endpoints corrigés (`/token` au lieu de `/api/auth/login`)
- ✅ `lib/screens/landing_page.dart` - Rendu scrollable
- ✅ CORS élargi pour accepter toutes origines

---

## 🎯 ENDPOINTS BACKEND

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/` | GET | Vérifier que le backend fonctionne |
| `/token` | POST | Login (form-data) |
| `/users/me` | GET | Profil utilisateur |
| `/docs` | GET | Documentation Swagger |

---

## ✨ COMPTE DE TEST

```
Email:    test@locustfarm.com
Password: test123
```

---

## 🆘 SI RIEN NE FONCTIONNE

Le backend peut avoir des problèmes de dépendances. Essayez:

```powershell
cd "C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\locust-farming-app\backend"
pip install fastapi uvicorn pyjwt python-multipart
python simple_main.py
```

Puis retestez la connexion dans l'app Flutter.

