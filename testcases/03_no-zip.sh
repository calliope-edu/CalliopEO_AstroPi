#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with no zip archive provided.
# Preparation
#   No zip archive has to be provided
# Expected result
#   CalliopEO.py returns code 12.
# Necessary clean-up
#   Nothing to clean up

###############################################################################
# Variables and definitions for this testcase
###############################################################################

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: No ZIP artchive provided"
echo "---------------------------------------"
echo ""
# Make sure, Calliope is connected to the Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is attached to USB [y] " ans
done

##############################################################################
# Exit script, if there is a ZIP archive in the main folder
##############################################################################
if [ $(find . -maxdepth 1 -iname *.zip | wc -l) -ne 0 ]; then
    echo "ERROR: Main folder contains zip archive. Exiting."
    exit 1
fi

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script}
# Save return code
ret_code=$?

# Let things settle (not neede here, because no files are written)
#sync
#sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 12?
echo -n "Check: Return code of script is 12 ... "
if [[ ${ret_code} -eq 12 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

