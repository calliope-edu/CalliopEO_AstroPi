#!/bin/bash

###############################################################################
# Testcase Description
###############################################################################

# Description
#   This is no real testcase but this script collects some system
#   information
# Preparation
#   Nothing to prepare.
# Expected result
#   Collects and outputs system information for the test log file.
# Necessary clean-up
#   Nothing to clean up

echo "  Hostname: $(cat /etc/hostname)"
echo "  User: ${USER}"
echo "  Group membership: $(groups)"
echo "  Working directory: $(pwd)"
echo "  System info: $(uname -a)"
os_release="/etc/os-release"
if [[ -f "${os_release}" ]]; then
    echo "  OS Release:"
    while read line; do
        echo "    ${line}"
    done < ${os_release}
    echo ""
fi
echo "  Python3 version: $(python3 --version)"
pip3 list > ~/python3_modules.list.tmp
echo "  Installed Python3 modules"
while read line; do
    echo "    ${line}"
done < ~/python3_modules.list.tmp
rm ~/python3_modules.list.tmp

