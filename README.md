**CalliopEO**
# Readme

## Description
CalliopEO is a Python script to facilitate interaction between the [Astro Pi microcomputer](https://astro-pi.org/) and the [CalliopEO Mini microcontroller board](https://calliope.cc/en/calliopeo). If executed, the script detects, if a CalliopEO Mini is attached to a USB board of the Astro Pi and determins the serial port to communicate with the CalliopEO.

### Essential Branch

This is the essential branch. It only contains essential files for running the program.

For a full documentation, please refer to the [main branch](https://github.com/calliope-edu/CalliopEO_AstroPi/tree/main).

#### Included files:
- `CalliopeEO.py`
- `setup.sh`
- all files in `modules/`
- `Testing.sh` and `testing.conf`
- all files in `testcases/shfuncs/`
- `30sec-iss-sensors.zip` in `/testcases/testfiles`
- `README.md` and `.gitignore`

#### Removed files:
- `assets/` folder
- all testcases in `testcases/`
- all testfiles except `30sec-iss-sensors.zip` in `testcases/testfiles/`
- `testresults/` folder
- `CHANGELOG.md`, `LICENSE`, `ProgramDescription.md` and `requirements.md`

