# Setup Monitoring Baseline Test Cases


---


### 1.Monitoring counter is already running (Exit 0) 

```bash
 - '============================================================'
  - 'HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)'
  - 'EXIT CODE    : 0'
  - 'STATUS       : SKIPPED'
  - >-
    DETAILS      : Exit 0 -> Baseline Monitoring Counters are already running,
    No action required
'============================================================'

```

### 2.When playbook executed successfully (Exit 1)

```bash
msg:
  - '============================================================'
  - 'HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)'
  - 'EXIT CODE    : 1'
  - 'STATUS       : SUCCESS'
  - 'DETAILS      : Exit 1 -> Completed BaseLine Performance Monitor setup'
  - '============================================================'
```

### 3.Failed to create Logs Folder (Exit 2)

Reproduce: Create a "Log" file inside path C:\PerfLogs\, instead of a "Log" directory.

```bash
{
  "msg": [
    "============================================================",
    "HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)",
    "EXIT CODE    : 2",
    "STATUS       : FAILED",
    "DETAILS      : Exit 2 -> Failed to create Logs Folder | Detail: path C:\\PerfLogs\\Logs is not a directory",
    "============================================================"
```

### 4.Failed to create Baseline & Setup folder (Exit 3)

Reproduce: Create a "Baseline" file inside path C:\PerfLogs\, instead of a "Baseline" directory.

```bash
  - '============================================================'
  - 'HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)'
  - 'EXIT CODE    : 3'
  - 'STATUS       : FAILED'
  - >-
    DETAILS      : Exit 3 -> Failed to create Baseline & Setup Folder | Detail:
    One or more items failed
  - '============================================================'
```

### 5.Failed to copy setup files  (Exit 4)

Reproduce: Temporarily rename files/Baseline.txt in your project directory to files/Baseline.txt.bak

```bash
    "============================================================",
    "HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)",
    "EXIT CODE    : 4",
    "STATUS       : FAILED",
    "DETAILS      : Exit 4 -> Failed to copy setup files | Detail: One or more items failed",
    "============================================================"
```

### 6. Failed to create Task Scheduler (Exit 5)

Reproduce: Added extra variable in the AAP template - 
task_name: 'Invalid\Task:Name*Test'

```bash
msg:
  - '============================================================'
  - 'HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)'
  - 'EXIT CODE    : 5'
  - 'STATUS       : FAILED'
  - >-
    DETAILS      : Exit 5 -> Failed to create Task Scheduler | Detail: non-zero
    return code
  - '============================================================'
```

### 7. Failed to setup BaseLine Performance Monitor (Exit 6)

Reproduce: Project Baseline file (files/Baseline.txt) is empty. 


```bash
  - '============================================================'
  - 'HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)'
  - 'EXIT CODE    : 6'
  - 'STATUS       : FAILED'
  - >-
    DETAILS      : Exit 6 -> Failed to setup BaseLine Performance Monitor |
    Detail: non-zero return code
  - '============================================================'
```

### 8. Script failed to execute (Exit 20)

Reproduce: Added the temporary task as the very first item inside the block.

- name: Temporary unhandled failure test (Exit 20)
          ansible.builtin.fail:
            msg: "Simulated unhandled block failure"

```bash
  "msg": [
    "============================================================",
    "HOST SUMMARY : win-vm (WIN-BA9MFQOIQCJ)",
    "EXIT CODE    : 20",
    "STATUS       : FAILED",
    "DETAILS      : Exit 20 -> Script failed to execute | Detail: Simulated unhandled block failure",
    "============================================================"
```

---

# Cleanup:

```bash

$TaskName = "Baseline Performance Monitoring"
$CollectorName = "Baseline"
$PerfLogsPath = "C:\PerfLogs"

Write-Host "Starting Baseline Performance Monitoring cleanup..." -ForegroundColor Cyan

# 1. Stop and delete Logman Data Collector Set
logman stop $CollectorName 2>$null
logman delete $CollectorName 2>$null

Write-Host "Logman collector removed."

# 2. Stop and delete Scheduled Task
$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($Task) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false

    Write-Host "Scheduled Task removed."
}

# 3. Delete complete PerfLogs directory
if (Test-Path $PerfLogsPath) {
    Remove-Item -Path $PerfLogsPath -Recurse -Force
    Write-Host "C:\PerfLogs directory removed."
}

Write-Host "=========================================="
Write-Host "Baseline Performance Monitoring cleanup completed!" -ForegroundColor Green
Write-Host "=========================================="

```
