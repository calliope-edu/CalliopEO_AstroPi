#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   Execute the CalliopEO.py with a corrupted zip archive. The corrupted zip
#   file is renamed to .zip.failed and the corresponding run_* folder is
#   empty.
# Preparation
#   Provide zip archive not.a.zip.
# Expected result
#   CalliopEO.py returns code 0
#   CalliopEO.py renames the corrupted .zip to .zip.failed
#   The folder run_* is empty
# Necessary clean-up
#   Remove created *.failed and folder run_*/

###############################################################################
# Variables and definitions for this testcase
###############################################################################
corruptedzip="testcases/testfiles/not.a.zip"
zipfile1="01.zip"
zipfile2="02.zip"
zipfile2="02.zip"
hexfile="05sec-counter.hex"
datafile="05sec-counter.hex.data"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Provide three ZIP archive, the 2nd corrupted"
echo "--------------------------------------------------"
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
cp corruptedzip ./${zipfile2}

# Copy Hex files to tmp
cp "testcases/testfiles/${hexfile}" "${tmpdir}/01.hex"
cp "testcases/testfiles/${hexfile}" "${tmpdir}/02.hex"
# Copy Data files to tmp
cp "testcases/testfiles/${datafile}" "${tmpdir}/01.hex.data"
cp "testcases/testfiles/${datafile}" "${tmpdir}/02.hex.data"
# Create MD5 for copyed fies
cd "${tmpdir}"
find  -type f \( -name "*.hex" -o -name "*.hex.data" \) -exec md5sum "{}" + > "${checksumfile}"
cd ..
# Create zip archives in the main directory
zip -mqj "${zipfile1}" "${tmpdir}/01.hex"
zip -mqj "${zipfile3}" "${tmpdir}/02.hex"

##############################################################################
# Execute testcase
###############################################################################

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
echo -n "Check 1/5: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed .zip to .zip.done or zip.failed?
zipfile1_done="${zipfile1}.done"
zipfile2_failed="${zipfile2}.failed"
zipfile3_done="${zipfile3}.done"
echo -n "Check 2/5: ZIP archive renamed to .failed ... "
if [[ ! -e "${zipfile1}" && -e "${zipfile1_done}" && ! -e "${zipfile2}" && -e "${zipfile2_failed}" && ! -e "${zipfile3}" && -e "${zipfile3_done}" ]]; then
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

# Created two .data files in the folder run_*?
data_files=($(ls -1 ./run_*/*.data))
echo -n "Check 4/5: Created two .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data file
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${checksumfile}" ${run_folder}/.
cd ${run_folder}
echo -n "Check 5/5: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${checksumfile}" >> /dev/null
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
rm ${zipfile_failed}

# Remove folder run_*
rm -rf run_*

