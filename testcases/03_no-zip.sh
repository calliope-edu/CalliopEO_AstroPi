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
ERRORS=0
# Make sure, Calliope is disconnected from Astro Pi
if [ "${CALLIOPE_ATTACHED}" != "yes" ]; then
    ans=""
    while [[ ! ${ans} =~ [Yy] ]]; do
        read -p "Confirm, Calliope Mini is attached to USB [y] " ans
    done
    CALLIOPE_ATTACHED="yes"
fi

##############################################################################
# Exit script, if there is a ZIP archive in the main folder
##############################################################################
if [ $(find . -maxdepth 1 -iname *.zip | wc -l) -ne 0 ]; then
    echo -e "${R}ERROR:${NC} Main folder contains zip archive. Exiting."
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
echo -n "Check 1/1: Return code of script is 12 ... "
if [[ ${ret_code} -eq 12 ]]; then
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

