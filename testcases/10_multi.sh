#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with two zip archives. One nominally transmitting
#   for 5 seconds. One containing two nominally files.
# Preparation
#   Hex file 05sec-counter.hex has to be provided
#   Data file 05sec-counter.hex.data has to be provided
# Expected result
#   CalliopEO.py returns code 0.
#   CalliopEO.py renames 01.zip and 02.zip to 01.zip.done and 02.zip.done
#   CalliopEO.py created folder run_*
#   Folder run_* contains three .data files
#   MD5 checksums of files in run_* match
# Necessary clean-up
#   Remove created *.done and folder run_*/ and folder tmp/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
tmpdir="./tmp"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo -e "Test: Multi, provice two Zip containing three Hex"
echo -e "-------------------------------------------"
echo -e ""
# Make sure, Calliope is connected to the Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is attached to USB [y] " ans
done

##############################################################################
# Exit script, if there is a ZIP archive or folder run_* in the main folder
##############################################################################
if [ $(find . -maxdepth 1 -iname *.zip | wc -l) -ne 0 ]; then
    echo -e "${R}ERROR: ${NC}Main folder contains zip archive. Exiting."
    exit 1
fi
if [ $(find . -type d -ipath "./run_*" | wc -l) -ne 0 ]; then
    echo -e "${R}ERROR: ${NC}Main folder contains folder run_*. Exiting."
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
cp "testcases/testfiles/05sec-counter.hex" "${tmpdir}/01.hex"
cp "testcases/testfiles/05sec-counter.hex" "${tmpdir}/02.hex"
cp "testcases/testfiles/05sec-counter.hex" "${tmpdir}/03.hex"
# Copy Data files to tmp
cp "testcases/testfiles/05sec-counter.hex.data" "${tmpdir}/01.hex.data"
cp "testcases/testfiles/05sec-counter.hex.data" "${tmpdir}/02.hex.data"
cp "testcases/testfiles/05sec-counter.hex.data" "${tmpdir}/03.hex.data"
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "checksum.md5"
cd ..
# Create zip archives in the main directory
zip -mqj "01.zip" "${tmpdir}/01.hex" "${tmpdir}/02.hex"
zip -mqj "02.zip" "${tmpdir}/03.hex"

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script} --fake-timestamp
# Save return code
ret_code=$?

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/5: Return code of script is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed 05sec-counter.zip to 05sec-counter.done?
zipfile1_main="01.zip"
zipfile1_done="${zipfile1_main}.done"
zipfile2_main="02.zip"
zipfile2_done="${zipfile2_main}.done"
echo -n "Check 2/5: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile1_main}" && -e "${zipfile1_done}" && ! -e "${zipfile2_main}" && -e "${zipfile2_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created folder run_*?
echo -n "Check 3/5: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created three .data files in the folder run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check 4/5: Created three .data files ... "
if [ ${#data_files[@]} -eq 3 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/checksum.md5" ${run_folder}/.
cd ${run_folder}
echo -n "Check 5/5: MD5 checksum in folder ${run_folder} ... "
md5sum -c "checksum.md5" >> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi
cd ..

###############################################################################
# Cleaning up
###############################################################################

# Remove .done file
rm ${zipfile1_done}
rm ${zipfile2_done}

# Remove folder run_*
rm -rf run_*

# Remove folder tmp
rm -r "${tmpdir}"
