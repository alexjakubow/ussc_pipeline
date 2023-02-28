# Directory setup
dir.create("R")
file.create("R/functions.R")

# Install
install.packages(c("targets", "usethis", "visNetwork"))
install.packages(c("tidyverse", "rvest"))
renv::snapshot()

# Initialize pipeline
targets::use_targets()
