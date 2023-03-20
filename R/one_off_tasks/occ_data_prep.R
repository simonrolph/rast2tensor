# This is a one off script that loads in the various csv data frames of occurences records, cleans to the required columns then saves as a .RDS file to be loaded by the main script

library(readr)
library(dplyr)

sp_data_day_moth <- read_csv("data/occurence/DayFlyingMoths_EastNorths_no_duplicates.csv") %>% 
  dplyr::select(id = TO_ID,x = lon,y = lat,sp = sp_n,date=date)


sp_data_butterfly <- read_csv("data/occurence/butterfly_EastNorths_no_duplicates_2021_12_06.csv") %>% dplyr::select(id = TO_ID,x = lon,y = lat,sp = sp_n,date=date)

sp_data <- bind_rows(sp_data_day_moth,sp_data_butterfly)


sp_data %>% saveRDS("data/occurence/all_occ_data.RDS")



sink("data/occurence/species_counts.txt")
sp_data %>% 
  group_by(sp) %>% 
  summarise(n=n()) %>% 
  arrange(-n) %>% 
  print(n=100000)
sink()
