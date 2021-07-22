#!/usr/bin/env python3

import os
import shutil
from datetime import datetime, timedelta
import sys
import serial
import serial.tools.list_ports
import time
import blkinfo
import re
import argparse

blk = blkinfo.BlkDiskInfo()

TEMP_MOUNT_MINI = "~/mnt/mini"
TEMP_MOUNT_FLASH = "~/mnt/flash"

# Expand mount path if they contain tilde
TEMP_MOUNT_MINI = os.path.expanduser(TEMP_MOUNT_MINI)
TEMP_MOUNT_FLASH = os.path.expanduser(TEMP_MOUNT_FLASH)

MODEL_MINI_REGEXP = 'SEGGER[-_ ]{1}MSD[-_ ]{1}Volume'
MODEL_FLASH_REGEXP = 'SEGGER[-_ ]{1}MSD[-_ ]{1}FLASH'

# Compile regexp match pattern objects
MODEL_MINI_MPO = re.compile(MODEL_MINI_REGEXP, re.IGNORECASE)
MODEL_FLASH_MPO = re.compile(MODEL_FLASH_REGEXP, re.IGNORECASE)

MSG_MINI_NOT_FOUND = "mini not found"
MSG_FLASH_NOT_FOUND = "flash not found"
#MSG_MINI_NO_SERIAL = "no serial connection found"

CMD_MOUNT = "mount %s"
CMD_UNMOUNT = "umount %s"
CMD_SYNC = "sync %s"

#define the archive ending you want to search for
archive_ending = ".zip"

DEFAULT_ENCODING = "utf-8"
MINI_SERIAL_REGEXP = "(/dev/tty[\w]+)[ -]+Calliope mini[ -]+CDC"
MINI_SERIAL_MPO = re.compile(MINI_SERIAL_REGEXP, re.IGNORECASE)
SERIAL_START = "@START@"
SERIAL_END = "@END@"
SERIAL_TIMEOUT = 1 # s
REPEAT_START_SERIAL = 20 # n times SERIAL_TIMEOUT
MAX_SCRIPT_EXECUTION_TIME = 11100 # s
MAX_DATA_SIZE = 20 * 1024 * 1024 # Bytes

# Returns the port for the (first) Calliope mini or None
def getMiniSerial():
    # Retrieve a list of serial ports
    # The serial port for Calliope Mini is typically
    # identified via "/dev/ttyACM0 - Calliope Mini - CDC"
    all_ports = serial.tools.list_ports.comports()

    # Iterate through all serial ports and return the first port
    # found where a Calliope Mini is attached to
    mini_port = None # Initialize
    for p in all_ports:
        m = re.match(MINI_SERIAL_MPO, str(p))
        if m is not None:
            mini_port = m.group(1)
            break

    return mini_port

# Connect to serial port and return pySerial instance. If connection
# is not successful, returns None
def serialConnect(mini_port):
    # Create pySerial instance with all the necessary parameters but
    # with port = None. This way, the port is not opened immediately
    ser = serial.Serial(
        port = None,
        baudrate = 115200,
        bytesize = serial.EIGHTBITS,
        parity = serial.PARITY_NONE,
        stopbits = serial.STOPBITS_ONE,
        timeout = SERIAL_TIMEOUT)

    # try to connect
    try:
        ser.port = mini_port
        if not ser.is_open:
            ser.open()
        mini_connected = True
    except Exception as Err:
        print("Error connecting serial port: %s" % Err)

    if mini_connected:
        return ser
    else:
        return None

def safe_decode(bytes, encoding=DEFAULT_ENCODING):
    try:
        return bytes.decode(encoding).strip()
    except:
        return ""

#waits for SERIAL_START
#if a timeout is reached the return value is False
def waitSerialStart(ser):
    serialTime = time.time()
    line = ""
    for x in range(REPEAT_START_SERIAL):
        print("\r\n" + "Send " + SERIAL_START)
        ser.write(b'@START@\r\n')
        while True:
            line = safe_decode(ser.readline())
            if SERIAL_START in line:
                print("\r\n" + "Received " + SERIAL_START)
                return True
            elif (time.time() - serialTime) > SERIAL_TIMEOUT:
                break
    return False

#reads the data received from mini ans returns it
#if SERIAL_END is received True is returnes indicating the end
def readSerialUntilEnd(ser):
    line = ""
    while True:
        line = safe_decode(ser.readline())
        if SERIAL_END in line:
            return True
        else:
            return line

#waits for SERIAL_START and collects the data received from mini until SERIAL_END is received
#if a timeout is received the return value is False
def readSerialData(ser):
    lines = []
    #ans = waitSerialStart(ser)
    scriptStartTime = datetime.now()
    scriptEndTime = (scriptStartTime
            + timedelta(seconds=MAX_SCRIPT_EXECUTION_TIME))
    tformat="%Y/%m/%d-%H:%M:%S"
    print("\r\n"
            + "Start @ "
            + scriptStartTime.strftime(tformat)
            + "; Will stop @ "
            + scriptEndTime.strftime(tformat)
            )
    # Received @START@?
    if waitSerialStart(ser) == True:
        while True:
            ans = readSerialUntilEnd(ser)
            # Received @END@?
            if ans == True:
                print("\r\n" + str(len(lines)) + " lines read")
                return lines
            else:
                if ans != "":
                    # Add time stamp to beginning of line (Github issue #45)
                    ts = datetime.now().strftime("%Y/%m/%d-%H:%M:%S.%f ")
                    ans = ts + ans

                    # Append the new line only if this will not exceed
                    # the threshold MAX_DATA_SIZE
                    if (
                            charInLines(lines)
                            + len(ans)
                            + 1 # The newline character char of last line
                            ) <= MAX_DATA_SIZE:
                        lines.append(ans)
                        print("*",end="",flush=True)
                    else:
                        print("\r\n" + "Max file size achieved")
                        print("\r\n" + str(len(lines)) + " lines read")
                        return lines
                if (datetime.now() > scriptEndTime):
                    print("\r\n" + "Max script time achieved")
                    print("\r\n" + str(len(lines)) + " lines read")
                    return lines
    else:
        return False

# Count the total number of characters for all lines
def charInLines(lines):
    chars = 0
    for line in lines:
        # Add one character for the newline at the end of each line
        chars += len(line) + 1
    return chars

def listFolders(path):
    temp_list = []
    for folder in os.listdir(path):
        if os.path.isdir(os.path.join(path, folder)):
            temp_list.append(os.path.join(path, folder))
    return temp_list

#unpacks given archives in a folder and returns the foldername
def unpackArchives(archive_list, destname=None):
    if(destname == None):
        archive_folder = os.path.join(
                os.getcwd(),
                datetime.now().strftime("run_%Y%m%d-%H%M%S")
                )
    else:
        archive_folder = os.path.join(os.getcwd(),destname)

    # Create empty archive_folder
    os.mkdir(archive_folder)

    for file in archive_list:
        try:
             shutil.unpack_archive(file, archive_folder)
             shutil.move(file, file + ".done")
             print("Unpacked " + file)
        except Exception as Err:
            shutil.move(file, file + ".failed")
            print("Error while unpacking " + file + ": %s" % Err)
            # Wait a second. Otherwise the folder run_YYYYMMDD-HHMMSS
            # for the next zip archive can have the time stamp which
            # would result in trying to create the same diretory which
            # in the end will cause the script to fail (Github issue #34).
            time.sleep(1)

    return archive_folder

#list files in this path filtered by ending and recurse if desired
def listFiles(path, ending=None, recurse=False):
    temp_list = []
    for file in os.listdir(path):
        if os.path.isfile(os.path.join(path,file)):
            if ending == None:
                temp_list.append(os.path.join(path,file))
            else:
                if file.endswith(ending):
                    temp_list.append(os.path.join(path,file))
        else:
            if recurse and os.path.isdir(os.path.join(path,file)):
                temp_list.extend(listFiles(os.path.join(path,file), ending))
    return sorted(temp_list)

def getMiniDisk():
    MINI_DEVICE = ""
    disks = blk.get_disks()
    for disk in disks:
        if MODEL_MINI_MPO.match(disk['model']) is not None:
            return True
    return False

def getFlashDisk():
    FLASH_DEVICE = ""
    disks = blk.get_disks()
    for disk in disks:
        if MODEL_FLASH_MPO.match(disk['model']) is not None:
            return True
    return False

#programm mini
def programmMini(hex):
    #mount mini disk
    os.system(CMD_MOUNT % (TEMP_MOUNT_MINI))
    #programm mini
    shutil.copy2(hex, TEMP_MOUNT_MINI)
    os.system(CMD_SYNC % TEMP_MOUNT_MINI)
    os.system(CMD_UNMOUNT % TEMP_MOUNT_MINI)

def writeToFile(hex, data):
    file = open(hex+".data","w")
    for line in data:
        file.write(line + "\n")
    file.close()

###################################################

def main(args):
    print("-=# CalliopEO #=-")

    # If CLI paramater --max-data-size or --max-script-execution-time
    # are set, update the global variables
    if args.max_data_size > 0:
        global MAX_DATA_SIZE
        MAX_DATA_SIZE = args.max_data_size
    if args.max_script_execution_time > 0:
        global MAX_SCRIPT_EXECUTION_TIME
        MAX_SCRIPT_EXECUTION_TIME = args.max_script_execution_time

    #check mini disk
    if not getMiniDisk():
        print(MSG_MINI_NOT_FOUND)
        sys.exit(10)
    #check flash disk
    if not getFlashDisk():
        print(MSG_MINI_NOT_FOUND)
        sys.exit(11)
    #make mini mount dir
    if not os.path.exists(TEMP_MOUNT_MINI):
        os.mkdir(TEMP_MOUNT_MINI)
    #make flash mount dir
    if not os.path.exists(TEMP_MOUNT_FLASH):
        os.mkdir(TEMP_MOUNT_FLASH)

    #get archives
    archive_file_list = listFiles(os.getcwd(), ending=archive_ending)
    if len(archive_file_list) == 0:
        print("no archives found in this directory")
        print("make sure you have at least one archive in this directory")
        sys.exit(12)
    #unpack archives to a folder named with current date and time
    folder_name = unpackArchives(archive_file_list)
    #recursively search for .hex files
    hex_files = listFiles(folder_name, ending=".hex" ,recurse=True)
    print("\r\n")

    for hex in hex_files:
        if os.path.exists(hex + ".data"):
            print("skipping: " + hex)
            continue
        tries  = 1
        while True:
            print("programming: " + hex)
            programmMini(hex)
            print("done")

            # After programming the Calliope Mini reboots. The serial ports
            # shows up quite soon. But it takes some time (~ 15 seconds) before
            # a read/write operation is possible, even if the Calliope Mini
            # accepted a connect (ser.open()).
            print("open serial port")
            ser = None
            mini_connected = False
            no_tries = 0
            while (not mini_connected and no_tries < 20):
                mini_port = getMiniSerial()
                if mini_port is not None:
                    print("Calliope Mini found on", mini_port, " ", end="", flush=True)
                    # Wait to give the Calliope Mini some time before
                    # connect. When conecting too early, the first read/write
                    # access will result in an I/O error.
                    for w in range(10):
                        print(".", end="", flush=True)
                        time.sleep(1)
                    ser = serialConnect(mini_port)
                    mini_connected = True
                else:
                    # Retry to connect after one second
                    no_tries += 1
                    time.sleep(1)

            print("\r\ndone")

            # If ser is still None at this point, connection to Calliope cannot
            # be established after flashing. Something serious might have
            # happend. Exit the script.
            if ser is None:
                print("\r\nCannot establish serial conection to Calliope Mini. Exiting.")
                sys.exit(13)

            print("reading data")
            data = readSerialData(ser)

            if data == False:
                print("Something went wrong retrying: " + str( tries ) + "/5")
                tries = tries + 1
                if tries > 5:
                    #give up
                    break
                else:
                    #repeat programming
                    continue
            else:
                writeToFile(hex, data)
                print("done")
                print("############################################################################################################\r\n")
                break

# Exit status
# 0     normally
# 10    could not find mini disk (Calliope mini not attached)
# 11    could not find flash disk (Calliope mini not attached)
# 12    no archives in diretory
# 13    could not establish serial connection
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--max-data-size',
            default = 0,
            dest = 'max_data_size',
            type=int,
            )
    parser.add_argument(
            '--max-script-execution-time',
            default = 0,
            dest = 'max_script_execution_time',
            type=int,
            )
    args = parser.parse_args()
    main(args)
