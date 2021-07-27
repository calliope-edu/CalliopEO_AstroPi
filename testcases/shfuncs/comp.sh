#!/bin/bash

comp() {
    fileA=${1}
    fileB=${2}
    threshold=${3}
    tmpfile="./tmp.data"

    # Initilaize return value for this function
    retval=1 # 0: equal, 1: different

    # Count the lines in both files
    linesA=$(cat ${fileA} | wc -l)
    linesB=$(cat ${fileB} | wc -l)

    # Create the realtive difference in number of lines
    reldiff=$(python -c "print(int(abs(float(${linesA}-${linesB})/(${linesA}+${linesB})*100)))")

    # Both files have equal number of lines
    if [ "${linesA}" -eq "${linesB}" ]; then
        cmp -s ${fileA} ${fileB}
        retval=$? # 0: equal, 1: different

    # fileA has less lines than fileB
    elif [[ "${reldiff}" -le "${threshold}" && "${linesA}" -lt "${linesB}" ]]; then
        head -${linesA} ${fileB} > ${tmpfile}
        cmp -s ${fileA} ${tmpfile}
        retval=$? # 0:equal, 1: different

    # fileA has more lines than fileB
    elif [[ "${reldiff}" -le "${threshold}" && "${linesA}" -gt "${linesB}" ]]; then
        head -${linesB} ${fileA} > ${tmpfile}
        cmp -s ${tmpfile} ${fileB}
        retval=$? # 0:equal, 1: different

    fi

    # We don't need ${tmpfile} anymore
    if [ -e ${tmpfile} ]; then
        rm ${tmpfile}
    fi

    echo ${retval}
}

