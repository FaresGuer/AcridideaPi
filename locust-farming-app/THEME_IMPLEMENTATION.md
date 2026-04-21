# Dark/Light Mode Toggle - Implémentation

## Vue d'ensemble
Une fonctionnalité complète de basculement entre les modes sombre (dark) et clair (light) a été ajoutée à l'application. Le bouton se trouve dans la page **Profile** sous la section **System Preferences**.

## Fichiers créés/modifiés

### 1. **ThemeContext.jsx** (NOUVEAU)
- **Localisation** : `src/context/ThemeContext.jsx`
- **Rôle** : Gère l'état global du thème avec React Context
- **Fonctionnalités** :
  - Stockage de la préférence de thème dans `localStorage`
  - Gestion automatique des classes CSS `dark` et `light` sur l'élément HTML
  - Hook `useTheme()` pour accéder au contexte dans les composants

### 2. **main.jsx** (MODIFIÉ)
- **Modification** : Ajout du `ThemeProvider` autour de l'application
- **Effet** : Le contexte de thème est accessible à tous les composants

### 3. **Profile.jsx** (MODIFIÉ)
- **Ajout** : Import et utilisation du hook `useTheme()`
- **Nouveau bouton** : "Theme Mode" dans la section "System Preferences"
- **Fonctionnalités du bouton** :
  - Affiche une icône `dark_mode` en mode sombre
  - Affiche une icône `light_mode` en mode clair
  - Change de couleur : vert (dark) ↔ orange (light)
  - Toggle au clic

### 4. **index.css** (MODIFIÉ)
- **Ajout** : Styles complets pour le mode light
- **Styles** :
  - Couleurs d'arrière-plan claires (#ffffff)
  - Panneaux avec transparence blanche
  - Scrollbar adaptée au mode clair
  - Texte de couleur sombre (#1a1a1a)

### 5. **index.html** (MODIFIÉ)
- **Ajout** : Script d'initialisation du thème
- **Effet** : Charge le thème depuis `localStorage` avant que React ne rende l'application
- **Évite** : Le flash blanc/noir au chargement

### 6. **tailwind.config.js** (MODIFIÉ)
- **Modification** : Ajout de `safelist` pour éviter que les classes soient purgées

## Fonctionnement technique

### 1. **Initialisation**
```javascript
// Au chargement de la page (index.html)
const savedTheme = localStorage.getItem('theme');
// Si rien n'est sauvegardé, défaut = 'dark'
```

### 2. **Basculement**
```javascript
// Dans Profile.jsx
const { isDarkMode, toggleTheme } = useTheme();

onClick={toggleTheme}  // Bascule le thème
```

### 3. **Application des styles**
- **Mode sombre** : classe `dark` ajoutée à `<html>`
- **Mode clair** : classe `light` ajoutée à `<html>`
- Tailwind et CSS réagissent à ces classes

## Persistance
Le thème sélectionné est sauvegardé dans le `localStorage` sous la clé `'theme'` et est restauré à chaque visite.

## Comment utiliser

1. Allez sur la page **Profile** (Settings)
2. Cherchez la section **System Preferences**
3. Trouvez le paramètre **Theme Mode**
4. Cliquez sur le bouton de basculement pour passer du mode sombre au mode clair

## Personnalisation future

Pour personnaliser les couleurs du mode clair, modifiez la section `/* Light Mode Styles */` dans `src/index.css`.

---

**État** : ✅ Complètement implémenté et testé

