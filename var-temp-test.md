# /var/tmp Filesystem Housekeeping – Test Cases


## Case 1: Disk cleanup for above threshold

1. Disk utilization above threshold

```bash
df -h /var/tmp/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   25G  5.0G  84% /var
```

2. Playbook successful execution

```bash
TASK [Display housekeeping summary] ********************************************  
4:41:55 PM

ok: [linux-test] => {

    "msg": [

        "Host: linux-test",

        "Region: US",

        "Directory: /var/tmp",

        "Usage before: 84%",

        "Usage after: 7%",

        "Files deleted: 4",

        "Result: HOUSEKEEPING_PERFORMED",

        "Housekeeping exit code: 1",

        "Log: /var/log/dc-tanium-housekeeping-psd-task.log"

```

3. Disk utilization under threshold

```bash
[fedora@linux-test tmp]$ df -h /var/tmp/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  1.9G   28G   7% /var
``` 


## Case 2: When size was under threshold


1. when utilization was less : 
```bash
[fedora@linux-test tmp]$ df -h /var/tmp/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  1.9G   28G   7% /var
[fedora@linux-test tmp]$ 
```

2. Successful playbook execution


```bash
TASK [Display housekeeping summary] ********************************************  
4:43:10 PM
ok: [linux-test] => {

    "msg": [

        "Host: linux-test",

        "Region: US",

        "Directory: /var/tmp",

        "Usage before: 7%",

        "Usage after: N/A%",

        "Files deleted: 0",

        "Result: HOUSEKEEPING_NOT_REQUIRED",

        "Housekeeping exit code: 0",

        "Log: /var/log/dc-tanium-housekeeping-psd-task.log"

    ]

}
```

## Case 3: No files matching for deletion

Availble files:

```bash
 ls -lr *.tar
-rw-r--r--. 1 root root     2099200 Oct 14 07:25 test-recent.tar
-rw-r--r--. 1 root root  7940280320 Oct 19 07:28 test-old.tar
-rw-r--r--. 1 root root 23277690880 Oct 19 07:32 house.tar
-rw-r--r--. 1 root root       10240 Oct 19 11:49 housekeeping-random-42.tar
-rw-r--r--. 1 root root       10240 Oct 19 11:25 housekeeping-random-33.tar
-rw-r--r--. 1 root root  5368719360 Oct 19 11:21 housekeeping-random-25.tar
-rw-r--r--. 1 root root  1825515520 Oct 19 07:26 housekeeping-filler.bin.tar

# Available size:

df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   26G  3.7G  88% /var
[fedora@linux-test tmp]$ 
```

2. Successful execution 

```bash
TASK [Display housekeeping summary] ********************************************  
5:24:56 PM

ok: [linux-test] => {

    "msg": [

        "Host: linux-test",

        "Region: US",

        "Directory: /var/tmp",

        "Usage before: 88%",

        "Usage after: 88%",

        "Files deleted: 0",

        "Result: NO_FILES_FOUND",

        "Housekeeping exit code: 3",

        "Log: /var/log/dc-tanium-housekeeping-psd-task.log"

```


## Case 4: Eligible files deleted, but threshold still high

Step 1. 

```bash

- Available files 


 ls -lrt *.tar
-rw-r--r--. 1 root root  7940280320 Oct  3 12:18 test-old.tar
-rw-r--r--. 1 root root     2099200 Oct 14 07:25 test-recent.tar
-rw-r--r--. 1 root root 23277690880 Oct 19 07:32 house.tar
-rw-r--r--. 1 root root       10240 Oct 19 11:25 housekeeping-random-33.tar
-rw-r--r--. 1 root root       10240 Oct 19 12:16 housekeeping-random-42.tar
-rw-r--r--. 1 root root  5368709120 Oct 19 12:17 housekeeping-random-222.tar

- Filesystem size

df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   26G  3.8G  88% /var
```


Step 2.  Successful execution


```bash
TASK [Display housekeeping summary] ********************************************  
5:52:47 PM
ok: [linux-test] => {

    "msg": [

        "Host: linux-test",

        "Region: US",

        "Directory: /var/tmp",

        "Usage before: 88%",

        "Usage after: 87%",

        "Files deleted: 1",

        "Result: USAGE_STILL_HIGH",

        "Housekeeping exit code: 2",

        "Log: /var/log/dc-tanium-housekeeping-psd-task.log"
    ]
}
```
