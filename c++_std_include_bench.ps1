# SPDX-FileCopyrightText: © 2026 Adrian Johnston.
# SPDX-License-Identifier: MIT
#
# Generates MSVC.md.

Set-StrictMode -Version Latest

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'cl.exe not found. Run from Developer PowerShell for Visual Studio.'
    exit 1
}

$RUNS = 51

$HEADERS = @(
    'algorithm','array','atomic','bitset','chrono','condition_variable',
    'deque','forward_list','fstream','functional','future','iostream',
    'iterator','list','locale','map','memory','mutex','numeric',
    'queue','random','regex','set','sstream','stack','stdexcept',
    'string','thread','tuple','typeindex','unordered_map','unordered_set',
    'utility','valarray','vector'
)

# MSVC has no /std:c++11; oldest supported mode is c++14.
$STANDARDS = @(
    [pscustomobject]@{ Flag = 'c++14';    Label = 'C++14' }
    [pscustomobject]@{ Flag = 'c++17';    Label = 'C++17' }
    [pscustomobject]@{ Flag = 'c++20';    Label = 'C++20' }
    [pscustomobject]@{ Flag = 'c++latest'; Label = 'C++23' }
)

# Create test files
($HEADERS | ForEach-Object { "#include <$_>" }) -join "`r`n" |
    Set-Content -Path 'std_all.cpp' -Encoding utf8
Copy-Item 'std_all.cpp' 'std_all.h'
Set-Content -Path 'empty_file.cpp' -Value '// Empty File' -Encoding utf8
Set-Content -Path 'pch_test.cpp'   -Value '// PCH Test'   -Encoding utf8
Set-Content -Path 'pch_source.cpp' -Value '#include "std_all.h"' -Encoding utf8

function Get-MedianMs([long[]]$Samples) {
    $sorted = $Samples | Sort-Object
    return $sorted[[int](($Samples.Count - 1) / 2)]
}

# Measure compiler startup: compile empty file, return median ms.
function Measure-Baseline {
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /c /std:c++20 /FoNUL empty_file.cpp 2>&1 | Out-Null
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    return Get-MedianMs $samples
}

# Compile std_all.cpp over $RUNS iterations, return median ms.
# Also preprocesses to std_all.i for LOC counting.
function Measure-CompileMs([string]$Std) {
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /c /std:$Std /FoNUL std_all.cpp 2>&1 | Out-Null
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    & cl.exe /nologo /W0 /P /EP /std:$Std std_all.cpp 2>&1 | Out-Null
    return Get-MedianMs $samples
}

# Build MSVC PCH then time $RUNS compilations using it, return median ms.
function Measure-PchMs([string]$Std) {
    & cl.exe /nologo /W0 /c /std:$Std `
        /Ycstd_all.h /Fpstd_all.pch /Fopch_source.obj pch_source.cpp 2>&1 | Out-Null
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /c /std:$Std `
            /Yustd_all.h /FIstd_all.h /Fpstd_all.pch /FoNUL pch_test.cpp 2>&1 | Out-Null
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    return Get-MedianMs $samples
}

# Preprocess a single header and count output lines.
function Measure-HeaderLoc([string]$Header, [string]$Std) {
    "#include <$Header>" | Set-Content -Path 'bench_hdr_tmp.cpp' -Encoding utf8
    $loc = (& cl.exe /nologo /W0 /EP /std:$Std bench_hdr_tmp.cpp 2>&1 |
            Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
            Measure-Object -Line).Lines
    Remove-Item 'bench_hdr_tmp.cpp' -Force -ErrorAction SilentlyContinue
    return $loc
}

$clVer = (& cl.exe /? 2>&1 |
          Where-Object { $_ -match 'Compiler Version' } |
          Select-Object -First 1)
$clVer = if ($clVer) { $clVer.ToString().Trim() } else { 'MSVC' }

Write-Host 'Measuring baseline...'
$baseMs = Measure-Baseline

$w = [System.IO.StreamWriter]::new(
    (Join-Path $PWD 'MSVC.md'), $false, [System.Text.Encoding]::UTF8)

$w.WriteLine('# Benchmarking Including The C++ Standard Library')
$w.WriteLine()
$w.WriteLine("All timings are the median of $RUNS runs. Timings collected on an MSI Stealth A16")
$w.WriteLine('AI+ A3XVFG.')
$w.WriteLine()
$w.WriteLine('This script measures the compilation overhead of including but not using a large')
$w.WriteLine('set of the C++ standard library headers with MSVC for C++14, C++17, C++20, and')
$w.WriteLine('C++23. Nothing in the headers is actually used. Startup time is the time taken')
$w.WriteLine('to compile an empty file with no includes at all and is deducted from all')
$w.WriteLine('subsequent measurements. MSVC has no /std:c++11 mode; C++14 is the oldest')
$w.WriteLine('standard tested here.')
$w.WriteLine()
$w.WriteLine('| Compiler | Version | Startup (ms) |')
$w.WriteLine('|----------|---------|-------------:|')
$w.WriteLine("| MSVC     | $clVer | $baseMs |")
$w.WriteLine()
$w.WriteLine('## Headers Under Test')
$w.WriteLine()
$w.WriteLine('These are C++11 headers that were chosen as representative of normal use in a')
$w.WriteLine('large C++ program with a complex include graph. Choosing C++11 headers allows')
$w.WriteLine('showing how they change across all language versions being tested.')
$w.WriteLine()
$w.WriteLine(($HEADERS | ForEach-Object { "``<$_>``" }) -join ' ')
$w.WriteLine()

$w.WriteLine('## Compilation Time')
$w.WriteLine()
$w.WriteLine('Time taken to compile the selected standard library headers in an otherwise empty')
$w.WriteLine('translation unit. Also lists the lines of code seen by the preprocessor for that')
$w.WriteLine('translation unit. Times do not include compiler startup.')
$w.WriteLine()
$w.WriteLine('| Standard | MSVC LOC | MSVC ms (net) |')
$w.WriteLine('|----------|--------:|--------------:|')

foreach ($s in $STANDARDS) {
    Write-Host "Timing $($s.Label) compilation..."
    $ms  = Measure-CompileMs -Std $s.Flag
    $loc = if (Test-Path 'std_all.i') {
               (Get-Content 'std_all.i' | Measure-Object -Line).Lines
           } else { 0 }
    $net = $ms - $baseMs
    $w.WriteLine(('| {0} | {1,8} | {2,13} |' -f $s.Label, $loc, $net))
}

$w.WriteLine()
$w.WriteLine('## Compilation Time Using A Precompiled Header')
$w.WriteLine()
$w.WriteLine('Time to compile an empty translation unit that uses only a precompiled header')
$w.WriteLine('(PCH) containing the selected standard library headers. The PCH is rebuilt')
$w.WriteLine('for each version of the standard. Times do not include compiler startup.')
$w.WriteLine()
$w.WriteLine('| Standard | MSVC PCH ms (net) |')
$w.WriteLine('|----------|------------------:|')

foreach ($s in $STANDARDS) {
    Write-Host "Timing $($s.Label) PCH..."
    $ms  = Measure-PchMs -Std $s.Flag
    $net = $ms - $baseMs
    $w.WriteLine(('| {0} | {1,17} |' -f $s.Label, $net))
}

$w.WriteLine()
$w.WriteLine('## Lines Of Code Per-Header (MSVC)')
$w.WriteLine()
$w.WriteLine('Lines of code seen by preprocessor when including each header individually.')
$w.WriteLine('Each column shows the absolute LOC and the delta from the prior standard,')
$w.WriteLine()
$w.WriteLine('if any.')
$w.WriteLine()
$w.WriteLine('| Header | C++14 | C++17 | C++20 | C++23 |')
$w.WriteLine('|--------|------:|------:|------:|------:|')

foreach ($h in $HEADERS) {
    Write-Host "Measuring LOC for <$h>..."
    $row  = "| $h"
    $prev = 0
    $first = $true
    foreach ($s in $STANDARDS) {
        $loc = Measure-HeaderLoc -Header $h -Std $s.Flag
        if ($first) {
            $row  += " | $loc"
            $first = $false
        } else {
            $row += ' | {0} (+{1})' -f $loc, ($loc - $prev)
        }
        $prev = $loc
    }
    $row += ' |'
    $w.WriteLine($row)
}

$w.Close()
Write-Host 'MSVC.md written.'

& git clean -qXf
