let runProgram = true
basic.forever(function () {
    images.iconImage(IconNames.Confused).showImage(0)
    // Student code goes here.
    while (runProgram) {
        serial.writeLine("plzkillme!")
    }
})

