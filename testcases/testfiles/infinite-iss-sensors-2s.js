input.onButtonPressed(Button.A, function () {
    useDisplay = !(useDisplay)
    if (!(useDisplay)) {
        basic.clearScreen()
    }
})
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if (startString == SERIAL_RECEIVED.substr(0, startString.length)) {
        serial.writeLine(startString)
        basic.clearScreen()
        startTime = control.millis()
        tick = control.millis() - startTime
        runProgram = true
    }
})
let counter = 0
let tick_cache = 0
let tick = 0
let startTime = 0
let SERIAL_RECEIVED = ""
let useDisplay = false
let runProgram = false
let startString = ""
startString = "@START@"
// Period to update measurements in ms. Should be higher than ~ 200 ms
let updatePeriod = 2000
runProgram = false
let testAccelerometer = true
let testMagnetometer = false
let testSCD30 = true
let testSI1145 = true
let testTCS34725 = true
useDisplay = false
basic.forever(function () {
    if (runProgram) {
        tick_cache = tick
        tick = control.millis() - startTime
        serial.writeValue("Time for last loop", tick - tick_cache)
        serial.writeValue("Time", tick)
        serial.writeValue("Loop", counter)
        serial.writeValue("Temperatur mini (Degrees)", input.temperature())
        serial.writeValue("Light Intensity mini", input.lightLevel())
        if (testAccelerometer == true) {
            serial.writeValue("Accelerometer X (mg)", input.acceleration(Dimension.X))
            serial.writeValue("Accelerometer Y mg", input.acceleration(Dimension.Y))
            serial.writeValue("Accelerometer Z mg", input.acceleration(Dimension.Z))
            serial.writeValue("Accelerometer total mg", input.acceleration(Dimension.Strength))
        }
        if (testMagnetometer == true) {
            serial.writeValue("Magnetormeter X (µT)", input.magneticForce(Dimension.X))
            serial.writeValue("Magnetormeter Y (µT)", input.magneticForce(Dimension.Y))
            serial.writeValue("Magnetormeter Z (µT)", input.magneticForce(Dimension.Z))
            serial.writeValue("Magnetormeter total (µT)", input.magneticForce(Dimension.Strength))
        }
        if (testSCD30 == true) {
            serial.writeValue("Temp SCD30 (Degrees)", SCD30.readTemperature())
            serial.writeValue("Humidity (%)", SCD30.readHumidity())
            serial.writeValue("CO2 (ppm)", SCD30.readCO2())
        }
        if (testSI1145 == true) {
            serial.writeValue("IR itensity", SI1145.readInfraRed())
            serial.writeValue("Light Intensity SI1145", SI1145.readLight())
            serial.writeValue("UV Indx", SI1145.readUltraVioletIndex())
        }
        if (testTCS34725 == true) {
            serial.writeValue("Red", TCS3414.readRed())
            serial.writeValue("Green", TCS3414.readGreen())
            serial.writeValue("Bblue", TCS3414.readBlue())
            serial.writeValue("White", TCS3414.readClear())
        }
        serial.writeLine("")
        counter += 1
        if (useDisplay) {
            led.toggle(2, 2)
        } else {
            basic.clearScreen()
        }
        basic.pause(updatePeriod - (control.millis() - startTime - tick))
    } else {
        if (useDisplay) {
            basic.showIcon(IconNames.Asleep)
        } else {
            basic.clearScreen()
        }
    }
})
