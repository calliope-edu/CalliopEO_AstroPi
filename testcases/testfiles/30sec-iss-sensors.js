function checkTimeout() {
    if (runMaxSeconds != 0) {
        if (control.millis() >= startTime + runMaxSeconds * 1000) {
            runProgram = false
            serial.writeLine(stopString)
            basic.pause(1000)
        }
    }
}
input.onButtonEvent(Button.AB, ButtonEvent.Click, function() {
    input.calibrateCompass()
})
input.onButtonEvent(Button.A, ButtonEvent.Click, function() {
    useDisplay = !(useDisplay)
    if (!(useDisplay)) {
        basic.clearScreen()
    }
})
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function() {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if (startString == SERIAL_RECEIVED.substr(0, startString.length)) {
        serial.writeLine(startString)
        basic.pause(1000)
        basic.clearScreen()
        startTime = control.millis()
        tick = control.millis() - startTime
        stringMini = ";" + "Temp mini (Degrees)" + (";" + "Light Intensity mini")
        if (testAccelerometer == true) {
            stringAccelerometer = ";" + "Accelerometer X (mg)" + (";" + "Accelerometer Y (mg)") + (";" + "Accelerometer Z (mg)") + (";" + "Accelerometer total (mg)")
        }
        if (testMagnetometer == true) {
            stringMagnetometer = ";" + "Magnetormeter X (µT)" + (";" + "Magnetormeter Y (µT)") + (";" + "Magnetormeter Z (µT)") + (";" + "Magnetormeter total (µT)")
        }
        if (testSCD30 == true) {
            stringSCD30 = ";" + "Temp SCD30 (Degrees)" + (";" + "Humidity (%)") + (";" + "CO2 (ppm)")
        }
        if (testSI1145 == true) {
            stringSI1145 = ";" + "IR itensity" + (";" + "Light Intensity SI1145") + (";" + "UV Index")
        }
        if (testTCS34725 == true) {
            stringTCS34725 = ";" + "Red" + (";" + "Green") + (";" + "Blue") + (";" + "White")
        }
        serial.writeLine("" + stringMini + stringAccelerometer + stringMagnetometer + stringSCD30 + stringSI1145 + stringTCS34725)
        runProgram = true
    }
})
let counter = 0
let tick = 0
let SERIAL_RECEIVED = ""
let startTime = 0
let stringTCS34725 = ""
let stringSI1145 = ""
let stringSCD30 = ""
let stringMagnetometer = ""
let stringAccelerometer = ""
let stringMini = ""
let useDisplay = false
let testTCS34725 = false
let testSI1145 = false
let testSCD30 = false
let testMagnetometer = false
let testAccelerometer = false
let runProgram = false
let runMaxSeconds = 0
let stopString = ""
let startString = ""
startString = "@START@"
stopString = "@END@"
    // runMaxSeconds is the maximum time in seconds the program is allowed to run.
runMaxSeconds = 30
runProgram = false
    // Period to update measurements in ms. Should be higher than ~ 200 ms
let updatePeriod = 2000
testAccelerometer = true
testMagnetometer = true
testSCD30 = true
testSI1145 = true
testTCS34725 = true
useDisplay = false
stringMini = ""
stringAccelerometer = ""
stringMagnetometer = ""
stringSCD30 = ""
stringSI1145 = ""
stringTCS34725 = ""
input.assumeCalibrationCompass()
basic.forever(function() {
    if (runProgram) {
        tick = control.millis() - startTime
        stringMini = ";" + input.temperature() + (";" + input.lightLevel())
        if (testAccelerometer == true) {
            stringAccelerometer = ";" + input.acceleration(Dimension.X) + (";" + input.acceleration(Dimension.Y)) + (";" + input.acceleration(Dimension.Z)) + (";" + input.acceleration(Dimension.Strength))
        }
        if (testMagnetometer == true) {
            stringMagnetometer = ";" + input.magneticForce(Dimension.X) + (";" + input.magneticForce(Dimension.Y)) + (";" + input.magneticForce(Dimension.Z)) + (";" + input.magneticForce(Dimension.Strength))
        }
        if (testSCD30 == true) {
            stringSCD30 = ";" + SCD30.readTemperature() + (";" + SCD30.readHumidity()) + (";" + SCD30.readCO2())
        }
        if (testSI1145 == true) {
            stringSI1145 = ";" + SI1145.readInfraRed() + (";" + SI1145.readLight()) + (";" + SI1145.readUltraVioletIndex())
        }
        if (testTCS34725 == true) {
            stringTCS34725 = ";" + TCS3414.readRed() + (";" + TCS3414.readGreen()) + (";" + TCS3414.readBlue()) + (";" + TCS3414.readClear())
        }
        serial.writeLine("" + stringMini + stringAccelerometer + stringMagnetometer + stringSCD30 + stringSI1145 + stringTCS34725)
        counter += 1
        if (useDisplay) {
            led.toggle(2, 2)
        } else {
            basic.clearScreen()
        }
        basic.pause(updatePeriod - (control.millis() - startTime - tick))
        checkTimeout()
    } else {
        if (useDisplay) {
            basic.showIcon(IconNames.Asleep)
        } else {
            basic.clearScreen()
        }
    }
})