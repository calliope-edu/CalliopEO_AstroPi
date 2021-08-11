**CalliopEO**

[README](README.md) | [Program Description](ProgramDescription.md) | [Testcases](testcases/testcases.md) | ***[CHANGELOG.md](CHANGELOG.md)***
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



## Tracking changes in master

**Updates**
- Replaced md5sum by custom-made `comp()` function in testcases 07a and 07b
- Removed unneeded declaration of `tc_folder`
- Added Cancel button to GUI
- Max no of retries to flash can now be configured via `MAX_RETRY_FLASHING`
- Cleaned up function `waitSerialStart()`, see issue #56
- Properly encode SERIAL_START before sending to serial port
- Added notes on propper usage of `SERIAL_TIMEOUT` and `MAX_SERIAL_WAIT_REPLY`


## [1.0.1](https://github.com/Amerlander/svelte-typeahead-multiselect/releases/tag/v1.0.0) - 2021-02-25

**Updates**

- Link Boilerplate files in Readme
- Describe CLI Argument --fake-timestamp in Readme

## [1.0.0](https://github.com/calliope-edu/CalliopEO_AstroPi/releases/tag/v1.0.0) - 2021-07-24

- Initial release