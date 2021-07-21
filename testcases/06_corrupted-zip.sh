#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with three zip archives. The first contains a
#   valid hex file, the second one contains a corrupted zip file. The last
#   zip file contains a valid hex, for simplicity identical to the first hex
#   file. In the second case, the Calliope Mini will execute the previous
#   valid hex file. The corrupted zip file is renamed to .zip.failed and the
#   corresponding run_* folder is empty. The third zip archive is executed
#   nominally.
# Preparation
#   Provide zip archives 30sec-counter.zip (2x) and not.a.zip.
# Expected result
#   CalliopEO.py returns code 0 in all runs with the three zip archives
#   CalliopEO.py renames the valid .zip to .zip.done
#   CalliopEO.py renames the corrupted .zip to .zip.failed
#   CalliopEO.py creates in total three folders run_*
#   CalliopEO.py creates a .data files in the first and last folder run_*
#   The seconds folder run_* is empty
#   The two .data files in the first and last folders run_* have the same
#   content.
# Necessary clean-up
#   Remove created *.done, *.failed and folders run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile1="testcases/testfiles/30sec-counter.zip"
zipfile2="testcases/testfiles/not.a.zip"
zipfile3="testcases/testfiles/30sec-counter2.zip"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Provide three ZIP archive, the 2nd corrupted"
echo "--------------------------------------------------"
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

# 1. Stage: Execute the CalliopEO.py script with nominal hex file
cp ${zipfile1} .
${cmd_calliope_script}
# Save return code
ret_code_1=$?

# 2. Stage: Execute the CalliopEO.py script with corrupted zip file
cp ${zipfile2} .
${cmd_calliope_script}
# Save return code
ret_code_2=$?

# 3. Stage: Execute the CalliopEO.py script again with nominal zip file
cp ${zipfile3} .
${cmd_calliope_script}
# Save return code
ret_code_3=$?

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check: Return code in all three cases is 0 ... "
if [[ ${ret_code1} -eq 0 &&  ${ret_code2} -eq 0 &&  ${ret_code3} -eq 0 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Renamed .zip to .zip.done or zip.failed?
zipfile1_main=$(basename ${zipfile1})
zipfile1_done="${zipfile1_main}.done"
zipfile2_main=$(basename ${zipfile2})
zipfile2_failed="${zipfile2_main}.failed"
zipfile3_main=$(basename ${zipfile3})
zipfile3_done="${zipfile3_main}.done"
echo -n "Check: ZIP archive renamed to .done/.failed ... "
if [[ ! -e "${zipfile1_main}" && -e "${zipfile1_done}" && ! -e "${zipfile2_main}" && -e "${zipfile2_failed}" && ! -e "${zipfile3_main}" && -e "${zipfile3_done}" ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Created three folders run_*?
echo -n "Check: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 3 ]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Created two .data files in the two folders run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check: Created to .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# The to .data files have same content?
# Use command cmp to compare the files
echo -n "Check: The two .data files have same content ... "
if [ ${#data_files[@]} -eq 2 ]; then
    cmp --silent ${data_files[@]}
    if [ $? -eq 0 ]; then
        echo "PASSED"
    else
        echo "NOT PASSED"
    fi
else
    echo "NOT PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
#rm ${zipfile1_done} ${zipfile2_done}

# Remove folder run_*
#rm -rf run_*

