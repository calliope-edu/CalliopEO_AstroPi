function checkTimeout () {
    if (control.millis() >= startTime + runMaxSeconds * 1000) {
        runProgram = false
        basic.showIcon(IconNames.Yes)
        serial.writeLine("@END@")
    }
}
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7)) {
        serial.writeLine("@START@")
        basic.clearScreen()
        counter = 0
        runProgram = true
        startTime = control.millis()
    }
})
let y = 0
let x = 0
let ledCounter = 0
let counter = 0
let SERIAL_RECEIVED = ""
let runProgram = false
let startTime = 0
let runMaxSeconds = 0
// runMaxSeconds is the maximum time in seconds the program is allowed to run.
runMaxSeconds = 10
basic.showIcon(IconNames.Asleep)
basic.forever(function () {
    if (runProgram) {
        serial.writeString("plzkillme!")
        ledCounter = counter % 25
        x = ledCounter % 5
        y = (ledCounter - x) / 5
        counter = counter + 1
        led.toggle(x, y)
        checkTimeout()
    }
})
