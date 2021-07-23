# Definition of Testcases

This tables helps to structure the test cases. The list gives also the preferred order of test cases.

No | Nominal? | Calliope connected? | Short ID/Filename | Description | Necessary files | TC implemented?
---|----------|---------------------|-------------------|-------------|---------------------|----------------
1 | n/a | - | 01_collect-sysinfo | Collects basic system info | none needed | yes
2 | no | no | 02_no-calliope | Run script with disconnected Calliope Mini. The script shall return code 10 or 11 | none needed | yes
3 | no | yes | 03_no-zip | No ZIP archive. The script shall return code 12 | none needed | yes
4 | yes | yes | 04_transmission-10s | Run script with ZIP archive containing nominal hex file transmitting data for 10s. This is important for the next non-nominal cases, where this hex is executed again. | 05sec-counter.hex, 05sec-counter.hex.data | yes
5 | no | yes | 05_corrupted-hex | Provide script with ZIP archive containing a currupted hex file. The script will flash the Calliope but the Calliope will execute the last programmed hex file. | 05sec-counter.hex, 05sec-counter.hex.data, its.garbage.hex| yes
6 | no | yes | 06a_corrupted-zip | Provide CalliopEO.py script with corrupted ZIP archive. | not.a.zip | yes
7 | no | yes | 06b_corrupted-zip | Provide CalliopEO.py script with two nominal ZIP archive and a corrupted ZIP archive in between. | not.a.zip, 05sec-counter.hex, 05sec-counter.hex.data | yes
8 | no | yes | 07a_transm-timeout | Calliope sends data for too long. The CalliopEO.py script shall terminate the connection. | 900sec-counter.hex, 900sec-counter.hex.data.terminated35s | yes
9 | no | yes | 07b_transm-timeout | Calliope sends data for too long. The CalliopEO.py script shall terminate the connection and proceed with the next hex. | 900sec-counter.hex, 05sec-counter.hex, 900sec-counter.hex.data.terminated35s, 05sec-counter.hex.data | yes
10 | no | yes | 08a_data-limit | Calliope exeeds data limit. The CalliopEO.py script shall terminate the connection. | burst.hex, burst.hex.data | yes
11 | no | yes | 08b_data-limit | Calliope exeeds data limit. The CalliopEO.py script shall terminate the connection and proceed with the next hex. | burst.hex, 05sec-counter.hex, burst.hex.data, 05sec-counter.hex.data | yes
12 | no | yes | 09a_no-response | Calliope does not respond to @START@ from the CalliopEO.py script. CalliopEO.py will resend @START@ a couple of times, then retry flashing in total 5 times. | no-start.hex | yes
13 | no | yes | 09b_no-response | Calliope does not respond to @START@ from the CalliopEO.py script. CalliopEO.py will resend @START@ a couple of times, then retry flashing in total 5 times and after this proceed with the next hex. | no-start.hex, 05sec-counter.hex, 05sec-counter.hex.data | yes
14 | no | yes | 09_multi-zip | Provide CalliopEO.py script with two zip archives containing three hex files. | 05sec-counter.hex, 05sec-counter.hex.data | yes
