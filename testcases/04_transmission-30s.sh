#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a single zip archive nominally transmitting
#   for 30 seconds.
# Preparation
#   Zip archive 30sec-counter.zip has to be provided
# Expected result
#   CalliopEO.py returns code 0.
#   CalliopEO.py renames 30sec-counter.zip to 30sec-counter.zip.done
#   CalliopEO.py created folder run_*
#   MD5 checksums of files in run_* match
# Necessary clean-up
#   Remove created *.done and folder run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile="testcases/testfiles/30sec-counter.zip"
md5file="testcases/testfiles/30sec-counter.md5"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Single, nominal ZIP archive provided"
echo "-------------------------------------------"
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
    echo -e "${R}ERROR:${NC} Main folder contains zip archive. Exiting."
    exit 1
fi
if [ $(find . -type d -ipath "./run_*" | wc -l) -ne 0 ]; then
    echo -e "${R}ERROR:${NC} Main folder contains folder run_*. Exiting."
    exit 1
fi

##############################################################################
# Preparations
##############################################################################

# Copy zip archive in the main directory
cp ${zipfile} .

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
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
echo -n "Check 1/4: Return code of script is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed 30sec-counter.zip to 30sec-counter.done?
zipfile_main=$(basename ${zipfile})
zipfile_done="${zipfile_main}.done"
echo -n "Check 2/4: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile_main}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created folder run_*?
echo -n "Check 3/4: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data file
run_folder=$(find . -type d -ipath "./run_*")
cp ${md5file} ${run_folder}/.
cd ${run_folder}
echo -n "Check 4/4: MD5 checksum in folder ${run_folder} ... "
md5sum -c $(basename ${md5file}) >> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi
cd ..

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm ${zipfile_done}

# Remove folder run_*
rm -rf run_*

