**CalliopEO**

[README](README.md) | [Program Description](ProgramDescription.md) | [Testcases](testcases/testcases.md) | ***[Changelog](CHANGELOG.md)***
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Tracking changes in master

*none yet*

## [1.1.1](https://github.com/calliope-edu/CalliopEO_AstroPi/releases/tag/v1.1.1)

**Fixes**
- Fix broken links A2 & A3 in ProgramDescription

## [1.1.0](https://github.com/calliope-edu/CalliopEO_AstroPi/releases/tag/v1.1.0)

**Updates**
- Closed issue #78: Testing.sh exits with notification if there are no test case files
- Closed issue #76: Inserted "5 second sleep phase" between test cases with unconnected and connected CalliopEO in testing.sh to avoid that the program accesses CalliopEO too early which can result in errors
- Closed issue #74: Reduced data rate for burst.hex to avoid having corrupted .data files resulting in incorrect MD5 checksums
- Closed issue #48: Handle "unstructured" data from CalliopEO without newlines
- Add test case for data without newline
- Update Test results
- Add error message output for `Max file size achieved` and `Max script time achieved`
- Add MIT License
- Do not add FLASH device in `/etc/fstab` in setup process anymore
- Updates in `Readme` and `ProgramDescription`
- Update to initial Hex file `30s-iss-sensors.hex`
- Replaced md5sum by custom-made `comp()` function in test cases 07a and 07b
- Removed unneeded declaration of `tc_folder`
- Added Cancel button to GUI
- Max number of retries to flash can now be configured via `MAX_RETRY_FLASHING`
- Max serial line length read can now be configured via `MAX_LINE_LENGTH`
- Cleaned up function `waitSerialStart()`, see issue #56
- Properly encode SERIAL_START before sending to serial port
- Added notes on proper usage of `SERIAL_TIMEOUT` and `MAX_SERIAL_WAIT_REPLY`


## [1.0.1](https://github.com/Amerlander/svelte-typeahead-multiselect/releases/tag/v1.0.0) - 2021-02-25

**Updates**

- Link Boilerplate files in Readme
- Describe CLI Argument --fake-timestamp in Readme

## [1.0.0](https://github.com/calliope-edu/CalliopEO_AstroPi/releases/tag/v1.0.0) - 2021-07-24

- Initial release
