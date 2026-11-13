# Test Setup:

Note: This setup is configured for local accounts only, as an Active Directory environment was not available.

### 1. Create C:\serverInfo\NetworkIdentifier (required so Get-Content doesn't throw Exit 20)

```bash
New-Item -Path "C:\serverInfo" -ItemType Directory -Force | Out-Null

Set-Content -Path "C:\serverInfo\NetworkIdentifier" -Value "Internal"
```

### 2. Create the custom HS_ServerData WMI class WITH a Key qualifier & dummy service metadata

```bash
$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null)
$newClass["__CLASS"] = "HS_ServerData"
$newClass.Qualifiers.Add("Static", $true)
$newClass.Properties.Add("Country", [System.Management.CimType]::String, $false)
$newClass.Properties.Add("servicename", [System.Management.CimType]::String, $false)
$newClass.Properties["servicename"].Qualifiers.Add("Key", $true)
$newClass.Put() | Out-Null

New-CimInstance -ClassName "HS_ServerData" -Namespace "root\cimv2" -Property @{
    Country     = "India"
    servicename = "DummyTestService"
} | Out-Null
```

### 3. Create two local Windows groups to act as target groups

```bash
New-LocalGroup -Name "AAP_Test_DC_Admins" -Description "Test DC Group" -ErrorAction SilentlyContinue
New-LocalGroup -Name "AAP_Test_EIP_Admins" -Description "Test EIP Group" -ErrorAction SilentlyContinue
```

### 4. Verify NetworkIdentifier file content

```bash
Get-Content -Path "C:\serverInfo\NetworkIdentifier"
```
### 5. Verify WMI Class & ServiceName (Expected: DummyTestService)
 
```bash
(Get-CimInstance -ClassName HS_ServerData).servicename
```

### 6. Verify ServerName (Expected: Your local machine name)

$env:COMPUTERNAME

### 7. Verify Local Windows Groups

Get-LocalGroup -Name "AAP_Test_*"

### 8. Update CSV files accordingly.

---

# Test Cases: 

---

***Test 1. When groups are already present (0)***

```bash
  - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : AAP_Test_DC_Admins -> Exists'
  - 'EIP Group        : AAP_Test_EIP_Admins -> Exists'
  - '------------------------------------------------------------'
  - 'Exit Code        : 0'
  - 'Summary          : Groups already exist or not defined'
  - '============================================================'

  - When Country is not defined in AAPMapping.csv(0)
  
  msg:
  - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : N/A -> Not_Evaluated'
  - 'EIP Group        : N/A -> Not_Evaluated'
  - '------------------------------------------------------------'
  - 'Exit Code        : 0'
  - 'Summary          : Server out of scope or AAPInstance is None'
  - '============================================================'

```
---

***Test 2. When groups added(1)***

```bash

TASK [Ensure local test groups exist on standalone VM (local_test_mode=true)] ***  
changed: [test-vm] => (item=AAP_Test_DC_Admins)
changed: [test-vm] => (item=AAP_Test_EIP_Admins)


Result:

msg:
  - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : AAP_Test_DC_Admins -> Added'
  - 'EIP Group        : AAP_Test_EIP_Admins -> Added'
  - '------------------------------------------------------------'
  - 'Exit Code        : 1'
  - 'Summary          : Groups successfully added'
  - '============================================================'

```

***Test 3. When groups are not being added***

For this test, parameter `local_test_mode: false`

```bash
- '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : False'
  - '------------------------------------------------------------'
  - 'DC Group         : AAP_Test_DC_Admins -> Failed'
  - 'EIP Group        : AAP_Test_EIP_Admins -> Failed'
  - '------------------------------------------------------------'
  - 'Exit Code        : 2'
  - 'Summary          : Both groups failed to add'
  - '============================================================'

```

***Test 4. When groups are partially created***

For this test, parameter `local_test_mode: false`, removed the group prefix `TESTDOMAIN` from the TESTDOMAIN\AAP_Test_DC_Admins in the csv file.

```bash
  - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : False'
  - '------------------------------------------------------------'
  - 'DC Group         : AAP_Test_DC_Admins -> Failed'
  - 'EIP Group        : AAP_Test_EIP_Admins -> Added'
  - '------------------------------------------------------------'
  - 'Exit Code        : 3'
  - >-
    Summary          : Partially successful (one group added/exists, one
    failed/not defined)
  - '============================================================'

```

***Test 5. When Service is excluded(22)***

```bash
- '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : N/A -> Not_Evaluated'
  - 'EIP Group        : N/A -> Not_Evaluated'
  - '------------------------------------------------------------'
  - 'Exit Code        : 22'
  - 'Summary          : Service is in Exclusion list'
  - '============================================================'
```
  
  
  
  ***Test 6. When Server is excluded (23)***
  
  ```bash
  - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : WORKGROUP'
  - 'Network ID       : Internal'
  - 'Country          : India'
  - 'Service Name     : DummyTestService'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : N/A -> Not_Evaluated'
  - 'EIP Group        : N/A -> Not_Evaluated'
  - '------------------------------------------------------------'
  - 'Exit Code        : 23'
  - 'Summary          : Server is in Exclusion list'
  - '============================================================'
```

  ***Test 7. when country data is removed from server(26)***
  
  ```bash
    - '============================================================'
  - 'Target VM        : WIN-G2D4BES9168'
  - 'Domain / Workgrp : N/A'
  - 'Network ID       : N/A'
  - 'Country          : Unknown'
  - 'Service Name     : N/A'
  - 'Local Test Mode  : True'
  - '------------------------------------------------------------'
  - 'DC Group         : N/A -> Not_Evaluated'
  - 'EIP Group        : N/A -> Not_Evaluated'
  - '------------------------------------------------------------'
  - 'Exit Code        : 26'
  - 'Summary          : Server Country Data not available'
  - '============================================================'
```
  
  
---
  
# Cleanup:
  
 - Remove country and service data:
  
```bash
Get-CimInstance -ClassName HS_ServerData -Namespace root\cimv2 |
Where-Object {
    $_.Country -eq "India" -and
    $_.servicename -eq "DummyTestService"
} |
Remove-CimInstance
```

verify:

```bash
Get-CimInstance -ClassName HS_ServerData -Namespace root\cimv2
```


***Groups removal***

 - Check whether the groups exist:

```bash
Get-LocalGroup -Name "AAP_Test_DC_Admins"
Get-LocalGroup -Name "AAP_Test_EIP_Admins"
```
- Check whether they are members of Local Administrators:
```bash
Get-LocalGroupMember -Group "Administrators"
```
 - Remove:

```bash
Remove-LocalGroupMember -Group "Administrators" -Member "AAP_Test_DC_Admins"
Remove-LocalGroupMember -Group "Administrators" -Member "AAP_Test_EIP_Admins"
```
