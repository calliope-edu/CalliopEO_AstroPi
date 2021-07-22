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
#   Hex file 30sec-counter.hex has to be provided
#   Hex file its.garbage.hex has to be provided
#   Data file 30sec-counter.hex.data has to be provided
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

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Provide two ZIP archive, the last one corrupted"
echo "-----------------------------------------------------"
echo ""
# Make sure, Calliope is connected to the Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is attached to USB [y] " ans
done

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
cp "testcases/testfiles/30sec-counter.hex" "${tmpdir}/01.hex"
cp "testcases/testfiles/its.garbage.hex" "${tmpdir}/02.hex"
# Copy Data files to tmp
cp "testcases/testfiles/30sec-counter.hex.data" "${tmpdir}/01.hex.data"
cp "testcases/testfiles/30sec-counter.hex.data" "${tmpdir}/02.hex.data"
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "checksum.md5"
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
fi

# Renamed .zip to .zip.done?
zipfile1_main="01.zip"
zipfile1_done="${zipfile1_main}.done"
echo -n "Check 2/6: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile1_main}" && -e "${zipfile1_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created folder run_*?
echo -n "Check 3/6: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created two .data files in the two folders run_*?
data_files=($(find ./run_* -name "*.data"))
echo -n "Check 4/6: Created two .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
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
    fi
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/checksum.md5" ${run_folder}/.
cd ${run_folder}
echo -n "Check 6/6: MD5 checksum in folder ${run_folder} ... "
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
rm ${zipfile1_done} ${zipfile2_done}

# Remove folder run_*
rm -rf run_*

# Remove folder tmp
rm -r "${tmpdir}"
