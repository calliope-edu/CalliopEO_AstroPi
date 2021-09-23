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
# SERIAL_TIMEOUT and MAX_SERIAL_WAIT_REPLY are different! SERIAL_TIMEOUT is
# the timeout defined for operations performed on the pySerial object.
# MAX_SERIAL_WAIT_REPLY is the maximum time in seconds to wait for a propper
# reply on the serial port after sending the start identifier SERIAL_START.
# SERIAL_TIMEOUT << MAX_SERIAL_WAIT_REPLY
SERIAL_TIMEOUT = 1 # s
MAX_SERIAL_WAIT_REPLY = 10 # Max time in s to wait for answer
MAX_RETRY_FLASHING = 3 # Max. number to retry flashing if no serial data
MAX_CONNECTION_TIME = 11100 # s
MAX_DATA_SIZE = 20 * 1024 * 1024 # Bytes

MAX_LINE_LENGTH = 1000 # Crop lines that are longer

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
        # Flush incoming buffer of serial port as a preventive measure
        # (see issue #74)
        ser.reset_input_buffer()
        mini_connected = True
    except Exception as Err:
        print("Error connecting serial port: %s" % Err)

    if mini_connected:
        return ser
    else:
        return None

# Listens to serial port, sends SERIAL_START and waits for response and
# data. Writes data with timestamps to file. Ends if timeout is reached,
# maximum size of data is written to file or SERIAL_END is received.
def readSerialData(ser, outFileName, fake_timestamp=False):

    # Initialize buffer for serial data
    serial_buffer = ''

    # Determine start/stop time for connection
    connStartTime = datetime.now()
    connEndTime = (connStartTime
            + timedelta(seconds=MAX_CONNECTION_TIME))
    connTimeoutNoResponse = (connStartTime
            + timedelta(seconds=MAX_SERIAL_WAIT_REPLY))

    # Write info to STDOUT
    tformat="%Y/%m/%d-%H:%M:%S"
    print("\r\n"
            + "Start @ "
            + connStartTime.strftime(tformat)
            + "; Will stop @ "
            + connEndTime.strftime(tformat)
            )

    # connTimeout can happen for two reasons:
    #   1. Still receivedStart == False after MAX_SERIAL_WAIT_REPLY
    #   2. receivedStart == True and serial connection established for
    #      longer than connEndTime
    connTimeout = False
    receivedStart = False
    # Variable dataSize is updated with the data in bytes written to outfile.
    # If dataSize exceeds MAX_DATA_SIZE no more data is written to file and
    # the function is exited.
    dataSize = 0

    # Main while loop
    while (connTimeout == False):

        # If receivedStart == False send SERIAL_START
        if (receivedStart == False):
            print("\r\n" + "Sending " + SERIAL_START)
            ser.write((SERIAL_START + '\r\n').encode(DEFAULT_ENCODING))
            time.sleep(1)

        # Append incoming data from serial port to serial_buffer
        if ser.in_waiting > 0:
            try:
                incoming = ser.read(ser.in_waiting).decode(DEFAULT_ENCODING)
            except:
                incoming = ''

            serial_buffer += incoming

            # Check if serial_buffer contains newline character. If so,
            # extract the first line for further processing. The function
            # .split('\n', 1) returns a list with one element if
            # serial_buffer contains no newline character and a list with 2
            # elements if there are newline characters.
            buffer_split = serial_buffer.split('\n', 1)

            # If serial_buffer contains no newline but the length exceeds
            # MAX_LINE_LENGTH, than extract MAX_LINE_LENGTH from
            # serial_buffer.
            if (len(buffer_split) == 1 and len(serial_buffer) >
                MAX_LINE_LENGTH):
                buffer_split = [
                    serial_buffer[:MAX_LINE_LENGTH],
                    serial_buffer[MAX_LINE_LENGTH:],
                    ]

            if (len(buffer_split) == 2):
                # This is the current line. The line does not end with
                # newline
                line = buffer_split[0].strip()

                # If receivedStart == False check if the current line
                # contains SERIAL_START and update receivedStart if
                # necessary
                if (receivedStart == False):
                    # If receivedStart == False and line contains
                    # SERIAL_START than set receivedStart to True and do
                    # nothing else with line
                    if (SERIAL_START in line):
                        print("\r\n" + "Received " + SERIAL_START)
                        receivedStart = True
                else:
                # receivedStart == True: Process line normally
                    print("*",end="",flush=True)

                    # If line contains SERIAL_END we exit the while loop
                    if (SERIAL_END in line):
                        break

                    # Add time stamp to beginning of line (Github issue #45).
                    # If --fake-timestamp is set, then set the time stamp to
                    # constant value 2000/01/01-00:00:00.000000
                    if (fake_timestamp == True):
                        ts = "2000/01/01-00:00:00.000000"
                    else:
                        ts = datetime.now().strftime("%Y/%m/%d-%H:%M:%S.%f")
                    line = ts + " " + line

                    # Output to file if updated dataSize plus length of lines
                    # plus 1 (for newline) do not exceed MAX_DATA_SIZE
                    if ((dataSize + len(line) + 1) <= MAX_DATA_SIZE):
                        write2File(outFileName, line+'\n')
                        dataSize += (len(line) + 1)
                    else:
                        # Exit while loop
                        print("\r\n" + "Max file size achieved")
                        break

                # Update serial_buffer
                serial_buffer = buffer_split[1]

        # Check time and update connTimeout if necessary
        now = datetime.now()
        # See if receivedStart == False and we are behind
        # connTimeoutNoResponse
        if (receivedStart == False and now > connTimeoutNoResponse):
            connTimeout = True
        # See if we are behind connEndTime
        if (receivedStart == True and now > connEndTime):
            print("\r\n" + "Max script time achieved")
            connTimeout = True

    return dataSize

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

def write2File(outFileName, string):
    # Open file in append mode
    outfile = open(outFileName,"a")
    # Write strings, NOT lines! Care yourself for newlines!
    outfile.write(string)
    outfile.close()

###################################################

def main(args):
    print("-=# CalliopEO #=-")

    # If CLI paramater --max-data-size or --max-script-execution-time
    # are set, update the global variables
    if args.max_data_size > 0:
        global MAX_DATA_SIZE
        MAX_DATA_SIZE = args.max_data_size
    if args.max_script_execution_time > 0:
        global MAX_CONNECTION_TIME
        MAX_CONNECTION_TIME = args.max_script_execution_time

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
        count_try_flashing  = 1 # Max: MAX_RETRY_FLASHING
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
            outFileName = hex + '.data'
            dataSize = readSerialData(ser, outFileName, args.fake_timestamp)

            if dataSize == 0:
                if count_try_flashing >= MAX_RETRY_FLASHING:
                    #give up
                    break
                else:
                    #repeat programming
                    count_try_flashing += 1
                    print(
                            "\r\nSomething went wrong. Retrying flashing ("
                            + str(count_try_flashing)
                            + "/"
                            + str(MAX_RETRY_FLASHING)
                            + ")"
                            )
                    continue
            else:
                print("\r\ndone")
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
    parser.add_argument(
            '--fake-timestamp',
            action = 'store_true',
            dest = 'fake_timestamp',
            help = """
            Set timestamp in output to constant value
            2000/01/01-00:00:00.000000
            """,
            )
    args = parser.parse_args()
    main(args)
