# Function: Log-Message
function Log-Message {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $TimeStamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $MessageOut = "$TimeStamp - $Message"

    Add-Content -Path $LogFile -Value $MessageOut
}
# End Function: Log-Message


# Setup Directories and Logging
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Logging Folder and Filename
$LogPath = "C:\PerfLogs\Logs"
$LogDate = Get-Date -Format "yyyyMMdd_HHmm"
$LogFile = "$LogPath\BaseLine_$LogDate.log"

if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

Log-Message "Starting BaseLine Performance Monitor setup"


# Check Free Space and Clear Logs and Output CSV Files
$FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk |
    Where-Object { $_.DeviceID -eq "C:" }).FreeSpace

$FreeSpaceGB = [Math]::Round(($FreeSpace / 1GB), 2)

Log-Message "Free space available on C Drive: $($FreeSpaceGB) GB"


# Skip Baseline Setup if Free Space is Less Than 1 GB
if ($FreeSpaceGB -lt 1) {
    Log-Message "Not enough free space available. Skipping Baseline Performance Monitor setup."
    exit 0
}


# Determine Log Retention Age Based on Available Free Space
switch ($FreeSpaceGB) {
    { $_ -ge 2.5 } {
        $Age = 30
        break
    }

    { $_ -ge 1 -and $_ -lt 2.5 } {
        $Age = 15
        break
    }
}


# Baseline CSV Folder
$CSVPath = "C:\PerfLogs\Baseline"

# Baseline Setup Folder
$SetupPath = "C:\PerfLogs\Setup"

$Folders = @($CSVPath, $SetupPath)

foreach ($Folder in $Folders) {
    if (-not (Test-Path -Path $Folder)) {
        New-Item -Path $Folder -ItemType Directory -Force | Out-Null
        Log-Message "Created Folder: '$Folder'"
    }
    else {
        Log-Message "Folder '$Folder' already exists"
    }
}


# If Existing - Stop and Delete Baseline Monitoring Counters
Log-Message "Checking existing Baseline Monitoring Counters"

$BaselineQuery = & logman query "Baseline" 2>&1

if ($BaselineQuery | Select-String -Pattern "Data Collector Set was not found") {
    Log-Message "Baseline Monitoring Counters do NOT exist"
}
else {
    Log-Message "Baseline Monitoring Counters exist"

    # Stop Baseline Counters if They Are Running
    if ($BaselineQuery | Select-String -Pattern "Status:\s+Running") {
        Log-Message "Stopping Baseline Monitoring Counters"

        & logman stop "Baseline" 2>&1 |
            Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile
    }

    # Delete Baseline Counters
    Log-Message "Deleting Baseline Monitoring Counters"

    & logman delete "Baseline" 2>&1 |
        Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile
}


# Remove Older Counter Log Files
Log-Message "Clearing counters and logs older than $Age days"

$CurrentDate = Get-Date
$DateToDelete = $CurrentDate.AddDays(-$Age)

$CompressDate = (Get-Date).AddDays(-1).ToString("MMdd")
$BaselineLogName = "$($Env:COMPUTERNAME)_${CompressDate}*.CSV"


# Remove Counter CSV Files
Get-ChildItem -Path $CSVPath -File |
    Where-Object { $_.LastWriteTime -lt $DateToDelete } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Log-Message "Removed Counter CSV files older than $Age days"


# Remove Old Logs
Get-ChildItem -Path $LogPath -File |
    Where-Object { $_.LastWriteTime -lt $DateToDelete } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Log-Message "Removed Logs older than $Age days"


# Compress Last CSV File (1 Day Old)
$CSVFiles = Get-ChildItem -Path $CSVPath -Filter $BaselineLogName -File

foreach ($File in $CSVFiles) {
    Log-Message "Compressing File: $($File.FullName)"

    $ZipFile = "$($File.FullName).zip"

    Compress-Archive -Path $File.FullName `
        -DestinationPath $ZipFile `
        -CompressionLevel Fastest `
        -Force

    Remove-Item -Path $File.FullName -Force

    Log-Message "Compressed and removed CSV: $($File.Name)"
}


# Create Baseline Performance Monitoring Task
# Daily restart and on-boot configuration is defined in XML.

# Check if Scheduler Already Exists
$TaskName = "Baseline Performance Monitoring"

Log-Message "Checking Scheduler: $TaskName"

$TaskScheduler = & schtasks.exe /Query /TN $TaskName 2>&1

if ($LASTEXITCODE -eq 0) {
    Log-Message "Scheduler already exists"

    if ($TaskScheduler | Select-String -Pattern "Disabled") {
        Log-Message "Scheduler State: Disabled"

        & schtasks.exe /Change /TN $TaskName /ENABLE 2>&1 |
            Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile

        Log-Message "Scheduler Enabled"
    }
}
else {
    # Create New Scheduled Task
    Log-Message "Scheduler does NOT exist. Creating '$TaskName' Scheduled Task"

    & schtasks.exe /Create `
        /TN $TaskName `
        /XML "C:\PerfLogs\Setup\BaseLine_PerfMon_Task.xml" `
        /F 2>&1 |
        Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile
}


# Create and Start Baseline Counter Set
# Run every day to ensure new objects are added.

Log-Message "Creating Baseline Counter Set"

& logman create counter "Baseline" `
    -o "C:\PerfLogs\Baseline\$($Env:COMPUTERNAME)" `
    -f csv `
    -v mmddhhmm `
    -cf "C:\PerfLogs\Setup\BASELINE.TXT" `
    -sc 1440 `
    -si 60 2>&1 |
    Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile


# Start Baseline Counter Set
Log-Message "Starting Baseline Counter Set"

& logman start "Baseline" 2>&1 |
    Out-File -Append -NoClobber -Encoding ascii -FilePath $LogFile


Log-Message "Completed BaseLine Performance Monitor setup"
