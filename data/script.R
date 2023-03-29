# Process CSEW open data tables as a single CSV file #

library(tidyverse) ; library(rvest) ; library(httr)

# open data table links
urls <- c("https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/householdcrimeincidencecsewopendatatable/current",
          "https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/householdcrimeprevalencecsewopendatatable/current",
          "https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/personalcrimeincidencecsewopendatatable/current",
          "https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/personalcrimeprevalencecsewopendatatable/current",
          "https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/perceptionscriminaljusticesystemcsewopendatatable/current",
          "https://www.ons.gov.uk/peoplepopulationandcommunity/crimeandjustice/datasets/perceptionsothercsewopendatatable/current")

# find zip file links
zip_urls <- map_df(urls, function(i) {
  webpage <- read_html(i)
  tibble(
    url = html_nodes(webpage, xpath=".//a[contains(@href, '.zip')]") %>%
      html_attr("href") %>% 
      sprintf("https://www.ons.gov.uk%s", .) %>% 
      .[[1]]
  )
})

# download and unzip files
walk(zip_urls$url, ~{
  message("Downloading: ", .x)
  GET(url = .x, write_disk(file.path(".", basename(.x))))
  unzip(sub(".*/", "", .x))
  file.remove(sub(".*/", "", .x))
})

# read and combine files
df <- list.files(path = ".", pattern = "Wales") %>% 
  map_df(~read_csv(., col_types = cols(.default = "c", Estimate = "n", StandardError = "n", UnweightedCount = "n")))

# write results
write_csv(df, paste0("CSEW_England and Wales_", str_sub(zip_urls$url[1],-10,-5), ".csv"))
