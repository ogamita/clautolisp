# Report the Windows interactive-session state of the process running it.
#
# WHY THIS EXISTS. A GitLab shell runner drives a real AutoCAD/BricsCAD by
# COM (`alfe --mode automation'), and COM automation of a GUI application
# needs a LIVE interactive desktop. When the runner's Windows session is
# disconnected -- locked, "switch user", the console handed back to the
# login screen, or an RDP client that closed without logging off -- the
# desktop is gone, and a COM/GUI CAD run FAILS or HANGS partway while a
# headless one (accoreconsole, `--mode batch') keeps working. That is the
# difference seen between benchmark:autocad:windows (COM, died after 2 of 7
# benchmarks) and benchmark:bricscad:windows (batch, ran all 7) on the SAME
# runner at the SAME minute -- see
# autocad-com-fails-in-disconnected-windows-session.issue.
#
# This script names that state, so a CAD job's log says WHY it failed
# instead of leaving "Error 1" to be guessed at. It only reads; it changes
# nothing, never throws out, and always exits 0 -- a diagnostic must not be
# the thing that fails the job it precedes.
#
# It is called from .cad-sweep-before (every Windows CAD job) and by
# probe-cad-session-state.ps1.

$ErrorActionPreference = 'Continue'

function Get-WtsInfo {
    # The authoritative connection state and window-station name come from
    # the WTS API, not from parsing `qwinsta' text (which is localized and
    # column-fragile). P/Invoke it once, tolerate any failure.
    $sig = @'
using System;
using System.Runtime.InteropServices;
public static class WtsNative {
    [DllImport("kernel32.dll")]
    public static extern uint WTSGetActiveConsoleSessionId();
    [DllImport("wtsapi32.dll", SetLastError=true)]
    public static extern bool WTSQuerySessionInformation(
        IntPtr hServer, uint sessionId, int wtsInfoClass,
        out IntPtr ppBuffer, out uint pBytesReturned);
    [DllImport("wtsapi32.dll")]
    public static extern void WTSFreeMemory(IntPtr pMemory);
}
'@
    try { Add-Type -TypeDefinition $sig -ErrorAction Stop } catch { }

    $result = [ordered]@{
        ProcessSessionId = $null
        ConsoleSessionId = $null
        ConnectState     = 'unknown'
        WinStationName   = 'unknown'
    }
    try { $result.ProcessSessionId = (Get-Process -Id $PID).SessionId } catch { }
    try { $result.ConsoleSessionId = [int][WtsNative]::WTSGetActiveConsoleSessionId() } catch { }

    $states = @('Active','Connected','ConnectQuery','Shadow','Disconnected',
                'Idle','Listen','Reset','Down','Init')
    $sid = $result.ProcessSessionId
    if ($sid -ne $null) {
        # WTS_INFO_CLASS: WTSConnectState = 8 (int), WTSWinStationName = 6 (string).
        try {
            $buf = [IntPtr]::Zero; $len = [uint32]0
            if ([WtsNative]::WTSQuerySessionInformation([IntPtr]::Zero, [uint32]$sid, 8, [ref]$buf, [ref]$len)) {
                $code = [System.Runtime.InteropServices.Marshal]::ReadInt32($buf)
                [WtsNative]::WTSFreeMemory($buf)
                if ($code -ge 0 -and $code -lt $states.Count) { $result.ConnectState = $states[$code] }
                else { $result.ConnectState = "code=$code" }
            }
        } catch { }
        try {
            $buf = [IntPtr]::Zero; $len = [uint32]0
            if ([WtsNative]::WTSQuerySessionInformation([IntPtr]::Zero, [uint32]$sid, 6, [ref]$buf, [ref]$len)) {
                $name = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($buf)
                [WtsNative]::WTSFreeMemory($buf)
                if ($name) { $result.WinStationName = $name }
            }
        } catch { }
    }
    return $result
}

Write-Host "==================== Windows session state ===================="

$wts = Get-WtsInfo

# LogonUI.exe runs on the SECURE desktop: it is present at the login/welcome
# screen and while the workstation is LOCKED, and absent on a normal unlocked
# desktop. It is the one signal that separates "locked / at login" (the state
# that breaks COM CAD) from a merely disconnected-but-still-unlocked session.
$logonUi = @(Get-Process -Name 'LogonUI' -ErrorAction SilentlyContinue)
$locked  = $logonUi.Count -gt 0

# console vs rdp-tcp#N -- the transport. Through RDP the interactive session
# is an rdp-tcp session (Active while the client is attached, Disconnected
# once it detaches WITHOUT logging off); the physical console is then usually
# Disconnected. A COM CAD run is happy in an Active rdp-tcp session and breaks
# in a Disconnected one, exactly as on the console.
$onConsole = ($wts.ProcessSessionId -ne $null -and $wts.ProcessSessionId -eq $wts.ConsoleSessionId)
$transport =
    if ($wts.WinStationName -match '^rdp')      { 'rdp' }
    elseif ($wts.WinStationName -match 'onsole') { 'console' }
    elseif ($onConsole)                          { 'console' }
    else                                         { $wts.WinStationName }

Write-Host ("process session id : {0}" -f $wts.ProcessSessionId)
Write-Host ("console session id : {0}" -f $wts.ConsoleSessionId)
Write-Host ("on console session : {0}" -f $(if ($onConsole) { 'YES' } else { 'no' }))
Write-Host ("winstation name    : {0}" -f $wts.WinStationName)
Write-Host ("connect state      : {0}" -f $wts.ConnectState)
Write-Host ("LogonUI present    : {0}  ({1})" -f $logonUi.Count,
            $(if ($locked) { 'locked / at login screen' } else { 'desktop unlocked' }))

# A live desktop for COM/GUI CAD needs: an Active connect state AND no secure
# desktop up. Disconnected, or locked, means a COM CAD run is expected to
# fail or hang while a headless one (accoreconsole / --mode batch) still works.
$comReady = ($wts.ConnectState -eq 'Active' -and -not $locked)
$verdict  =
    if ($comReady)                          { 'DESKTOP-LIVE (COM/GUI CAD should work)' }
    # Disconnected first: a switched-user / detached-RDP session is usually ALSO
    # at the login screen (LogonUI up), and it is the state that matters.
    elseif ($wts.ConnectState -eq 'Disconnected') { 'DISCONNECTED (COM/GUI CAD failed in job 16990501680, confounded by a dropped VPN/license server; headless batch ok)' }
    elseif ($locked)                        { 'LOCKED (console session still Active: COM/GUI CAD measured OK, job 16984618487)' }
    else                                    { ('connect-state=' + $wts.ConnectState + ' (COM/GUI CAD uncertain)') }

# The one-line summary a job's log can be grepped for.
Write-Host ("SESSION-STATE: transport={0} connect={1} locked={2} on-console={3} => {4}" -f `
            $transport, $wts.ConnectState, $(if ($locked) { 'yes' } else { 'no' }),
            $(if ($onConsole) { 'yes' } else { 'no' }), $verdict)

Write-Host ""
Write-Host "----- qwinsta (raw)"
try { & "$env:SystemRoot\System32\qwinsta.exe" 2>&1 | Out-String | Write-Host } catch { Write-Host "qwinsta unavailable: $_" }
Write-Host "----- quser (raw)"
try { & "$env:SystemRoot\System32\quser.exe" 2>&1 | Out-String | Write-Host } catch { Write-Host "quser unavailable: $_" }

Write-Host "==============================================================="
exit 0
