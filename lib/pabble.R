library(tidyverse)
library(magrittr)
library(lubridate)
library(xts)

get_pabble <- function(minute_data, 
                   nonwear_method = c("missing_HR", 
                                      "missing_HR_zero_steps"), 
                   adherent_time = c("daytime", 
                                     "nightime", 
                                     "24hrs"), 
                   minimum_adherent_minutes = 10 * 60) {
  #nonwear_method
  if(nonwear_method[1] == "missing_HR") {
    minute_data %<>%  
      mutate(wear = !(is.na(HR) | is.na(steps)))
  }
  if(nonwear_method[1] == "missing_HR_zero_steps") {
    minute_data %<>% 
      mutate(wear = !(is.na(HR) & steps_is_zero | is.na(steps)))
  }
  
  #adherent_time
  if(adherent_time[1] == "daytime") {
    minute_data %<>% 
      mutate(adherence = eight_to_eight, 
             adherent_wear = wear & adherence)
  }
  if(adherent_time[1] == "nighttime") {
    minute_data %<>% 
      mutate(adherence = !eight_to_eight, 
             adherent_wear = wear & adherence)
  }
  if(adherent_time[1] == "24hrs") {
    minute_data %<>% 
      mutate(adherence = TRUE,
             adherent_wear = wear)
  }
  
  #minimum_adherent_minutes
  minute_data %<>%
    group_by(id, date) %>% 
    mutate(is_adherent_day = (sum(adherent_wear) >= minimum_adherent_minutes)) %>% 
    ungroup()
  
  minute_data %<>%
    group_by(id, date) %>% 
    mutate(adherence = adherence & is_adherent_day, 
           adherent_wear = adherent_wear & is_adherent_day) %>% 
    ungroup()
  
  ts_minute <- minute_data %>%
    distinct(id, time, 
             date, hour, weekday, eight_to_eight, 
             wear, is_adherent_day, adherence, adherent_wear,
             intensity, intensity_is_missing
             )
  
  minute_data <- ts_minute %>% 
    left_join(minute_data %>% 
                filter(adherent_wear))
}
