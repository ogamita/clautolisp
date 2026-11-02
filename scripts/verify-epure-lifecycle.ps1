# Strict native qualification; never sweep CAD processes from other invocations.
[CmdletBinding()]
param([string]$OutputDirectory, [switch]$IncludeControls,[switch]$RequireComDrawing,[switch]$IncludeBricsBatch,[int]$TimeoutSeconds=360,[ValidateRange(0,120)][int]$CrashObservationSeconds=30)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$alfe=Join-Path $repo 'autolisp-front-end/tools/alfe/bin/alfe-sbcl.exe'
$root=if($OutputDirectory){Join-Path $repo $OutputDirectory}else{Join-Path $repo 'dist/epure-lifecycle'}
$null=New-Item -ItemType Directory -Path $root -Force
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$session=(Get-Process -Id $PID).SessionId
$localData=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class EpureQualificationWindow {
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
}
'@
function Quote-Argument([string]$value) {
 if($value -ne '' -and $value -notmatch '[\s"]'){return $value}
 return '"'+[regex]::Replace([regex]::Replace($value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}
$cases=@([pscustomobject]@{Cad='autocad';Mode='automation'},[pscustomobject]@{Cad='bricscad';Mode='automation'})
if($IncludeBricsBatch){$cases+=[pscustomobject]@{Cad='bricscad';Mode='batch'}}
if($IncludeControls){$cases+=@([pscustomobject]@{Cad='autocad';Mode='automation';Control=$true},[pscustomobject]@{Cad='bricscad';Mode='automation';Control=$true})}
$results=@()
foreach($case in $cases){
 $name=$case.Cad+'-'+$case.Mode
 if($case.Control){$name+='-without-epure-plugin'}
 $work=Join-Path $root $name
 if(Test-Path -LiteralPath $work){throw 'Qualification workdir already exists; refusing to mix receipts.'}
 $null=New-Item -ItemType Directory -Path $work
 $drawing=Join-Path $work 'qualification.dwg'
 Copy-Item -LiteralPath (Join-Path $repo 'autolisp-front-end/source/empty.dwg') -Destination $drawing
 $probe=Join-Path $work 'probe.lsp'
 $forms=@('(if (car (atoms-family 1 (quote ("com_way")))) (princ "\nALFE.API.COM_WAY.OK\n") (princ "\nALFE.API.COM_WAY.FAIL\n"))','(if (car (atoms-family 1 (quote ("com_tl_continu")))) (princ "\nALFE.API.COM_TL_CONTINU.OK\n") (princ "\nALFE.API.COM_TL_CONTINU.FAIL\n"))')
 if($RequireComDrawing -or $case.Mode -eq 'batch'){
  $wanted=$drawing.Replace('\','/').ToUpperInvariant()
  $forms+='(if (= (strcase (vl-string-translate (chr 92) "/" (strcat (getvar "DWGPREFIX") (getvar "DWGNAME")))) "'+$wanted+'") (princ "\nALFE.DWG.OK\n") (princ "\nALFE.DWG.BAD\n"))'
 }
 $forms+=@('(princ "\nDIAG.ATOMS=") (prin1 (atoms-family 1 (quote ("com_way" "COM_WAY" "com_tl_continu" "COM_TL_CONTINU"))))', '(princ "\nDIAG.ENV=") (prin1 (list (getvar "VENDORNAME") (getvar "CPROFILE") (getvar "SECURELOAD") (findfile "com/lisp/sncf_startup.lsp") (findfile "on_start.lsp") (getenv "APPDATA")))')
 $forms+='(if (entmakex (quote ((0 . "LINE") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0)))) (princ "\nALFE.DIRTY.OK\n") (princ "\nALFE.DIRTY.FAIL\n"))'
 $forms | Set-Content -LiteralPath $probe -Encoding ASCII
 $arguments=@('--no-init','--debug','--plugin-path',(Join-Path $repo 'autolisp-front-end/plugins'),('--'+$case.Cad),'--epure','--mode',$case.Mode,'--timeout',([string]$TimeoutSeconds),'--workdir',$work,'--keep-workdir','-l',$probe)
 if($case.Control){$arguments=@($arguments|Where-Object {$_ -ne '--epure'})+@('--no-plugins')}
 if($RequireComDrawing -or $case.Mode -eq 'batch'){$arguments+=@('--dwg',$drawing)}
 $before=@{}
 Get-CimInstance Win32_Process -Filter "Name='acad.exe' OR Name='bricscad.exe' OR Name='accoreconsole.exe'" | ForEach-Object {$before[[string]$_.ProcessId]=$_.CreationDate.ToUniversalTime().Ticks}
 $record=[ordered]@{Name=$name;Commit=(& git -C $repo rev-parse HEAD);ExecutableHash=(Get-FileHash -LiteralPath $alfe -Algorithm SHA256).Hash;EpurePluginHash=(Get-FileHash -LiteralPath (Join-Path $repo 'autolisp-front-end/plugins/epure/epure.lisp') -Algorithm SHA256).Hash;Arguments=$arguments;EpurePlugin=(-not [bool]$case.Control);DrawingBefore=(Get-FileHash -LiteralPath $drawing -Algorithm SHA256).Hash;DrawingUnchanged=$false;DirtyVerified=$false;Started=[DateTime]::UtcNow.ToString('o');CadPid=$null;CadStartTicks=$null;NativeTerminated=$false;NativeExit=$null;NativeExitHex=$null;CliExit=$null;CleanupRequested=$false;Forced=$false;CrashEvents=@();Dumps=@();ApiMatches=0;DrawingVerified=$false;Passed=$false;Error=$null}
 $start=Get-Date
 $native=$null;$cli=$null
 try{
  $cli=Start-Process -FilePath $alfe -ArgumentList (($arguments|ForEach-Object {Quote-Argument $_}) -join ' ') -PassThru -RedirectStandardOutput (Join-Path $work 'alfe.stdout') -RedirectStandardError (Join-Path $work 'alfe.stderr')
  $null=$cli.Handle
  $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds+30)
  do{
   if(-not $native){
    $identityFile=Join-Path $work 'owned-cad-process.json'
    $candidates=@()
    if(Test-Path -LiteralPath $identityFile){
     try{$identity=Get-Content -LiteralPath $identityFile -Raw|ConvertFrom-Json;$candidates=@(Get-CimInstance Win32_Process -Filter ('ProcessId='+$identity.pid))}catch{$identity=$null}
    }elseif($case.Mode -eq 'batch'){
     $candidates=@(Get-CimInstance Win32_Process -Filter "Name='bricscad.exe'"|Where-Object {$_.ParentProcessId -eq $cli.Id -and $_.CommandLine.Replace('\','/').Contains($work.Replace('\','/'))})
    }
    foreach($candidate in $candidates){
     if($candidate.Name -ne ($case.Cad+'.exe') -and -not($case.Cad -eq 'autocad' -and $candidate.Name -eq 'acad.exe')){continue}
     $owner=Invoke-CimMethod -InputObject $candidate -MethodName GetOwnerSid
     if($owner.Sid -ne $sid -or $candidate.SessionId -ne $session -or $candidate.CreationDate -lt $start -or $before.ContainsKey([string]$candidate.ProcessId)){continue}
     $p=Get-Process -Id $candidate.ProcessId -ErrorAction Stop
     $ticks=$p.StartTime.ToUniversalTime().Ticks
     if($case.Mode -ne 'batch' -and $ticks -ne [int64]$identity.startTicks){$p.Dispose();continue}
     $null=$p.Handle;$native=$p;$record.CadPid=$p.Id;$record.CadStartTicks=[string]$ticks
     Write-Host "Owned $name PID=$($p.Id) start=$ticks"
     break
    }
   }
   if($cli.WaitForExit(0)){break}
   if([DateTime]::UtcNow -ge $deadline){throw 'ALFE qualification timeout.'}
   Start-Sleep -Milliseconds 100
  }while($true)
  $record.CliExit=$cli.ExitCode
  if(-not $native){throw 'No strongly owned native process captured; closure cannot be qualified.'}
  $record.NativeTerminated=$native.WaitForExit(10000)
  if(-not $record.NativeTerminated){throw 'The native process is still alive after ALFE returned.'}
  if($null -eq $native.ExitCode){throw "Native exit code unavailable."}
  $record.NativeExit=$native.ExitCode
  $record.NativeExitHex='0x'+[BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$native.ExitCode),0).ToString('X8')
  $stdout=Get-Content -LiteralPath (Join-Path $work 'alfe.stdout') -Raw
  $text=$stdout+(Get-Content -LiteralPath (Join-Path $work 'alfe.stderr') -Raw)
  $record.ApiMatches=[int]($stdout -match '(?m)^ALFE.API.COM_WAY.OK\r?$')+[int]($stdout -match '(?m)^ALFE.API.COM_TL_CONTINU.OK\r?$')
  $record.DrawingVerified=($stdout -match '(?m)^ALFE.DWG.OK\r?$')
  $record.DirtyVerified=($stdout -match '(?m)^ALFE.DIRTY.OK\r?$')
  $record.DrawingUnchanged=((Get-FileHash -LiteralPath $drawing -Algorithm SHA256).Hash -eq $record.DrawingBefore)
  # A natural native exit must be zero; neither SEH nor BABE variants are success.
  $allowedExit=($record.NativeExit -eq 0)
  $drawingOk=(-not($RequireComDrawing -or $case.Mode -eq 'batch') -or $record.DrawingVerified)
  $record.Passed=($record.CliExit -eq 0 -and $allowedExit -and ($case.Control -or $record.ApiMatches -eq 2) -and $drawingOk -and $record.DirtyVerified -and $record.DrawingUnchanged -and $text -notmatch 'natural shutdown; terminating it|OWNED-CAD-CLOSE-FAILED')
 }catch{$record.Error=$_.Exception.Message;$record.Passed=$false}
 finally{
  if($cli -and -not $cli.WaitForExit(0)){$cli.Kill();$null=$cli.WaitForExit(5000);$record.Forced=$true;$record.Passed=$false}
  if($native -and -not $native.WaitForExit(0)){
   $record.CleanupRequested=$true;$record.Passed=$false
   $null=[EpureQualificationWindow]::PostMessage($native.MainWindowHandle,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)
   if(-not $native.WaitForExit(5000)){$native.Kill();$null=$native.WaitForExit(5000);$record.Forced=$true}
  }
  if($native){
   Start-Sleep -Seconds $CrashObservationSeconds
   $hexPid='0x'+$native.Id.ToString('x')
   try{$record.CrashEvents=@(Get-WinEvent -LogName Application -MaxEvents 500 -ErrorAction Stop|Where-Object {$_.Id -in 1000,1001,1002 -and $_.TimeCreated -ge $start -and $_.Message -match ('(?i)\b'+[regex]::Escape($hexPid)+'\b')}|ForEach-Object {[pscustomobject]@{At=$_.TimeCreated.ToUniversalTime().ToString('o');Id=$_.Id;Message=$_.Message;Xml=$_.ToXml()}})}catch{$record.Error='Crash event collection failed: '+$_.Exception.Message;$record.Passed=$false}
   $dumpRoot=Join-Path $localData 'CrashDumps'
   if(Test-Path -LiteralPath $dumpRoot){$record.Dumps=@(Get-ChildItem -LiteralPath $dumpRoot -File|Where-Object {$_.Name -match ('\.'+$native.Id+'\.') -and $_.LastWriteTime -ge $start}|Select-Object Name,Length,CreationTimeUtc,LastWriteTimeUtc)}
   if($record.CrashEvents.Count -or $record.Dumps.Count){$record.Passed=$false}
   $native.Dispose()
  }
  if($cli){$cli.Dispose()}
  $record.ObservedUntil=[DateTime]::UtcNow.ToString('o')
  $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $work 'lifecycle.json') -Encoding UTF8
  $results+=[pscustomobject]$record
 }
 Write-Host "$name passed=$($record.Passed) cli=$($record.CliExit) native=$($record.NativeExitHex) forced=$($record.Forced)"
 # An unrecorded COM instance may still be running. Never launch further
 # CAD cases into that uncertainty, and never sweep unrelated instances.
 if(-not $native -and -not $record.CadPid){break}
}
$failed=@($results|Where-Object {-not $_.Passed}).Count
$settings=New-Object System.Xml.XmlWriterSettings;$settings.Indent=$true
$xml=[System.Xml.XmlWriter]::Create((Join-Path $root 'junit.xml'),$settings)
try{
 $xml.WriteStartDocument();$xml.WriteStartElement('testsuite');$xml.WriteAttributeString('name','epure-native-lifecycle');$xml.WriteAttributeString('tests',[string]$results.Count);$xml.WriteAttributeString('failures',[string]$failed);$xml.WriteAttributeString('errors','0')
 foreach($r in ($results|Sort-Object Name)){
  $xml.WriteStartElement('testcase');$xml.WriteAttributeString('classname','epure-native-lifecycle');$xml.WriteAttributeString('name',$r.Name)
  if(-not $r.Passed){$xml.WriteStartElement('failure');$xml.WriteAttributeString('message','Native EPURE lifecycle was not qualified');$xml.WriteString(($r|ConvertTo-Json -Depth 8));$xml.WriteEndElement()}
  $xml.WriteEndElement()
 }
 $xml.WriteEndElement();$xml.WriteEndDocument()
}finally{$xml.Dispose()}
$results|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $root 'summary.json') -Encoding UTF8
if($results.Count -ne $cases.Count){$failed++}
exit ([int]($failed -gt 0))
