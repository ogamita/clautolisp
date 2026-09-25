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
    Write-Host ("--- alfe stdout ({0} bytes)" -f $text.Length)
    Write-Host $text
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

Run-Alfe "1. booleans, no EPURE" `
    @('--keep-workdir', '-norc', '--debug', '--bricscad',
      '-x', '(print (= 1 1))', '-x', '(print (= 1 2))', '-x', '(princ "end")')

Run-Alfe "2. booleans, under EPURE" `
    @('--keep-workdir', '-norc', '--debug', '--bricscad', '--epure',
      '-x', '(print (= 1 1))', '-x', '(princ "end")')

Write-Host ""
Write-Host "Read the two protocol/stdout.txt dumps above:"
Write-Host "  T and nil present in run 1 -> the EPURE session is the difference"
Write-Host "  bare newlines in run 1 too -> boolean rendering in the shadow"
exit 0
