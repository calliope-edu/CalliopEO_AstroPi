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
zipfile="testcases/testfiles/not.a.zip"

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
cp ${zipfile} .

##############################################################################
# Execute testcase
###############################################################################

${cmd_calliope_script}
# Save return code
ret_code=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed .zip to .zip.done or zip.failed?
zipfile_main=$(basename ${zipfile})
zipfile_failed="${zipfile_main}.failed"
echo -n "Check: ZIP archive renamed to .failed ... "
if [[ ! -e "${zipfile_main}" && -e "${zipfile_failed}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created an empty folder run_*?
echo -n "Check: Empty folder run_* created ... "
run_folders=($(find . -type d -ipath "./run_*"))
if [ ${#run_folders[@]} -eq 1 ]; then
    if [ $(find ${run_folders[0]} -type f | wc -l) -eq 0 ]; then
        echo -e "${G}PASSED${NC}"
    else
        echo -e "${R}NOT PASSED${NC}"
    fi
else
    echo -e "${R}NOT PASSED${NC}"
fi

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm ${zipfile_failed}

# Remove folder run_*
rm -rf run_*

