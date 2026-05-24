# Benchmarking C++23 Modules vs Headers

All timings are the median of 11 runs. Timings collected on an MSI Stealth A16
AI+ A3XVFG.

This script measures three things for C++23: (1) the time to compile the
toolchain-provided standard library module interface unit from source, (2) the
time to compile a translation unit that does `import std;` and writes `"hello1"`
to `std::cout`, and (3) the time to compile a translation unit that `#include`s
all standard library headers directly and writes `"hello2"` to `std::cout`.
GCC uses `/usr/include/c++/15/bits/std.cc`; Clang uses `/usr/lib/llvm-20/share/libc++/v1/std.cppm`.

| Compiler | Version |
|----------|---------|
| GCC      | g++ (Ubuntu 15.2.0-4ubuntu4) 15.2.0 |
| Clang    | Ubuntu clang version 20.1.8 (0ubuntu4) |

## 1. Module Build Time

Time to compile the standard library module interface unit from the
toolchain-provided source. GCC writes a CMI to `gcm.cache/std.gcm` as a
side-effect of `-c`; Clang produces `llvm_std.pcm` via `--precompile`.
Each run starts from a clean cache.

| GCC ms | Clang ms |
|-------:|---------:|
|   2280 |     1491 |

## 2. Using The Module (`hello1`)

Time to compile a translation unit that does `import std;` and writes
`"hello1"` to `std::cout`. The module is already compiled before this
measurement begins; each run times only the import and TU compilation.

| GCC ms | Clang ms |
|-------:|---------:|
|    172 |       44 |

## 3. Including All Headers (`hello2`)

Time to compile a translation unit that `#include`s all standard library
headers and writes `"hello2"` to `std::cout`. No precompilation step is
used; every run parses the full header set from scratch.

| GCC ms | Clang ms |
|-------:|---------:|
|    877 |     1142 |
