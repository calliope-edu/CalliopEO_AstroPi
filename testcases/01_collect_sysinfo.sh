#!/bin/bash

# Testcase name:
#   01_collect_sysinfo
# Testcase description:
#   This is no real testcase but this script collects some system
#   information

echo "  Hostname: $(cat /etc/hostname)"
echo "  User: ${USER}"
echo "  Working directory: $(pwd)"
echo "  System info: $(uname -a)"
os_release="/etc/os-release"
if [[ -f "${os_release}" ]]; then
    echo "  OS Release:"
    cat ${os_release}
    echo ""
fi

