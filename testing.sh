#!/bin/bash

# This bash script is used to perform testing on the
# Python script CalliopEO.py.

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

echo "################## TESTING CALLOPEO.PY ##################"
echo "Test started: $(date)"

# Loop over all testcases found in the folder ${tc_folder}
for testcase in ${tc_folder%/}/*.*; do
    # If the variable ${tc_confirm} is set to true ask
    # before execute any testcase. If the variable is unset or set
    # to false, execute testcase immediately.
    if [[ ${tc_confirm} == "true" ]]; then
        read -p "Execute testcase \"$(basename ${testcase})\"? [y/N] " ans
    else
        ans="y"
    fi
    if [[ ${ans} =~ [Yy]$ ]]; then
        echo ""
        source ${testcase}
        echo ""
    fi
done

echo "Test ended: $(date)"
exit 0

