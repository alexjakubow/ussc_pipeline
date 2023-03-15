# USSC Pipeline

## Overview
This pipeline automates the following tasks in sequence to prepare the US Sentencing Commission [Individual Offender Datafiles](https://www.ussc.gov/research/datafiles/commission-datafiles#individual) for analysis:
- Download files from website (results saved to `data/01_source`)
- Extract file contents (results saved to `data/02_raw`)
- Parse the SAS helper files (`.sas`) to ingest the raw data files (`.dat`) in fixed-width format
- Reduce the dimensionality of the yearly-files using [2_io_download.R](https://github.com/charlottemary/sentencing_data/blob/main/2_io_download.R) as a guide to subset on features (columns) of interest (variable sets for each yearly file are saved as supplementary .txt files in `data/00_meta`)
- Save data files in .csv format (`data/03_csv`)
- Push contents of `data/03_csv` to shared OneDrive folder

## Execution notes
### Using the .csv files
- File year is saved in the column `DATAYEAR` (previously  `opafy` in [source repo](https://github.com/charlottemary/sentencing_data))
- Converted .csv files can be accessed directly from the shared OneDrive folder `ussc_pipeline/data/03_csv`

### Full reproduction
If you want to reproduce this entire pipeline from scratch:
- Clone this repo
- Modify `_targets.R`
	- comment-out or delete the last `tar_target(...)` command starting on line 53
- Run `renv::restore()` from console in RStudio to load necessary project dependencies via [`renv`](https://rstudio.github.io/renv/articles/collaborating.html)