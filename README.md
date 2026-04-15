# GitHub Branch Installation Guide

## Overview

This repository documents a reproducible, safety-first workflow for building and installing software directly from a specific Git branch of a GitHub project. While most users install stable releases via package managers (Homebrew, apt, etc.), developers, translators, and power users often need to test features, localizations, or fixes that exist only in development branches.

This guide provides a generalized methodology, illustrated with the concrete example of building [NotepadNext](https://github.com/dail8859/NotepadNext) from its `l10n_master` branch (a localization-focused development branch). The principles apply to any CMake/Qt-based project on macOS Apple Silicon, with adaptation notes for other platforms and build systems.

## When to Build from a Branch

| Scenario | Why Build from Branch |
|----------|----------------------|
| 🌐 Localization testing | Verify translations before they merge to main |
| 🐛 Bug fix validation | Test a PR or hotfix before official release |
| 🧪 Feature experimentation | Try in-development features without affecting stable install |
| 🔍 Contribution workflow | Build your own fork + branch before submitting a PR |
| 📦 Dependency debugging | Isolate build issues in a controlled environment |

> ⚠️ **Warning**: Development branches may contain unstable code, incomplete features, or breaking changes. Always test in an isolated environment and never replace your production installation without validation.

## Prerequisites (macOS Apple Silicon)

```bash
xcode-select --install
brew install cmake ninja qt@6 pkg-config
brew install ccache
cmake --version && ninja --version && qmake6 --version
```

### Environment Configuration (Qt@6 specific)

```bash
echo 'export PATH="$(brew --prefix qt@6)/bin:$PATH"' >> ~/.zshrc
echo 'export PKG_CONFIG_PATH="$(brew --prefix qt@6)/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc
echo 'export CMAKE_PREFIX_PATH="$(brew --prefix qt@6):$CMAKE_PREFIX_PATH"' >> ~/.zshrc
source ~/.zshrc
```

## General Workflow: Build from Any GitHub Branch

### Step 1: Clone the Specific Branch

```bash
REPO_URL="https://github.com/USERNAME/REPOSITORY.git"
BRANCH_NAME="branch-to-build"
BUILD_DIR="$HOME/Projects/REPOSITORY-build"
git clone --branch "$BRANCH_NAME" --depth 1 "$REPO_URL" "$BUILD_DIR"
cd "$BUILD_DIR"
```

### Step 2: Prepare Build Environment

```bash
mkdir -p build && cd build
export CCACHE_DIR="$BUILD_DIR/.ccache"
export CC="ccache clang"
export CXX="ccache clang++"
```

### Step 3: Configure with CMake

```bash
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/install" \
  -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" \
  ..
```

### Step 4: Compile

```bash
ninja
```

### Step 5: Install or Run

```bash
cmake --install . --prefix "$BUILD_DIR/install"
# Or run directly:
./NotepadNext.app/Contents/MacOS/NotepadNext
```

## Concrete Example: NotepadNext from l10n_master

```bash
cd ~/Projects
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

## Dry-Run Mode: Test Before Building

Before executing a full build from a development branch, it is recommended to run a **dry-run simulation**. This verifies all prerequisites, checks for potential conflicts, and displays the exact commands that would be executed—**without modifying your system**.

### Usage

```bash
# Copy-paste this dry-run block (100% safe, read-only operations)
echo "🔍 [DRY-RUN] Simulation of NotepadNext build from l10n_master"
echo "=============================================================="

# 1. Verify core tools
echo -e "\n📦 System tools :"
command -v git >/dev/null && echo "  ✅ git : $(git --version | cut -d' ' -f3)" || echo "  ❌ git missing"
command -v cmake >/dev/null && echo "  ✅ cmake : $(cmake --version | head -n1)" || echo "  ❌ cmake missing"
command -v ninja >/dev/null && echo "  ✅ ninja : $(ninja --version)" || echo "  ❌ ninja missing"

# 2. Verify Qt@6
echo -e "\n🎨 Qt framework :"
if brew list qt@6 >/dev/null 2>&1; then
  echo "  ✅ qt@6 installed : $(brew info qt@6 --json | jq -r '.[0].versions.stable')"
  echo "  📍 Path : $(brew --prefix qt@6)"
else
  echo "  ⚠️  qt@6 not installed (would be installed via: brew install qt@6)"
fi

# 3. Check disk space
echo -e "\n💾 Disk space :"
FREE_SPACE=$(df -g ~/Projets | tail -1 | awk '{print $4}')
echo "  📊 Free in ~/Projets : ${FREE_SPACE}GB"
if [[ $FREE_SPACE -lt 3 ]]; then
  echo "  ⚠️  Warning: less than 3GB free (recommended: 5GB+)"
else
  echo "  ✅ Sufficient space for build"
fi

# 4. Check for naming conflicts
echo -e "\n📁 Potential conflicts :"
if [[ -d ~/Projets/NotepadNext-l10n ]]; then
  echo "  ⚠️  Directory ~/Projets/NotepadNext-l10n already exists"
  echo "     → Script may fail or overwrite (depending on git clone)"
else
  echo "  ✅ No conflict: ~/Projets/NotepadNext-l10n will be created"
fi

# 5. Display commands that WOULD be executed (without running them)
echo -e "\n🔧 Commands that would be executed :"
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
  6. open ./NotepadNext.app  # to test
CMD_EOF

# 6. Estimates
echo -e "\n⏱️  Estimates :"
echo "  • Download: ~50-150 MB (depending on connection)"
echo "  • Final build size: ~1.5-2.5 GB"
echo "  • M2 compilation time: ~5-15 minutes"
echo "  • Peak RAM usage: ~2-4 GB"

echo -e "\n✅ [DRY-RUN COMPLETE] No modifications performed."
echo "🚀 To launch the REAL build, execute:"
echo "   ./scripts/build-from-branch.sh https://github.com/dail8859/NotepadNext.git l10n_master NotepadNext-l10n"
```

### Interpreting the Output

| Message | Meaning | Action |
|---------|---------|--------|
| `✅ git/cmake/ninja` | Tools present | Proceed to build |
| `❌ cmake missing` | Dependency missing | Run `brew install cmake` first |
| `✅ qt@6 installed` | Qt prerequisite OK | Ready to build |
| `⚠️ qt@6 not installed` | Will be auto-installed | Real build will trigger `brew install qt@6` |
| `✅ Sufficient space` | >3GB free | OK to compile |
| `⚠️ Directory exists` | Naming conflict | Rename or remove `~/Projets/NotepadNext-l10n` first |

### Why Use Dry-Run?

1. **Safety-first**: Verify prerequisites before committing to a 15-minute build
2. **Conflict detection**: Catch naming collisions or permission issues early
3. **Resource planning**: Know exactly how much disk/RAM/time to expect
4. **Educational**: See the exact commands before they execute
5. **Reversible**: Zero side effects—purely informational

> 💡 **Tip**: Save the dry-run block as a standalone script `scripts/dry-run-build.sh` for reuse across projects.

## Updating a Branch Build

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
echo "✅ $(basename "$PROJECT_DIR") ($BRANCH) updated and rebuilt"
```

## Coexistence with Stable Installation

| Installation | Location | Launch Command |
|-------------|----------|---------------|
| Homebrew stable | `/Applications/Notepad Next.app` | `open -a "Notepad Next"` |
| Dev branch build | `~/Projects/NotepadNext/build/NotepadNext.app` | `open ~/Projects/NotepadNext/build/NotepadNext.app` |

## Troubleshooting

### Qt Not Found
```bash
brew info qt@6
echo $CMAKE_PREFIX_PATH | grep qt@6
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" ..
```

### Architecture Mismatch
```bash
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 ..
file ./NotepadNext.app/Contents/MacOS/NotepadNext
```

### Build Fails After Git Pull
```bash
ninja clean && ninja
# Or full clean:
cd .. && rm -rf build && mkdir build && cd build
cmake ... && ninja
```

## Best Practices

1. **Isolate builds**: Use out-of-source builds (`build/` directory)
2. **Version your installs**: Use descriptive prefixes (`~/Apps/NotepadNext-l10n-20260415`)
3. **Document deviations**: Note custom CMake flags in `BUILD_NOTES.md`
4. **Automate updates**: Use the update script for branch synchronization
5. **Test before replacing**: Validate dev builds before critical use

## Rollback & Recovery

```bash
cd ~/Projects/NotepadNext
git log --oneline -10
git checkout <commit-hash>
cd build && ninja
# Or switch to stable:
git checkout main && git pull origin main && cd build && ninja
```

## License

This documentation is provided as-is for educational purposes. No warranty is expressed or implied. Users are responsible for validating build procedures in their own environments.

## References

- [NotepadNext Repository](https://github.com/dail8859/NotepadNext)
- [CMake Documentation](https://cmake.org/documentation/)
- [Homebrew Qt@6 Formula](https://formulae.brew.sh/formula/qt@6)
- [macOS Developer Tools Guide](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
