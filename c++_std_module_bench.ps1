# SPDX-FileCopyrightText: © 2026 Adrian Johnston.
# SPDX-License-Identifier: MIT
#
# Generates MSVC_modules.md.

Set-StrictMode -Version Latest

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'cl.exe not found. Run from Developer PowerShell for Visual Studio.'
    exit 1
}

$RUNS = 11

# ── Discover toolchain module source ────────────────────────────────────────

if (-not $env:VCToolsInstallDir) {
    Write-Host 'VCToolsInstallDir not set. Run from Developer PowerShell for Visual Studio.'
    exit 1
}

$MSVC_STD = Join-Path $env:VCToolsInstallDir 'modules\std.ixx'
if (-not (Test-Path $MSVC_STD)) {
    Write-Host "std.ixx not found at: $MSVC_STD"
    exit 1
}

Write-Host "MSVC std module: $MSVC_STD"

# ── Load and probe headers ───────────────────────────────────────────────────

$allHeaders = Get-Content 'headers' |
    Where-Object { $_ -match '^\s*<' } |
    ForEach-Object { $_ -replace '^\s*<([^>]+)>.*', '$1' }

Write-Host "Probing $($allHeaders.Count) headers for MSVC c++latest..."

$validHeaders = [System.Collections.Generic.List[string]]::new()
foreach ($h in $allHeaders) {
    Set-Content -Path 'probe_tmp.cpp' -Value "#include <$h>" -Encoding utf8
    & cl.exe /nologo /W0 /c /std:c++latest /EHsc /FoNUL probe_tmp.cpp 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $validHeaders.Add($h) }
}
Remove-Item 'probe_tmp.cpp' -Force -ErrorAction SilentlyContinue

Write-Host "MSVC: $($validHeaders.Count)/$($allHeaders.Count) headers valid"
$excluded = $allHeaders | Where-Object { $_ -notin $validHeaders }
if ($excluded.Count -gt 0) {
    Write-Host "MSVC excluded: $($excluded -join ', ')"
}

# ── Generate test source files ───────────────────────────────────────────────

$lines = [System.Collections.Generic.List[string]]::new()
foreach ($h in $validHeaders) { $lines.Add("#include <$h>") }
$lines.Add('int main() { std::cout << "hello2\n"; }')
($lines -join "`n") | Set-Content -Path 'msvc_use_headers.cpp' -Encoding utf8

"import std;`nint main() { std::cout << `"hello1\n`"; }" |
    Set-Content -Path 'use_module.cpp' -Encoding utf8

# ── Median helper ────────────────────────────────────────────────────────────

function Get-MedianMs([long[]]$Samples) {
    $sorted = $Samples | Sort-Object
    return $sorted[[int](($Samples.Count - 1) / 2)]
}

# ── Timing functions ─────────────────────────────────────────────────────────

# Build the MSVC standard library module from source, clean cache each run.
function Measure-MsvcModuleMs {
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        Remove-Item 'std.ifc','std.obj' -Force -ErrorAction SilentlyContinue
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /std:c++latest /EHsc /c /interface $MSVC_STD /ifcOutput std.ifc /Fostd.obj 2>&1 | Out-Null
        $sw.Stop()
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    return Get-MedianMs $samples
}

# Pre-build the MSVC module once, then time use_module.cpp over $RUNS iterations.
function Measure-MsvcUseModuleMs {
    Remove-Item 'std.ifc','std.obj' -Force -ErrorAction SilentlyContinue
    & cl.exe /nologo /W0 /std:c++latest /EHsc /c /interface $MSVC_STD /ifcOutput std.ifc /Fostd.obj 2>&1 | Out-Null
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /std:c++latest /EHsc /c /reference std=std.ifc use_module.cpp /FoNUL 2>&1 | Out-Null
        $sw.Stop()
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    return Get-MedianMs $samples
}

# Time all-headers compilation for MSVC over $RUNS iterations.
function Measure-MsvcHeadersMs {
    $samples = [long[]]::new($RUNS)
    for ($i = 0; $i -lt $RUNS; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cl.exe /nologo /W0 /c /std:c++latest /EHsc /FoNUL msvc_use_headers.cpp 2>&1 | Out-Null
        $sw.Stop()
        $samples[$i] = $sw.ElapsedMilliseconds
    }
    return Get-MedianMs $samples
}

# ── Correctness check: compile, link and run (untimed) ───────────────────────

Write-Host 'Verifying correctness...'

Remove-Item 'std.ifc','std.obj' -Force -ErrorAction SilentlyContinue

& cl.exe /nologo /W0 /std:c++latest /EHsc /c /interface $MSVC_STD /ifcOutput std.ifc /Fostd.obj 2>&1 | Out-Null
& cl.exe /nologo /W0 /std:c++latest /EHsc /c /reference std=std.ifc use_module.cpp /Foverify_msvc_module.obj 2>&1 | Out-Null
& cl.exe /nologo /W0 /std:c++latest /EHsc verify_msvc_module.obj std.obj /Fe:verify_msvc_module.exe 2>&1 | Out-Null
$out = (& .\verify_msvc_module.exe 2>&1 | Select-Object -First 1).ToString().Trim()
if ($out -ne 'hello1') {
    Write-Host "FAIL: MSVC module (got: '$out')"
    exit 1
}

& cl.exe /nologo /W0 /std:c++latest /EHsc /c msvc_use_headers.cpp /Foverify_msvc_headers.obj 2>&1 | Out-Null
& cl.exe /nologo /W0 /std:c++latest /EHsc verify_msvc_headers.obj /Fe:verify_msvc_headers.exe 2>&1 | Out-Null
$out = (& .\verify_msvc_headers.exe 2>&1 | Select-Object -First 1).ToString().Trim()
if ($out -ne 'hello2') {
    Write-Host "FAIL: MSVC headers (got: '$out')"
    exit 1
}

Write-Host 'All checks passed'

# ── Collect timings ──────────────────────────────────────────────────────────

Write-Host 'Timing module build...'
$msvcModuleMs = Measure-MsvcModuleMs

Write-Host 'Timing module use...'
$msvcUseMs = Measure-MsvcUseModuleMs

Write-Host 'Timing headers...'
$msvcHeadersMs = Measure-MsvcHeadersMs

$clVer = (& cl.exe /? 2>&1 |
          Where-Object { $_ -match 'Compiler Version' } |
          Select-Object -First 1)
$clVer = if ($clVer) { $clVer.ToString().Trim() } else { 'MSVC' }

# ── Output markdown ──────────────────────────────────────────────────────────

$w = [System.IO.StreamWriter]::new(
    (Join-Path $PWD 'MSVC_modules.md'), $false, [System.Text.Encoding]::UTF8)

$w.WriteLine('# Benchmarking C++23 Modules vs Headers')
$w.WriteLine()
$w.WriteLine("All timings are the median of $RUNS runs. Timings collected on an MSI Stealth A16")
$w.WriteLine('AI+ A3XVFG.')
$w.WriteLine()
$w.WriteLine('This script measures three things for C++23: (1) the time to compile the')
$w.WriteLine('toolchain-provided standard library module interface unit from source, (2) the')
$w.WriteLine('time to compile a translation unit that does `import std;` and writes `"hello1"`')
$w.WriteLine('to `std::cout`, and (3) the time to compile a translation unit that `#include`s')
$w.WriteLine('all standard library headers directly and writes `"hello2"` to `std::cout`.')
$w.WriteLine("MSVC uses ``$MSVC_STD``.")
$w.WriteLine()
$w.WriteLine('| Compiler | Version |')
$w.WriteLine('|----------|---------|')
$w.WriteLine("| MSVC     | $clVer |")
$w.WriteLine()
$w.WriteLine('## Module Build Time')
$w.WriteLine()
$w.WriteLine('Time to compile the standard library module interface unit from the')
$w.WriteLine('toolchain-provided source. MSVC produces `std.ifc` and `std.obj` via `/c /interface`.')
$w.WriteLine('Each run starts from a clean cache.')
$w.WriteLine()
$w.WriteLine('| MSVC ms |')
$w.WriteLine('|--------:|')
$w.WriteLine("| $msvcModuleMs |")
$w.WriteLine()
$w.WriteLine('## Using The Module')
$w.WriteLine()
$w.WriteLine('Time to compile a translation unit that does `import std;` and writes')
$w.WriteLine('`"hello1"` to `std::cout`. The module is already compiled before this')
$w.WriteLine('measurement begins; each run times only the import and TU compilation.')
$w.WriteLine()
$w.WriteLine('| MSVC ms |')
$w.WriteLine('|--------:|')
$w.WriteLine("| $msvcUseMs |")
$w.WriteLine()
$w.WriteLine('## Including All Headers')
$w.WriteLine()
$w.WriteLine('Time to compile a translation unit that `#include`s all standard library')
$w.WriteLine('headers and writes `"hello2"` to `std::cout`. No precompilation step is')
$w.WriteLine('used; every run parses the full header set from scratch.')
$w.WriteLine()
$w.WriteLine('| MSVC ms |')
$w.WriteLine('|--------:|')
$w.WriteLine("| $msvcHeadersMs |")

$w.Close()
Write-Host 'MSVC_modules.md written.'

& git clean -qXf
