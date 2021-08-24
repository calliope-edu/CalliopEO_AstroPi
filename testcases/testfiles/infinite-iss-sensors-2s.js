function sendInfo() {
    serial.writeLine("T4L: Time for last loop")
    serial.writeLine("time: Zeit")
    serial.writeLine("loop#: Loop Nr.")
    serial.writeString("")
    serial.writeLine("Mini...")
    serial.writeLine("   T1: Temperatur mini in Degrees")
    serial.writeLine("   L1: Lichtstärke mini")
    if (testAccelerometer == true) {
        serial.writeString("   Accelerometer...")
        serial.writeLine("      Ax: Accelerometer X mg")
        serial.writeLine("      Ay: Accelerometer Y mg")
        serial.writeLine("      Az: Accelerometer Z mg")
        serial.writeLine("      A: Accelerometer total mg")
    }
    if (testMagnetometer == true) {
        serial.writeString("   Magnetormeter...")
        serial.writeLine("      Mx: Magnetormeter X µT")
        serial.writeLine("      My: Magnetometer Y µT")
        serial.writeLine("      Mz: Magnetometer Z µT")
        serial.writeLine("      M: Magnetometer total µT")
    }
    serial.writeString("")
    if (testSCD30 == true) {
        serial.writeLine("Temp RH CO2 . . .")
        serial.writeLine("   T2: Temperature in Degrees")
        serial.writeLine("   H: Humidity in %")
        serial.writeLine("   CO2: Co2 in ppm")
    }
    serial.writeString("")
    if (testSI1145 == true) {
        serial.writeLine("Sunlight Sensor . . .")
        serial.writeLine("   IR: IR intensity")
        serial.writeLine("   L2: Light intensity")
        serial.writeLine("   UV: UV Index")
    }
    serial.writeString("")
    if (testTCS34725 == true) {
        serial.writeLine("Color Sensor . . .")
        serial.writeLine("   R: Red")
        serial.writeLine("   G: Green")
        serial.writeLine("   B: Blue")
        serial.writeLine("   W: White")
    }
    serial.writeLine("")
}
input.onButtonEvent(Button.A, ButtonEvent.Click, function() {
    useDisplay = !(useDisplay)
})
serial.onDataReceived(serial.delimiters(Delimiters.NewLine), function() {
    SERIAL_RECEIVED = serial.readUntil(serial.delimiters(Delimiters.NewLine))
    if ("@START@" == SERIAL_RECEIVED.substr(0, 7) && !(runProgram)) {
        serial.writeLine("@START@")
        basic.clearScreen()
        sendInfo()
        tick = control.millis() - startTime
        startTime = tick
        runProgram = true
    }
})
let tick_cache = 0
let startTime = 0
let tick = 0
let SERIAL_RECEIVED = ""
let useDisplay = false
let testTCS34725 = false
let testSI1145 = false
let testSCD30 = false
let testMagnetometer = false
let testAccelerometer = false
let runProgram = false
    // Period to update measurements in ms. Should be higher than ~ 200 ms
let updatePeriod = 2000
runProgram = false
let counter = 0
testAccelerometer = true
testMagnetometer = false
testSCD30 = true
testSI1145 = true
testTCS34725 = true
useDisplay = false
basic.showIcon(IconNames.Asleep, 1)
basic.forever(function() {
    if (runProgram) {
        led.enable(useDisplay)
        tick_cache = tick
        tick = control.millis() - startTime
        serial.writeValue("T4LL", tick - tick_cache)
        serial.writeValue("time", tick)
        serial.writeValue("loop#", counter)
        serial.writeValue("T1", input.temperature())
        serial.writeValue("L1", input.lightLevel())
        if (testAccelerometer == true) {
            serial.writeValue("Ax", input.acceleration(Dimension.X))
            serial.writeValue("Ay", input.acceleration(Dimension.Y))
            serial.writeValue("Az", input.acceleration(Dimension.Z))
            serial.writeValue("A", input.acceleration(Dimension.Strength))
        }
        if (testMagnetometer == true) {
            serial.writeValue("Mx", input.magneticForce(Dimension.X))
            serial.writeValue("My", input.magneticForce(Dimension.Y))
            serial.writeValue("Mz", input.magneticForce(Dimension.Z))
            serial.writeValue("M", input.magneticForce(Dimension.Strength))
        }
        if (testSCD30 == true) {
            serial.writeValue("T2", SCD30.readTemperature())
            serial.writeValue("H", SCD30.readHumidity())
            serial.writeValue("CO2", SCD30.readCO2())
        }
        if (testSI1145 == true) {
            serial.writeValue("IR", SI1145.readInfraRed())
            serial.writeValue("L2", SI1145.readLight())
            serial.writeValue("UV", SI1145.readUltraVioletIndex())
        }
        if (testTCS34725 == true) {
            serial.writeValue("R", TCS3414.readRed())
            serial.writeValue("G", TCS3414.readGreen())
            serial.writeValue("B", TCS3414.readBlue())
            serial.writeValue("W", TCS3414.readClear())
        }
        serial.writeLine("")
        led.toggle(2, 2)
        counter += 1
        basic.pause(updatePeriod - (control.millis() - startTime - tick))
    }
})