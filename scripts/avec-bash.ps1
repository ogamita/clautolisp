# avec-bash.ps1 — run a POSIX shell script from a PowerShell Windows runner.
#
# ADAPTED from run-forest-run/scripts/avec-bash.ps1 (pjb), which is where
# this knowledge was won. Kept to what the clautolisp release lane needs;
# fix the original there, then re-vendor, exactly as scripts/check-versions.sh
# is vendored from informatimago/rules.
#
#   & scripts/avec-bash.ps1 scripts/release-windows.sh
#
# Two Git-for-Windows executables must not be confused:
#   git-bash.exe  GRAPHICAL launcher (mintty). It detaches and returns at
#                 once, so a job using it would finish without waiting, with
#                 an exit code that says nothing. NOT this one.
#   bin\bash.exe  the shell itself: synchronous, exit code propagated.

$ErrorActionPreference = 'Stop'

if ($args.Count -lt 1) {
    Write-Error "usage: avec-bash.ps1 <script.sh> [arguments...]"
    exit 2
}

function Trouver-Bash {
    # MSYS2's bash is PREFERRED over Git for Windows'. Both can run the
    # script, but they do not share a root: MSYS2 maps "/" onto C:\msys64\,
    # Git's onto its own install directory. A "/mingw64/..." path therefore
    # exists only under MSYS2 — and that is what build-libredwg.sh looks for
    # to find the native compiler. Under Git's bash the MINGW64 chain stays
    # invisible whatever the PATH says, and the DWG codec build fails with
    # "the native MSYS2 MINGW64 compiler is not installed".
    if ($env:AVEC_BASH -and (Test-Path -LiteralPath $env:AVEC_BASH)) {
        return $env:AVEC_BASH
    }
    $candidats = @(
        "$env:MSYS2_ROOT\usr\bin\bash.exe",
        "C:\msys64\usr\bin\bash.exe",
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($c in $candidats) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    $surPath = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($surPath) { return $surPath.Source }
    return $null
}

$bash = Trouver-Bash
if (-not $bash) {
    Write-Error "bash not found. Install MSYS2 (or Git for Windows), or set the AVEC_BASH variable to the bash.exe to use."
    exit 127
}
Write-Host "avec-bash: $bash"

# BEFORE anything else: MSYS2 then KEEPS the Windows PATH and adds its own,
# instead of rebuilding it. That is what makes the login shell below usable.
#
# History, so it is not re-derived: a first attempt with -l failed on
# "sbcl not found in PATH", the profile having replaced PATH. The conclusion
# drawn was that -l had to go — but `inherit' landed in the same change, so
# the two had never been tried TOGETHER. This combination is the one that
# works.
$env:MSYS2_PATH_TYPE = 'inherit'

# The native MSYS2 toolchain, for the DWG codec.
#
# MINGW64 FIRST, and the order is not a detail: build-libredwg.sh REFUSES
# UCRT64 and CLANG64 for the native Windows codec — those builds import
# private UCRT API sets that native SBCL/CCL do not have. Choosing "whatever
# is installed" would be taking the observation for a criterion.
$sousSystemes = @(
    @{ nom = 'MINGW64'; prefixe = '/mingw64'; bin = 'C:\msys64\mingw64\bin' },
    @{ nom = 'UCRT64';  prefixe = '/ucrt64';  bin = 'C:\msys64\ucrt64\bin'  },
    @{ nom = 'CLANG64'; prefixe = '/clang64'; bin = 'C:\msys64\clang64\bin' }
)
foreach ($ss in $sousSystemes) {
    $etat = if (Test-Path -LiteralPath "$($ss.bin)\gcc.exe") { 'gcc present' } else { 'no gcc' }
    Write-Host "avec-bash: $($ss.nom) -> $etat ($($ss.bin))"
}
$choisi = $sousSystemes | Where-Object { Test-Path -LiteralPath "$($_.bin)\gcc.exe" } | Select-Object -First 1
if ($choisi -and $choisi.nom -ne 'MINGW64') {
    Write-Host "avec-bash: WARNING $($choisi.nom) chosen for want of MINGW64 -- the DWG codec will refuse it"
    Write-Host "avec-bash: install it with  pacman -S --needed mingw-w64-x86_64-gcc"
}
if ($choisi) {
    # MSYSTEM must be set BEFORE the call: the login profile reads it to pick
    # the subsystem and add the right /<prefix>/bin.
    #
    # CC is deliberately NOT set here. The MSYS layer converts values at
    # process entry, so "/mingw64/bin/gcc" would come out as
    # "C:/msys64/mingw64/bin/gcc" -- which CMake then truncates at the colon
    # ("The CMAKE_C_COMPILER: C is not a full path"). environnement-windows.sh
    # sets it on the bash side, where the POSIX form survives intact.
    $env:MSYSTEM      = $choisi.nom
    $env:MINGW_PREFIX = $choisi.prefixe
    $env:PATH         = "$($choisi.bin);$env:PATH"
    Write-Host "avec-bash: native chain $($choisi.nom)"
} else {
    Write-Host "avec-bash: no native MSYS2 chain found (mingw64/ucrt64/clang64) -- the DWG codec will not build"
}

# -l : LOGIN shell, for /etc/profile — that is what sets up the MSYS2 native
# chain from MSYSTEM. It does NOT give the account's .bashrc: a login shell
# reads profiles, not .bashrc, and login is not INTERACTIVE. Hence
# environnement-windows.sh, which describes the machine explicitly.
& $bash -l @args
exit $LASTEXITCODE
