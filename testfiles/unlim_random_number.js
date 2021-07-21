serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7) && !(runProgram)) {
        serial.writeLine("@START@")
        runProgram = true
    }
})
let SERIAL_RECEIVED = ""
let runProgram = false
runProgram = false
basic.forever(function () {
    // Program goes here
    if (runProgram) {
        images.iconImage(IconNames.ArrowNorth).showImage(0)
        serial.writeString("" + (randint(0, 9)))
    }
})
