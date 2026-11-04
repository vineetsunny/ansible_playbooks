# OTEL Collector Test Preparation and Cases

Note: For testing purpose, we have used v0.164.0.0, instead of 0.96.0.0. 

# Prepare Setup

***Step 1. Download and untar***

i) Invoke-WebRequest -Uri "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.164.0 otelcol_0.164.0_windows_amd64.tar.gz" -OutFile "otelcol_0.164.0_windows_amd64.tar.gz"

ii) tar -xvzf otelcol_0.164.0_windows_amd64.tar.gz



***Step 2. Define the executable and configuration paths***

$exe = "C:\Program Files\Otel-Collector\otelcol.exe"
$config = "C:\Program Files\Otel-Collector\conf\otel-config.yaml"
$binPath = "`"$exe`" --config=`"$config`""


***Step 3. Added configuration in `otel-config.yaml`***

```bash
receivers:
  filelog:
    include:
      - 'C:\Logs\*.log'
    start_at: beginning

processors:
  memory_limiter:
    check_interval: 5s
    limit_mib: 650
    spike_limit_mib: 130

exporters:
  debug:
    verbosity: detailed

service:
  telemetry:
    logs:
      level: info
      output_paths:
        - 'C:\Windows\CWS Build\Logs\otel-debug.log'
  pipelines:
    logs:
      receivers: [filelog]
      processors: [memory_limiter]
      exporters: [debug]
```

***Step 4. Create service:***

New-Service -Name "otel" -BinaryPathName $binPath -DisplayName "OpenTelemetry Collector" -StartupType Automatic

Start the service:
Start-Service -Name "otel"

Verify service: 
Get-Service -Name "otel"

Verify:
Get-Process otelcol

Validate the configuration:
.\otelcol.exe validate --config="C:\Program Files\Otel-Collector\conf\otel-config.yaml"


---

## Test Requirment: 

***1. Test Log Truncation (> 5 MB Log File)***

```bash
$logDir = "C:\Windows\CWS Build\Logs"
$logPath = Join-Path $logDir "otel-debug.log"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force
}

# Create a file with 10,000 lines (~6-8 MB)
$dummyLines = 1..10000 | ForEach-Object {
    "Line $($_): " + ("X" * 700)
}
$dummyLines | Set-Content -LiteralPath $logPath -Encoding utf8
``


Verification: Run (Get-Item 'C:\Windows\CWS Build\Logs\otel-debug.log').Length and confirm it returns a number greater than 5242880.
```


***2. Test Memory Limit & Spike Limit Modification***


$configPath = "C:\Program Files\Otel-Collector\conf\otel-config.yaml"

#Replace or set lower values to trigger the update

```bash
(Get-Content -LiteralPath $configPath -Raw) `
    -replace '(?m)^\s*limit_mib\s*:\s*\d+', '    limit_mib: 400' `
    -replace '(?m)^\s*spike_limit_mib\s*:\s*\d+', '    spike_limit_mib: 80' |
    Set-Content -LiteralPath $configPath
```

***3. Test Service Startup Type (start_mode: manual)***

```bash
Set-Service -Name "Otel" -StartupType Manual -Status Stopped
```

Verification: 

```bash
Get-CimInstance Win32_Service -Filter "Name='Otel'" | Select-Object Name, StartMode, DelayedAutoStart 
```

---

## Test Cases

***1. When otel service version matched, skipped further actions***

```bash
TASK [Display detected Otel version and check details] *************************  
3:37:44 PM
ok: [test-vm] => {
    "msg": [
        "--- OTEL VERSION INSPECTION ---",
        "Raw Detected Version: '0.164.0'",
        "Expected Version:     '0.164.0.0'",
        "Does it match?:        False",
        "Service Start Mode:    'delayed'",

        "--------------------------------"
    ]
}

TASK [End host run if remediation is skipped] **********************************  
3:37:44 PM
```
***2. When version didn't match, then performed further actions***

```bash

TASK [Display detected Otel version and check details] *************************  
3:43:01 PM
ok: [test-vm] => {
    "msg": [
        "--- OTEL VERSION INSPECTION ---",
        "Raw Detected Version: '0.164.0'",
        "Expected Version:     '0.96.0.0'",
        "Does it match?:        False",
        "Service Start Mode:    'delayed'",
        "--------------------------------"
    ]
}

TASK [Display Otel remediation summary] ****************************************  
3:43:18 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Actions:",
        "SKIPPED - Memory limit: already set to 650 MiB",
        "SKIPPED - Spike limit: already set to 130 MiB",
        "SKIPPED - Service restart: no configuration changes were made",
        "SKIPPED - Service startup: already set to Automatic Delayed Start",
        "SUCCESS - Otel service: started and verified running",
        "Successful actions: 1",
        "Failed actions: 0",
        "Final Exit Code: 1",
        "=============================================="
    ]
}

```

***3. When version matched & changed the Memory limit,Spike limit,log file size configuration not matched***

```bash
TASK [Display Otel remediation summary] ****************************************  
4:19:03 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Actions:",
        "SUCCESS - Log cleanup: retained latest 500 lines",
        "SUCCESS - Memory limit: configured and validated at 650 MiB",
        "SUCCESS - Spike limit: configured and validated at 130 MiB",
        "SUCCESS - Otel service: restarted and verified running",
        "SKIPPED - Service startup: already set to Automatic Delayed Start",
        "SUCCESS - Otel service: started and verified running",
        "Successful actions: 5",
        "Failed actions: 0",
        "Final Exit Code: 1",
        "=============================================="
    ]
}
```

***4. When service stopped, and startup type differ***

```bash
TASK [Display Otel remediation summary] ****************************************  
4:30:22 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Actions:",
        "SKIPPED - Memory limit: already set to 650 MiB",
        "SKIPPED - Spike limit: already set to 130 MiB",
        "SKIPPED - Service restart: no configuration changes were made",
        "SUCCESS - Service startup: set to Automatic Delayed Start",
        "SUCCESS - Otel service: started and verified running",
        "Successful actions: 2",
        "Failed actions: 0",
        "Final Exit Code: 1",
        "=============================================="
    ]
}
```

***5. When Service misconfigured***

```bash
TASK [Display Otel remediation summary] ****************************************  
4:39:19 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Actions:",
        "SKIPPED - Memory limit: already set to 650 MiB",
        "SKIPPED - Spike limit: already set to 130 MiB",
        "SKIPPED - Service restart: no configuration changes were made",
        "SKIPPED - Service startup: already set to Automatic Delayed Start",
        "FAILED - Otel service: unexpected error while starting",
        "Successful actions: 0",
        "Failed actions: 1",
        "Final Exit Code: 3",
        "=============================================="
    ]
}
```

***6. When partially steps are successful***

```bash
TASK [Display Otel remediation summary] ****************************************  
4:51:42 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Actions:",
        "SUCCESS - Memory limit: configured and validated at 650 MiB",
        "SUCCESS - Spike limit: configured and validated at 130 MiB",

        "FAILED - Otel service: unexpected error during restart",

        "SKIPPED - Service startup: already set to Automatic Delayed Start",
        
        "FAILED - Otel service: unexpected error while starting",
        
        "Successful actions: 2",
        "Failed actions: 2",
        "Final Exit Code: 2",
        "=============================================="
    ]
}
```

***7. When otel version matched, no action required***

```bash
TASK [Display Otel remediation summary] ****************************************  
5:37:53 PM
ok: [test-vm] => {
    "msg": [
        "========== OTEL REMEDIATION SUMMARY ==========",
        "Status: NO ACTION REQUIRED",
        "Actions:",
        "NO ACTION REQUIRED - Otel service version: 0.96.0.0",
        "Successful actions: 0",
        "Failed actions: 0",
        "Final Exit Code: 0",
        "=============================================="
    ]
}

```
