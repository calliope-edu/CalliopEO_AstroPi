#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with two zip archives. The first contains a
#   valid hex file, but transmitting more data than configured via the cli
#   option --max-data-size). The second zip contains a hex file
#   transmitting well below this threshold. This testcase demonstrates that
#   the CalliopEO.py script handles the data limit thtreshold and proceeds
#   with the next zip archive.
# Preparation
#   Provide zip archives 900sec-counter.zip and 30sec-counter.zip.
# Expected result
#   CalliopEO.py returns code 0 in all runs with the two zip archives
#   CalliopEO.py renames the the .zip to .zip.done
#   CalliopEO.py creates two folders run_*
#   CalliopEO.py creates .data files in both folders run_*
#   Second .data file has correct MD5 checksum
#   Size of first data file is meets the size treshold
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
hexfile2="testcases/testfiles/05sec-counter.hex"
datafile2="testcases/testfiles/05sec-counter.hex.data"
md5file="checksum.md5"
tmpdir="./tmp"
ERRORS=0

###############################################################################
# Import necessary functions
###############################################################################
source testcases/shfuncs/wait_for_calliope.sh

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Handle data limit treshold"
echo "--------------------------------"
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

# Created two .data files in the two folders run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check 4/6: Created two .data files ... "
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
if [ ${#data_files[@]} -eq 2 ]; then
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
