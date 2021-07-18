serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7) && !(runProgram)) {
        serial.writeLine("@START@")
        runProgram = true
    }
})
let Temperatur = 0
let SERIAL_RECEIVED = ""
let runProgram = false
runProgram = false
basic.forever(function () {
    // Program goes here
    if (runProgram) {
        images.iconImage(IconNames.ArrowNorth).showImage(0)
        Temperatur = input.temperature()
        serial.writeLine("Temperatur:" + Temperatur)
        basic.pause(900)
        images.iconImage(IconNames.Yes).showImage(0)
        basic.pause(100)
    }
})
