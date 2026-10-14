# Test Cases for /tmp Filesystem Cleanup

---

## Case 1. If space more than 75%

1. Created old timestamps files:

```bash
[root@linux-test tmp]# ls -lrt
total 1894400
-rw-r--r--. 1 root root 1835008000 Sep 24 01:28 housekeeping_fill.log
-rw-r--r--. 1 root root  104857600 Sep 24 01:28 housekeeping_test.txt
```

2. /tmp mount utilization:
```bash
[root@linux-test tmp]# df -h /tmp
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.9G  1.9G   89M  96% /tmp
```

3. Playbook successful execution:

```bash
TASK [Display housekeeping summary] ********************************************  
7:05:12 AM
[linux-test] => {

    "msg": [

        "Target filesystem: /tmp",

        "Usage before: 96%",

        "Usage after: 1%",

        "Files deleted: 2",

        "Result: Housekeeping performed successfully",

        "Exit code: 1"

    ]

}
TASK [Return housekeeping exit code] *******************************************  
7:05:12 AM
skipping: [linux-test]
PLAY RECAP *********************************************************************
101
linux-test                 : ok=15   changed=3    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0   
```

4. Utilization post cleanup
```bash
[root@linux-test tmp]# df -h /tmp
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.9G     0  1.9G   0% /tmp
[root@linux-test tmp]# 
```
---

## Case 2. If space less than 75%

```bash
TASK [Display housekeeping summary] ********************************************  
7:18:10 AM

ok: [linux-test] => {
    "msg": [

        "Target filesystem: /tmp",

        "Usage before: 73%",

        "Usage after: 73%",

        "Files deleted: 0",

        "Result: Housekeeping not required; usage is 73%",

        "Exit code: 0"

}

TASK [Return housekeeping exit code] *******************************************  
7:18:10 AM
skipping: [linux-test]
PLAY RECAP *********************************************************************
linux-test                 : ok=9    changed=1    unreachable=0    failed=0    skipped=12   rescued=0    ignored=0   
```

---

## Case 3. When utilization more than 75%, but files are not matching

Step 1 : Utilization 91%
```bash
[root@linux-test tmp]# df -h /tmp
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.9G  1.8G  189M  91% /tmp
```

Step 2: File extension is `.dat`, which is not meeting our deletion criteria. 
```bash
[root@linux-test tmp]# du -sh *
1.8G	housekeeping_fill.dat
```

Step 3: Playbook execution result

```bash
TASK [Display housekeeping summary] ********************************************  
7:25:50 AM

ok: [linux-test] => {

    "msg": [

        "Target filesystem: /tmp",

        "Usage before: 91%",

        "Usage after: 91%",

        "Files deleted: 0",

        "Result: No files found matching cleanup criteria; PSD attention required",

        "Exit code: 3"

    ]

}

TASK [Return housekeeping exit code] *******************************************  
7:25:50 AM

fatal: [linux-test]: FAILED! => {"changed": false, "msg": "No files found matching cleanup criteria; PSD attention required (exit code 3)"}

PLAY RECAP *********************************************************************
linux-test                 : ok=10   changed=1    unreachable=0    failed=1    skipped=10   rescued=0    ignored=0  
```

