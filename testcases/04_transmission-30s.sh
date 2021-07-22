#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a single zip archive nominally transmitting
#   for 30 seconds.
# Preparation
#   Hex file 30sec-counter.hex has to be provided
#   Data file 30sec-counter.hex.data has to be provided
# Expected result
#   CalliopEO.py returns code 0.
#   CalliopEO.py renames 01.zip to 01.zip.done
#   CalliopEO.py created folder run_*
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
echo "Test: Single, nominal ZIP archive provided"
echo "-------------------------------------------"
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

# Ensure variable ${tmpdir} has no trailing /
tmpdir=${tmpdir#/}
# Remove old ${tmdir} if exists
if [ -d ${tmpdir} ]; then
    rm -r ${tmpdir}
fi
mkdir "${tmpdir}"

# Copy Hex files to tmp
cp "testcases/testfiles/30sec-counter.hex" "${tmpdir}/01.hex"
# Copy Data files to tmp
cp "testcases/testfiles/30sec-counter.hex.data" "${tmpdir}/01.hex.data"
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "checksum.md5"
cd ..
# Create zip archives in the main directory
zip -mqj "01.zip" "${tmpdir}/01.hex"

##############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script}
# Save return code
ret_code=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check 1/4: Return code of script is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed 01.zip to 01.zip.done?
zipfile_main="01.zip"
zipfile_done="${zipfile_main}.done"
echo -n "Check 2/4: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile_main}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created folder run_*?
echo -n "Check 3/4: Folder run_* created ... "
if [ $(find . -type d -ipath "./run_*" | wc -l) -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data file
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/checksum.md5" ${run_folder}/.
cd ${run_folder}
echo -n "Check 4/4: MD5 checksum in folder ${run_folder} ... "
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
rm ${zipfile_done}

# Remove folder run_*
rm -rf run_*

# Remove folder tmp
rm -r "${tmpdir}"
