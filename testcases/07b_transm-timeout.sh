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
datafile1="testcases/testfiles/900sec-counter.hex.data.terminated30s"
max_exec_time=30 # seconds
hexfile2="testcases/testfiles/05sec-counter.hex"
datafile2="testcases/testfiles/05sec-counter.hex.data"
zipfile="01.zip"
md5file="check.md5"
tmpdir="./tmp"

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Continue with next hex after timeout"
echo "------------------------------------------"
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
${cmd_calliope_script} --max-script-execution-time=${max_exec_time} | tee ./output.txt.tmp
# Save return code
ret_code=$?

# Let things settle
sync
sleep 1

###############################################################################
# Check if testcase was successfully
###############################################################################

# Return code of script is 0?
echo -n "Check: Return code is 0 ... "
if [[ ${ret_code} -eq 0 ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Renamed .zip to .zip.done?
zipfile_done="${zipfile}.done"
echo -n "Check: ZIP archive renamed to .done ... "
if [[ ! -e "${zipfile}" && -e "${zipfile_done}" ]]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created one folder run_*?
run_folders=($(find . -type d -ipath "./run_*"))
echo -n "Check: Folder run_* created ... "
if [ ${#run_folders[@]} -eq 1 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Created two .data files in the folder run_*?
data_files=($(ls -1 ./run_*/*.data))
echo -n "Check: Created two .data files ... "
if [ ${#data_files[@]} -eq 2 ]; then
    echo -e "${G}PASSED${NC}"
else
    echo -e "${R}NOT PASSED${NC}"
fi

# Check md5sums for hex and data files
run_folder=$(find . -type d -ipath "./run_*")
mv "${tmpdir}/${md5file}" ${run_folder}/.
cd ${run_folder}
echo -n "Check: MD5 checksum in folder ${run_folder} ... "
md5sum -c "${md5file}" >> /dev/null
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

# Remove temporary file with script output
rm ./output.txt.tmp

# Remove tmp dir
rm -rf "${tmpdir}"