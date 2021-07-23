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
#   the CalliopEO.py script handles the timeout and proceeds with the next
#   hex files.
# Preparation
#   Provide a zip file containing 900sec-counter.hex as 01.hex and
#   05sec-counter.hex as 02.hex
# Expected result
#   CalliopEO.py returns code 0
#   CalliopEO.py renames the the .zip to .zip.done
#   CalliopEO.py creates one folder run_*
#   CalliopEO.py creates two .data files in the folder run_*
#   The MD5 checksum in the folder run_* is verified
# Necessary clean-up
#   Remove created *.done, folder run_*/ and tmp files

###############################################################################
# Variables and definitions for this testcase
###############################################################################
hexfile1="testcases/testfiles/900sec-counter.hex"
datafile1="testcases/testfiles/900sec-counter.hex.data.terminated35s"
max_exec_time=35 # seconds
hexfile2="testcases/testfiles/05sec-counter.hex"
datafile2="testcases/testfiles/05sec-counter.hex.data"
zipfile="01.zip"
md5file="check.md5"
tmpdir="./tmp"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Continue with next hex after timeout"
echo "------------------------------------------"
echo ""
# Make sure, Calliope is disconnected from Astro Pi
if [ "${CALLIOPE_ATTACHED}" != "yes" ]; then
    ans=""
    while [[ ! ${ans} =~ [Yy] ]]; do
        read -p "Confirm, Calliope Mini is attached to USB [y] " ans
    done
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

cp "${hexfile1}" "${tmpdir}/01.hex"
cp "${hexfile2}" "${tmpdir}/02.hex"

cp "${datafile1}" "${tmpdir}/01.hex.data"
cp "${datafile2}" "${tmpdir}/02.hex.data"

cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "${md5file}"
cd ..

zip -mqj "${zipfile}" "${tmpdir}/01.hex" "${tmpdir}/02.hex"

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

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/5: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Renamed .zip to .zip.done?
zipfile_done="${zipfile}.done"
echo -n "Check 2/5: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created one folder run_*?
run_folders=($(find . -type d -ipath "./run_*"))
echo -n "Check 3/5: Folder run_* created ... "
if [ ${#run_folders[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created two .data files in the folder run_*?
data_files=($(ls -1 ./run_*/*.data))
echo -n "Check 4/5: Created two .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${md5file}" ${run_folder}/.
cd ${run_folder}
echo -n "Check 5/5: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${md5file}" >> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi
cd ..

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
