#!/bin/bash

# Testcase name:
#   02_do_tests
# Testcase description:
#   This tests the following
#   - Run Script without Calliope / Error no Calliope found
#   - Run Script without Zip Files / Error no Zip files found
#   - Run with only corrupted Zip file (and so no Hex file at all) / Error no files found
#   - Run with the following files
#       - Corrupted Zip File
#       - Zip file with .garbage File inside / The last flashed script will be logged
#       - Zip file with invalid .hex File / the last flashed script will be logged
#       - Hex file which runs 10s and then stops / regular running
#       - Hex file which runs 900s and then stops / should result in a timeout in this test
#       - Hex file which logs a lot of data / should run into the filesize limit in this test
#       - Hex file which send serial Data, but does not send a start or end tag. / This file will be reflashed n times and then skipped


# Ask to disconnect the mini
echo "Please disconnect the calliope mini"
echo "Press [return] to continue..."
while [ true ] ; do
read -s -N 1 -t 1 key
if [[ $key == $'\x0a' ]] ; then  # if input == ENTER key
break ;
fi
done

# Run without mini
echo "Run without Calliope mini"
python3 ./CalliopEO.py

# Ask to connect the mini again
echo "Please connect the calliope mini"
echo "Press [return] to continue..."
while [ true ] ; do
read -s -N 1 -t 1 key
if [[ $key == $'\x0a' ]] ; then  # if input == ENTER key
break ;
fi
done

# Run with no Zip File
echo "Run without Zip file"
python3 ./CalliopEO.py

cp ./testcases/testfiles/not.a.zip ./not.a.zip

# Run with corrupted Zip File
echo "Run with only corrupted Zip file"
python3 ./CalliopEO.py

cp ./testcases/testfiles/its.garbage.zip ./its.garbage.zip
cp ./testcases/testfiles/log10s.zip ./log10s.zip
cp ./testcases/testfiles/log900s.zip ./log900s.zip
cp ./testcases/testfiles/logMuch.zip ./logMuch.zip
cp ./testcases/testfiles/no-start.zip ./no-start.zip
cp ./testcases/testfiles/not.a.hex.zip ./not.a.hex.zip
cp ./testcases/testfiles/not.a.zip ./not.a.zip

# Run with all Zip files
echo "Run all test files"
python3 ./CalliopEO.py --max-data-size=1000 --max-script-execution=30

echo "All tests done"