## Test preparation: 


1. Created test files using a script, with modification timestamps set to 5 days ago and each file sized at 5 GB.

```bash
#!/bin/bash

set -euo pipefail

TARGET_DIR="/var/crash"
FILE_SIZE="5G"
FILE_AGE="5 days ago"
FILE_COUNT=8

# Ensure the target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "ERROR: Directory $TARGET_DIR does not exist."
    exit 1
fi

# Check available space
available_kb=$(df -Pk "$TARGET_DIR" | awk 'END {print $4}')
required_kb=$((FILE_COUNT * 5 * 1024 * 1024))

if (( available_kb < required_kb )); then
    echo "ERROR: Insufficient free space in $TARGET_DIR."
    echo "Required: approximately 50 GiB"
    echo "Available: $((available_kb / 1024 / 1024)) GiB"
    exit 1
fi

echo "Creating $FILE_COUNT files of $FILE_SIZE each in $TARGET_DIR..."

for i in $(seq 1 "$FILE_COUNT"); do
    file="${TARGET_DIR}/core.old${i}"

    echo "Creating $file..."

    fallocate -l "$FILE_SIZE" "$file"
    touch -d "$FILE_AGE" "$file"

    echo "Created: $file"
done

echo
echo "All test files created successfully."
echo
echo "File details:"
ls -lh --time-style=long-iso "$TARGET_DIR"/core.old*

echo
echo "Filesystem usage:"
df -h "$TARGET_DIR"

```

2. Verify file names and ages

```bash
ls -l --time-style=long-iso /var/crash
```

Sample output for random files:

```bash
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old1
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old2
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old3
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old4
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old5
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old6
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old7
-rw-r--r--. 1 root root 5368709120 2026-10-10 05:42 core.old8
-rw-r--r--. 1 root root 5368709120 2026-10-13 05:28 core.old9
-rw-r--r--. 1 root root          0 2026-10-10 05:44 rest.core.old2
-rw-r--r--. 1 root root          0 2026-10-10 05:44 tcore.core.old2
-rw-r--r--. 1 root root          0 2026-10-10 05:44 test.core.old1
```


3. Files matching the deletion criteria

```bash
find /var/crash -maxdepth 1 -type f -name 'core.*' -mmin +4320 -print
```


4. Now total size - 78% (>65%)

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        60G   46G   14G  78% /var
```

## Case 1. Deleted matched criteria files, and skipped not matching.

```bash
TASK [Display housekeeping summary] ********************************************  
11:24:32 AM

ok: [linux-test] => {

    "msg": [

        "Filesystem: /var",

        "Cleanup directory: /var/crash",

        "Usage before: 78%",

        "Usage after: 10%",

        "Threshold: 65%",

        "Files deleted: 8",

        "Deleted files: ['/var/crash/core.old1', '/var/crash/core.old2', '/var/crash/core.old3', '/var/crash/core.old4', '/var/crash/core.old5', '/var/crash/core.old6', '/var/crash/core.old7', '/var/crash/core.old8']",

        "Raw df output before: Filesystem     1024-blocks     Used Available Capacity Mounted on\n/dev/vda3         62809068 48020848  14317520      78% /var",

        "Raw df output after: Filesystem     1024-blocks    Used Available Capacity Mounted on\n/dev/vda3         62809068 6077868  56260500      10% /var",

        "Result: Housekeeping performed successfully",

        "Exit code: 1"

    ]

}


TASK [Return housekeeping failure status] **************************************  
11:24:32 AM
skipping: [linux-test]

PLAY RECAP *********************************************************************

linux-test                 : ok=16   changed=3    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0   
```


## Case 2: When directory was not present 

i) Removed the crash directory
ii) Playbook result :
```bash
TASK [Display housekeeping summary] ********************************************  
11:31:05 AM

ok: [linux-test] => {

    "msg": [

        "Filesystem: /var",

        "Cleanup directory: /var/crash",

        "Usage before: 0%",

        "Usage after: 0%",

        "Threshold: 65%",

        "Files deleted: 0",

        "Deleted files: []",

        "Raw df output before: Not checked",

        "Raw df output after: Not rechecked",

        "Result: Directory not present: /var/crash",

        "Exit code: 21"

    ]

}


TASK [Return housekeeping failure status] **************************************  
11:31:05 AM
fatal: [linux-test]: FAILED! => {"changed": false, "msg": "Directory not present: /var/crash (logical exit code 21)"}

PLAY RECAP *********************************************************************

linux-test                 : ok=6    changed=1    unreachable=0    failed=1    skipped=15   rescued=0    ignored=0   

```

## Case 3: When utilization more than 65%, and no Files Found with Criteria

i) Created files with no matching criteria

```bash
ls -l --time-style=long-iso /var/crash
total 41943040
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 acore.old1
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 bcore.old1
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 ccore.old3
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 dcore.old4
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 ecore.old4
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 fcore.old4
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 gcore.old7
-rw-r--r--. 1 root root 5368709120 2026-10-10 06:09 hcore.old8
[root@linux-test var]# 
[root@linux-test var]# find /var/crash -maxdepth 1 -type f -name 'core.*' -mmin +4320 -print
[root@linux-test var]# 
[root@linux-test var]# df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        60G   41G   19G  69% /var

```
ii) Playbook result:

```bash
TASK [Display housekeeping summary] ********************************************  
11:42:47 AM

ok: [linux-test] => {

    "msg": [

        "Filesystem: /var",

        "Cleanup directory: /var/crash",

        "Usage before: 69%",

        "Usage after: 69%",

        "Threshold: 65%",

        "Files deleted: 0",

        "Deleted files: []",

        "Raw df output before: Filesystem     1024-blocks     Used Available Capacity Mounted on\n/dev/vda3         62809068 42778144  19560288      69% /var",

        "Raw df output after: Not rechecked",

        "Result: No eligible core dump files found; PSD attention required",

        "Exit code: 3"

    ]

}



TASK [Return housekeeping failure status] **************************************  
11:42:47 AM

fatal: [linux-test]: FAILED! => {"changed": false, "msg": "No eligible core dump files found; PSD attention required (logical exit code 3)"}

PLAY RECAP *********************************************************************

linux-test                 : ok=10   changed=1    unreachable=0    failed=1    skipped=11   rescued=0    ignored=0  
```

