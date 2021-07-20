# Definition of Testcases

This tables helps to structure the test cases. The list gives also the preferred order of test cases.

No | Nominal? | Calliope connected? | Short ID/Filename | Description | Necessary ZIP files | TC implemented?
---|----------|---------------------|-------------------|-------------|---------------------|----------------
1 | n/a | no | 01_collect-sysinfo | Collects basic system info | none needed | yes
2 | no | no | 02_no-calliope | Run script with disconnected Calliope Mini. The script shall return code 10 or 11 | none needed | yes
3 | no | yes | 03_no-zip | No ZIP archive. The script shall return code 12 | none needed | yes
4 | yes | yes | 04_transmission-10s | Run script with ZIP archive containing nominal hex file transmitting data for 10s. This is important for the next non-nominal cases, where this hex is executed again. | log10s.zip | yes
5 | no | yes | corrupted_hex | Provide script with ZIP archive containing a currupted hex file. The script will flash the Calliope but the Calliope will execute the last programmed hex file. | its.garbage.zip | no
6 | no | yes | corrupted_zip | Provide script corrupted ZIP archive. | not.a.zip | no
