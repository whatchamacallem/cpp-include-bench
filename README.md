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
| GCC      | g++ (Ubuntu 15.2.0-4ubuntu4) 15.2.0 | 22 |
| Clang    | Ubuntu clang version 20.1.8 (0ubuntu4) | 23 |

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
| C++11    |   75473 |          432 |     63666 |            759 |
| C++14    |   77209 |          476 |     65102 |            827 |
| C++17    |   85540 |          516 |     71479 |            880 |
| C++20    |  112913 |         1001 |     84360 |           1363 |
| C++23    |  128846 |         1175 |     87186 |           1598 |

## Compilation Time Using A Precompiled Header

Time to compile an empty translation unit that uses only a precompiled header
(PCH) containing the selected standard library headers. The PCH is rebuilt
for each version of the standard. Times do not include compiler startup.

| Standard | GCC PCH ms (net) | Clang PCH ms (net) |
|----------|-----------------:|-------------------:|
| C++11    |               69 |                 88 |
| C++14    |               69 |                 91 |
| C++17    |               85 |                130 |
| C++20    |              352 |                135 |
| C++23    |              367 |                138 |

## Lines Of Code Per-Header (GCC)

Lines of code seen by preprocessor when including each header individually.
Each column shows the absolute LOC and the delta from the prior standard,

if any.

| Header | C++11 | C++14 | C++17 | C++20 | C++23 |
|--------|------:|------:|------:|------:|------:|
| algorithm | 10681 | 11150 (🔺469) | 12195 (🔺1045) | 21204 (🔺9009) | 23963 (🔺2759) |
| array | 5642 | 6025 (🔺383) | 6535 (🔺510) | 9926 (🔺3391) | 10575 (🔺649) |
| atomic | 3397 | 3460 (🔺63) | 3938 (🔺478) | 7827 (🔺3889) | 7999 (🔺172) |
| bitset | 13619 | 14473 (🔺854) | 17897 (🔺3424) | 22979 (🔺5082) | 24933 (🔺1954) |
| chrono | 3873 | 4702 (🔺829) | 5232 (🔺530) | 62831 (🔺57599) | 65771 (🔺2940) |
| condition_variable | 14430 | 15332 (🔺902) | 16082 (🔺750) | 39914 (🔺23832) | 42019 (🔺2105) |
| deque | 10043 | 10850 (🔺807) | 13340 (🔺2490) | 18286 (🔺4946) | 20219 (🔺1933) |
| forward_list | 8306 | 9113 (🔺807) | 11612 (🔺2499) | 16576 (🔺4964) | 17853 (🔺1277) |
| fstream | 22103 | 22938 (🔺835) | 26380 (🔺3442) | 31644 (🔺5264) | 50918 (🔺19274) |
| functional | 5544 | 6169 (🔺625) | 20490 (🔺14321) | 25777 (🔺5287) | 29055 (🔺3278) |
| future | 24880 | 26065 (🔺1185) | 28383 (🔺2318) | 42163 (🔺13780) | 44280 (🔺2117) |
| iostream | 20418 | 21253 (🔺835) | 24660 (🔺3407) | 29810 (🔺5150) | 49575 (🔺19765) |
| iterator | 16311 | 17146 (🔺835) | 20550 (🔺3404) | 25614 (🔺5064) | 27561 (🔺1947) |
| list | 8140 | 8524 (🔺384) | 11024 (🔺2500) | 15987 (🔺4963) | 17267 (🔺1280) |
| locale | 21479 | 22314 (🔺835) | 25723 (🔺3409) | 30923 (🔺5200) | 32870 (🔺1947) |
| map | 11089 | 12141 (🔺1052) | 13931 (🔺1790) | 18897 (🔺4966) | 20183 (🔺1286) |
| memory | 15130 | 15946 (🔺816) | 16730 (🔺784) | 36564 (🔺19834) | 38306 (🔺1742) |
| mutex | 7563 | 8502 (🔺939) | 9229 (🔺727) | 15480 (🔺6251) | 16695 (🔺1215) |
| numeric | 1863 | 2588 (🔺725) | 4346 (🔺1758) | 6994 (🔺2648) | 14951 (🔺7957) |
| queue | 13925 | 14739 (🔺814) | 17184 (🔺2445) | 22180 (🔺4996) | 46575 (🔺24395) |
| random | 25977 | 26856 (🔺879) | 33555 (🔺6699) | 38677 (🔺5122) | 42330 (🔺3653) |
| regex | 47134 | 48354 (🔺1220) | 51322 (🔺2968) | 57038 (🔺5716) | 79140 (🔺22102) |
| set | 9532 | 10538 (🔺1006) | 13643 (🔺3105) | 18609 (🔺4966) | 19887 (🔺1278) |
| sstream | 21039 | 21874 (🔺835) | 25281 (🔺3407) | 30658 (🔺5377) | 50423 (🔺19765) |
| stack | 10284 | 11098 (🔺814) | 13485 (🔺2387) | 18439 (🔺4954) | 42508 (🔺24069) |
| stdexcept | 13057 | 13892 (🔺835) | 17294 (🔺3402) | 22372 (🔺5078) | 24318 (🔺1946) |
| string | 12588 | 13423 (🔺835) | 16847 (🔺3424) | 21933 (🔺5086) | 23886 (🔺1953) |
| thread | 9118 | 10515 (🔺1397) | 11174 (🔺659) | 36425 (🔺25251) | 55024 (🔺18599) |
| tuple | 3561 | 3726 (🔺165) | 4228 (🔺502) | 10871 (🔺6643) | 12025 (🔺1154) |
| typeindex | 195 | 195 (🔺0) | 195 (🔺0) | 3476 (🔺3281) | 3521 (🔺45) |
| unordered_map | 12278 | 13156 (🔺878) | 14999 (🔺1843) | 20201 (🔺5202) | 21564 (🔺1363) |
| unordered_set | 12242 | 13120 (🔺878) | 14878 (🔺1758) | 20084 (🔺5206) | 21435 (🔺1351) |
| utility | 2188 | 2317 (🔺129) | 2758 (🔺441) | 4587 (🔺1829) | 4900 (🔺313) |
| valarray | 15344 | 15813 (🔺469) | 20879 (🔺5066) | 29965 (🔺9086) | 33921 (🔺3956) |
| vector | 10893 | 11700 (🔺807) | 14206 (🔺2506) | 19220 (🔺5014) | 21444 (🔺2224) |
