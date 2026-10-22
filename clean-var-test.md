

## Script to generate the test files:

```bash
#!/bin/bash

set -euo pipefail

# Test file creation script for /var housekeeping
# Run as root or with sudo.

echo "=========================================="
echo "Creating /var housekeeping test files"
echo "=========================================="

# 1. Create old compressed files in /var/tmp (20 MB each, 20 days old)
echo "[1/5] Creating old compressed files in /var/tmp..."

mkdir -p /var/tmp

for ext in zip gz tar xz bz2 tgz; do
    file="/var/tmp/test-old.${ext}"
    fallocate -l 20M "$file"
    touch -d "20 days ago" "$file"
    echo "Created: $file (20 MB, 20 days old)"
done

# 2. Create old cache files (20 MB each, 20 days old)
echo "[2/5] Creating old cache files in /var/cache..."

mkdir -p /var/cache

for file in \
    /var/cache/test-x86_64-rpm \
    /var/cache/test-housekeeping.sqlite \
    /var/cache/test-housekeeping.sqlite-wal
do
    fallocate -l 20M "$file"
    touch -d "20 days ago" "$file"
    echo "Created: $file (20 MB, 20 days old)"
done

# 3. Create old client mail queue file (5 MB, 10 days old)
echo "[3/5] Creating client mail queue test file..."

mkdir -p /var/spool/clientmqueue

fallocate -l 5M /var/spool/clientmqueue/test-old-mail
touch -d "10 days ago" /var/spool/clientmqueue/test-old-mail

echo "Created: /var/spool/clientmqueue/test-old-mail (5 MB, 10 days old)"

# 4. Create old Postfix mail queue file (15 GB, 10 days old)
echo "[4/5] Creating Postfix mail queue test file..."

mkdir -p /var/spool/postfix/maildrop

fallocate -l 15G /var/spool/postfix/maildrop/test-old-mail
touch -d "10 days ago" /var/spool/postfix/maildrop/test-old-mail

echo "Created: /var/spool/postfix/maildrop/test-old-mail (15 GB, 10 days old)"

# 5. Create a 3 GB Centrify test file in /var/tmp
echo "[5/5] Creating Centrify test file..."

mkdir -p /var/tmp/centrify2017.3upgrade

fallocate -l 3G /var/tmp/centrify2017.3upgrade/test-file

echo "Created: /var/tmp/centrify2017.3upgrade/test-file (3 GB)"

echo
echo "=========================================="
echo "Test file creation completed successfully"
echo "=========================================="

echo
echo "Created files and sizes:"
du -h \
    /var/tmp/test-old.* \
    /var/cache/test-x86_64-rpm \
    /var/cache/test-housekeeping.sqlite \
    /var/cache/test-housekeeping.sqlite-wal \
    /var/spool/clientmqueue/test-old-mail \
    /var/spool/postfix/maildrop/test-old-mail \
    /var/tmp/centrify2017.3upgrade/test-file

echo
echo "Filesystem usage after file creation:"
df -h /var /var/tmp /var/cache /var/spool
```

## Files Matching the criteria:

ls -lr /var/spool/clientmqueue/</br>
total 3145728</br>
-rw-r--r--. 1 root root 3221225472 Oct  9 16:59 test-old-mail</br>
ls -lr /var/cache/</br>
total 15728640</br>
-rw-r--r--. 1 root root 5368709120 Sep 29 16:57 test-x86_64-rpm</br>
-rw-r--r--. 1 root root 5368709120 Sep 29 16:57 test-housekeeping.sqlite-wal</br>
-rw-r--r--. 1 root root 5368709120 Sep 29 16:57 test-housekeeping.sqlite</br>


## Before Space Utilization: 


```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   23G  6.6G  78% /var
```

## Successful Execution

```bash
TASK [Display filesystem calculation and result summary] ***********************  
3:55:27 PM

ok: [linux-test] => {

    "msg": [

        "========== HOUSEKEEPING FINAL REPORT ==========",
        "Host: linux-test",
        "Region: US",
        "Filesystem: /var",
        "Threshold: 65%",
        "Start time UTC: 2026-10-20 10:24:57",
        "Filesystem size: 31351788 KiB",
        "Usage before: 78%",
        "Available bytes before: 6992175104",
        "Successful actions: 12",
        "Failed actions: 0",
        "Usage after: 17%",
        "Available bytes after: 26513494016",
        "Net space reclaimed (+) / increased (-): 19063820 KiB",
        "Filesystem samples: 6",
        "Final status: SUCCESS",
        "Exit-code equivalent: 1",
        "Result: Filesystem usage is at or below 65%. Failed actions: 0.
```

## After filesystem Utilization

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  4.8G   25G  17% /var
```

