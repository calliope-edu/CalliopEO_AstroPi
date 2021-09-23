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

ERRORS=0

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

raspi_model="/sys/firmware/devicetree/base/model"
if [[ -f "${raspi_model}" ]]; then
    echo "  Model: $(tr -d '\0' < ${raspi_model})"
    echo "  $(cat /proc/meminfo | grep MemTotal)"
else
    echo "  Model: unknown"
fi
echo ""

echo "  Check for dependencies:"
needed_progs="lsblk md5sum cmp pip3"
for prog in ${needed_progs}; do
    echo -n "    ${prog}: "
    command -v ${prog} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${G}present${NC}"
    else
	echo -e "${R}not present${NC}"
	ERRORS=$((ERRORS+1))
    fi
done

echo "  Python3 version: $(python3 --version)"

pip3 list > ~/python3_modules.list.tmp
echo "  Installed Python3 modules"
while read line; do
    echo "    ${line}"
done < ~/python3_modules.list.tmp
rm ~/python3_modules.list.tmp
echo ""

# Serial port and getty service config (Github issue #100)
ser_getty="serial-getty@ttyAMA0.service"
rpi_cnf="raspi-config nonint get_serial"
echo "  ${ser_getty} status: $(systemctl is-active ${ser_getty})"
echo "  ${ser_getty} enabled: $(systemctl is-enabled ${ser_getty})"
echo "  /boot/cmdline.txt:"
echo "    $(cat /boot/cmdline.txt)"
echo "  ${rpi_cnf}: $(${rpi_cnf})"
echo "  ${rpi_cnf}_hw: $(${rpi_cnf}_hw)"
echo ""

# Track testcase result
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${BG_G}Testcase passed.${BG_NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${BG_R}Testcase failed.${BG_NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi

