# Fluent Bit Software Uninstallation -  Test Prerequisites & Cases

***1. Install Fluent Bit***
- Install Fluent Bit under:  `C:\Program Files\td-agent-bit`
- Install fluent bit ( manually )

```bash
msiexec.exe /i "C:\Users\Administrator\Downloads\fluent-bit-5.1.3-win64.msi" /L*v "C:\Windows\Temp\fluent-install-ui.log"
```

***2. Create configuration directory and file***
```bash
New-Item -ItemType Directory -Path 'C:\Program Files\td-agent-bit\conf\company' -Force
```

```bash
@"
[SERVICE]
    Flush        1
    Log_Level    info

[OUTPUT]
    Name         stdout
    Match        *
    Host         Vmserver1
"@ | Set-Content 'C:\Program Files\td-agent-bit\conf\company\upstream.conf'
```

***3. Create source directory and dummy file***

```bash
New-Item -ItemType Directory -Path 'C:\Windows\Build\Scripts\Fluent-Test' -Force
```
```bash
New-Item -ItemType File -Path 'C:\Windows\Build\Scripts\Fluent-Test\test.txt' -Force
```

***4. Create machine-level environment variables***

```bash
[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-PAYLOAD', 'C:\Temp\FluentBitPayload', 'Machine')

[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-INSTALL', 'C:\Temp\FluentBitInstaller', 'Machine')
```
---

## Validation --  Run the following commands before executing the playbook.

***1. Check Fluent Bit installation and registry entry***

```bash
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'Fluent*' } | Select-Object DisplayName, UninstallString
```
***2. Check configuration file and content***

```bash

Test-Path 'C:\Program Files\td-agent-bit\conf\company\upstream.conf'

Select-String -Path 'C:\Program Files\td-agent-bit\conf\company\upstream.conf' -Pattern 'Vmserver1|Vmserver2'

```

***3. Check source directory***

```bash
Test-Path 'C:\Windows\Build\Scripts\Fluent-Test'
```

***4. Check machine-level environment variables***

```bash
[Environment]::GetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-PAYLOAD', 'Machine')

[Environment]::GetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-INSTALL', 'Machine')
```
---

# Test Cases:

***1.  Uninstall Fluent software***

```bash
TASK [Display remediation status] **********************************************  
11:26:46 AM

ok: [test-vm] => {

    "msg": [

        "Exit Code          : 1",

        "Successful Actions : 5",

        "Failed Actions     : 0",

        "Actions Attempted  : 5"

    ]

}

TASK [Display individual remediation details] **********************************  
11:26:46 AM

ok: [test-vm] => (item=Server 'Vmserver1' found in upstream.conf.) => {

    "msg": "Server 'Vmserver1' found in upstream.conf."

}

ok: [test-vm] => (item=Successfully uninstalled fluent-bit.) => {

    "msg": "Successfully uninstalled fluent-bit."

}

ok: [test-vm] => (item=Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-PAYLOAD) => {

    "msg": "Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-PAYLOAD"

}

ok: [test-vm] => (item=Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-INSTALL) => {

    "msg": "Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-INSTALL"

}

ok: [test-vm] => (item=Removed installation directory: C:\Program Files\td-agent-bit) => {

    "msg": "Removed installation directory: C:\\Program Files\\td-agent-bit"

}

ok: [test-vm] => (item=Removed source directory: C:\Windows\Build\Scripts\Fluent-Test) => {

    "msg": "Removed source directory: C:\\Windows\\Build\\Scripts\\Fluent-Test"

}

```

***2. If software not available*** 

```bash

TASK [Display remediation status] **********************************************  
11:31:33 AM

ok: [test-vm] => {

    "msg": [
        "Exit Code          : 0",

        "Successful Actions : 0",

        "Failed Actions     : 0",

        "Actions Attempted  : 0"

    ]

}
TASK [Display individual remediation details] **********************************  
11:31:33 AM

ok: [test-vm] => (item=Fluent Bit is not installed. No action required.) => {

    "msg": "Fluent Bit is not installed. No action required."
}

```

***3. Partial Test***


1. Created Mock Registry Entry, and Configuration File & Directory

```bash
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FluentBitMock"
New-Item -Path $RegPath -Force | Out-Null
Set-ItemProperty -Path $RegPath -Name "DisplayName" -Value "Fluent Bit Test"
Set-ItemProperty -Path $RegPath -Name "UninstallString" -Value "msiexec.exe /x {12345678-1234-1234-1234-1234567890AB} /qn"
$ConfigDir = "C:\Program Files\td-agent-bit\conf\company"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
Set-Content -Path "$ConfigDir\upstream-test.conf" -Value "Host Vmserver1"
``` 

2. Create test variable:

```bash
[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-PAYLOAD', 'test_value', 'Machine')
[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-INSTALL', 'test_value', 'Machine')
```

3. Playbook execution result
```bash
TASK [Check configuration and uninstall Fluent Bit] ****************************  
12:50:52 PM
fatal: [test-vm]: FAILED! => {"changed": true, "debug": [], "error": [], "host_err": "", "host_out": "", "information": [], "output": [], "result": {"ActionsAttempted": 4, "ExitCode": 2, "FailureCount": 1, "Messages": ["Server 'Vmserver1' found in upstream-test.conf.", "Failed to uninstall Fluent Bit Test: MSI uninstall returned exit code 1605.", "Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-PAYLOAD", "Removed machine environment variable: PUPPET-FLUENTBIT1.8.11-INSTALL", "Removed installation directory: C:\\Program Files\\td-agent-bit", "No matching Fluent Bit source directories found."], "SuccessCount": 3}, "verbose": [], "warning": []}
```

***Clean up:***

```bash
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FluentBitMock" -Recurse -Force
Remove-Item -Path "C:\Program Files\td-agent-bit" -Recurse -Force -ErrorAction SilentlyContinue
[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-PAYLOAD', $null, 'Machine')
[Environment]::SetEnvironmentVariable('PUPPET-FLUENTBIT1.8.11-INSTALL', $null, 'Machine')
```

***4. If target server is not found****

This test shows if the target server is not defined in `upstream.conf` then no action would be taken.

```bash
TASK [Display remediation status] **********************************************  
3:33:05 PM
ok: [test-vm] => {
    "msg": [
        "Exit Code          : 0",

        "Successful Actions : 0",

        "Failed Actions     : 0",

        "Actions Attempted  : 0"

    ]

}

TASK [Display individual remediation details] **********************************  
3:33:05 PM
ok: [test-vm] => (item=No matching server names found. No action taken.) => {
    "msg": "No matching server names found. No action taken."
}
```
