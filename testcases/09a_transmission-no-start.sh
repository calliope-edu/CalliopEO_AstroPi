#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a single zip archive nominally transmitting
#   for 30 seconds.
# Preparation
#   Hex file no-start.hex has to be provided
#   Data file no-start.hex.data has to be provided
# Expected result
#   CalliopEO.py returns code 0.
#   CalliopEO.py renames 01.zip to 01.zip.done
#   CalliopEO.py created folder run_*
#   MD5 checksums of files in run_* match
# Necessary clean-up
#   Remove created *.done and folder run_*/ and folder tmp/

###############################################################################
# Import necessary functions
###############################################################################
source testcases/shfuncs/wait_for_calliope.sh

###############################################################################
# Variables and definitions for this testcase
###############################################################################
tmpdir="./tmp"
zipfile="01.zip"
hexfile1="no-start.hex"
checksumfile="checksum.md5"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Hex File without sending @START@, but send other data."
echo "-------------------------------------------"
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

# Ensure variable ${tmpdir} has no trailing /
tmpdir=${tmpdir#/}
# Remove old ${tmdir} if exists
if [ -d ${tmpdir} ]; then
    rm -r ${tmpdir}
fi
mkdir "${tmpdir}"

# Copy Hex files to tmp
cp "testcases/testfiles/${hexfile1}" "${tmpdir}/01.hex"
# Copy Data files to tmp
## no data file created
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "${checksumfile}"
cd ..
# Create zip archives in the main directory
zip -mqj "${zipfile}" "${tmpdir}/01.hex"

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script} --fake-timestamp
# Save return code
ret_code=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/5: Return code of script is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Renamed 01.zip to 01.zip.done?
zipfile_done="${zipfile}.done"
echo -n "Check 2/5: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created folder run_*?
echo -n "Check 3/5: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check md5sums for hex and data file
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${checksumfile}" ${run_folder}/.
cd ${run_folder}
echo -n "Check 4/5: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${checksumfile}" >> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi
cd ..

# Created no .data files in the folder run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check 5/5: Created no .data files ... "
if [ ${#data_files[@]} -eq 0 ]; then
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

# Remove folder tmp
rm -r "${tmpdir}"
