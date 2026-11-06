# Exercise the real Windows process/receipt verdict without starting a CAD.
[CmdletBinding()]
param([string]$Workdir=(Join-Path $env:TEMP ('epure-gate-'+[guid]::NewGuid().ToString('N'))))
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $Workdir){throw 'Fixture directory already exists.'}
$null=New-Item -ItemType Directory -Path $Workdir
$code=@'
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
public class Fixture {
 public static void Main(string[] args) {
  string work=null;
  for(int i=0;i<args.Length-1;i++)if(args[i]=="--workdir")work=args[i+1];
  string role=Path.GetFileNameWithoutExtension(Process.GetCurrentProcess().MainModule.FileName);
  string mode=Environment.GetEnvironmentVariable("EPURE_GATE_FIXTURE");
  if(role!="alfe-sbcl") {
   Process p=Process.GetCurrentProcess();
   File.WriteAllText(Path.Combine(work,"owned-cad-process.json"),"{\"pid\":"+p.Id+",\"startTicks\":\""+p.StartTime.ToUniversalTime().Ticks+"\"}");
   Thread.Sleep(2500);
   Environment.Exit(mode=="crash" ? unchecked((int)0xc0000005) : (mode=="nonzero" ? 47806 : 0));
  }
  string cad=Array.IndexOf(args,"--autocad")>=0 ? "acad.exe" : "bricscad.exe";
  ProcessStartInfo info=new ProcessStartInfo(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,cad),"--workdir \""+work+"\"");
  info.UseShellExecute=false;info.CreateNoWindow=true;
  Process child=Process.Start(info);
  Console.WriteLine(mode=="missing-api" ? "ALFE.API.COM_WAY.FAIL" : "ALFE.API.COM_WAY.OK");
  Console.WriteLine(mode=="missing-api" ? "ALFE.API.COM_TL_CONTINU.FAIL" : (mode=="duplicate-api" ? "ALFE.API.COM_WAY.OK" : "ALFE.API.COM_TL_CONTINU.OK"));
  Console.WriteLine("ALFE.DIRTY.OK");
  child.WaitForExit();
  // alfe's cleanup report (contract 2); the "unreported" mode writes none.
  int report=Array.IndexOf(args,"--cleanup-report");
  if(report>=0 && report<args.Length-1 && mode!="unreported") {
   uint code=unchecked((uint)child.ExitCode);
   File.WriteAllText(args[report+1],"contract=2\nowned=created\ncleanup-outcome=exited\ncleanup-forced=0\ncleanup-exit-code-hex=0x"+code.ToString("X8")+"\ncleanup=ok\nend=1\n");
  }
 }
}
'@
$binary=Join-Path $Workdir 'fixture.exe'
Add-Type -TypeDefinition $code -OutputAssembly $binary -OutputType ConsoleApplication
$helper=Join-Path $PSScriptRoot '../verify-epure-lifecycle.ps1'
# Also support an isolated checkout of the two fixture scripts.
if(-not(Test-Path -LiteralPath $helper)){$helper=Join-Path $PSScriptRoot 'verify-epure-lifecycle.ps1'}
foreach($mode in @('success','crash','duplicate-api','missing-api','nonzero','unreported')){
 $repo=Join-Path $Workdir $mode
 $bin=Join-Path $repo 'autolisp-front-end/tools/alfe/bin'
 $null=New-Item -ItemType Directory -Path $bin -Force
 $null=New-Item -ItemType Directory -Path (Join-Path $repo 'autolisp-front-end/source') -Force
 $null=New-Item -ItemType Directory -Path (Join-Path $repo 'autolisp-front-end/plugins/epure') -Force
 Set-Content -LiteralPath (Join-Path $repo 'autolisp-front-end/plugins/epure/epure.lisp') -Value '; fake CLI never loads plugins'
 $null=New-Item -ItemType Directory -Path (Join-Path $repo 'scripts')
 Copy-Item -LiteralPath $helper -Destination (Join-Path $repo 'scripts/verify-epure-lifecycle.ps1')
 foreach($name in @('alfe-sbcl.exe','acad.exe','bricscad.exe')){Copy-Item -LiteralPath $binary -Destination (Join-Path $bin $name)}
 Set-Content -LiteralPath (Join-Path $repo 'autolisp-front-end/source/empty.dwg') -Value 'fixture, not a CAD drawing'
 & git init --quiet $repo
 & git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit --allow-empty --quiet -m Fixture
 $previous=$env:EPURE_GATE_FIXTURE;$env:EPURE_GATE_FIXTURE=$mode
 try{
  $extra=@(if($mode -eq 'missing-api'){'-IncludeControls'})
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'scripts/verify-epure-lifecycle.ps1') -CrashObservationSeconds 0 -TimeoutSeconds 15 @extra
  $status=$LASTEXITCODE
 }finally{$env:EPURE_GATE_FIXTURE=$previous}
 # Contract 2: a native crash or nonzero code after alfe's frontier is reported,
 # not failed; a missing cleanup report, or a functional check, still fails.
 $expected=if($mode -in @('success','crash','nonzero')){0}else{1}
 if($status -ne $expected){throw "Unexpected gate exit for $mode : $status"}
 $summary=Get-Content (Join-Path $repo 'dist/epure-lifecycle/summary.json') -Raw|ConvertFrom-Json
 $caseCount=if($mode -eq 'missing-api'){4}else{2}
 if(@($summary).Count -ne $caseCount){throw 'Both fake engines must be observed.'}
 if($mode -eq 'crash' -and @($summary|Where-Object {$_.NativeExitHex -ne '0xC0000005' -or -not $_.Passed}).Count){throw 'Native crash code not recorded, or it failed the verdict.'}
 if($mode -eq 'nonzero' -and @($summary|Where-Object {$_.NativeExitHex -ne '0x0000BABE' -or -not $_.Passed}).Count){throw 'Nonzero native code not recorded, or it failed the verdict.'}
 if($mode -eq 'unreported' -and @($summary|Where-Object {$_.Passed}).Count){throw 'A run without a cleanup report was accepted.'}
 if($mode -eq 'duplicate-api' -and @($summary|Where-Object {$_.ApiMatches -ne 1 -or $_.Passed}).Count){throw 'Duplicated first API marker masked a missing second assertion.'}
 if($mode -eq 'missing-api'){
  foreach($r in $summary){if($r.ApiMatches -ne 0 -or $r.Passed -eq $r.EpurePlugin){throw 'Control cases masked missing EPURE APIs.'}}
 }
 [xml]$junit=Get-Content (Join-Path $repo 'dist/epure-lifecycle/junit.xml') -Raw
 if([int]$junit.testsuite.tests -ne $caseCount){throw 'JUnit cases missing.'}
 Write-Host "PASS $mode : two strongly owned native processes; expected lifecycle verdict and JUnit"
}
