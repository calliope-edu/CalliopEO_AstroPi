#!/bin/bash

###############################################################################
# Variables and definitions for this testcase
###############################################################################
hex_prog="./testfiles/10x_1hz_temp.hex" # prog for this testcase

###############################################################################
# Information and instructions for the test operator
###############################################################################
echo "Test: Nominal, three hex files with data output"
echo "-----------------------------------------------"
echo ""
# Make sure, Calliope is attached to Astro Pi
ans=""
while [[ ! ${ans} =~ [Yy] ]]; do
    read -p "Confirm, Calliope Mini is attached to USB [y] " ans
done

# make sure, working diretcory is clean and contains no sub directories
# "run_*" from previous runs
while [[ $(find . -maxdepth 1 -type d -name "run_*" | wc -l) -ne 0 ]]; do
    read -p "Delete/move away all directories \"run_\" from $(pwd) [y] " ans
done

###############################################################################
# Preparations for the testcase
###############################################################################

# Copy the Calliope Mini program for this testfile (defined above) to the
# folder, where the CalliopEO.py script is located. Do this three times
for n in {1..3}; do
    cp ${hex_prog} ./${n}_$(basename ${hex_prog})
done
# ZIP all the hex files created above
for file in *.hex; do
    zip ${file%.hex}.zip ${file}
done

###############################################################################
# Execute testcase
###############################################################################

# Execute the CalliopEO.py script
${cmd_calliope_script} || {
    echo "ERROR: Cannot execute ${cmd_calliope_script}. Exiting"
    exit 1
}

###############################################################################
# Check if testcase was successfully
###############################################################################

# Initialize variable
tc_passed=1

# Diretcory "run_*" created?
echo -n "Check: Output directory \"run_*\" created ... "
if [[ $(find . -maxdepth 1 -type d -name "run_*" | wc -l) -ne 1 ]]; then
    echo "NOT PASSED"
    tc_passed=0
else
    echo "PASSED"
fi

# Directory contains three hex file?
echo -n "Check: Output diretcory \"run_*\" contains three .hex file ... "
if [[ $(find ./run* -type f -name "*.hex" | wc -l) -ne 3 ]]; then
    echo "NOT PASSED"
    tc_passed=0
else
    echo "PASSED"
fi

# Directory contains three data file?
echo -n "Check: Output diretcory \"run_*\" contains three .data file ... "
if [[ $(find ./run* -type f -name "*.data" | wc -l) -ne 3 ]]; then
    echo "NOT PASSED"
    tc_passed=0
else
    echo "PASSED"
fi

###############################################################################
# Cleaning up
###############################################################################

rm *.done
rm *.hex
rm -rf run_*
