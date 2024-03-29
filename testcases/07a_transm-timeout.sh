#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with two hex files. The first is a
#   valid hex file, but transmitting longer than the configured transmission
#   timeout in the CalliopEO.py script (cli option
#   --max-script-execution-time). The second hex file is
#   transmitting well below this threshold. This testcase demonstrates that
#   the CalliopEO.py script handles the timeout as defined by the cli
#   parameter.
# Preparation
#   Provide a zip file containing 900sec-counter.hex
# Expected result
#   CalliopEO.py returns code 0
#   CalliopEO.py renames the the .zip to .zip.done
#   CalliopEO.py creates one folder run_*
#   CalliopEO.py creates a .data files in the folder run_*
#   Check output .data file
#   Transmission of first hex file was terminated not later than 5 seconds
#   after specified time
# Necessary clean-up
#   Remove created *.done, folder run_*/ and tmp files

###############################################################################
# Import necessary functions
###############################################################################
source testcases/shfuncs/comp.sh
source testcases/shfuncs/wait_for_calliope.sh

###############################################################################
# Variables and definitions for this testcase
###############################################################################
hexfile="testcases/testfiles/900sec-counter.hex"
datafile="testcases/testfiles/900sec-counter.hex.data.terminated35s"
allow_lines_differ_percent=10
max_exec_time=35 # seconds
zipfile="01.zip"
max_tdiff=5 # seconds
tmpdir="./tmp"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Handle transmission timeout"
echo "---------------------------------"
echo ""
# Make sure, Calliope is connected to Astro Pi
if [ "${CALLIOPE_ATTACHED}" != "yes" ]; then
    ans=""
    while [[ ! ${ans} =~ [Yy] ]]; do
        read -p "Confirm, Calliope Mini is attached to USB [y] " ans
    done
    if [ ${WAIT_AFTER_CALL_ATTACHED} -eq 1 ]; then
        wait_for_calliope
    fi
    CALLIOPE_ATTACHED="yes"
fi

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

# Ensure variable ${tmpdir} has no trailing /
tmpdir=${tmpdir#/}
# Remove old ${tmdir} if exists
if [ -d ${tmpdir} ]; then
    rm -r ${tmpdir}
fi
mkdir "${tmpdir}"

cp "${hexfile}" "${tmpdir}/01.hex"

cp "${datafile}" "${tmpdir}/01.hex.data"

zip -mqj "${zipfile}" "${tmpdir}/01.hex"

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
# set the --max-script-execution-time to ${max_exec_time}
${cmd_calliope_script} \
    --fake-timestamp \
    --max-script-execution-time=${max_exec_time} | tee ./output.txt.tmp
# Save return code
ret_code=$?
end=$(date +%s)

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/6: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Renamed .zip to .zip.done?
zipfile_done="${zipfile}.done"
echo -n "Check 2/6: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created one folders run_*?
run_folders=($(find . -type d -ipath "./run_*"))
echo -n "Check 3/6: Folder run_* created ... "
if [ ${#run_folders[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created one .data files in the folder run_*?
data_files=($(ls -1 ./run_*/*.data))
echo -n "Check 4/6: Created two .data files ... "
if [ ${#data_files[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

run_folder=$(find . -type d -ipath "./run_*")
echo -n "Check 5/6: Check .data file in ${run_folder} ... "
# Compare .data file created in test with "template" data file in folder
# ${tmpdir}. Due to timing issues, the number of lines in both files can
# differ. Hence, declare the test also successful if the files differ by
# ${allow_lines_differ_percent} of lines.
ret=$(comp "${run_folder}/01.hex.data" "${tmpdir}/01.hex.data" ${allow_lines_differ_percent})
if [ ${ret} -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Extract stop time from output of CalliopEO.py (YYYY/MM/DD-HH:MM:SS)
stop_time=$(cat ./output.txt.tmp | grep "Will stop @" | head -1 | awk '{print $7}')
# Re-format ${stop_time}: MM/DD/YYYY HH:MM:SS
stop_time2="${stop_time:5:2}/${stop_time:8:2}/${stop_time:0:4} ${stop_time:11:8}"
# Convert ${stop_time} to unix time stamp
stop_time_unix=$(date -d "${stop_time2}" +%s)
# Calculate the difference between ${end} and ${stop_time_unix} (seconds)
tdiff=$((end - stop_time_unix))
tdiff=${tdiff#-} # absolute value
# Time difference less-equal ${max_tdiff}?
echo -n "Check 6/6: Transmission terminated in time ... "
if [ "${tdiff}" -le "${max_tdiff}" ]; then
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

# Remove .done file
rm ${zipfile_done}

# Remove folder run_*
rm -rf run_*

# Remove temporary file with script output
rm ./output.txt.tmp

# Remove tmp dir
rm -rf "${tmpdir}"
