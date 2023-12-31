library(tidyverse)
library(here)
library(tidycensus)
library(rvest)
options(tigris_use_cache = TRUE)

total_using_public_transportation <- c("B08301_010E")
total_commuting <- c("B08301_001E")
by_earnings <- c("B08119_029E","B08119_030E","B08119_031E","B08119_032E","B08119_033E","B08119_034E","B08119_035E","B08119_036E")
by_vehicles <- c("B08141_017E","B08141_018E","B08141_019E","B08141_020E")
variables <- c(total_using_public_transportation, total_commuting,by_earnings,by_vehicles)

boston <- c(02101:02137, 02163,02199,02203,02205,02208,02209,02215,02222,02228,02283,02284,02455)

new_york <- read_html("https://www.nycbynatives.com/nyc_info/new_york_city_zip_codes.php") %>%  
  html_elements(".grippy-host , td:nth-child(4) , td:nth-child(1)") %>% 
  html_text2() %>% 
  c() %>% 
  as.numeric()
  
philadelphia <- read_html("https://www.ciclt.net/sn/clt/capitolimpact/gw_ziplist.aspx?FIPS=42101") %>%  
  html_elements("td td td:nth-child(1) a") %>% 
  html_text2() %>% 
  c() %>% 
  as.numeric()

dc <- read_html("https://www.ciclt.net/sn/clt/capitolimpact/gw_ziplist.aspx?FIPS=11001&stfips=&state=DC&stname=") %>%  
  html_elements("td td td:nth-child(1) a") %>% 
  html_text2() %>% 
  c() %>% 
  as.numeric()

zipcodes <- c(boston,new_york,philadelphia,dc)

if (!dir.exists(here("data"))) {
  dir.create(here("data"))
}

if (any(!file.exists(here("data", "ACS_2020_transportation.RDS")))) {
  ACS_2020_transportation <- get_acs(
    geography = "zcta" ,
    variables = variables,
    year = 2020,
    geometry = TRUE,)
  saveRDS(ACS_2020_transportation, file = here("data","ACS_2020_transportation.RDS"))
} else {ACS_2020_transportation <- readRDS(here("data","ACS_2020_transportation.RDS"))
}

ACS_2020_transportation_filtered <- ACS_2020_transportation %>% 
  mutate(variable = as_factor(variable),
         population = fct_collapse(variable,
                                   total_commuting = "B08301_001",
                                   total_pt = "B08301_010",
                                   no_cars = "B08141_017",
                                   one_car = "B08141_018",
                                   two_cars = "B08141_019",
                                   three_cars = "B08141_020",
                                   income_10k = "B08119_029",
                                   income_10k_25k = c("B08119_030", "B08119_031"),
                                   income_25k_50k = c("B08119_032","B08119_033"),
                                   income_50k_75k = c("B08119_034","B08119_035"),
                                   income_75k = "B08119_036"),
         zipcode_dbl = as.double(GEOID)) %>% 
  filter(zipcode_dbl %in% zipcodes) %>% 
  mutate(city = case_when(
    zipcode_dbl %in% boston ~ "Boston",
    zipcode_dbl %in% dc ~ "DC",
    zipcode_dbl %in% new_york ~ "New York",
    zipcode_dbl %in% philadelphia ~ "Philadelphia"
  ))

saveRDS(ACS_2020_transportation_filtered, file = here("data","ACS_2020_transportation_filtered.RDS"))

ACS_2020_transportation_filtered <- readRDS(gzcon(url("https://github.com/nsifnugel/biostat777-project4-data/raw/main/ACS_2020_transportation_filtered.RDS")))


