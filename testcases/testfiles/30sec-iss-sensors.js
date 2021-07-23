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
        serial.writeLine("R: Red; G: Green; B: Blue; C: Clear")
        serial.writeLine("CO2: CO2; T: Temperature; H: Humidity")
        serial.writeLine("IR: Infrared; L: Light; UV: UV Index")
        runProgram = true
        startTime = control.millis()
    }
})
let SERIAL_RECEIVED = ""
let startTime = 0
let runProgram = false
let runMaxSeconds = 0
    // runMaxSeconds is the maximum time in seconds the program is allowed to run.
runMaxSeconds = 30
runProgram = false
basic.showIcon(IconNames.Asleep)
basic.forever(function() {
    if (runProgram) {
        basic.showLeds(`
            . . . . .
            . . . . .
            . . # . .
            . . . . .
            . . . . .
            `)
        serial.writeLine("R:" + TCS3414.readRed() + ("; G:" + TCS3414.readGreen()) + ("; B:" + TCS3414.readBlue()) + ("; C:" + TCS3414.readClear()))
        serial.writeLine("###")
        serial.writeLine("CO2:" + SCD30.readCO2() + ("; T:" + SCD30.readTemperature()) + ("; H:" + SCD30.readHumidity()))
        serial.writeLine("###")
        serial.writeLine("IR:" + SI1145.readInfraRed() + ("; L:" + SI1145.readLight()) + ("; UV:" + SI1145.readUltraVioletIndex()))
        serial.writeLine("###")
        basic.clearScreen()
        basic.pause(1000)
        checkTimeout()
    }
})