serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7)) {
        serial.writeLine("@START@")
        runProgram = true
        startTime = control.millis()
        images.iconImage(IconNames.ArrowNorth).showImage(0)
    }
})
let startTime = 0
let SERIAL_RECEIVED = ""
let runProgram = false
// runMaxSeconds is the maximum time in seconds the program is allowed to run.
let runMaxSeconds = 30
runProgram = false
images.iconImage(IconNames.Asleep).showImage(0)
basic.forever(function () {
    // Student code goes here.
    while (runProgram) {
        serial.writeLine("plzkillme!")
        control.waitMicros(100000)
    }
})
