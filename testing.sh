#!/bin/bash

# This bash script is used to perform testing on the
# Python script CalliopEO.py.

# Colors for coloured output
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
NC='\033[0m' # No Color
BG_R='\e[0;41m'
BG_G='\e[0;42m'
BG_NC='\e[0m'

TESTS_PERFORMED=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=""

CALLIOPE_ATTACHED=""

# This variable indicates if we need to wait a little bit after attaching
# the CalliopEO (see issue #76)
WAIT_AFTER_CALL_ATTACHED=1

# Cd into the directory where testing.sh is located in the case
# this script was called from somewhere else.
cd $(dirname ${0})

# If exists, source the file testing.conf which holds
# definitions for some variables.
testing_conf="./testing.conf"
if [[ -f "${testing_conf}" ]]; then
    source ${testing_conf}
fi

# All the testcases are defined as bash scripts in the folder
# ${tc_folder}. If ${tc_folder} is unset (equal empty string) set it to
# default
if [[ ${tc_folder} == "" ]]; then
    tc_folder="./testcases"
fi

# If there are no testcases files in ${tc_folder} exit with message
# See issue #78
if [ $(ls -l ${tc_folder%/}/*.sh | wc -l) -eq 0 ]; then
    message="No testcases found in ${tc_folder}."
    whiptail --msgbox --title "CalliopEO Test" "${message}" 10 70
    exit 1
fi

whiptail_args+=(
    --backtitle "CalliopEO Test"
    --title "Select Tests"
    --clear
    --ok-button "Start"
    --checklist  "\nSelect the testcases to be executed"
    26 80 16
)

# Add testcase files as selection list to dialogue box
i=0
for f in ${tc_folder%/}/*.sh
do
    whiptail_args+=( "$((++i))" "${f##*/}" "on" )
done

# Show dialog box to let the user select the testcases
selected=$(whiptail  "${whiptail_args[@]}" 3>&1 1>&2 2>&3)

# Exit if user selected "Cancel"
dialog_status=$?
if [ "${dialog_status}" -eq 1 ]; then
    echo "No tests executed: ${dialog_status}"
    exit 1
fi

echo "################## TESTING CALLIOPEO.PY ##################"
echo "Test started: $(date)"

echo "Selected Tests: ${selected}"

# Loop over all testcases found in the folder ${tc_folder}. To disable
# a testcase from being executed, let the file name start with "."
i=0
for testcase in ${tc_folder%/}/*.sh; do
    i=$((i+1))
    if [[ "${selected}" == *"\"${i}\""* ]]; then
        echo ""
        echo -e "${G}Start #${i} ${testcase}${NC}"
        echo "---------------------------------"
        source ${testcase}
        echo "---------------------------------"
        echo -e "${Y}Finished #${i} ${testcase}${NC}"
        echo ""
        TESTS_PERFORMED=$((TESTS_PERFORMED+1))
    else
        echo ""
        echo -e "${Y}Skipped #${i} ${testcase}${NC}"
        echo ""
    fi
    # If the variable ${tc_confirm} is set to true ask
    # before execute any testcase. If the variable is unset or set
    # to false, execute testcase immediately.
    # if [[ ${tc_confirm} == "true" ]]; then
    #     read -p "Execute testcase \"$(basename ${testcase})\"? [y/N] " ans
    # else
    #     ans="y"
    # fi
    # if [[ ${ans} =~ [Yy]$ ]]; then
    #     echo ""
    #     source ${testcase}
    #     echo ""
    # fi
done

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${BG_G}"
else
    echo -e "${BG_R}"
fi
echo ""
echo "          Test ended: $(date)"
echo "${TEST_RESULTS}"
echo "          ${TESTS_PERFORMED} FINISHED"
echo "          ${TESTS_PASSED} PASSED"
echo "          ${TESTS_FAILED} NOT PASSED"
echo ""
echo -e "${BG_NC}"
exit 0

