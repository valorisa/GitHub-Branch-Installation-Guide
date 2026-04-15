#!/bin/zsh
set -euo pipefail
# Usage: ./build-from-branch.sh <repo-url> <branch> <project-name>
REPO_URL="$1"
BRANCH="$2"
PROJECT="$3"
BASE_DIR="$HOME/Projects"
cd "$BASE_DIR"
git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$PROJECT"
cd "$PROJECT"
mkdir -p build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" ..
ninja
echo "✅ $PROJECT ($BRANCH) built successfully in $(pwd)"
