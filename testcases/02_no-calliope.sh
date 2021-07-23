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
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: No Calliope attached"
echo "---------------------------------------"
echo ""
# Make sure, Calliope is disconnected from Astro Pi
if [ "${CALLIOPE_ATTACHED}" != "no" ]; then
    ans=""
    while [[ ! ${ans} =~ [Yy] ]]; do
        read -p "Confirm, Calliope Mini is NOT attached to USB [y] " ans
    done
    CALLIOPE_ATTACHED="no"
fi

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

# Return code of script is 10 or 11?
echo -n "Check 1/1: Return code of script is 10 or 11 ... "
if [[ ${ret_code} -eq 10 || ${ret_code} -eq 11 ]]; then
    echo -e "${G}PASSED${NC}"
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

