#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a corrupted zip archive. The corrupted zip
#   file is renamed to .zip.failed and the corresponding run_* folder is
#   empty.
# Preparation
#   Provide zip archive not.a.zip.
# Expected result
#   CalliopEO.py returns code 0
#   CalliopEO.py renames the corrupted .zip to .zip.failed
#   The folder run_* is empty
# Necessary clean-up
#   Remove created *.failed and folder run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile="testcases/testfiles/not.a.zip"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Provide three ZIP archive, the 2nd corrupted"
echo "--------------------------------------------------"
echo ""
# Make sure, Calliope is disconnected from Astro Pi
if [ "${CALLIOPE_ATTACHED}" != "yes" ]; then
    ans=""
    while [[ ! ${ans} =~ [Yy] ]]; do
        read -p "Confirm, Calliope Mini is attached to USB [y] " ans
    done
    CALLIOPE_ATTACHED="yes"
fi

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
cp ${zipfile} .

##############################################################################
# Execute testcase
###############################################################################

${cmd_calliope_script} --fake-timestamp
# Save return code
ret_code=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/3: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Renamed .zip to .zip.done or zip.failed?
zipfile_main=$(basename ${zipfile})
zipfile_failed="${zipfile_main}.failed"
echo -n "Check 2/3: ZIP archive renamed to .failed ... "
if [[ ! -e "${zipfile_main}" && -e "${zipfile_failed}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created an empty folder run_*?
echo -n "Check 3/3: Empty folder run_* created ... "
run_folders=($(find . -type d -ipath "./run_*"))
if [ ${#run_folders[@]} -eq 1 ]; then
    if [ $(find ${run_folders[0]} -type f | wc -l) -eq 0 ]; then
        echo -e "${G}PASSED${NC}"
    else
        echo -e "${R}NOT PASSED${NC}"
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Track testcase result
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${BG_G}Testcase passed.${BG_NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${BG_R}Testcase failed.${BG_NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm ${zipfile_failed}

# Remove folder run_*
rm -rf run_*

