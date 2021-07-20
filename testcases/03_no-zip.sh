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
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script}
# Save return code
ret_code=$?

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

