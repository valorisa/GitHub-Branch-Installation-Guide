# Guide d'Installation depuis une Branche GitHub

## Aperçu

Ce dépôt documente un workflow reproductible et axé sur la sécurité pour compiler et installer des logiciels directement depuis une branche Git spécifique d'un projet GitHub. Bien que la plupart des utilisateurs installent des versions stables via des gestionnaires de paquets (Homebrew, apt, etc.), les développeurs, traducteurs et utilisateurs avancés ont souvent besoin de tester des fonctionnalités, des localisations ou des correctifs qui n'existent que dans des branches de développement.

Ce guide fournit une méthodologie généralisée, illustrée par l'exemple concret de la compilation de [NotepadNext](https://github.com/dail8859/NotepadNext) depuis sa branche `l10n_master` (une branche de développement dédiée à la localisation). Les principes s'appliquent à tout projet basé sur CMake/Qt sous macOS Apple Silicon, avec des notes d'adaptation pour d'autres plateformes et systèmes de build.

## Quand Compiler depuis une Branche

| Scénario | Pourquoi compiler depuis une branche |
|----------|-------------------------------------|
| 🌐 Tests de localisation | Vérifier les traductions avant leur fusion dans `main` |
| 🐛 Validation de correctifs | Tester une PR ou un hotfix avant publication officielle |
| 🧪 Expérimentation de fonctionnalités | Essayer des fonctionnalités en développement sans affecter l'installation stable |
| 🔍 Workflow de contribution | Compiler son propre fork + branche avant de soumettre une PR |
| 📦 Débogage de dépendances | Isoler les problèmes de build dans un environnement contrôlé |

> ⚠️ **Avertissement** : Les branches de développement peuvent contenir du code instable, des fonctionnalités incomplètes ou des changements cassants. Testez toujours dans un environnement isolé et ne remplacez jamais votre installation de production sans validation préalable.

## Prérequis (macOS Apple Silicon)

```bash
xcode-select --install
brew install cmake ninja qt@6 pkg-config
brew install ccache
cmake --version && ninja --version && qmake6 --version
```

### Configuration de l'Environnement (spécifique à Qt@6)

```bash
echo 'export PATH="$(brew --prefix qt@6)/bin:$PATH"' >> ~/.zshrc
echo 'export PKG_CONFIG_PATH="$(brew --prefix qt@6)/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc
echo 'export CMAKE_PREFIX_PATH="$(brew --prefix qt@6):$CMAKE_PREFIX_PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Workflow Général : Compiler depuis N'importe Quelle Branche GitHub

### Étape 1 : Cloner la Branche Spécifique

```bash
REPO_URL="https://github.com/NOM_UTILISATEUR/REPO.git"
BRANCH_NAME="branche-a-compiler"
BUILD_DIR="$HOME/Projets/REPO-build"
git clone --branch "$BRANCH_NAME" --depth 1 "$REPO_URL" "$BUILD_DIR"
cd "$BUILD_DIR"
```

### Étape 2 : Préparer l'Environnement de Build

```bash
mkdir -p build && cd build
export CCACHE_DIR="$BUILD_DIR/.ccache"
export CC="ccache clang"
export CXX="ccache clang++"
```

### Étape 3 : Configurer avec CMake

```bash
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/install" \
  -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" \
  ..
```

### Étape 4 : Compiler

```bash
ninja
```

### Étape 5 : Installer ou Exécuter

```bash
cmake --install . --prefix "$BUILD_DIR/install"
# Ou exécuter directement :
./NotepadNext.app/Contents/MacOS/NotepadNext
```

## Exemple Concret : NotepadNext depuis l10n_master

```bash
cd ~/Projets
git clone --branch l10n_master --depth 1 https://github.com/dail8859/NotepadNext.git
cd NotepadNext
mkdir -p build && cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" \
  ..
ninja
open ./NotepadNext.app
```

## Mode Dry-Run : Tester Avant de Compiler

Avant d'exécuter un build complet depuis une branche de développement, il est recommandé de lancer une **simulation dry-run**. Cela vérifie tous les prérequis, détecte les conflits potentiels et affiche les commandes exactes qui seraient exécutées — **sans modifier votre système**.

### Utilisation

```bash
# Copiez-collez ce bloc dry-run (opérations 100% sûres, lecture seule)
echo "🔍 [DRY-RUN] Simulation du build NotepadNext depuis l10n_master"
echo "=============================================================="

# 1. Vérifier les outils de base
echo -e "\n📦 Outils système :"
command -v git >/dev/null && echo "  ✅ git : $(git --version | cut -d' ' -f3)" || echo "  ❌ git manquant"
command -v cmake >/dev/null && echo "  ✅ cmake : $(cmake --version | head -n1)" || echo "  ❌ cmake manquant"
command -v ninja >/dev/null && echo "  ✅ ninja : $(ninja --version)" || echo "  ❌ ninja manquant"

# 2. Vérifier Qt@6
echo -e "\n🎨 Framework Qt :"
if brew list qt@6 >/dev/null 2>&1; then
  echo "  ✅ qt@6 installé : $(brew info qt@6 --json | jq -r '.[0].versions.stable')"
  echo "  📍 Chemin : $(brew --prefix qt@6)"
else
  echo "  ⚠️  qt@6 non installé (serait installé via : brew install qt@6)"
fi

# 3. Vérifier l'espace disque
echo -e "\n💾 Espace disque :"
FREE_SPACE=$(df -g ~/Projets | tail -1 | awk '{print $4}')
echo "  📊 Libre dans ~/Projets : ${FREE_SPACE}GB"
if [[ $FREE_SPACE -lt 3 ]]; then
  echo "  ⚠️  Attention : moins de 3GB libres (recommandé : 5GB+)"
else
  echo "  ✅ Espace suffisant pour le build"
fi

# 4. Vérifier les conflits de nom
echo -e "\n📁 Conflits potentiels :"
if [[ -d ~/Projets/NotepadNext-l10n ]]; then
  echo "  ⚠️  Le dossier ~/Projets/NotepadNext-l10n existe déjà"
  echo "     → Le script peut échouer ou écraser (selon git clone)"
else
  echo "  ✅ Aucun conflit : ~/Projets/NotepadNext-l10n sera créé"
fi

# 5. Afficher les commandes qui SERAIENT exécutées (sans les lancer)
echo -e "\n🔧 Commandes qui seraient exécutées :"
cat << 'CMD_EOF'
  1. cd ~/Projets
  2. git clone --branch l10n_master --depth 1 \
        https://github.com/dail8859/NotepadNext.git \
        NotepadNext-l10n
  3. cd NotepadNext-l10n && mkdir -p build && cd build
  4. cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" \
        ..
  5. ninja
  6. open ./NotepadNext.app  # pour tester
CMD_EOF

# 6. Estimations
echo -e "\n⏱️  Estimations :"
echo "  • Téléchargement : ~50-150 MB (selon connexion)"
echo "  • Taille finale du build : ~1,5-2,5 GB"
echo "  • Temps de compilation M2 : ~5-15 minutes"
echo "  • Utilisation RAM pic : ~2-4 GB"

echo -e "\n✅ [DRY-RUN TERMINÉ] Aucune modification effectuée."
echo "🚀 Pour lancer le VRAI build, exécutez :"
echo "   ./scripts/build-from-branch.sh https://github.com/dail8859/NotepadNext.git l10n_master NotepadNext-l10n"
```

### Interpréter la Sortie

| Message | Signification | Action |
|---------|--------------|--------|
| `✅ git/cmake/ninja` | Outils présents | Procéder au build |
| `❌ cmake manquant` | Dépendance manquante | Exécuter `brew install cmake` d'abord |
| `✅ qt@6 installé` | Prérequis Qt OK | Prêt à compiler |
| `⚠️ qt@6 non installé` | Sera installé automatiquement | Le vrai build déclenchera `brew install qt@6` |
| `✅ Espace suffisant` | >3GB libres | OK pour compiler |
| `⚠️ Dossier existe` | Conflit de nom | Renommer ou supprimer `~/Projets/NotepadNext-l10n` d'abord |

### Pourquoi Utiliser le Dry-Run ?

1. **Sécurité d'abord** : Vérifier les prérequis avant de s'engager dans un build de 15 minutes
2. **Détection de conflits** : Repérer tôt les collisions de noms ou problèmes de permissions
3. **Planification des ressources** : Savoir exactement combien de disque/RAM/temps prévoir
4. **Pédagogique** : Voir les commandes exactes avant leur exécution
5. **Réversible** : Zéro effet de bord — purement informatif

> 💡 **Astuce** : Sauvegardez le bloc dry-run comme script autonome `scripts/dry-run-build.sh` pour le réutiliser sur d'autres projets.

## Mettre à Jour un Build depuis une Branche

```bash
#!/bin/zsh
set -euo pipefail
PROJECT_DIR="$1"
BRANCH="${2:-main}"
cd "$PROJECT_DIR"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull origin "$BRANCH"
[[ -d build ]] && cd build && ninja
echo "✅ $(basename "$PROJECT_DIR") ($BRANCH) mis à jour et recompilé"
```

## Coexistence avec une Installation Stable

| Installation | Emplacement | Commande de lancement |
|-------------|-------------|----------------------|
| Homebrew stable | `/Applications/Notepad Next.app` | `open -a "Notepad Next"` |
| Build branche dev | `~/Projets/NotepadNext/build/NotepadNext.app` | `open ~/Projets/NotepadNext/build/NotepadNext.app` |

## Dépannage

### Qt Non Trouvé
```bash
brew info qt@6
echo $CMAKE_PREFIX_PATH | grep qt@6
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" ..
```

### Incompatibilité d'Architecture
```bash
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 ..
file ./NotepadNext.app/Contents/MacOS/NotepadNext
```

### Échec du Build Après Git Pull
```bash
ninja clean && ninja
# Ou nettoyage complet :
cd .. && rm -rf build && mkdir build && cd build
cmake ... && ninja
```

## Bonnes Pratiques

1. **Isoler les builds** : Utiliser des builds hors-source (dossier `build/`)
2. **Versionner vos installations** : Utiliser des préfixes descriptifs (`~/Apps/NotepadNext-l10n-20260415`)
3. **Documenter les écarts** : Noter les flags CMake personnalisés dans `BUILD_NOTES.md`
4. **Automatiser les mises à jour** : Utiliser le script de mise à jour pour la synchronisation des branches
5. **Tester avant de remplacer** : Valider les builds de développement avant usage critique

## Retour Arrière & Récupération

```bash
cd ~/Projets/NotepadNext
git log --oneline -10
git checkout <hash-commit>
cd build && ninja
# Ou revenir à la branche stable :
git checkout main && git pull origin main && cd build && ninja
```

## Licence

Cette documentation est fournie « en l'état » à des fins éducatives. Aucune garantie, explicite ou implicite, n'est fournie. Les utilisateurs sont responsables de valider les procédures de build dans leur propre environnement.

## Références

- [Dépôt NotepadNext](https://github.com/dail8859/NotepadNext)
- [Documentation CMake](https://cmake.org/documentation/)
- [Formule Homebrew Qt@6](https://formulae.brew.sh/formula/qt@6)
- [Guide des Outils Développeur macOS](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)