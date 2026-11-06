# C drive houskeeping - Test preparation and Cases


### Cleanup location & condition


| S.No. | Directory / Location | Cleanup Criteria | Remarks |
|---:|---|---|---|
| 1 | `C:\Temp\` | Files older than 7 days | |
| 2 | `C:\Windows\Temp\` | Files older than 7 days |  |
| 3 | `C:\SYS\PERFLOG\Troubleshoot_CTR\` | Files older than 15 days | |
| 4 | `C:\SYS\evtlog\sec\` | Files older than 15 days |  |
| 5 | `C:\Windows\Installer\$PatchCache$\Managed\` | Files older than 15 days | |
| 6 | `C:\$Recycle.Bin\` | Files older than 15 days | |
| 7 | IIS log directories (`W3SVC*`) | `.log` files older than 30 days | Location to be confirmed |
| 9 | `C:\Windows\` | `mem*.dmp*` files older than 7 days | |

---

## Script to generate the dummy files to fill up the disk:

```bash
# ============================================================
# Script Name : cdrive.ps1
# Purpose     : Provision test data for C Drive Housekeeping
# Target      : Reduce C: free space to approximately 19%
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# 1. Configuration
# ------------------------------------------------------------

$TargetFreePercent = 19
$MinimumFreeGB = 8

$LargeFile = "C:\Temp\C_Housekeeping_Test_Trigger.bin"

$OldDate7  = (Get-Date).AddDays(-8)
$OldDate15 = (Get-Date).AddDays(-16)
$GB = 1GB

# ------------------------------------------------------------
# 2. Get Initial Disk Information
# ------------------------------------------------------------

$Drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$TotalBytes = [long]$Drive.Size
$FreeBytes = [long]$Drive.FreeSpace

$TargetFreeBytes = [long]($TotalBytes * ($TargetFreePercent / 100))

Write-Host "`n========================================"
Write-Host " INITIAL C DRIVE STATUS"
Write-Host "========================================"

Write-Host "Total Size : $([math]::Round($TotalBytes/$GB,2)) GB"
Write-Host "Free Space : $([math]::Round($FreeBytes/$GB,2)) GB"
Write-Host "Free       : $([math]::Round(($FreeBytes/$TotalBytes)*100,2))%"

# ------------------------------------------------------------
# 3. Calculate Required Test Data
# ------------------------------------------------------------

[long]$BytesToCreate = $FreeBytes - $TargetFreeBytes

if ($BytesToCreate -le 0) {
    Write-Host "`nFree space is already at or below target."
    exit 0
}

if (($FreeBytes - $BytesToCreate) -lt ($MinimumFreeGB * $GB)) {
    throw "Insufficient disk safety margin. Aborting."
}

$RequiredGB = [math]::Round($BytesToCreate/$GB,2)

Write-Host "`nRequired test data: $RequiredGB GB"

$Confirm = Read-Host "Type YES to continue"

if ($Confirm -cne "YES") {
    Write-Host "Provisioning cancelled."
    exit 0
}

# ------------------------------------------------------------
# 4. Create Old Dummy Files in Cleanup Locations
# ------------------------------------------------------------

$TestLocations = @(
    @{ Path = "C:\Temp"; Age = 8 },
    @{ Path = "C:\Windows\Temp"; Age = 8 },
    @{ Path = "C:\SYS\PERFLOG\Troubleshoot_CTR"; Age = 16 },
    @{ Path = "C:\SYS\evtlog\sec"; Age = 16 },
    @{ Path = "C:\Windows\System32\Configuration\ConfigurationStatus"; Age = 16 }
)

foreach ($Location in $TestLocations) {

    $Path = $Location.Path

    try {

        if (!(Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force |
                Out-Null
        }

        $TestFolder = Join-Path $Path "Housekeeping_Test_Data"

        New-Item -ItemType Directory -Path $TestFolder -Force |
            Out-Null

        $File = Join-Path $TestFolder "housekeeping-test.txt"

        "Dummy housekeeping test file" |
            Set-Content -LiteralPath $File

        $OldDate = (Get-Date).AddDays(-$Location.Age)

        (Get-Item -LiteralPath $File).LastWriteTime = $OldDate

        Write-Host "Created: $File (Age: $($Location.Age) days)" `
            -ForegroundColor Green

    }
    catch {
        Write-Warning "Could not provision $Path : $_"
    }
}

# ------------------------------------------------------------
# 4A. Create Dummy Windows Installer PatchCache File (>15 days)
# ------------------------------------------------------------

try {
    $PatchCachePath = 'C:\Windows\Installer\$PatchCache$\Managed'

    if (!(Test-Path -LiteralPath $PatchCachePath)) {
        New-Item -ItemType Directory -Path $PatchCachePath -Force |
            Out-Null
    }

    $PatchTestFile = Join-Path $PatchCachePath 'housekeeping-test-patch.txt'

    'Dummy PatchCache housekeeping test file' |
        Set-Content -LiteralPath $PatchTestFile

    (Get-Item -LiteralPath $PatchTestFile).LastWriteTime = $OldDate15

    Write-Host "Created PatchCache test file: $PatchTestFile" `
        -ForegroundColor Green
}
catch {
    Write-Warning "PatchCache test file provisioning skipped: $_"
}

# ------------------------------------------------------------
# 4B. Create Dummy Recycle Bin File (>15 days)
# ------------------------------------------------------------

try {
    $RecyclePath = 'C:\$Recycle.Bin'

    if (!(Test-Path -LiteralPath $RecyclePath)) {
        New-Item -ItemType Directory -Path $RecyclePath -Force |
            Out-Null
    }

    $RecycleTestFile = Join-Path $RecyclePath 'housekeeping-test-recycle.txt'

    'Dummy Recycle Bin housekeeping test file' |
        Set-Content -LiteralPath $RecycleTestFile

    (Get-Item -LiteralPath $RecycleTestFile).LastWriteTime = $OldDate15

    Write-Host "Created Recycle Bin test file: $RecycleTestFile" `
        -ForegroundColor Green
}
catch {
    Write-Warning "Recycle Bin test file provisioning skipped: $_"
}

# ------------------------------------------------------------
# 5. Create Dummy IIS Log (If IIS Is Installed)
# ------------------------------------------------------------

try {

    $IISService = Get-Service W3SVC -ErrorAction SilentlyContinue

    if ($IISService) {

        Import-Module WebAdministration -ErrorAction Stop

        foreach ($Site in Get-Website) {

            $LogDir = [Environment]::ExpandEnvironmentVariables(
                $Site.logFile.directory
            )

            if ($LogDir -match '^[Cc]:') {

                $SiteLogPath = Join-Path $LogDir "W3SVC$($Site.id)"

                if (Test-Path $SiteLogPath) {

                    $LogFile = Join-Path $SiteLogPath `
                        "housekeeping-test-$($Site.id).log"

                    "Dummy IIS housekeeping log" |
                        Set-Content $LogFile

                    (Get-Item $LogFile).LastWriteTime = $OldDate15

                    Write-Host "Created IIS test log: $LogFile"
                }
            }
        }
    }
}
catch {
    Write-Warning "IIS test log provisioning skipped: $_"
}

# ------------------------------------------------------------
# 6. Create Dummy Windows Memory Dump
# ------------------------------------------------------------

try {

    $DumpFile = "C:\Windows\mem-housekeeping-test.dmp"

    "Dummy memory dump test data" |
        Set-Content $DumpFile

    (Get-Item $DumpFile).LastWriteTime = $OldDate7

    Write-Host "Created dummy memory dump: $DumpFile"

}
catch {
    Write-Warning "Memory dump provisioning skipped: $_"
}

# ------------------------------------------------------------
# 7. Create Large Test File
# ------------------------------------------------------------

Write-Host "`nCreating large test file..." -ForegroundColor Yellow

$Buffer = New-Object byte[] (64MB)

# Fill buffer with non-zero data to ensure actual disk allocation
$Random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

try {
    $Random.GetBytes($Buffer)
}
finally {
    $Random.Dispose()
}

$Stream = $null

try {

    $Stream = [System.IO.File]::Open(
        $LargeFile,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )

    [long]$Remaining = $BytesToCreate

    while ($Remaining -gt 0) {

        # Avoid Int32 overflow by comparing before conversion
        if ($Remaining -gt [long]$Buffer.Length) {
            [int]$WriteSize = $Buffer.Length
        }
        else {
            [int]$WriteSize = [int]$Remaining
        }

        $Stream.Write($Buffer, 0, $WriteSize)

        $Remaining -= [long]$WriteSize

        $WrittenGB = [math]::Round(
            ($BytesToCreate - $Remaining)/$GB, 2
        )

        Write-Progress `
            -Activity "Creating test data" `
            -Status "$WrittenGB GB written of $RequiredGB GB" `
            -PercentComplete (
                (($BytesToCreate - $Remaining)/$BytesToCreate)*100
            )
    }

    $Stream.Flush()
    $Stream.Close()
    $Stream = $null

    (Get-Item $LargeFile).LastWriteTime = $OldDate7

    Write-Progress -Activity "Creating test data" -Completed

    Write-Host "Large test file created successfully." `
        -ForegroundColor Green

}
catch {

    if ($Stream) {
        $Stream.Dispose()
    }

    Remove-Item $LargeFile -Force -ErrorAction SilentlyContinue

    throw "Large test file creation failed: $_"
}

# ------------------------------------------------------------
# 8. Final Disk Space Verification
# ------------------------------------------------------------

$FinalDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$FinalFreeGB = [math]::Round($FinalDrive.FreeSpace/$GB,2)

$FinalFreePct = [math]::Round(
    ($FinalDrive.FreeSpace/$FinalDrive.Size)*100,2
)

$RecoveredGB = [math]::Round(
    ($FreeBytes - $FinalDrive.FreeSpace)/$GB,2
)

Write-Host "`n========================================"
Write-Host " C DRIVE TEST DATA PROVISIONING SUMMARY"
Write-Host "========================================"

Write-Host "Total Drive Size : $([math]::Round($FinalDrive.Size/$GB,2)) GB"
Write-Host "Initial Free     : $([math]::Round($FreeBytes/$GB,2)) GB"
Write-Host "Final Free       : $FinalFreeGB GB"
Write-Host "Final Free %     : $FinalFreePct %"
Write-Host "Space Consumed   : $RecoveredGB GB"
Write-Host "Large Test File  : $LargeFile"

Write-Host "========================================"

if ($FinalFreePct -lt 20) {

    Write-Host "SUCCESS: Cleanup threshold reached." `
        -ForegroundColor Green

}
else {

    Write-Warning "Free space is still above 20%. Check disk metrics."

}

```
---

### Test Cases:

***1) When free space is above 20%, no action needed i.e exit code 0***

Result:

```bash
msg:
  - '=========================================================='
  - '               DRIVE C: HOUSEKEEPING SUMMARY             '
  - '=========================================================='
  - ' Host             : test-vm'
  - ' Total Drive Size : 59.4 GB'
  - ' Pre-cleanup Free : 43.8 GB (73.74%)'
  - ' Post-cleanup Free: 43.8 GB (73.74%)'
  - ' Space Recovered  : 0.0 GB'
  - ' Action Items Hit : 0'
  - ' Message          : Free space is above 20%. No action needed.'
  - ' Log Location     : C:\Windows\Build\logs\C_Housekeeping_ARF\C_Housekeeping_ARF.log'
  - ' Execution Status : OUT_OF_SCOPE (Exit Code: 0)'
  - '=========================================================='

```

***2) When space is less than 20%, and successful execution i.e exit code 1.***

Result:

```bash
msg:
  - '=========================================================='
  - '               DRIVE C: HOUSEKEEPING SUMMARY             '
  - '=========================================================='
  - ' Host             : test-vm'
  - ' Total Drive Size : 59.4 GB'
  - ' Pre-cleanup Free : 11.29 GB (19%)'
  - ' Post-cleanup Free: 43.8 GB (73.74%)'
  - ' Space Recovered  : 32.51 GB'
  - ' Action Items Hit : 7'
  - ' Message          : Remediation executed.'
  - ' Log Location     : C:\Windows\Build\logs\C_Housekeeping_ARF\C_Housekeeping_ARF.log'
  - ' Execution Status : SUCCESSFUL_CLEANUP (Exit Code: 1)'
  - '=========================================================='
```

***3) When clean up is partially successful, still space is less than 20%. i.e exit code 2***

```bash
  - '=========================================================='
  - '               DRIVE C: HOUSEKEEPING SUMMARY             '
  - '=========================================================='
  - ' Host             : test-vm'
  - ' Total Drive Size : 59.4 GB'
  - ' Pre-cleanup Free : 3.81 GB (6.41%)'
  - ' Post-cleanup Free: 8.81 GB (14.83%)'
  - ' Space Recovered  : 5.0 GB'
  - ' Action Items Hit : 1'
  - ' Message          : Remediation executed.'
  - ' Log Location     : C:\Windows\Build\logs\C_Housekeeping_ARF\C_Housekeeping_ARF.log'
  - ' Execution Status : PARTIAL_CLEANUP (Exit Code: 2)'
  - '=========================================================='
```

***4) No file matched for deletion, still space is less than 20%. i.e exit code 3***

```bash
msg:
  - '=========================================================='
  - '               DRIVE C: HOUSEKEEPING SUMMARY             '
  - '=========================================================='
  - ' Host             : test-vm'
  - ' Total Drive Size : 59.4 GB'
  - ' Pre-cleanup Free : 3.81 GB (6.41%)'
  - ' Post-cleanup Free: 3.81 GB (6.41%)'
  - ' Space Recovered  : 0.0 GB'
  - ' Action Items Hit : 0'
  - ' Message          : Remediation executed.'
  - ' Log Location     : C:\Windows\Build\logs\C_Housekeeping_ARF\C_Housekeeping_ARF.log'
  - ' Execution Status : NO_CLEANUP_PERFORMED (Exit Code: 3)'
  - '=========================================================='
```

