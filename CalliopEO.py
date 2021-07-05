import os
import shutil
import datetime
import glob
import sys
import serial
import time
import blkinfo
import re

blk = blkinfo.BlkDiskInfo()

TEMP_MOUNT_MINI = "~/mnt/mini"
TEMP_MOUNT_FLASH = "~/mnt/flash"

# Expand mount path if they contain tilde
TEMP_MOUNT_MINI = os.path.expanduser(TEMP_MOUNT_MINI)
TEMP_MOUNT_FLASH = os.path.expanduser(TEMP_MOUNT_FLASH)

#MODEL_MINI_VALUE = "SEGGER MSD Volume"
MODEL_MINI_REGEXP = 'SEGGER[-_ ]{1}MSD[-_ ]{1}Volume'
#MODEL_FLASH_VALUE = "SEGGER MSD FLASH"
MODEL_FLASH_REGEXP = 'SEGGER[-_ ]{1}MSD[-_ ]{1}FLASH'

# Compile regexp match pattern objects
MPO_MINI = re.compile(MODEL_MINI_REGEXP, re.IGNORECASE)
MPO_FLASH = re.compile(MODEL_FLASH_REGEXP, re.IGNORECASE)

MSG_MINI_NOT_FOUND = "mini not found"
MSG_FLASH_NOT_FOUND = "flash not found"
MSG_MINI_NO_SERIAL = "no serial connection found"

#CMD_MOUNT = "mount -t vfat %s %s"
CMD_MOUNT = "mount %s"
CMD_UNMOUNT = "umount %s"
CMD_SYNC = "sync %s"

#define the archive ending you want to search for
archive_ending = ".zip"

DEFAULT_ENCODING = "utf-8"
SERIAL_START = "@START@"
SERIAL_END = "@END@"
SERIAL_TIMEOUT = 1 # s
REPEAT_START_SERIAL = 20 # n times SERIAL_TIMEOUT
MAX_SCRIPT_EXECUTION_TIME = 11100 # s
MAX_DATA_SIZE = 20 # MB

def getMiniSerial():
    devices = glob.glob("/dev/ttyACM*")
    if  len(devices) > 0:
        return devices[0]  # should only every be one
    else:
        return None

ser = serial.Serial(
    port=getMiniSerial(),
    baudrate=115200,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=10)

def serialConnect():
    port = getMiniSerial()
    #if ser.getPort() != port:
    if ser.port != port:
        ser.close()
        ser.port=port
        ser.baudrate=115200
        ser.bytesize=serial.EIGHTBITS
        ser.parity=serial.PARITY_NONE
        ser.stopbits=serial.STOPBITS_ONE
        ser.timeout=10
        ser.open()
        return True

def safe_decode(bytes, encoding=DEFAULT_ENCODING):
    try:
        return bytes.decode(encoding).strip()
    except:
        return ""

#waits for SERIAL_START
#if a timeout is reached the return value is False
def waitSerialStart():
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
def readSerialUntilEnd():
    line = ""
    while True:
        line = safe_decode(ser.readline())
        if SERIAL_END in line:
            return True
        else:
            return line

#waits for SERIAL_START and collects the data received from mini until SERIAL_END is received
#if a timeout is received the return value is False
def readSerialData():
    lines = []
    ans = waitSerialStart()
    scriptStartTime = time.time()
    scriptEndTime = scriptStartTime + MAX_SCRIPT_EXECUTION_TIME
    print("\r\n" + "Start @ " + str(scriptStartTime) + "; Will stop @ " + str(scriptEndTime) )
    if ans == True:
        while True:
            ans = readSerialUntilEnd()
            if ans == True:
                print("\r\n" + str(len(lines)) + " lines read")
                return lines
            else:
                lines.append(ans)
                print("*",end="",flush=True)
                if len(lines) > ((MAX_DATA_SIZE * 1024 * 1024) / 17):
                    print("\r\n" + "Max file Size archieved")
                    print("\r\n" + str(len(lines)) + " lines read")
                    return lines
                if (time.time() > scriptEndTime):
                    print("\r\n" + "Max script time archived")
                    print("\r\n" + str(len(lines)) + " lines read")
                    return lines
    elif ans == False:
        return False

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
                datetime.datetime.now().strftime("run_%d%m%y-%H%M")
                )
    else:
        archive_folder = os.path.join(os.getcwd(),destname)

    for file in archive_list:
        shutil.unpack_archive(file, archive_folder)
        shutil.move(file, file + ".done")
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
    return temp_list

def getMiniDisk():
    MINI_DEVICE = ""
    disks = blk.get_disks()
    for disk in disks:
        #print(disk['model'])
        #if disk['model'] == MODEL_MINI_VALUE:
        if MPO_MINI.match(disk['model']) is not None:
            #MINI_DEVICE = "/dev/" + disk['name']
            #return MINI_DEVICE
            return True
    #return None
    return False

def getFlashDisk():
    FLASH_DEVICE = ""
    disks = blk.get_disks()
    for disk in disks:
        #if disk['model'] == MODEL_FLASH_VALUE:
        if MPO_FLASH.match(disk['model']) is not None:
            #FLASH_DEVICE = "/dev/" + disk['name']
            #return FLASH_DEVICE
            return True
    #return None
    return False

#programm mini
def programmMini(hex):
    #mount mini disk
    #os.system(CMD_MOUNT % (getMiniDisk(), TEMP_MOUNT_MINI))
    os.system(CMD_MOUNT % (TEMP_MOUNT_MINI))
    #programm mini
    shutil.copy2(hex, TEMP_MOUNT_MINI)
    os.system(CMD_SYNC % TEMP_MOUNT_MINI)
    os.system(CMD_UNMOUNT % TEMP_MOUNT_MINI)
    #wait for mini disconect and reconnect
    #time.sleep(20)
    #connect to serial
    DEVICE_CONNECTED = False
    while not DEVICE_CONNECTED:
        try:
            DEVICE_CONNECTED = serialConnect()
        except Exception:
            DEVICE_CONNECTED = False
            time.sleep(1)
    

def writeToFile(hex, data):
    file = open(hex+".data","w")
    for line in data:
        file.write(line+"\r\n")
    file.close()

###################################################

def main():
    #check mini disk
    #if getMiniDisk() == None:
    if not getMiniDisk():
        print(MSG_MINI_NOT_FOUND)
        sys.exit(0)
    #check flash disk
    #if getFlashDisk() == None:
    if not getFlashDisk():
        print(MSG_MINI_NOT_FOUND)
        sys.exit(0)
    #check serial
    if getMiniSerial() == None:
        print(MSG_MINI_NO_SERIAL)
        sys.exit(0)
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
        sys.exit(0)
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
            print("reading data")
            data = readSerialData()

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

if __name__ == "__main__":
    main()
