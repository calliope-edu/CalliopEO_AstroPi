#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py script with a hex file producing a lot of data
#   and setting the setting the command line paranmeter of CalliopEO.py
#   --max-data-size to provoke a termination by CalliopEO.py due to
#   exeedance of the data threshold. This testcase demonstrates that
#   the CalliopEO.py script handles the data limit threshold.
# Preparation
#   Provide zip archive burst.zip.
# Expected result
#   CalliopEO.py returns code 0
#   CalliopEO.py renames the the .zip to .zip.done
#   CalliopEO.py creates a folder run_*
#   CalliopEO.py creates a .data files in the folder run_*
#   The .data file has correct MD5 checksum
#   Size of .data file is meets the size treshold
# Necessary clean-up
#   Remove created *.done and folders run_*/

###############################################################################
# Import necessary functions
###############################################################################
source testcases/shfuncs/wait_for_calliope.sh

###############################################################################
# Variables and definitions for this testcase
###############################################################################
zipfile="01.zip"
max_data_size=8000 # bytes
hexfile1="testcases/testfiles/burst.hex"
datafile1="testcases/testfiles/burst.hex.data"
md5file="checksum.md5"
tmpdir="./tmp"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Handle data limit threshold"
echo "---------------------------------"
echo ""
# Make sure, Calliope is disconnected from Astro Pi
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
    echo -e "${R}ERROR:${NC} Main folder contains zip archive. Exiting."
    exit 1
fi
if [ $(find . -type d -ipath "./run_*" | wc -l) -ne 0 ]; then
    echo -e "${R}ERROR:${NC} Main folder contains folder run_*. Exiting."
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

cp "${datafile1}" "${tmpdir}/01.hex.data"

cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "${md5file}"
cd ..

zip -mqj "${zipfile}" "${tmpdir}/01.hex"

##############################################################################
# Execute testcase
###############################################################################


${cmd_calliope_script} --fake-timestamp --max-data-size=${max_data_size}
# Save return code
ret_code_1=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/6: Return code is 0 ... "
if [[ ${ret_code1} -eq 0 ]]; then
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

# Created folder run_*?
run_folders=($(find . -type d -ipath "./run_*"))
echo -n "Check 3/6: Folder run_* created ... "
if [ ${#run_folders[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created one .data files in the two folders run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check 4/6: Created two .data files ... "
if [ ${#data_files[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${md5file}" ${run_folder}/.
cd ${run_folder}
echo -n "Check 5/6: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${md5file}" >> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi
cd ..

# Verify that the first .data file meets the size threshold
echo -n "Check 6/6: First .data meets the size threshold (${max_data_size} bytes) ... "
if [ ${#data_files[@]} -eq 1 ]; then
    data_size2=$(wc -c ${data_files[0]} | awk '{print $1}') # size in bytes
    if [ "${data_size2}" -le "${max_data_size}" ]; then
        echo -e "${G}PASSED${NC}"
    else
        echo -e "${R}NOT PASSED${NC}"
        ERRORS=$((ERRORS+1))
    fi
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

# Remove folder tmp
rm -r "${tmpdir}"
