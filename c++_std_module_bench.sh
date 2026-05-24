#!/bin/sh
# SPDX-FileCopyrightText: © 2026 Adrian Johnston.
# SPDX-License-Identifier: MIT
#
# Generates linux_modules.md.

set -eu

RUNS=11

# ── Discover toolchain module sources ──────────────────────────────────────

GNU_MODULES_JSON=$(g++ -print-file-name=libstdc++.modules.json)
GNU_STD=$(python3 -c "
import json, os
json_path = '$GNU_MODULES_JSON'
with open(json_path) as f:
    d = json.load(f)
src = next(m['source-path'] for m in d['modules'] if m['logical-name'] == 'std')
print(os.path.normpath(os.path.join(os.path.dirname(os.path.realpath(json_path)), src)))
")
LLVM_STD=$(python3 -c "
import subprocess, os, glob

# Try 1: clang++ -print-file-name for libc++.modules.json
r = subprocess.run(['clang++', '-stdlib=libc++', '-print-file-name=libc++.modules.json'],
                   capture_output=True, text=True)
json_path = r.stdout.strip()
if os.path.isabs(json_path) and os.path.exists(json_path):
    import json
    with open(json_path) as f:
        d = json.load(f)
    src = next(m['source-path'] for m in d['modules'] if m['logical-name'] == 'std')
    print(os.path.normpath(os.path.join(os.path.dirname(os.path.realpath(json_path)), src)))
    exit()

# Try 2: search installed LLVM directories, highest version first
dirs = sorted(glob.glob('/usr/lib/llvm-*'),
              key=lambda p: int(p.rsplit('-', 1)[-1]) if p.rsplit('-', 1)[-1].isdigit() else 0,
              reverse=True)
for base in dirs:
    p = os.path.join(base, 'share', 'libc++', 'v1', 'std.cppm')
    if os.path.exists(p):
        print(p); exit()

raise RuntimeError('LLVM std.cppm not found')
")

printf 'GNU  std module: %s\n' "$GNU_STD" >&2
printf 'LLVM std module: %s\n' "$LLVM_STD" >&2

# ── Generate test source files ─────────────────────────────────────────────

python3 - <<'PYEOF'
import subprocess, sys

with open('headers') as f:
    all_headers = [line.strip()[1:-1] for line in f if line.strip().startswith('<')]

def probe(compiler, extra):
    valid = []
    for h in all_headers:
        r = subprocess.run(
            [compiler] + extra + ['-std=c++23', '-x', 'c++', '-fsyntax-only', '-w', '-'],
            input=f'#include <{h}>\n'.encode(),
            capture_output=True
        )
        if r.returncode == 0:
            valid.append(h)
    return valid

gnu  = probe('g++',     [])
llvm = probe('clang++', ['-stdlib=libc++'])

def write_headers(path, headers):
    with open(path, 'w') as f:
        for h in headers:
            f.write(f'#include <{h}>\n')
        f.write('int main() { std::cout << "hello2\\n"; }\n')

write_headers('gnu_use_headers.cpp',  gnu)
write_headers('llvm_use_headers.cpp', llvm)

gnu_only  = sorted(set(all_headers) - set(gnu))
llvm_only = sorted(set(all_headers) - set(llvm))
print(f'GCC:   {len(gnu)}/{len(all_headers)} headers valid', file=sys.stderr)
print(f'Clang: {len(llvm)}/{len(all_headers)} headers valid', file=sys.stderr)
if gnu_only:
    print(f'GCC  excluded: {gnu_only}',  file=sys.stderr)
if llvm_only:
    print(f'Clang excluded: {llvm_only}', file=sys.stderr)
PYEOF

printf 'import std;\nint main() { std::cout << "hello1\\n"; }\n' > use_module.cpp

# ── Timing functions ────────────────────────────────────────────────────────

median_ms() {
    printf '%s\n' $1 | sort -n | awk -v n="$RUNS" '
        NR == int((n+1)/2) { printf "%d", int($1 / 1000000); exit }'
}

# Build the GCC standard library module from source, clean cache each run.
time_gnu_module_ms() {
    samples=""
    for i in $(seq "$RUNS"); do
        rm -rf gcm.cache/
        t0=$(date +%s%N)
        g++ -std=c++23 -fmodules-ts -w -c "$GNU_STD" -o /dev/null
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# Build the LLVM standard library module from source, clean output each run.
time_llvm_module_ms() {
    samples=""
    for i in $(seq "$RUNS"); do
        rm -f llvm_std.pcm
        t0=$(date +%s%N)
        clang++ -stdlib=libc++ -std=c++23 -w --precompile "$LLVM_STD" -o llvm_std.pcm
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# Pre-build the GCC module once, then time use_module.cpp over $RUNS iterations.
time_gnu_use_module_ms() {
    rm -rf gcm.cache/
    g++ -std=c++23 -fmodules-ts -w -c "$GNU_STD" -o /dev/null
    samples=""
    for i in $(seq "$RUNS"); do
        t0=$(date +%s%N)
        g++ -std=c++23 -fmodules-ts -w \
            -fmodule-file=std=gcm.cache/std.gcm \
            -c use_module.cpp -o /dev/null
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# Pre-build the LLVM module once, then time use_module.cpp over $RUNS iterations.
time_llvm_use_module_ms() {
    clang++ -stdlib=libc++ -std=c++23 -w --precompile "$LLVM_STD" -o llvm_std.pcm
    samples=""
    for i in $(seq "$RUNS"); do
        t0=$(date +%s%N)
        clang++ -stdlib=libc++ -std=c++23 -w \
            -fmodule-file=std=llvm_std.pcm \
            -c use_module.cpp -o /dev/null
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# Time all-headers compilation for GNU over $RUNS iterations.
time_gnu_headers_ms() {
    samples=""
    for i in $(seq "$RUNS"); do
        t0=$(date +%s%N)
        g++ -w -c -o /dev/null -std=c++23 gnu_use_headers.cpp
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# Time all-headers compilation for LLVM over $RUNS iterations.
time_llvm_headers_ms() {
    samples=""
    for i in $(seq "$RUNS"); do
        t0=$(date +%s%N)
        clang++ -stdlib=libc++ -w -c -o /dev/null -std=c++23 llvm_use_headers.cpp
        samples="$samples $(( $(date +%s%N) - t0 ))"
    done
    median_ms "$samples"
}

# ── Correctness check: link and run (untimed) ───────────────────────────────

printf 'Verifying correctness...\n' >&2

rm -rf gcm.cache/ llvm_std.pcm
g++ -std=c++23 -fmodules-ts -w -c "$GNU_STD" -o /dev/null
clang++ -stdlib=libc++ -std=c++23 -w --precompile "$LLVM_STD" -o llvm_std.pcm

g++ -std=c++23 -fmodules-ts -w \
    -fmodule-file=std=gcm.cache/std.gcm \
    -c use_module.cpp -o verify_gnu_module.o
g++ verify_gnu_module.o -o verify_gnu_module
[ "$(./verify_gnu_module)" = "hello1" ] || { printf 'FAIL: GCC module\n' >&2; exit 1; }

clang++ -stdlib=libc++ -std=c++23 -w \
    -fmodule-file=std=llvm_std.pcm \
    -c use_module.cpp -o verify_llvm_module.o
clang++ -stdlib=libc++ verify_llvm_module.o -o verify_llvm_module
[ "$(./verify_llvm_module)" = "hello1" ] || { printf 'FAIL: Clang module\n' >&2; exit 1; }

g++ -std=c++23 -w -c gnu_use_headers.cpp -o verify_gnu_headers.o
g++ verify_gnu_headers.o -o verify_gnu_headers
[ "$(./verify_gnu_headers)" = "hello2" ] || { printf 'FAIL: GCC headers\n' >&2; exit 1; }

clang++ -stdlib=libc++ -std=c++23 -w -c llvm_use_headers.cpp -o verify_llvm_headers.o
clang++ -stdlib=libc++ verify_llvm_headers.o -o verify_llvm_headers
[ "$(./verify_llvm_headers)" = "hello2" ] || { printf 'FAIL: Clang headers\n' >&2; exit 1; }

printf 'All checks passed\n' >&2

# ── Collect timings ─────────────────────────────────────────────────────────

GNU_MODULE_MS=$(time_gnu_module_ms)
LLVM_MODULE_MS=$(time_llvm_module_ms)
GNU_USE_MS=$(time_gnu_use_module_ms)
LLVM_USE_MS=$(time_llvm_use_module_ms)
GNU_HEADERS_MS=$(time_gnu_headers_ms)
LLVM_HEADERS_MS=$(time_llvm_headers_ms)

GNU_VER=$(g++ --version | head -1)
LLVM_VER=$(clang++ --version | head -1)

# ── Output markdown ─────────────────────────────────────────────────────────

exec > linux_modules.md

printf '# Benchmarking C++23 Modules vs Headers\n\n'

printf 'All timings are the median of %d runs. Timings collected on an MSI Stealth A16\n' "$RUNS"
printf 'AI+ A3XVFG.\n\n'

printf 'This script measures three things for C++23: (1) the time to compile the\n'
printf 'toolchain-provided standard library module interface unit from source, (2) the\n'
printf 'time to compile a translation unit that does `import std;` and writes `"hello1"`\n'
printf 'to `std::cout`, and (3) the time to compile a translation unit that `#include`s\n'
printf 'all standard library headers directly and writes `"hello2"` to `std::cout`.\n'
printf 'GCC uses `%s`; Clang uses `%s`.\n\n' "$GNU_STD" "$LLVM_STD"

printf '| Compiler | Version |\n'
printf '|----------|---------|\n'
printf '| GCC      | %s |\n'   "$GNU_VER"
printf '| Clang    | %s |\n\n' "$LLVM_VER"

printf '## Module Build Time\n\n'

printf 'Time to compile the standard library module interface unit from the\n'
printf 'toolchain-provided source. GCC writes a CMI to `gcm.cache/std.gcm` as a\n'
printf 'side-effect of `-c`; Clang produces `llvm_std.pcm` via `--precompile`.\n'
printf 'Each run starts from a clean cache.\n\n'

printf '| GCC ms | Clang ms |\n'
printf '|-------:|---------:|\n'
printf '| %6d | %8d |\n' "$GNU_MODULE_MS" "$LLVM_MODULE_MS"

printf '\n## Using The Module\n\n'

printf 'Time to compile a translation unit that does `import std;` and writes\n'
printf '`"hello1"` to `std::cout`. The module is already compiled before this\n'
printf 'measurement begins; each run times only the import and TU compilation.\n\n'

printf '| GCC ms | Clang ms |\n'
printf '|-------:|---------:|\n'
printf '| %6d | %8d |\n' "$GNU_USE_MS" "$LLVM_USE_MS"

printf '\n## Including All Headers\n\n'

printf 'Time to compile a translation unit that `#include`s all standard library\n'
printf 'headers and writes `"hello2"` to `std::cout`. No precompilation step is\n'
printf 'used; every run parses the full header set from scratch.\n\n'

printf '| GCC ms | Clang ms |\n'
printf '|-------:|---------:|\n'
printf '| %6d | %8d |\n' "$GNU_HEADERS_MS" "$LLVM_HEADERS_MS"

# Quietly delete all .gitignore'd files.
git clean -qXf
