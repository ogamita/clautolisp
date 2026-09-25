# Why does (print X) write only a newline in an EPURE session?
#
# pjb ran, on 2.2.90 and plain --bricscad:
#
#   -x (print 42) -x (princ 42)   ->   newline: 42 42
#
# so print works. But in his --epure run, protocol/stdout.txt held
# exactly \r\n\r\n: a bare newline per print, WITHOUT the trailing space
# print always writes. That is the (null args) branch of the shadow --
# print behaving as though it had no argument at all.
#
# Two runs separate what is left:
#
#   1. booleans, no EPURE: does (print (= 1 1)) show T?
#   2. the same under EPURE.
#
# If 1 prints T and nil, the difference is the EPURE SESSION (something
# there redefines print, or the arity normaliser, after alfe installs
# its shadows). If 1 also gives bare newlines, it is BOOLEAN RENDERING
# in the shadow and EPURE is innocent.
#
# The bytes of protocol/stdout.txt are dumped for each run: a trailing
# space or its absence is the whole distinction, and it does not survive
# ordinary echoing.

$ErrorActionPreference = 'Continue'

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 2 }

$timeout = $env:PRINT_CHECK_TIMEOUT
if (-not $timeout) { $timeout = '600' }
$work = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-print-check'
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Run-Alfe([string]$label, [string[]]$arguments) {
    $out = Join-Path $work 'stdout.txt'
    $err = Join-Path $work 'stderr.txt'
    Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "================ $label"
    Write-Host "    alfe $($arguments -join ' ')"
    $proc = Start-Process -FilePath $alfe -ArgumentList $arguments -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden
    if (-not $proc) { Write-Host "    (alfe did not start)"; return }
    $proc | Wait-Process -Timeout ([int]$timeout) -ErrorAction SilentlyContinue
    $proc.Refresh()
    if (-not $proc.HasExited) {
        Write-Host "    (still running after $timeout s; ending it)"
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $proc.Refresh()
    }
    Write-Host ("--- exit {0}" -f $(if ($proc.HasExited) { $proc.ExitCode } else { 'killed' }))
    $text = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
    $outBytes = if (Test-Path $out) { [System.IO.File]::ReadAllBytes($out) } else { @() }
    Write-Host ("--- alfe stdout ({0} bytes)" -f $outBytes.Length)
    Write-Host ("    hex  : {0}" -f (($outBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ' '))
    Write-Host ("    text : {0}" -f ($text -replace "`r", '\r' -replace "`n", '\n'))
    $errtext = if (Test-Path $err) { Get-Content $err -Raw } else { '' }
    if ($errtext) { Write-Host "--- alfe stderr"; Write-Host $errtext }

    # The workdir it kept: the protocol stdout is where the CAD-side
    # print actually lands, and its BYTES are the evidence.
    $dir = ($text -split "`n" | Where-Object { $_ -match 'workdir = (\S+)' } |
            Select-Object -First 1)
    if ($dir -match 'workdir = (\S+)') {
        $w = $Matches[1].Trim()
        $protocol = Join-Path $w 'protocol\stdout.txt'
        if (Test-Path $protocol) {
            $bytes = [System.IO.File]::ReadAllBytes($protocol)
            Write-Host ("--- protocol/stdout.txt ({0} bytes)" -f $bytes.Length)
            Write-Host ("    hex   : {0}" -f (($bytes | ForEach-Object { '{0:x2}' -f $_ }) -join ' '))
            Write-Host ("    text  : {0}" -f ([System.Text.Encoding]::ASCII.GetString($bytes) -replace "`r", '\r' -replace "`n", '\n'))
        } else {
            Write-Host "--- no protocol/stdout.txt under $w"
        }
        Remove-Item -Recurse -Force $w -ErrorAction SilentlyContinue
    } else {
        Write-Host "--- no workdir reported"
    }
    Get-Process bricscad -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 5
}

# From a FILE, never -x. PowerShell splits an -x expression on its
# spaces when it hands arguments to a native program: the first attempt
# reported `actions = 10' for three expressions, and every one of them
# was a fragment. The file is read by AutoLISP itself, so the source
# arrives as written.
$booleans = Join-Path $work 'booleans.lsp'
@'
(print (= 1 1))
(print (= 1 2))
(princ "end")
'@ | Set-Content -Path $booleans -Encoding ASCII
Write-Host "--- the file both runs load:"
Get-Content $booleans | Out-String | Write-Host

function Run-Alfe-Raw([string]$label, [string]$argumentString) {
    $out = Join-Path $work 'stdout.txt'
    $err = Join-Path $work 'stderr.txt'
    Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "================ $label"
    Write-Host "    alfe $argumentString"
    $proc = Start-Process -FilePath $alfe -ArgumentList $argumentString -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden
    if (-not $proc) { Write-Host "    (alfe did not start)"; return }
    $proc | Wait-Process -Timeout ([int]$timeout) -ErrorAction SilentlyContinue
    $proc.Refresh()
    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $proc.Refresh()
    }
    Write-Host ("--- exit {0}" -f $(if ($proc.HasExited) { $proc.ExitCode } else { 'killed' }))
    $text = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
    $bytes = if (Test-Path $out) { [System.IO.File]::ReadAllBytes($out) } else { @() }
    Write-Host ("--- alfe stdout ({0} bytes)" -f $bytes.Length)
    Write-Host ("    hex  : {0}" -f (($bytes | ForEach-Object { '{0:x2}' -f $_ }) -join ' '))
    Write-Host ("    text : {0}" -f ($text -replace "`r", '\r' -replace "`n", '\n'))
    $errtext = if (Test-Path $err) { Get-Content $err -Raw } else { '' }
    $actions = ($errtext -split "`n" | Where-Object { $_ -match 'actions = ' } | Select-Object -First 1)
    Write-Host ("--- alfe saw: {0}" -f $actions.Trim())
    Get-Process bricscad -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 5
}

Run-Alfe "1. the same forms LOADED from a file" `
    @('--keep-workdir', '-norc', '--debug', '--bricscad', '-l', $booleans)

# The -x half of the comparison. ONE argument string, with the quoting
# spelled out, because passing an array let PowerShell split each
# expression on its spaces (alfe reported actions = 10 for three of
# them). No string literal is used inside, so no nested quoting is
# needed: the marker is a number.
$xargs = '--keep-workdir -norc --debug --bricscad ' +
         '-x "(print (= 1 1))" -x "(print (= 1 2))" -x "(princ 42)"'
Run-Alfe-Raw "2. the same forms passed with -x" $xargs

Run-Alfe "3. under EPURE, loaded from a file" `
    @('--keep-workdir', '-norc', '--debug', '--bricscad', '--epure', '-l', $booleans)

Write-Host ""
Write-Host "Read the two protocol/stdout.txt dumps above:"
Write-Host "  T and nil present in run 1 -> the EPURE session is the difference"
Write-Host "  bare newlines in run 1 too -> boolean rendering in the shadow"
exit 0
