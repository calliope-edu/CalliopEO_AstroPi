let y = 0
let x = 0
let ledCounter = 0
let counter = 0
let SERIAL_RECEIVED = ""
let startTime = 0
let runProgram = false
let runMaxSeconds = 30 // runMaxSeconds is the maximum time in seconds the program is allowed to run.

basic.showIcon(IconNames.Asleep)

function checkTimeout() {
    if (control.millis() >= startTime + runMaxSeconds * 1000) {
        runProgram = false
        basic.showIcon(IconNames.Yes)
        serial.writeLine("@END@")
    }
}
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function() {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7) && !(runProgram)) {
        serial.writeLine("@START@")
        basic.clearScreen()
        counter = 0
        runProgram = true
        startTime = control.millis()
    }
})

basic.forever(function() {
    if (runProgram) {
        serial.writeLine("" + (counter))
        ledCounter = counter % 25
        x = ledCounter % 5
        y = (ledCounter - x) / 5
        counter = counter + 1
        led.toggle(x, y)
        basic.pause(1000)
        checkTimeout()
    }
})