download_source <- function(type = "individual",
                            outdir) {
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
  
  # Create output directory if needed
  if (!dir.exists(outdir)) {
    dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Download
  safe_dl <- safely(download.file)
  map(
    .x = links,
    .f = ~ {
      Sys.sleep(10);
      safe_dl(.x, 
              destfile = paste0(outdir, "/", gsub("^.+/", "", .x))
              )
    },
    .progress = TRUE
    )
}