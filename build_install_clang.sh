#!/usr/bin/env bash
# Build and install LLVM/Clang 22.1.6 from source to /opt/llvm-22.1.6
# Uses clang-21 + lld-21 (from apt) to bootstrap the build.
set -euo pipefail

LLVM_VERSION=22.1.6
PREFIX=/opt/llvm-${LLVM_VERSION}
JOBS=$(nproc)
LOG=~/build/clang-build.log

stamp() { echo "[clang $(date +%H:%M:%S)] $*"; }

mkdir -p ~/build
exec > >(tee "$LOG") 2>&1

stamp "=== LLVM/Clang ${LLVM_VERSION} build starting (${JOBS} jobs) ==="

# ── dependencies ─────────────────────────────────────────────────────────────
stamp "Installing build dependencies (clang-21, lld-21)..."
sudo apt-get install -y clang-21 lld-21

# ── source ───────────────────────────────────────────────────────────────────
cd ~/build

TARBALL=llvm-project-${LLVM_VERSION}.src.tar.xz
if [ ! -f "$TARBALL" ]; then
  stamp "Downloading LLVM ${LLVM_VERSION}..."
  wget -q --show-progress \
    https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${TARBALL}
else
  stamp "Tarball already present, skipping download."
fi

if [ ! -d "llvm-project-${LLVM_VERSION}.src" ]; then
  stamp "Extracting..."
  tar xf "$TARBALL"
else
  stamp "Source tree already present, skipping extract."
fi

cd llvm-project-${LLVM_VERSION}.src

# ── configure ────────────────────────────────────────────────────────────────
mkdir -p _build && cd _build

stamp "Configuring with CMake..."
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_C_COMPILER=clang-21 \
  -DCMAKE_CXX_COMPILER=clang++-21 \
  -DLLVM_USE_LINKER=lld-21 \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb" \
  -DLLVM_TARGETS_TO_BUILD=X86 \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DLLVM_LINK_LLVM_DYLIB=ON \
  ../llvm

# ── build ─────────────────────────────────────────────────────────────────────
stamp "Building (${JOBS} jobs)... this will take ~20-45 min"
ninja -j"${JOBS}"

# ── install ───────────────────────────────────────────────────────────────────
stamp "Installing to ${PREFIX}..."
sudo ninja install

# ── alternatives ──────────────────────────────────────────────────────────────
stamp "Registering with update-alternatives..."
sudo update-alternatives \
  --install /usr/bin/clang   clang   "${PREFIX}/bin/clang"   220 \
  --slave   /usr/bin/clang++ clang++ "${PREFIX}/bin/clang++"
sudo update-alternatives \
  --install /usr/bin/lld lld "${PREFIX}/bin/lld" 220

stamp "=== Done ==="
"${PREFIX}/bin/clang" --version
