# Load packages required to define the pipeline
library(targets)

# Set target options
tar_option_set(
  packages = c("tidyverse", "rvest"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# Run the R scripts in the R/ folder with your custom functions
tar_source()

# Pipeline
list(
  tar_target(
    name = source_files,
    command = download_source(outdir = "data/01_source")
  )
)
