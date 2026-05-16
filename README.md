# Benchmarking Including The C++ Standard Library

All timings are the median of 51 runs. Timings collected on an MSI Stealth A16
AI+ A3XVFG.

This script measures the compilation overhead of including but not using a large
set of the C++ standard library headers with GCC and Clang for C++11, C++14, C++17,
C++20, and C++23. Nothing in the headers is actually used. Startup time is the
time taken to compile an empty file with no includes at all and is deducted from
all subsequent measurements. GCC uses libstdc++ and Clang uses libc++.

| Compiler | Version | Startup (ms) |
|----------|---------|-------------:|
| GCC      | g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 | 6 |
| Clang    | Ubuntu clang version 18.1.3 (1ubuntu1) | 15 |

## Headers Under Test

These are C++11 headers that were chosen as representative of normal use in a
large C++ program with a complex include graph. Choosing C++11 headers allows
showing how they change across all language versions being tested.

`<algorithm>` `<array>` `<atomic>` `<bitset>` `<chrono>` `<condition_variable>` `<deque>` `<forward_list>` `<fstream>` `<functional>` `<future>` `<iostream>` `<iterator>` `<list>` `<locale>` `<map>` `<memory>` `<mutex>` `<numeric>` `<queue>` `<random>` `<regex>` `<set>` `<sstream>` `<stack>` `<stdexcept>` `<string>` `<thread>` `<tuple>` `<typeindex>` `<unordered_map>` `<unordered_set>` `<utility>` `<valarray>` `<vector>` 

## Compilation Time

Time taken to compile the selected standard library headers in an otherwise empty
translation unit. Also lists the lines of code seen by the preprocessor for that
translation unit. Times do not include compiler startup.

| Standard | GCC LOC | GCC ms (net) | Clang LOC | Clang ms (net) |
|----------|--------:|-------------:|----------:|---------------:|
| C++11    |   73860 |          354 |     60612 |            500 |
| C++14    |   75657 |          370 |     61644 |            527 |
| C++17    |   83880 |          451 |     68122 |            629 |
| C++20    |  108899 |          814 |     83963 |            938 |
| C++23    |  112865 |          868 |     86602 |            995 |

## Compilation Time Using A Precompiled Header

Time to compile an empty translation unit that uses only a precompiled header
(PCH) containing the selected standard library headers. The PCH is rebuilt
for each version of the standard. Times do not include compiler startup.

| Standard | GCC PCH ms (net) | Clang PCH ms (net) |
|----------|-----------------:|-------------------:|
| C++11    |               59 |                 71 |
| C++14    |               64 |                 81 |
| C++17    |               76 |                 99 |
| C++20    |              237 |                 94 |
| C++23    |              238 |                102 |

## Lines Of Code Per-Header (GCC)

Lines of code seen by preprocessor when including each header individually.
Each column shows the absolute LOC and the delta from the prior standard,

if any.

| Header | C++11 | C++14 | C++17 | C++20 | C++23 |
|--------|------:|------:|------:|------:|------:|
| algorithm | 10759 | 11302 (🔺543) | 12383 (🔺1081) | 21184 (🔺8801) | 23940 (🔺2756) |
| array | 5678 | 6132 (🔺454) | 6655 (🔺523) | 9944 (🔺3289) | 10473 (🔺529) |
| atomic | 3400 | 3461 (🔺61) | 3950 (🔺489) | 7767 (🔺3817) | 7920 (🔺153) |
| bitset | 13518 | 14430 (🔺912) | 17834 (🔺3404) | 23084 (🔺5250) | 24116 (🔺1032) |
| chrono | 3866 | 4691 (🔺825) | 5233 (🔺542) | 60024 (🔺54791) | 61446 (🔺1422) |
| condition_variable | 13409 | 14298 (🔺889) | 15020 (🔺722) | 39998 (🔺24978) | 41170 (🔺1172) |
| deque | 10097 | 10975 (🔺878) | 13439 (🔺2464) | 18509 (🔺5070) | 19428 (🔺919) |
| forward_list | 8014 | 8892 (🔺878) | 11372 (🔺2480) | 16517 (🔺5145) | 17436 (🔺919) |
| fstream | 21748 | 22654 (🔺906) | 26071 (🔺3417) | 31503 (🔺5432) | 32620 (🔺1117) |
| functional | 5562 | 6185 (🔺623) | 26147 (🔺19962) | 31571 (🔺5424) | 33415 (🔺1844) |
| future | 24537 | 25785 (🔺1248) | 28081 (🔺2296) | 42231 (🔺14150) | 43412 (🔺1181) |
| iostream | 20077 | 20983 (🔺906) | 24365 (🔺3382) | 29683 (🔺5318) | 30800 (🔺1117) |
| iterator | 16064 | 16970 (🔺906) | 20349 (🔺3379) | 25582 (🔺5233) | 26607 (🔺1025) |
| list | 7765 | 8220 (🔺455) | 10701 (🔺2481) | 15850 (🔺5149) | 16769 (🔺919) |
| locale | 21210 | 22116 (🔺906) | 25500 (🔺3384) | 30869 (🔺5369) | 31894 (🔺1025) |
| map | 10651 | 11789 (🔺1138) | 13556 (🔺1767) | 18705 (🔺5149) | 19624 (🔺919) |
| memory | 15094 | 15978 (🔺884) | 16785 (🔺807) | 36698 (🔺19913) | 37736 (🔺1038) |
| mutex | 7855 | 8794 (🔺939) | 9553 (🔺759) | 15850 (🔺6297) | 16758 (🔺908) |
| numeric | 1940 | 2733 (🔺793) | 4563 (🔺1830) | 7113 (🔺2550) | 7308 (🔺195) |
| queue | 13832 | 14717 (🔺885) | 17136 (🔺2419) | 22246 (🔺5110) | 23195 (🔺949) |
| random | 25481 | 26429 (🔺948) | 33162 (🔺6733) | 38388 (🔺5226) | 40628 (🔺2240) |
| regex | 46191 | 47475 (🔺1284) | 50374 (🔺2899) | 56217 (🔺5843) | 57376 (🔺1159) |
| set | 9099 | 10191 (🔺1092) | 13268 (🔺3077) | 18417 (🔺5149) | 19336 (🔺919) |
| sstream | 20689 | 21595 (🔺906) | 24977 (🔺3382) | 30514 (🔺5537) | 31631 (🔺1117) |
| stack | 10339 | 11224 (🔺885) | 13585 (🔺2361) | 18663 (🔺5078) | 19603 (🔺940) |
| stdexcept | 12944 | 13850 (🔺906) | 17232 (🔺3382) | 22478 (🔺5246) | 23502 (🔺1024) |
| string | 12471 | 13377 (🔺906) | 16781 (🔺3404) | 22035 (🔺5254) | 23066 (🔺1031) |
| thread | 8983 | 10372 (🔺1389) | 11045 (🔺673) | 36539 (🔺25494) | 37711 (🔺1172) |
| tuple | 3590 | 3755 (🔺165) | 4275 (🔺520) | 11078 (🔺6803) | 11931 (🔺853) |
| typeindex | 178 | 178 (🔺0) | 178 (🔺0) | 3570 (🔺3392) | 3625 (🔺55) |
| unordered_map | 12589 | 13538 (🔺949) | 15287 (🔺1749) | 20639 (🔺5352) | 21558 (🔺919) |
| unordered_set | 12553 | 13502 (🔺949) | 15166 (🔺1664) | 20522 (🔺5356) | 21441 (🔺919) |
| utility | 2224 | 2353 (🔺129) | 2812 (🔺459) | 4609 (🔺1797) | 4812 (🔺203) |
| valarray | 15263 | 15806 (🔺543) | 20819 (🔺5013) | 29697 (🔺8878) | 33653 (🔺3956) |
| vector | 10848 | 11726 (🔺878) | 14206 (🔺2480) | 19333 (🔺5127) | 20261 (🔺928) |
