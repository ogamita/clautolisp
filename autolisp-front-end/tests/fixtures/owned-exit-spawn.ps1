param([string]$Directory,[int]$Code)
$ErrorActionPreference='Stop'
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-Command',('Start-Sleep -Seconds 15; exit '+$Code)) -WindowStyle Hidden -PassThru
@{pid=$p.Id;startTicks=$p.StartTime.ToUniversalTime().Ticks.ToString()} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Directory 'owned-cad-process.json') -Encoding ASCII
[IO.File]::WriteAllLines((Join-Path $Directory 'com-flags.txt'),@('CREATED=1','ATTACHED=0'))
