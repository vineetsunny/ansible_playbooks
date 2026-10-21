# Test Cases For /var/log Filesystem

## Case 1.  Utilization Above Threshold, Successful Execution.

***1. High utilization***

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   25G  4.7G  85% /var
```

***2. Execution Summary - Utilization is within threshold***
```bash

TASK [Display final housekeeping result] ***************************************  
6:09:26 PM
ok: [linux-test] => {
    "msg": [
        "Filesystem: /dev/vda3",
        "Initial utilization: 85%",
        "Final utilization: 17%",
        "Threshold: 65%",
        "Housekeeping required: True",
        "Eligible files: 1",
        "Compression failures: 0",
        "Result: SUCCESS - Utilization is within threshold",
        "Exit code: 1"
    ]
}
```
***3. Post deletion validation***

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G  4.8G   25G  17% /var
```

## Case 2. High utilization, compress file but utilization remains above threshold.

***1. High Filesystem Utilization***
```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   27G  2.7G  91% /var
```

***2. Result Summary- Utilization remains above threshold***

```bash
TASK [Display final housekeeping result] ***************************************  
6:25:56 PM
ok: [linux-test] => {
    "msg": [
        "Filesystem: /dev/vda3",
        "Initial utilization: 91%",
        "Final utilization: 78%",
        "Threshold: 65%",
        "Housekeeping required: True",
        "Eligible files: 1",
        "Compression failures: 0",
        "Result: NO_SUCCESS - Utilization remains above threshold; PSD attention required",
        "Exit code: 2"
    ]
}
TASK [Fail job if housekeeping did not meet the threshold] *********************  
6:25:56 PM
fatal: [linux-test]: FAILED! => {"changed": false, "msg": "NO_SUCCESS - Utilization remains above threshold; PSD attention required. Utilization before=91%, after=78%, threshold=65%, exit_code=2."}
```
***3. Utilization Post Execution***

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   23G  6.7G  78% /var
```

## Case 3. High utilization, No eligible files found

***1. High Filesystem Utilization***

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   25G  4.7G  85% /var
```
***2.Execution Result- No eligible files found***

```bash
TASK [Display final housekeeping result] ***************************************  
6:34:21 PM
ok: [linux-test] => {
    "msg": [
        "Filesystem: /dev/vda3",
        "Initial utilization: 85%",
        "Final utilization: 85%",
        "Threshold: 65%",
        "Housekeeping required: True",
        "Eligible files: 0",
        "Compression failures: 0",
        "Result: NO_SUCCESS - No eligible files found",
        "Exit code: 3"
    ]
}


```

***3. Utilization Post Execution***

```bash
df -h /var
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda3        30G   25G  4.7G  85% /var
```
