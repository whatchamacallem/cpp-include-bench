# Benchmarking Including The C++ Standard Library

All timings are the median of 51 runs. Timings collected on an MSI Stealth A16
AI+ A3XVFG.

This script measures the compilation overhead of including but not using a large
set of the C++ standard library headers with MSVC for C++14, C++17, C++20, and
C++23. Nothing in the headers is actually used. Startup time is the time taken
to compile an empty file with no includes at all and is deducted from all
subsequent measurements. MSVC has no /std:c++11 mode; C++14 is the oldest
standard tested here.

| Compiler | Version | Startup (ms) |
|----------|---------|-------------:|
| MSVC     | Microsoft (R) C/C++ Optimizing Compiler Version 19.38.33145 for x64 | 26 |

## Headers Under Test

These are C++11 headers that were chosen as representative of normal use in a
large C++ program with a complex include graph. Choosing C++11 headers allows
showing how they change across all language versions being tested.

`<algorithm>` `<array>` `<atomic>` `<bitset>` `<chrono>` `<condition_variable>` `<deque>` `<forward_list>` `<fstream>` `<functional>` `<future>` `<iostream>` `<iterator>` `<list>` `<locale>` `<map>` `<memory>` `<mutex>` `<numeric>` `<queue>` `<random>` `<regex>` `<set>` `<sstream>` `<stack>` `<stdexcept>` `<string>` `<thread>` `<tuple>` `<typeindex>` `<unordered_map>` `<unordered_set>` `<utility>` `<valarray>` `<vector>`

## Compilation Time

Time taken to compile the selected standard library headers in an otherwise empty
translation unit. Also lists the lines of code seen by the preprocessor for that
translation unit. Times do not include compiler startup.

| Standard | MSVC LOC | MSVC ms (net) |
|----------|--------:|--------------:|
| C++14 |    76450 |           342 |
| C++17 |    80143 |           392 |
| C++20 |   106817 |           907 |
| C++23 |   119710 |          1013 |

## Compilation Time Using A Precompiled Header

Time to compile an empty translation unit that uses only a precompiled header
(PCH) containing the selected standard library headers. The PCH is rebuilt
for each version of the standard. Times do not include compiler startup.

| Standard | MSVC PCH ms (net) |
|----------|------------------:|
| C++14 |                 3 |
| C++17 |                 3 |
| C++20 |                 4 |
| C++23 |                 5 |

## Lines Of Code Per-Header (MSVC)

Lines of code seen by preprocessor when including each header individually.
Each column shows the absolute LOC and the delta from the prior standard,

if any.

| Header | C++14 | C++17 | C++20 | C++23 |
|--------|------:|------:|------:|------:|
| algorithm | 25993 | 26829 (+836) | 36761 (+9932) | 39418 (+2657) |
| array | 8437 | 8685 (+248) | 12847 (+4162) | 13424 (+577) |
| atomic | 5371 | 5458 (+87) | 8111 (+2653) | 8117 (+6) |
| bitset | 26977 | 28732 (+1755) | 33165 (+4433) | 34289 (+1124) |
| chrono | 18775 | 31669 (+12894) | 69354 (+37685) | 72026 (+2672) |
| condition_variable | 33725 | 35128 (+1403) | 41915 (+6787) | 60884 (+18969) |
| deque | 24734 | 25779 (+1045) | 30079 (+4300) | 31090 (+1011) |
| forward_list | 24623 | 25667 (+1044) | 29983 (+4316) | 30958 (+975) |
| fstream | 39076 | 41219 (+2143) | 48856 (+7637) | 60593 (+11737) |
| functional | 25224 | 32878 (+7654) | 37385 (+4507) | 39308 (+1923) |
| future | 45686 | 52346 (+6660) | 64325 (+11979) | 84710 (+20385) |
| iostream | 38177 | 40320 (+2143) | 47957 (+7637) | 60265 (+12308) |
| iterator | 21718 | 21966 (+248) | 26813 (+4847) | 27406 (+593) |
| list | 24832 | 25875 (+1043) | 30193 (+4318) | 31172 (+979) |
| locale | 38575 | 40723 (+2148) | 48289 (+7566) | 49556 (+1267) |
| map | 25865 | 26721 (+856) | 31024 (+4303) | 32040 (+1016) |
| memory | 25454 | 25842 (+388) | 34501 (+8659) | 35623 (+1122) |
| mutex | 33602 | 35005 (+1403) | 41724 (+6719) | 60693 (+18969) |
| numeric | 8079 | 8961 (+882) | 13303 (+4342) | 13915 (+612) |
| queue | 29776 | 31396 (+1620) | 40736 (+9340) | 59112 (+18376) |
| random | 46671 | 49217 (+2546) | 61612 (+12395) | 64784 (+3172) |
| regex | 47582 | 50254 (+2672) | 62716 (+12462) | 65888 (+3172) |
| set | 25198 | 26553 (+1355) | 30861 (+4308) | 31874 (+1013) |
| sstream | 39085 | 41228 (+2143) | 49053 (+7825) | 61361 (+12308) |
| stack | 24836 | 25886 (+1050) | 30191 (+4305) | 46822 (+16631) |
| stdexcept | 26424 | 28179 (+1755) | 32604 (+4425) | 33710 (+1106) |
| string | 26987 | 28742 (+1755) | 33167 (+4425) | 34273 (+1106) |
| thread | 30987 | 32335 (+1348) | 40493 (+8158) | 60034 (+19541) |
| tuple | 3138 | 3208 (+70) | 4786 (+1578) | 7119 (+2333) |
| typeindex | 4855 | 4930 (+75) | 6914 (+1984) | 6920 (+6) |
| unordered_map | 30189 | 31429 (+1240) | 35887 (+4458) | 37199 (+1312) |
| unordered_set | 30063 | 31288 (+1225) | 35746 (+4458) | 37057 (+1311) |
| utility | 2586 | 2627 (+41) | 3913 (+1286) | 5947 (+2034) |
| valarray | 25908 | 26529 (+621) | 31557 (+5028) | 32503 (+946) |
| vector | 25922 | 26966 (+1044) | 31321 (+4355) | 32461 (+1140) |
