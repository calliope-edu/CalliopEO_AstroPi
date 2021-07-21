#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with no attached Calliope Mini microcontroller
#   board.
# Preparation
#   No zip archive with hex file(s) has to be provided because the script
#   shall check if a Calliope Mini is attached before processing any zip
#   archives. CalliopEO.py shall exit with return code 10 or 11.
# Expected result
#   CalliopEO.py returns code 10 or 11.
# Necessary clean-up
#   Nothing to clean up

###############################################################################
# Variables and definitions for this testcase
###############################################################################

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: No Calliope attached"
echo "---------------------------------------"
echo ""
# Make sure, Calliope is disconnected from Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is NOT attached to USB [y] " ans
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

# Return code of script is 10 or 11?
echo -n "Check: Return code of script is 10 or 11 ... "
if [[ ${ret_code} -eq 10 || ${ret_code} -eq 11 ]]; then
    echo "PASSED"
else
    echo "NOT PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

