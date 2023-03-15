# Harvest functions ------------------------------------------------------------
get_links <- function(type = "individual") {
  # Setup for scrape
  home <- "https://www.ussc.gov"
  url <- paste0(home, "/research/datafiles/commission-datafiles")
  all_links_css <- ".subContainer a" 
  
  # Determine links
  links <- read_html(url) %>%
    html_elements(all_links_css) %>%
    html_attr("href")
  if (type == "individual") {
    regex_str <- "opafy"
  }
  links <- paste0(home,
                  links[grepl("\\.zip$", links) & grepl(regex_str, links)]
  )
}

download_source <- function(links,
                            outdir = "data/01_source") {
  
  # Create output directory if needed
  if (!dir.exists(outdir)) {
    dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  }

  # Check for files
  # Download
  safe_dl <- safely(download.file)
  map(
    .x = links,
    .f = ~ if (!file.exists(paste0(outdir, "/", gsub("^.+/", "", .x)))) {
        safe_dl(.x,
              destfile = paste0(outdir, "/", gsub("^.+/", "", .x)),
              mode = "wb"
              )
    },
    .progress = TRUE
  )
  
  # Return files
  list.files(outdir, full.names = TRUE)
}

unzipper <- function(files,
                     outdir = "data/02_raw") {
  
  # Make outputdir
  if (!dir.exists(outdir)) {
    dir.create(outdir)
  }
  
  # Extract
  map(
    .x = files,
    .f = ~unzip(.x, overwrite = FALSE, exdir = outdir),
    .progress = TRUE
  )
  
  # Return filestubs
  f <- list.files(outdir, full.names = TRUE)
  f <- gsub("\\..+$", "", f)
  unique(f)
}


# Import Functions -------------------------------------------------------------
# Create dictionary from sas file
create_dict_sas <- function(f) {
  # Load
  x <- read_lines(f)
  
  # Determine start and end lines
  y <- x[which(grepl("^INPUT", x)) + 1:length(x)]
  y <- y[1: which(grepl(";$", str_trim(y)))[1]]
  if (grepl("^;$", str_trim(y[length(y)]))) {
    y <- y[1:length(y) - 1]
  } else {
    y[length(y)] <- gsub(";", "", y[length(y)])
  }
  # Remove extra whitespace
  y <- str_trim(gsub(" \\$", "$", gsub("\\s+" ," ", str_trim(y))))
  
  # Parse components
  n <- length(y)*3
  df1 <- tibble(
    x = str_split_i(y, "\\s", 1),
    pos = str_split_i(y, "\\s", 2)
  ) %>%
    mutate(
      i = seq(from = 1, to = n - 2, by = 3)
    )
  df2 <- tibble(
    x = str_split_i(y, "\\s", 3),
    pos = str_split_i(y, "\\s", 4)
  ) %>%
    mutate(
      i = seq(from = 2, to = n - 1, by = 3)
    )
  df3 <- tibble(
    x = str_split_i(y, "\\s", 5),
    pos = str_split_i(y, "\\s", 6)
  ) %>%
    mutate(
      i = seq(from = 3, to = n, by = 3)
    )
  
  # Combine and define positions
  df <- bind_rows(df1, df2, df3) %>%
    filter(!is.na(x)) %>%
    arrange(i) %>%
    mutate(
      start = as.numeric(str_extract(pos, "^[0-9]+")),
      stop = as.numeric(str_extract(pos, "[0-9]+$")),
      width = 
        case_when(
          grepl("DATE", pos) ~ as.numeric(gsub("[^0-9]", "", pos)),
          TRUE ~ stop - start + 1
        )
    )
  
  # Loop to add starts and stops for date formats
  for (i in 2:nrow(df)) {
    if (is.na(df$start[i])) {
      df$start[i] <- df$stop[i-1] + 1
      df$stop[i] <- df$start[i] + df$width[i]-1
    }
  }
  
  # Add variable type and tidy up
  df %>%
    mutate(
      type =
        case_when(
          grepl("\\$", x) ~ "character",
          grepl("DATE11", x) ~ "date (yy-mmm-yyyy)",
          TRUE ~ "unknown"
        ),
      pos = 
        case_when(
          grepl("DATE11", x) ~ paste0(start, "-", stop),
          TRUE ~ pos
        ),
      x = toupper(gsub("\\$", "", x))
    )
}

# Convert to dataframe
convert_df <- function(f) {
  
  # Subset file types
  sasfile <- paste0(f, ".sas")
  datfile <- paste0(f, ".dat")
  
  # Create dictionary
  dict <- create_dict_sas(sasfile)
  
  # Read
  vroom_fwf(file = datfile,
           fwf_positions(dict$start, dict$stop, dict$x),
           col_types = paste(rep("c", nrow(dict)), collapse = "")) %>%
    mutate(DATAYEAR = paste0("20", gsub("[^0-9]", "", gsub("^.+/", "", f))))
}


# Transform Functions ----------------------------------------------------------
# Subset
select_cols <- function(dat) {
  # Get year from file
  y <- dat %>%
    select("DATAYEAR") %>%
    slice(1) %>%
    as_vector()

  # Lookup variables in manifest
  keeps <- y %>%
    paste0("data/00_meta/varlist_", ., ".txt") %>%
    read_lines() %>%
    str_trim()
  
  # Read and subset
  dat %>%
    select(all_of(keeps)) %>%
    mutate(DATAYEAR = y)
}

# Convert to .csv
convert_csv <- function(dat,
                        outdir = "data/03_csv") {
  # Create output dir
  if (!dir.exists(outdir)) {
    dir.create(outdir)
  }
  
  # Get year from file
  y <- dat %>%
    select(DATAYEAR) %>%
    slice(1) %>%
    as_vector()
  
  # Save as csv
  fileout <- paste0(outdir, "/opafy", y, ".csv")
  dat %>%
    vroom_write(delim = ",",
                file = fileout)
  return(fileout)
}


# Output Functions -------------------------------------------------------------
# wake_onedrive <- function() {
#   # Wake
#   d <- get_business_onedrive()
#   rm(d)
# }

push_to_onedrive <- function(f,
                            od_dir) {
  # Wake
  d <- get_business_onedrive()
  rm(d)
  
  # Rerun and create project dir
  od <- get_business_onedrive()
  dircheck <- try(od$list_items(od_dir))
  if (class(dircheck) == "try-error") {
    od$create_folder(od_dir)
  }
  
  # Upload file
  od$upload_file(src = f,
                 dest = paste0(od_dir, "/", f))
}