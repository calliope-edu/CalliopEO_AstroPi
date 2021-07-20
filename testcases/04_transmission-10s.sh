#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a single zip archive nominally transmitting
#   for 10 seconds.
# Preparation
#   Zip archive log10s.zip has to be provided
# Expected result
#   CalliopEO.py returns code 0.
#   CalliopEO.py renames log10s.zip to log10s.zip.done
#   CalliopEO.py created folder run_YYYYMMDD-HHMMSS
# Necessary clean-up
#   Remove created *.done and folder run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile="testcases/testfiles/log10s.zip"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Single, nominal ZIP artchive provided"
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

# Copy zip archive in the main directory
cp ${zipfile} .

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script}
# Save return code
ret_code=$?

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check: Return code of script is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Renamed log10s.zip to log10s.zip.done?
zipfile_main=$(basename ${zipfile})
zipfile_done="${zipfile_main}.done"
echo -n "Check: ZIP archive renamed to .done ... "
if [[ $(find . -maxdepth 1 -iname "${zipfile_main}" | wc -l) -eq 0 && $(find . -maxdepth 1 -iname "${zipfile_done}" | wc -l) -eq 1 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

# Created folder run_*?
echo -n "Check: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm *.done

# Remove folder run_*
rm -rf run_*

