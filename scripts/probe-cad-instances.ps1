# Probe: how a SECOND instance of a Windows CAD behaves under COM.
#
# alfe-cad-launch-new-by-default (pjb, 2026-10-23): alfe is to LAUNCH a new
# CAD by default and attach only on request -- to a given instance, by PID.
# Before the bridges are changed, this measures what COM actually offers:
#
#   1. Does CreateObject(ProgID) start a NEW process when one is running?
#   2. Which instance does GetActiveObject (VBScript GetObject(, ProgID))
#      return when two run: the first, the last, or none?
#   3. What does the Running Object Table hold per instance: the ProgID's
#      class moniker once or per instance, a file moniker per OPEN, SAVED
#      document, anything for an unnamed Drawing1?
#   4. Does a saved document's ROT entry reach the instance that has it
#      open -- the only per-instance handle COM may offer? Only an entry
#      the ROT really holds is bound: binding a .dwg path the ROT does NOT
#      hold makes COM start (or wait on) another CAD for it -- the first
#      run of this probe hung there for 20 minutes on BricsCAD V25.
#
# Every instance it creates is quit, then killed if still alive, and is
# also written to %TEMP%\alfe-created-cad.txt (alfe's own registry, same
# format) so the pre-job sweep ends it should this job be cancelled.
#
# Measures; never fails on a finding. Output: lines "CADINST ..." on stdout
# and in dist/cad-instances/cad-instances-<backend>-windows.txt.

param(
    [ValidateSet('autocad', 'bricscad')]
    [string] $Backend = 'autocad',
    [int] $ReadySecs = 180
)

$ErrorActionPreference = 'Continue'
$outDir = Join-Path (Get-Location) 'dist/cad-instances'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$log = Join-Path $outDir "cad-instances-$Backend-windows.txt"
Set-Content -Path $log -Value '' -Encoding ascii

function Say([string] $s) {
    $line = "CADINST $s"
    Write-Host $line
    Add-Content -Path $log -Value $line -Encoding ascii
}

# Keep every SaveAs and ROT lookup in the same private namespace. A/B
# distinguishes the two logical instances; PID + GUID distinguishes probes,
# even when two CI checkouts run under the same Windows account and TEMP.
function New-CadInstDrawingPaths([string] $backendName, [string] $temporaryDirectory) {
    $runId = "$PID-$([Guid]::NewGuid().ToString('N'))"
    $directory = Join-Path $temporaryDirectory "cadinst-$backendName-$runId"
    New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
    $drawings = @{}
    foreach ($tag in @('A', 'B')) {
        $drawings[$tag] = Join-Path $directory "cadinst-$backendName-$runId-$tag.dwg"
    }
    [pscustomobject] @{ Directory = $directory; Drawings = $drawings }
}

function Remove-CadInstDrawingPaths($paths) {
    foreach ($path in $paths.Drawings.Values) {
        foreach ($extension in @('.dwg', '.dwl', '.dwl2')) {
            Remove-Item -LiteralPath ([IO.Path]::ChangeExtension($path, $extension)) `
                -Force -ErrorAction SilentlyContinue
        }
    }
    # Leave unexpected files behind, rather than recursively deleting them.
    try { [IO.Directory]::Delete($paths.Directory, $false) } catch { }
}

if ($Backend -eq 'autocad') {
    $progId = 'AutoCAD.Application'; $image = 'acad.exe'
} else {
    $progId = 'BricscadApp.AcadApplication'; $image = 'bricscad.exe'
}
Say "backend=$Backend progid=$progId image=$image"

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class CadInstRot {
    [DllImport("ole32.dll")] static extern int GetRunningObjectTable(uint r, out IRunningObjectTable rot);
    [DllImport("ole32.dll")] static extern int CreateBindCtx(uint r, out IBindCtx ctx);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    public static uint PidOfHwnd(long h) {
        uint pid = 0;
        GetWindowThreadProcessId(new IntPtr(h), out pid);
        return pid;
    }
    public static List<object[]> Entries() {
        List<object[]> res = new List<object[]>();
        IRunningObjectTable rot; IBindCtx ctx; IEnumMoniker en;
        GetRunningObjectTable(0, out rot);
        CreateBindCtx(0, out ctx);
        rot.EnumRunning(out en);
        IMoniker[] m = new IMoniker[1];
        while (en.Next(1, m, IntPtr.Zero) == 0) {
            string name = "?";
            try { m[0].GetDisplayName(ctx, null, out name); } catch (Exception) { }
            object o = null;
            try { rot.GetObject(m[0], out o); } catch (Exception) { }
            res.Add(new object[] { name, o });
        }
        return res;
    }
}
'@

function Get-ImagePids {
    @(Get-CimInstance Win32_Process -Filter "Name = '$image'" -ErrorAction SilentlyContinue |
        ForEach-Object { [int] $_.ProcessId })
}

function Get-AppPid($app) {
    # An application answers HWND; a document answers Application.HWND.
    try { return [int] [CadInstRot]::PidOfHwnd([long] $app.HWND) } catch { }
    try { return [int] [CadInstRot]::PidOfHwnd([long] $app.Application.HWND) } catch { }
    return -1
}

function Wait-Ready($app, [string] $tag) {
    # A just-created CAD rejects calls (RPC_E_CALL_REJECTED) while it starts.
    $deadline = (Get-Date).AddSeconds($ReadySecs)
    $last = ''
    while ((Get-Date) -lt $deadline) {
        try { $app.Visible = $true; $null = $app.Documents.Count; return $true }
        catch { $last = $_.Exception.Message; Start-Sleep -Seconds 2 }
    }
    Say "$tag not-ready-after=${ReadySecs}s last-error=$last"
    return $false
}

function Record-Created([int[]] $pids) {
    $registry = Join-Path $env:TEMP 'alfe-created-cad.txt'
    foreach ($p in $pids) {
        $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $p" -ErrorAction SilentlyContinue
        if ($cim) { Add-Content -Path $registry -Value "PID=$p CREATED=$($cim.CreationDate)" -Encoding ascii }
    }
}

function Dump-Rot([string] $tag) {
    $n = 0
    foreach ($e in [CadInstRot]::Entries()) {
        $name = $e[0]; $o = $e[1]
        $kind = 'other'; $pidOf = ''
        if ($o -ne $null) {
            $p = Get-AppPid $o
            if ($p -gt 0) { $pidOf = " pid=$p" }
            try { $null = $o.Documents; $kind = 'application' } catch {
                try { $null = $o.Application; $kind = 'document' } catch { }
            }
        }
        if ($kind -ne 'other' -or $name -match '(?i)\.dwg|acad|bricscad|!\{') {
            Say "ROT $tag name=$name kind=$kind$pidOf"
            $n++
        }
    }
    Say "ROT $tag cad-entries=$n"
}

function Active-Pid([string] $tag) {
    try {
        $a = [System.Runtime.InteropServices.Marshal]::GetActiveObject($progId)
        Say "ACTIVE $tag pid=$(Get-AppPid $a)"
    } catch { Say "ACTIVE $tag none ($($_.Exception.Message))" }
}

$pre = Get-ImagePids
Say "PRE running=$($pre.Count) pids=$($pre -join ',')"

$created = @()
$apps = @{}
$probePaths = New-CadInstDrawingPaths $Backend $env:TEMP
Say "workdir=$($probePaths.Directory)"

try {
    foreach ($tag in @('A', 'B')) {
        $before = Get-ImagePids
        $t0 = Get-Date
        try { $app = New-Object -ComObject $progId }
        catch { Say "CREATE $tag failed: $($_.Exception.Message)"; continue }
        $ready = Wait-Ready $app $tag
        $after = Get-ImagePids
        $new = @($after | Where-Object { $before -notcontains $_ })
        $created += $new
        Record-Created $new
        $apid = Get-AppPid $app
        $apps[$tag] = $app
        $secs = [int] ((Get-Date) - $t0).TotalSeconds
        $ver = ''; try { $ver = $app.Version } catch { }
        Say "CREATE $tag ready=$ready secs=$secs app-pid=$apid new-processes=$($new -join ',') running-now=$($after.Count) version=$ver"
        Active-Pid "after-$tag"
        Dump-Rot "after-$tag"
    }

    if ($apps.ContainsKey('A') -and $apps.ContainsKey('B')) {
        $pa = Get-AppPid $apps['A']; $pb = Get-AppPid $apps['B']
        Say "DISTINCT-INSTANCES $(if ($pa -gt 0 -and $pa -ne $pb) { 'yes' } else { 'no' }) A=$pa B=$pb"
    }

    # A SAVED document per instance: does the ROT get a file moniker, and
    # does binding it reach the instance holding it?
    foreach ($tag in @($apps.Keys | Sort-Object)) {
        $app = $apps[$tag]
        $path = $probePaths.Drawings[$tag]
        try {
            if ($app.Documents.Count -eq 0) { $null = $app.Documents.Add() }
            $doc = $app.ActiveDocument
            $doc.SaveAs($path)
            Say "SAVEAS $tag ok path=$path"
        } catch { Say "SAVEAS $tag failed: $($_.Exception.Message)" }
    }
    Dump-Rot 'after-saves'
    $entries = [CadInstRot]::Entries()
    foreach ($tag in @($apps.Keys | Sort-Object)) {
        $path = $probePaths.Drawings[$tag]
        $hit = @($entries | Where-Object { $_[0] -ieq $path })
        if ($hit.Count -eq 0) { Say "BIND-DOC $tag not-in-rot path=$path"; continue }
        foreach ($h in $hit) {
            Say "BIND-DOC $tag in-rot pid=$(Get-AppPid $h[1]) expected=$(Get-AppPid $apps[$tag])"
        }
    }
    Active-Pid 'final'
}
finally {
    foreach ($tag in @($apps.Keys)) {
        $app = $apps[$tag]
        try {
            for ($i = $app.Documents.Count - 1; $i -ge 0; $i--) {
                try { $app.Documents.Item($i).Close($false) } catch { }
            }
            $app.Quit()
            Say "QUIT $tag requested"
        } catch { Say "QUIT $tag failed: $($_.Exception.Message)" }
    }
    $apps.Clear()
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline) {
        $alive = @(Get-ImagePids | Where-Object { $created -contains $_ })
        if ($alive.Count -eq 0) { break }
        Start-Sleep -Seconds 2
    }
    foreach ($p in @(Get-ImagePids | Where-Object { $created -contains $_ })) {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        Say "KILLED $p (did not quit within 30s)"
    }
    # Anything else of this image that was not running before the probe is
    # the probe's too (an instance COM started on its own).
    foreach ($p in @(Get-ImagePids | Where-Object { $pre -notcontains $_ })) {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        Say "KILLED $p (started during the probe, not by CreateObject)"
    }
    Remove-CadInstDrawingPaths $probePaths
    Say "DONE left-running=$((Get-ImagePids).Count)"
}
exit 0
