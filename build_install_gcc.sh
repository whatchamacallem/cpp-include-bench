#!/usr/bin/env bash
# Build and install GCC 16.1 from source to /opt/gcc-16.1
set -euo pipefail

GCC_VERSION=16.1.0
PREFIX=/opt/gcc-${GCC_VERSION}
BUILDROOT=~/build/gcc
JOBS=$(nproc)
LOG=~/build/gcc-build.log

stamp() { echo "[gcc $(date +%H:%M:%S)] $*"; }

mkdir -p ~/build
exec > >(tee "$LOG") 2>&1

stamp "=== GCC ${GCC_VERSION} build starting (${JOBS} jobs) ==="

# ── dependencies ────────────────────────────────────────────────────────────
stamp "Installing build dependencies..."
sudo apt-get install -y \
  flex bison \
  libgmp-dev libmpfr-dev libmpc-dev libisl-dev libzstd-dev

# ── source ──────────────────────────────────────────────────────────────────
mkdir -p ~/build
cd ~/build

TARBALL=gcc-${GCC_VERSION}.tar.xz
if [ ! -f "$TARBALL" ]; then
  stamp "Downloading GCC ${GCC_VERSION}..."
  wget -q --show-progress \
    https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${TARBALL}
else
  stamp "Tarball already present, skipping download."
fi

if [ ! -d "gcc-${GCC_VERSION}" ]; then
  stamp "Extracting..."
  tar xf "$TARBALL"
else
  stamp "Source tree already present, skipping extract."
fi

cd gcc-${GCC_VERSION}

stamp "Downloading prerequisites (GMP/MPFR/MPC/ISL)..."
contrib/download_prerequisites

# ── configure ───────────────────────────────────────────────────────────────
mkdir -p _build && cd _build

stamp "Configuring..."
../configure \
  --prefix="${PREFIX}" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --with-system-zlib \
  --enable-lto \
  --program-suffix=-16

# ── build ────────────────────────────────────────────────────────────────────
stamp "Building (${JOBS} jobs)... this will take ~20-30 min"
make -j"${JOBS}"

# ── install ──────────────────────────────────────────────────────────────────
stamp "Installing to ${PREFIX}..."
sudo make install

# ── alternatives ─────────────────────────────────────────────────────────────
stamp "Registering with update-alternatives..."
sudo update-alternatives \
  --install /usr/bin/gcc gcc "${PREFIX}/bin/gcc-16" 160 \
  --slave   /usr/bin/g++ g++ "${PREFIX}/bin/g++-16"

stamp "=== Done ==="
"${PREFIX}/bin/gcc-16" --version
