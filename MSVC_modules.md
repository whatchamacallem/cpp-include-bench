# Benchmarking C++23 Modules vs Headers

All timings are the median of 11 runs. Timings collected on an MSI Stealth A16
AI+ A3XVFG.

This script measures three things for C++23: (1) the time to compile the
toolchain-provided standard library module interface unit from source, (2) the
time to compile a translation unit that does `import std;` and writes `"hello1"`
to `std::cout`, and (3) the time to compile a translation unit that `#include`s
all standard library headers directly and writes `"hello2"` to `std::cout`.
MSVC uses `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.38.33130\modules\std.ixx`.

| Compiler | Version |
|----------|---------|
| MSVC     | Microsoft (R) C/C++ Optimizing Compiler Version 19.38.33145 for x64 |

## Module Build Time

Time to compile the standard library module interface unit from the
toolchain-provided source. MSVC produces `std.ifc` and `std.obj` via `/c /interface`.
Each run starts from a clean cache.

| MSVC ms |
|--------:|
| 2058 |

## Using The Module

Time to compile a translation unit that does `import std;` and writes
`"hello1"` to `std::cout`. The module is already compiled before this
measurement begins; each run times only the import and TU compilation.

| MSVC ms |
|--------:|
| 81 |

## Including All Headers

Time to compile a translation unit that `#include`s all standard library
headers and writes `"hello2"` to `std::cout`. No precompilation step is
used; every run parses the full header set from scratch.

| MSVC ms |
|--------:|
| 1295 |
