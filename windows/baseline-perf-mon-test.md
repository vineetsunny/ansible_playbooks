# Test Procedure

### 1. Create target directories

```bash
$SetupPath = 'C:\PerfLogs\Setup'
if (-not (Test-Path -LiteralPath $SetupPath)) {
    New-Item -Path $SetupPath -ItemType Directory -Force | Out-Null
}
```
### 2. Populate BASELINE.TXT with standard performance counters

```bash
$CounterFile = Join-Path $SetupPath 'BASELINE.TXT'
$Counters = @(
    "\LogicalDisk(C:)\% Free Space",
    "\LogicalDisk(C:)\Disk Reads/sec",
    "\LogicalDisk(C:)\Disk Writes/sec",
)
$Counters | Set-Content -LiteralPath $CounterFile -Encoding Ascii

```
### 3. Create the XML definition for the Scheduled Task

```bash
$TaskXmlPath = Join-Path $SetupPath 'BaseLine_PerfMon_Task.xml'
$TaskXmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Daily baseline performance monitoring starter task</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-01-01T00:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>logman.exe</Command>
      <Arguments>start Baseline</Arguments>
    </Exec>
  </Actions>
</Task>
"@
```
$TaskXmlContent | Set-Content -LiteralPath $TaskXmlPath -Encoding Unicode

---

## Case 1: When Disk space < 2.5 & files matched for deletion 

***Test***

i) We have more than 30 days old file with extention *.dat</br>
ii) One csv file 17 days older 

***Result***

```bash
TASK [Display summary report] **************************************************  
10:04:02 AM
ok: [win-test19] => {

    "msg": [

        "================ BASELINE SUMMARY REPORT ================",

        "Initial Free Space : 1.02 GB",

        "Post-Cleanup Free  : 41.02 GB",

        "Retention Days     : 15",

        "Sampling Status    : ok",

        "Target File        : WIN-BA9MFQOIQCJ_10282111.csv",

        "Latest Free %      : 13.504981750024662",

        "=========================================================="
    ]
}
```
***Logs***

```bash
2026/10/28 21:33:41 - Initial free space: 1.02 GB. Retention window: 15 days.


2026/10/28 21:33:41 - Removed expired artifact: C: \PerfLogs|Baseline\testfile_10GB.dat


2026/10/28 21:33:41 - Removed expired artifact: C: \PerfLogs\Baseline\testfile_30GB.dat


2026/10/28 21:33:41 - Removed expired artifact: C: \PerfLogs\Baseline\WIN-BA9MFQ0IQCJ]
_10252112.csv

2026/10/28 21:33:55 - Collector and task verified active.
```

## Case 2: When Disk space > 2.5, files matched for compression & deletion

***Test***

i) One csv file 3 days older</br>
ii) One file older than 30 days

***Result***

```bash
TASK [Display summary report] **************************************************  
10:18:59 AM

ok: [win-test19] => {

    "msg": [

        "================ BASELINE SUMMARY REPORT ================",

        "Initial Free Space : 41.02 GB",

        "Post-Cleanup Free  : 48.02 GB",

        "Retention Days     : 30",

        "Sampling Status    : ok",

        "Target File        : WIN-BA9MFQOIQCJ_10282111.csv",

        "Latest Free %      : 69.062181447502553",

        "=========================================================="

    ]

}
```

***Logs***

```bash
2026/10/28 21:48:37 - Initial free space: 41.02 GB. Retention window: 30 days.

026/10/28 21:48:37 - Removed expired artifact: C: \PerfLogs |Baseline|testfile_7GB.dat

2026/10/28 21:48:38 - Compressed archive: C: \PerfLogs\Baseline\WIN-BA9MFQ0IQCJ_10272112.csv -> C: \PerfLogs\Baseline

2026/10/28 21:48:52 - Collector and task verified active.
```
