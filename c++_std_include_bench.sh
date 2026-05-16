#!/bin/sh
# SPDX-FileCopyrightText: © 2026 Adrian Johnston.
# SPDX-License-Identifier: MIT
#
# Generates README.md.

set -eu

RUNS=51

HEADERS="algorithm array atomic bitset chrono condition_variable deque forward_list
	fstream functional future iostream iterator list locale map memory mutex numeric
	queue random regex set sstream stack stdexcept string thread tuple typeindex
	unordered_map unordered_set utility valarray vector"

PREPROCESS="-x c++ -E -P -w"

# Create the test files.
{
	for h in $HEADERS; do
		printf '#include <%s>\n' "$h"
	done
} > std_all.cpp

cp std_all.cpp std_all.h
printf '// Empty File\n' > empty_file.cpp
printf '// PCH Test\n' > pch_test.cpp

# Compute median of space-separated nanosecond samples, print ms
median_ms() {
	printf '%s\n' $1 | sort -n | awk -v n="$RUNS" '
		NR == int((n+1)/2) { printf "%d", int($1 / 1000000); exit }'
}

# Measure baseline (compiler startup) over $RUNS iterations, return ms median.
# Uses -std=c++23 for all standards. Startup overhead is process creation and
# should be negligible relative to any per-standard difference.
baseline_ms() {
	compiler="$1"
	samples=""
	for i in $(seq "$RUNS"); do
		t0=$(date +%s%N)
		"$compiler" -w -c -o /dev/null -std=c++23 empty_file.cpp
		samples="$samples $(( $(date +%s%N) - t0 ))"
	done
	median_ms "$samples"
}

# Time compilation of std_all.cpp over $RUNS iterations, return ms median.
# $4 is optional extra compiler flags (e.g. -stdlib=libc++)
time_ms() {
	compiler="$1"
	std="$2"
	outfile="$3"
	flags="${4-}"
	samples=""
	for i in $(seq "$RUNS"); do
		t0=$(date +%s%N)
		"$compiler" $flags -w -c -o /dev/null -std="c++$std" std_all.cpp
		samples="$samples $(( $(date +%s%N) - t0 ))"
	done
	"$compiler" $flags $PREPROCESS -std="c++$std" std_all.cpp > "$outfile"
	median_ms "$samples"
}

# Build GCC PCH then time $RUNS compilations using it, return ms median
time_gnu_pch_ms() {
	std="$1"
	g++ -w -std="c++$std" -x c++-header std_all.h
	samples=""
	for i in $(seq "$RUNS"); do
		t0=$(date +%s%N)
		g++ -w -c -o /dev/null -std="c++$std" -include std_all.h pch_test.cpp
		samples="$samples $(( $(date +%s%N) - t0 ))"
	done
	median_ms "$samples"
}

# Build Clang PCH then time $RUNS compilations using it, return ms median
time_llvm_pch_ms() {
	std="$1"
	clang++ -stdlib=libc++ -w -std="c++$std" -x c++-header std_all.h -o llvm_std_all.pch
	samples=""
	for i in $(seq "$RUNS"); do
		t0=$(date +%s%N)
		clang++ -stdlib=libc++ -w -c -o /dev/null -std="c++$std" -include-pch llvm_std_all.pch pch_test.cpp
		samples="$samples $(( $(date +%s%N) - t0 ))"
	done
	median_ms "$samples"
}

GNU_BASE=$(baseline_ms g++)
LLVM_BASE=$(baseline_ms clang++)
GNU_VER=$(g++ --version | head -1)
LLVM_VER=$(clang++ --version | head -1)

exec > README.md

printf '# Benchmarking Including The C++ Standard Library\n\n'

printf 'All timings are the median of %d runs. Timings collected on an MSI Stealth A16\n' "$RUNS"
printf 'AI+ A3XVFG.\n\n'

printf 'This script measures the compilation overhead of including but not using a large\n'
printf 'set of the C++ standard library headers with GCC and Clang for C++11, C++14, C++17,\n'
printf 'C++20, and C++23. Nothing in the headers is actually used. Startup time is the\n'
printf 'time taken to compile an empty file with no includes at all and is deducted from\n'
printf 'all subsequent measurements. GCC uses libstdc++ and Clang uses libc++.\n\n'

printf '| Compiler | Version | Startup (ms) |\n'
printf '|----------|---------|-------------:|\n'
printf '| GCC      | %s | %d |\n' "$GNU_VER" "$GNU_BASE"
printf '| Clang    | %s | %d |\n\n' "$LLVM_VER" "$LLVM_BASE"

printf '## Headers Under Test\n\n'

printf 'These are C++11 headers that were chosen as representative of normal use in a\n'
printf 'large C++ program with a complex include graph. Choosing C++11 headers allows\n'
printf 'showing how they change across all language versions being tested.\n\n'

for h in $HEADERS; do
	printf '`<%s>` ' "$h"
done

printf '\n\n## Compilation Time\n\n'

printf 'Time taken to compile the selected standard library headers in an otherwise empty\n'
printf 'translation unit. Also lists the lines of code seen by the preprocessor for that\n'
printf 'translation unit. Times do not include compiler startup.\n\n'

printf '| Standard | GCC LOC | GCC ms (net) | Clang LOC | Clang ms (net) |\n'
printf '|----------|--------:|-------------:|----------:|---------------:|\n'

for std in 11 14 17 20 23; do
	gnu_ms=$(time_ms g++ "$std" gnu_pp.txt)
	llvm_ms=$(time_ms clang++ "$std" llvm_pp.txt -stdlib=libc++)
	gnu_loc=$(wc -l < gnu_pp.txt)
	llvm_loc=$(wc -l < llvm_pp.txt)
	gnu_net=$(( gnu_ms - GNU_BASE ))
	llvm_net=$(( llvm_ms - LLVM_BASE ))
	printf '| C++%s    | %7d | %12d | %9d | %14d |\n' \
		"$std" "$gnu_loc" "$gnu_net" "$llvm_loc" "$llvm_net"
done

printf '\n## Compilation Time Using A Precompiled Header\n\n'

printf 'Time to compile an empty translation unit that uses only a precompiled header\n'
printf '(PCH) containing the selected standard library headers. The PCH is rebuilt\n'
printf 'for each version of the standard. Times do not include compiler startup.\n\n'

printf '| Standard | GCC PCH ms (net) | Clang PCH ms (net) |\n'
printf '|----------|-----------------:|-------------------:|\n'

for std in 11 14 17 20 23; do
	gnu_ms=$(time_gnu_pch_ms "$std")
	llvm_ms=$(time_llvm_pch_ms "$std")
	gnu_net=$(( gnu_ms - GNU_BASE ))
	llvm_net=$(( llvm_ms - LLVM_BASE ))
	printf '| C++%s    | %16d | %18d |\n' \
		"$std" "$gnu_net" "$llvm_net"
done

printf '\n## Lines Of Code Per-Header (GCC)\n\n'

printf 'Lines of code seen by preprocessor when including each header individually.\n'
printf 'Each column shows the absolute LOC and the delta from the prior standard,\n\n'
printf 'if any.\n\n'

printf '| Header | C++11 | C++14 | C++17 | C++20 | C++23 |\n'
printf '|--------|------:|------:|------:|------:|------:|\n'

for h in $HEADERS; do
	printf '| %s' "$h"
	prev=0
	for std in 11 14 17 20 23; do
		loc=$(printf '#include <%s>\n' "$h" | g++ $PREPROCESS -std="c++$std" - | wc -l)
		if [ "$std" = "11" ]; then
			printf ' | %d' "$loc"
		else
			printf ' | %d (🔺%d)' "$loc" $(( loc - prev ))
		fi
		prev=$loc
	done
	printf ' |\n'
done

# quietly delete all .gitignore'd files.
git clean -qXf
