# Prove that an INSTALLED alfe finds its CAD runtime assets from its own
# location, on Windows.
#
# alfe-installed-runtime-prefix-discovery.issue was fixed in alfe 2.2.74
# and unit-tested with a pretend executable and a pretend install tree.
# Its remaining acceptance criterion is this one: a real install, on the
# platform where it failed, with no $ALFE_*_LSP overrides.
#
# What is asserted, and why each matters:
#   - `make install-programs' puts both .lsp assets under
#     <PREFIX>/share/alfe/runtime/;
#   - the installed alfe resolves them FROM THE PREFIX, not from the CI
#     checkout that happens to sit on the same disk -- the source tree is
#     present here, so the assertion is that the resolved path is under
#     the prefix;
#   - it works from an unrelated working directory (the prefix must come
#     from the executable, never from the cwd);
#   - it works through the bare `alfe.exe' entry point, not only
#     `alfe-sbcl.exe';
#   - it still works after the whole prefix is MOVED, which is what a
#     release archive unpacked anywhere really is;
#   - the prefix contains a space.
#
# Starts no CAD: --print-command stages the workdir and prints the
# command line.

$ErrorActionPreference = 'Continue'
$script:failures = 0

function Assert([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "ok   $what" }
    else     { Write-Host "FAIL $what"; $script:failures++ }
}

$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$root = Join-Path $env:TEMP 'alfe prefix check'
$prefix = Join-Path $root 'install one'
$moved = Join-Path $root 'install moved'
$elsewhere = Join-Path $root 'unrelated cwd'

Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $elsewhere | Out-Null

Write-Host "=== install into '$prefix'"
# PREFIX= with DESTDIR= is how the root Makefile stages a tree: the
# install lands at $(DESTDIR)$(PREFIX), so an empty PREFIX makes DESTDIR
# the prefix itself.
& make -C "$repo/autolisp-front-end" install-programs PREFIX= DESTDIR="$prefix" 2>&1 |
    Out-String | Write-Host
Write-Host "--- make exit $LASTEXITCODE"

foreach ($relative in @('bin\alfe-sbcl.exe', 'bin\alfe.exe',
                        'share\alfe\runtime\autolisp-bootstrap.lsp',
                        'share\alfe\runtime\autolisp-remote-io.lsp')) {
    Assert (Test-Path (Join-Path $prefix $relative)) "installed: $relative"
}

# No overrides: the whole point is that none are needed.
Remove-Item Env:\ALFE_RUNTIME_LSP -ErrorAction SilentlyContinue
Remove-Item Env:\ALFE_BOOTSTRAP_LSP -ErrorAction SilentlyContinue

function Check-Install([string]$where, [string]$exe, [string]$label) {
    Write-Host ""
    Write-Host "=== $label : $exe"
    if (-not (Test-Path $exe)) { Assert $false "$label : executable exists"; return }
    Push-Location $elsewhere
    $out = & $exe --no-init --debug --cad autocad --mode automation `
        --print-command --keep-workdir -x '(princ 1)' 2>&1 | Out-String
    $status = $LASTEXITCODE
    Pop-Location
    Write-Host $out
    Write-Host "--- alfe exit $status"
    Assert ($status -eq 0) "$label : exit 0"

    # The sources alfe reports must live under the install prefix.
    foreach ($asset in @('bootstrap', 'runtime')) {
        $line = ($out -split "`n" | Where-Object { $_ -match "$asset LSP source = (.+)$" } |
                 Select-Object -First 1)
        if ($line -match "$asset LSP source = (.+?)\s*$") {
            $path = $Matches[1]
            Write-Host "    $asset source: $path"
            Assert ($path.Replace('\','/').ToLower().StartsWith($where.Replace('\','/').ToLower())) `
                "$label : $asset resolved under the prefix"
        } else {
            Assert $false "$label : $asset source reported"
        }
    }

    # And both must actually be staged into the engine's runtime dir.
    $workdir = ($out -split "`n" | Where-Object { $_ -match 'workdir = (\S+)' } |
                Select-Object -First 1)
    if ($workdir -match 'workdir = (\S+)') {
        $dir = $Matches[1].Trim()
        foreach ($name in @('autolisp-bootstrap.lsp', 'autolisp-remote-io.lsp')) {
            Assert (Test-Path (Join-Path $dir "runtime\$name")) "$label : staged $name"
        }
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
    } else {
        Assert $false "$label : workdir reported"
    }
}

Check-Install $prefix (Join-Path $prefix 'bin\alfe-sbcl.exe') 'installed alfe-sbcl.exe'
Check-Install $prefix (Join-Path $prefix 'bin\alfe.exe')      'installed alfe.exe (bare launcher)'

Write-Host ""
Write-Host "=== move the whole installation to '$moved'"
Move-Item -Path $prefix -Destination $moved
Check-Install $moved (Join-Path $moved 'bin\alfe.exe') 'moved installation'

# An explicit override still wins over the installed copies.
Write-Host ""
Write-Host "=== an explicit override still takes precedence"
$own = Join-Path $root 'mine.lsp'
Set-Content -Path $own -Value '(princ)' -Encoding ASCII
$env:ALFE_RUNTIME_LSP = $own
Push-Location $elsewhere
$out = & (Join-Path $moved 'bin\alfe.exe') --no-init --debug --cad autocad `
    --mode automation --print-command -x '(princ 1)' 2>&1 | Out-String
Pop-Location
Remove-Item Env:\ALFE_RUNTIME_LSP -ErrorAction SilentlyContinue
Write-Host $out
# Compare on a normalised path: alfe reports a namestring with forward
# slashes, and the value handed to it here has backslashes. Comparing
# them verbatim failed the check while the override itself worked.
$wanted = $own.Replace('\', '/').ToLower()
$seen = $out.Replace('\', '/').ToLower()
Assert ($seen.Contains($wanted)) 'override: the named file is the runtime source'

Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== $script:failures failure(s)"
exit $script:failures
