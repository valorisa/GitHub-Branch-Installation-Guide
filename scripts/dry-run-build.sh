#!/bin/zsh
set -euo pipefail
# Usage: ./dry-run-build.sh <repo-url> <branch> <project-name>
REPO_URL="${1:-https://github.com/dail8859/NotepadNext.git}"
BRANCH="${2:-l10n_master}"
PROJECT="${3:-NotepadNext-l10n}"
BASE_DIR="$HOME/Projets"

echo "🔍 [DRY-RUN] Simulation for $PROJECT ($BRANCH)"
echo "================================================"
command -v git >/dev/null && echo "  ✅ git" || echo "  ❌ git missing"
command -v cmake >/dev/null && echo "  ✅ cmake" || echo "  ❌ cmake missing"
command -v ninja >/dev/null && echo "  ✅ ninja" || echo "  ❌ ninja missing"
brew list qt@6 >/dev/null 2>&1 && echo "  ✅ qt@6" || echo "  ⚠️  qt@6 would be installed"
FREE=$(df -g "$BASE_DIR" | tail -1 | awk '{print $4}')
[[ $FREE -ge 3 ]] && echo "  ✅ Disk: ${FREE}GB free" || echo "  ⚠️  Disk: ${FREE}GB (<3GB recommended)"
[[ ! -d "$BASE_DIR/$PROJECT" ]] && echo "  ✅ No naming conflict" || echo "  ⚠️  $PROJECT exists"
echo -e "\n✅ [DRY-RUN OK] Ready to build with: ./build-from-branch.sh $REPO_URL $BRANCH $PROJECT"
