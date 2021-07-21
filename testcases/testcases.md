# Definition of Testcases

This tables helps to structure the test cases. The list gives also the preferred order of test cases.

No | Nominal? | Calliope connected? | Short ID/Filename | Description | Necessary ZIP files | TC implemented?
---|----------|---------------------|-------------------|-------------|---------------------|----------------
1 | n/a | no | 01_collect-sysinfo | Collects basic system info | none needed | yes
2 | no | no | 02_no-calliope | Run script with disconnected Calliope Mini. The script shall return code 10 or 11 | none needed | yes
3 | no | yes | 03_no-zip | No ZIP archive. The script shall return code 12 | none needed | yes
4 | yes | yes | 04_transmission-10s | Run script with ZIP archive containing nominal hex file transmitting data for 10s. This is important for the next non-nominal cases, where this hex is executed again. | 30sec-counter.zip | yes
5 | no | yes | 05_corrupted-hex | Provide script with ZIP archive containing a currupted hex file. The script will flash the Calliope but the Calliope will execute the last programmed hex file. | 30sec-counter.zip, its.garbage.zip | yes
6 | no | yes | 06_corrupted-zip | Provide CalliopEO.py script with corrupted ZIP archive. | 30sec-counter.zip, not.a.zip, 30sec-counter2.zip | yes
7 | no | yes | 07_transm-timeout | Calliope sends data for too long. The CalliopEO.py script shall terminate the connection and proceed with the next hex. | 900sec-counter.zip, 30sec-counter.zip | yes
8 | no | yes | 08_data-limit | Calliope exeeds data limit. The CalliopEO.py script shall terminate the connection and proceed with the next hex. | burst.zip, 30sec-counter.zip | yes
9 | no | yes | 09_no-response | Calliope does not respond to @START@ from the CalliopEO.py script. CalliopEO.py will resend @START@ a couple of times, then retry flashing in total 5 times and after this proceed with the next hex. | no-response.zip, 30sec-counter.zip | no
10 | no | yes | 09_multi-zip | Provide CalliopEO.py script with zip archive containing multiple hex files. | 30sec-counter.zip (multiple times) | yes
