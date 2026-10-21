# Test Cases for /opt Filesystem

***--------Script used to generate the eligible test files---------***

```bash
#!/bin/bash
set -euo pipefail

# Patrol paths use the actual server hostname
HOST="$(hostname -s)"

# Create the directories searched by clean-opt.yml
mkdir -p \
  "/opt/patrol/PATROL/log" \
  "/opt/patrol/PATROL/log/history/${HOST}/3300" \
  "/opt/patrol/PATROL/log/history/${HOST}/3399" \
  "/opt/controlm" \
  "/opt/IBM/wlp/usr/servers/testserver/logs" \
  "/opt/VRTSvxvm/debuginfo" \
  "/opt/VRTSaslapm/debuginfo"

echo "housekeeping test files"

# 1. Patrol: matching filename pattern, older than 1 day
fallocate -l 1G "/opt/patrol/PATROL/log/test.err5.housekeeping"
touch -d "2 days ago" "/opt/patrol/PATROL/log/test.err5.housekeeping"

# 2. Control-M: any regular file within the searched directory,
# older than 3 days
fallocate -l 2G "/opt/controlm/housekeeping_test.log"
touch -d "4 days ago" "/opt/controlm/housekeeping_test.log"

# 3. WAS archived log: matching archive extension,
# older than 7 days
fallocate -l 3G "/opt/IBM/wlp/usr/servers/testserver/logs/messages_test.zip"
touch -d "8 days ago" "/opt/IBM/wlp/usr/servers/testserver/logs/messages_test.zip"

# 4. WAS log: matching compression filename pattern,
# older than 1 day
fallocate -l 2G "/opt/IBM/wlp/usr/servers/testserver/logs/messages_test.log"
touch -d "2 days ago" "/opt/IBM/wlp/usr/servers/testserver/logs/messages_test.log"

# 5. VCS debuginfo: older than 30 days
fallocate -l 1G "/opt/VRTSvxvm/debuginfo/housekeeping_test.debug"
touch -d "31 days ago" "/opt/VRTSvxvm/debuginfo/housekeeping_test.debug"

echo
echo "Test files created."
```



## Case 1. Disk utilization more than 75%
***1. Higher disk utilization***

df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  9.3G  732M  93% /opt



***2. Playbook Successful Execution***

```bash
TASK [Report final result] *****************************************************  
3:59:50 PM
ok: [linux-test] => {
    "msg": [
        "Filesystem: /opt",
        "Usage before: 93%",
        "Usage after: 3%",
        "Threshold: 75%",
        "Result: HOUSEKEEPING_PERFORMED",
        "Exit code: 1",
        "Candidate report: /var/tmp/findfiles.txt",
        "Execution log: /var/log/housekeeping-psd-task.log"
    ]
}
```
***3. System disk validation***

```bash
df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  230M  9.8G   3% /opt
```

## Case 2. Utilization is high, files are present but not meeting conditions

***1. High disk utilization***

```bash
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  9.3G  730M  93% /opt
```

***2. No matching files found for deletion***

```bash
TASK [Report final result] *****************************************************  
4:40:55 PM

ok: [linux-test] => {
    "msg": [
        "Filesystem: /opt",
        "Usage before: 93%",
        "Usage after: 93%",
        "Threshold: 75%",
        "Result: FILESYSTEM_UTILIZATION_UNCHANGED",
        "Execution result: Filesystem utilization remains unchanged after housekeeping.",
        "Exit code: 2",
        "Candidate report: /var/tmp/findfiles.txt",
        "Execution log: /var/log/housekeeping-psd-task.log"
    ]
}

```
***3. Utilization is still above (same)***

```bash
df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  9.3G  730M  93% /opt
```


## Case 3. Utilization is above threshold, and no matching file exist.


***1. Utilization is high***
```bash
df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  8.3G  1.8G  83% /opt
```

***2. Result summary - no any matching file found***

```bash
TASK [Report final result] *****************************************************  
4:58:56 PM
189
ok: [linux-test] => {
190
    "msg": [
191
        "Filesystem: /opt",
192
        "Usage before: 83%",
193
        "Usage after: 83%",
194
        "Threshold: 75%",
195
        "Result: NO_ELIGIBLE_FILES",
196
        "Execution result: No eligible files found for housekeeping.",
197
        "Exit code: 3",
198
        "Candidate report: /var/tmp/findfiles.txt",
199
        "Execution log: /var/log/housekeeping-psd-task.log"
200
    ]
201
}
```


***3. Utilzation Remain High***

```bash
df -h /opt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  8.3G  1.8G  83% /opt
```


## Case 4. Target Directory Not Present

***1. Removed the /opt directory***

```bash
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  4.8G   25G  17% /
devtmpfs        888M     0  888M   0% /dev
tmpfs           933M     0  933M   0% /dev/shm
efivarfs        256K   48K  204K  20% /sys/firmware/efi/efivars
tmpfs           373M  752K  373M   1% /run
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
tmpfs           933M     0  933M   0% /tmp
/dev/vda3        30G  4.8G   25G  17% /boot
/dev/vda3        30G  4.8G   25G  17% /home
/dev/vda3        30G  4.8G   25G  17% /var
/dev/vda2       100M   22M   79M  22% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs           187M  4.0K  187M   1% /run/user/1000
```

***2. Result- Directory not present***
```bash
TASK [Report missing target directory] *****************************************  
5:16:51 PM
ok: [linux-test] => {
    "msg": [
        "Execution result: Target directory not present.",
        "Exit code: 21"
    ]
}

TASK [Stop if target directory is missing] *************************************  
5:16:51 PM
31
fatal: [linux-test]: FAILED! => {"changed": false, "msg": "HOUSEKEEPING_EXIT_CODE=21: Target directory not present: /opt"}
```

## Case 5. Unmounted Filesystem

***1. Unmount Filesystem From /opt Mount***

```bash
[root@linux-test /]# umount /opt
[ 9666.072346] XFS (sda1): Unmounting Filesystem dd70c162-7cf0-4d02-8963-87fb5b4372a9

---

 df -h 
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  4.8G   25G  17% /
devtmpfs        888M     0  888M   0% /dev
tmpfs           933M     0  933M   0% /dev/shm
efivarfs        256K   48K  204K  20% /sys/firmware/efi/efivars
tmpfs           373M  752K  373M   1% /run
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
tmpfs           933M     0  933M   0% /tmp
/dev/vda3        30G  4.8G   25G  17% /boot
/dev/vda3        30G  4.8G   25G  17% /home
/dev/vda3        30G  4.8G   25G  17% /var
/dev/vda2       100M   22M   79M  22% /boot/efi

```

***2. Result summary - Filesystem not mounted***

```bash
TASK [Report target filesystem is not mounted] *********************************  
5:07:04 PM

ok: [linux-test] => {
    "msg": [
        "Execution result: Target filesystem not mounted.",
        "Exit code: 22"
    ]
}
```