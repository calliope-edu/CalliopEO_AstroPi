#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with two zip archives. The first contains a
#   valid hex file, the second one contains a corrupted hex file. In the
#   latter case, the Calliope Mini will execute the previous valid hex
#   file.
# Preparation
#   Hex file 05sec-counter.hex has to be provided
#   Hex file its.garbage.hex has to be provided
#   Data file 05sec-counter.hex.data has to be provided
# Expected result
#   CalliopEO.py returns code 0 in both runs with the two zip arhives.
#   CalliopEO.py renames *.zip to *.zip.done
#   CalliopEO.py creates two folders run_*
#   CalliopEO.py cretaed two .data files in the two folders run_*
#   The two .data files in the folders run_* have the same content
# Necessary clean-up
#   Remove created *.done and folder run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
tmpdir="./tmp"
hexfile1="05sec-counter.hex"
hexfile2="its.garbage.hex"
datafile1="05sec-counter.hex.data"
checksumfile="checksum.md5"
ERRORS=0

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Provide two ZIP archive, the last one corrupted"
echo "-----------------------------------------------------"
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

##############################################################################
# Execute testcase
###############################################################################

# 1. Create Zip file with nominal hex file
# Ensure variable ${tmpdir} has no trailing /
tmpdir=${tmpdir#/}
# Remove old ${tmdir} if exists
if [ -d ${tmpdir} ]; then
    rm -r ${tmpdir}
fi
mkdir "${tmpdir}"

# Copy Hex files to tmp
cp "testcases/testfiles/${hexfile1}" "${tmpdir}/01.hex"
cp "testcases/testfiles/${hexfile2}" "${tmpdir}/02.hex"
# Copy Data files to tmp
cp "testcases/testfiles/${datafile1}" "${tmpdir}/01.hex.data"
cp "testcases/testfiles/${datafile1}" "${tmpdir}/02.hex.data"
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "${checksumfile}"
cd ..
# Create zip archives in the main directory
zip -mqj "01.zip" "${tmpdir}/01.hex" "${tmpdir}/02.hex"

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
echo -n "Check 1/6: Return code of script is 0 ... "
if [[ ${ret_code1} -eq 0 &&  ${ret_code2} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Renamed .zip to .zip.done?
zipfile1_main="01.zip"
zipfile1_done="${zipfile1_main}.done"
echo -n "Check 2/6: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile1_main}" && -e "${zipfile1_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Created folder run_*?
echo -n "Check 3/6: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
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

# The two .data files have same content?
# Use command cmp to compare the files
echo -n "Check 5/6: The two .data files have same content ... "
if [ ${#data_files[@]} -eq 2 ]; then
    cmp --silent ${data_files[@]}
    if [ $? -eq 0 ]; then
        echo -e "${G}PASSED${NC}"
    else
        echo -e "${R}NOT PASSED${NC}"
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "${R}NOT PASSED${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${checksumfile}" ${run_folder}/.
cd ${run_folder}
echo -n "Check 6/6: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${checksumfile}" >> /dev/null
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
rm ${zipfile1_done} ${zipfile2_done}

# Remove folder run_*
rm -rf run_*

# Remove folder tmp
rm -r "${tmpdir}"
