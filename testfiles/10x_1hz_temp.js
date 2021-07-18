function checkEndTime () {
    if (control.millis() - startTime >= runMaxSeconds * 1000) {
        runProgram = false
        serial.writeLine("@END@")
    }
}
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7) && !(runProgram)) {
        serial.writeLine("@START@")
        runProgram = true
        startTime = control.millis()
    }
})
let Temperatur = 0
let SERIAL_RECEIVED = ""
let startTime = 0
let runProgram = false
let runMaxSeconds = 0
runMaxSeconds = 60
runProgram = false
basic.forever(function () {
    // Program goes here
    if (runProgram) {
        for (let index = 0; index < 10; index++) {
            images.iconImage(IconNames.ArrowNorth).showImage(0)
            Temperatur = input.temperature()
            serial.writeLine("Temperatur:" + Temperatur)
            basic.pause(900)
            images.iconImage(IconNames.Yes).showImage(0)
            basic.pause(100)
        }
        serial.writeLine("@END@")
        runProgram = false
    }
})
basic.forever(function () {
    checkEndTime()
})
