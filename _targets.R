# Load packages required to define the pipeline
library(targets)

# Set target options
tar_option_set(
  packages = c("tidyverse", "rvest", "qs", "arrow", "vroom",
               "Microsoft365R"), # packages that your targets need to run
  memory = "transient",
  garbage_collection = TRUE,
  format = "qs" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# Run the R scripts in the R/ folder with your custom functions
tar_source()

# Pipeline
list(
  tar_target(
    name = source_links,
    command = get_links()
  ),
  tar_target(
    name = source_files,
    command = download_source(links = source_links)
  ),
  tar_target(
    name = extracted_filestubs,
    command = unzipper(files = source_files,
                    outdir = "data/02_raw")
  ),
  tar_target(
    name = converted_files,
    command = convert_df(extracted_filestubs),
    pattern = map(extracted_filestubs),
    format = "feather"
  ),
  tar_target(
    name = subset_files,
    command = select_cols(dat = converted_files),
    pattern = map(converted_files),
    format = "feather"
  ),
  tar_target(
    name = csvs,
    command = convert_csv(dat = subset_files),
    pattern = map(subset_files),
    format = "file"
  ),
  tar_target(
    name = cloud_upload,
    command = push_to_onedrive(f = csvs,
                               od_dir = "projects/ussc_pipeline"),
    pattern = map(csvs)
  )
)
