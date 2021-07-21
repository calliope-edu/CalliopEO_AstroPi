#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with two zip archives. The first contains a
#   valid hex file, but transmitting longer than the configured transmission
#   timeout in the CalliopEO.py script (cli option
#   --max-script-execution-time). The second zip contains a hex file
#   transmitting well below this threshold. This testcase demonstrates that
#   the CalliopEO.py script handles the time out and proceeds with the next
#   zip archive.
# Preparation
#   Provide zip archives 900sec-counter.zip and 30sec-counter.zip.
# Expected result
#   CalliopEO.py returns code 0 in all runs with the two zip archives
#   CalliopEO.py renames the the .zip to .zip.done
#   CalliopEO.py creates two folders run_*
#   CalliopEO.py creates .data files in both folders run_*
#   Second .data file has correct MD5 checksum
#   ToDo: Transmission of first hex file was terminated after specified time
# Necessary clean-up
#   Remove created *.done and folders run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile1="testcases/testfiles/900sec-counter.zip"
max_exec_time=30 # seconds
zipfile2="testcases/testfiles/30sec-counter.zip"
md5file2="testcases/testfiles/30sec-counter.md5"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Handle transmission timeout"
echo "---------------------------------"
echo ""
# Make sure, Calliope is connected to the Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is attached to USB [y] " ans
done

##############################################################################
# Exit script, if there is a ZIP archive or folder run_* in the main folder
##############################################################################
if [ $(find . -maxdepth 1 -iname *.zip | wc -l) -ne 0 ]; then
    echo "ERROR: Main folder contains zip archive. Exiting."
    exit 1
fi
if [ $(find . -type d -ipath "./run_*" | wc -l) -ne 0 ]; then
    echo "ERROR: Main folder contains folder run_*. Exiting."
    exit 1
fi

##############################################################################
# Preparations
##############################################################################

##############################################################################
# Execute testcase
###############################################################################

# 1. Stage: Execute the CalliopEO.py script with the hex file transmitting too
# long and set the --max-script-execution-time to ${max_exec_time}
cp ${zipfile1} .
s1start=$(date +%s)
ret1=$(${cmd_calliope_script} --max-script-execution-time=${max_exec_time})
# Save return code
ret_code_1=$?
s1end=$(date +%s)

# 2. Stage: Execute the CalliopEO.py script with nominal zip file
cp ${zipfile2} .
${cmd_calliope_script}
# Save return code
ret_code_2=$?

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check: Return code in all cases is 0 ... "
if [[ ${ret_code1} -eq 0 &&  ${ret_code2} -eq 0 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Renamed .zip to .zip.done?
zipfile1_main=$(basename ${zipfile1})
zipfile1_done="${zipfile1_main}.done"
zipfile2_main=$(basename ${zipfile2})
zipfile2_done="${zipfile2_main}.done"
echo -n "Check: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile1_main}" && -e "${zipfile1_done}" && ! -e "${zipfile2_main}" && -e "${zipfile2_done}" ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Created two folders run_*?
run_folders=($(find . -type d -ipath "./run_*"))
echo -n "Check: Folder run_* created ... "
if [ ${#run_folders[@]} -eq 2 ]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Created two .data files in the two folders run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check: Created two .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Verify content of .data file after execution of 30sec-counter.hex
echo -n "Check: Verify content of .data file ... "
if [ ${#run_folders[@]} -eq 2 ]; then
    cp ${md5file2} ${run_folders[1]}
    cd ${run_folders[1]}
    md5sum -c $(basename ${md5file2}) >> /dev/null
    if [ $? -eq 0 ]; then
        echo "PASSED"
    else
        echo "NOT PASSED"
    fi
    cd ..
else
    echo "NOT PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm ${zipfile1_done} ${zipfile2_done}

# Remove folder run_*
rm -rf run_*

