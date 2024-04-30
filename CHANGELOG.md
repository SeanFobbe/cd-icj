# Changelog

The Changelog documents changes made to the data set. Versions are named according to the day on which the data creation process began.


## Version \version

- Full recompilation of data set
- Scope extended up to case number 193: *Alleged Breaches of Certain International Obligations in respect of the Occupied Palestinian Territory* (Nicaragua v. Germany) 


## Version 2023-10-22

- Full recompilation of data set
- Scope extended up to case number 190: *Aerial Incident of 8 January 2020* (Canada, Sweden, Ukraine and United Kingdom v. Islamic Republic of Iran)
- Add fix for lowercase components in URL basenames
- Updated Python toolchain
- Align Docker config with Debian as host system



## Version 2023-05-07


- Full recompilation of data set
- Entire computational environment now version-controlled with Docker
- Scope extended up to case number 187: *Obligations of States in respect of climate change* (Advisory Opinion)
- Upgrade Tesseract OCR to version 5.3.1
- Upgrade OCR training data to "tesseract_best"
- Simplified config file
- Simplified function loading
- Ensure that debug mode only processes cases once
- Fix download manifest
- Update download function
- Contents of source ZIP file linked to Git manifest


## Version 2022-09-07

- Full recompilation of data set
- Scope extended up to case number 183: *Jurisdictional Immunities* (Germany v Italy)
- Upgraded OCR to Tesseract 5.0.1
- CHANGELOG and README converted to external markdown files
- The ZIP archive of source files includes the TEX files
- Config file converted to TOML format
- All R packages are version-controlled with {renv}
- Data set creation process cleans up all files from previous runs before a new data set is created
- Removed redundant color from violin plots
- Added custom split instructions for the 2021-07-21 Order in the Amity Treaty case



## Version 2021-11-23

- Initial Release


