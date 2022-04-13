#server

library(tidyverse)
library(magrittr)
library(lubridate)
library(zip)
library(fs)
library(R.utils)
library(DT)
library(xts)


##### ---------- include in app? >>>
# intensity %>% 
#   group_by(id) %>% 
#   summarise(total_hours = n() / 60, 
#             total_days = n() / 60 / 24)
#
# redefine min and max in timePeriod and show a table
##### ---------- <<<

function(input, output) {
  reactive_list <- reactiveValues(message = "choose a file")
  
  output$message <- renderText({
    reactive_list$message
  })
  
  reactive_data <- reactive({
    zip_path <- req(input$zip$datapath)
    reactive_list$message <- ""
    reactive_data <- list()
    #### ####
    # read data
    #### ####
    
    #zip_path <- "~/Box Sync/fitbit_patients (ma58494@eid.utexas.edu)/AYA FITBIT DATA/test_export_2.zip"
    if(dir.exists(file.path(tempdir(), "files_path")))
      dir_delete(file.path(tempdir(), "files_path"))
    files_path <- dir_create(file.path(tempdir(), "files_path"))
    zip::unzip(zip_path, exdir = files_path, junkpaths = T)
    
    files <- tibble(filename = list.files(files_path, pattern = "heartrate_1min"), 
                    filetype = "HR")
    files <- bind_rows(files, 
                       tibble(filename = list.files(files_path, pattern = "minuteStepsNarrow"), 
                             filetype = "steps"))
    files <- bind_rows(files, 
                       tibble(filename = list.files(files_path, pattern = "minuteIntensitiesNarrow"), 
                              filetype = "intensity"))
    files$lines <- sapply(file.path(files_path, files$filename), countLines)
    files %<>% 
      mutate(label = sub("(_heartrate_1min|_minuteStepsNarrow|_minuteIntensitiesNarrow).*", "", filename)) %>%
      group_by(label) %>% 
      mutate(id = cur_group_id(), 
             min_lines = min(lines)) %>% 
      ungroup()
    
    reactive_data$files <- files

    #### ####
    # preprocessing HR
    #### ####
    
    files_ <- filter(files, filetype == "HR", min_lines > 1)
    raw_HR_list <- lapply(1:nrow(files_),  
                          function(r) {
                            read_csv(file.path(files_path, files_$filename[r])) %>% 
                              mutate(id = files_$id[r], 
                                     label = files_$label[r])
                          })
    
    read_raw_HR <- function(x) {
      x %>% 
        rename(time = Time, 
               HR = Value) %>% 
        mutate(time = parse_date_time(time, "%m/%d/%Y %H:%M:%S %Op")) %>% 
        arrange(time) %>% 
        mutate(jump_mins = as.numeric(difftime(time, lag(time), units = "min")) - 1)
    }
    
    raw_HR_list <- lapply(raw_HR_list, read_raw_HR)
    
    # lapply(raw_HR_list, 
    #        function(x) summary(table(x$time)))
    # lapply(raw_HR_list, function(x) summary(x$jump_mins))
    # lapply(raw_HR_list, function(x) summary(x$HR))
    
    preprocess_raw_HR <- function(x) {
      ts <- seq(min(x$time), max(x$time), by="min")
      ts <- data.frame(time = ts)
      
      ts %>%
        left_join(x) %>% 
        mutate(id = na.locf(id), 
               label = na.locf(label),
               date = as.Date(time), 
               #jump_mins = na.locf(jump_mins, fromLast = TRUE),  
               HR_is_missing = is.na(HR) * 1) 
    }
    
    raw_HR_list <- lapply(raw_HR_list, preprocess_raw_HR)
    raw_HR <- bind_rows(raw_HR_list)
    
    timePeriod <- raw_HR %>% 
      group_by(id, label) %>% 
      summarise(min_HR_time = min(time), 
                max_HR_time = max(time))
    
    #### ####
    # preprocessing steps
    #### ####
    
    files_ <- filter(files, filetype == "steps", min_lines > 1)
    raw_steps_list <- lapply(1:nrow(files_),  
                             function(r) {
                               read_csv(file.path(files_path, files_$filename[r])) %>% 
                                 mutate(id = files_$id[r], 
                                        label = files_$label[r])
                             }
    )
    
    read_raw_steps <- function(x) {
      x %>% 
        rename(time = ActivityMinute, 
               steps = Steps) %>% 
        mutate(time = parse_date_time(time, "%m/%d/%Y %H:%M:%S %Op")) %>% 
        arrange(time) %>% 
        mutate(jump_mins = as.numeric(difftime(time, lag(time), units = "min")) - 1)
    }
    
    raw_steps_list <- lapply(raw_steps_list, read_raw_steps)
    
    # lapply(raw_steps_list, 
    #        function(x) summary(table(x$time)))
    # lapply(raw_steps_list,
    #        function(x) summary(x$jump_mins))
    # lapply(raw_steps_list, function(x) summary(x$steps))
    
    preprocess_raw_steps <- function(x) {
      ts <- seq(min(x$time), max(x$time), by="min")
      ts <- data.frame(time = ts)
      
      ts %>%
        left_join(x) %>% 
        mutate(id = na.locf(id),
               label = na.locf(label),
               date = as.Date(time),  
               #jump_mins = na.locf(jump_mins, fromLast = TRUE), 
               steps_is_missing = is.na(steps) * 1, 
               steps_is_zero = (steps == 0) * 1, 
               steps_is_zero = if_else(is.na(steps_is_zero), 0, steps_is_zero))
    }
    
    raw_steps_list <- lapply(raw_steps_list, preprocess_raw_steps)
    raw_steps <- bind_rows(raw_steps_list)
    
    timePeriod %<>%  
      left_join(
        raw_steps %>% 
          group_by(id, label) %>% 
          summarise(min_steps_time = min(time), 
                    max_steps_time = max(time))
      )
    
    #### ####
    # preprocessing intensities
    #### ####
    
    files_ <- filter(files, filetype == "intensity", min_lines > 1)
    raw_intensity_list <- lapply(1:nrow(files_),  
                                 function(r) {
                                   read_csv(file.path(files_path, files_$filename[r])) %>% 
                                     mutate(id = files_$id[r], 
                                            label = files_$label[r])
                                 }
    )
    
    read_raw_intensity <- function(x) {
      x %>% 
        rename(time = ActivityMinute, 
               intensity = Intensity) %>% 
        mutate(time = parse_date_time(time, "%m/%d/%Y %H:%M:%S %Op")) %>% 
        arrange(time) %>% 
        mutate(jump_mins = as.numeric(difftime(time, lag(time), units = "min")) - 1)
    }
    
    raw_intensity_list <- lapply(raw_intensity_list, read_raw_intensity)
    
    # lapply(raw_intensity_list, 
    #        function(x) summary(table(x$time)))
    # lapply(raw_intensity_list,
    #        function(x) summary(x$jump_mins))
    # lapply(raw_intensity_list, function(x) summary(as.factor(x$intensity)))
    
    preprocess_raw_intensity <- function(x) {
      ts <- seq(min(x$time), max(x$time), by="min")
      ts <- data.frame(time = ts)
      
      ts %>%
        left_join(x) %>% 
        mutate(id = na.locf(id), 
               label = na.locf(label), 
               date = as.Date(time),  
               #jump_mins = na.locf(jump_mins, fromLast = TRUE), 
               intensity_is_missing = is.na(intensity) * 1)
    }
    
    raw_intensity_list <- lapply(raw_intensity_list, preprocess_raw_intensity)
    raw_intensity <- bind_rows(raw_intensity_list)
    
    timePeriod %<>%  
      left_join(
        raw_intensity %>% 
          group_by(id, label) %>% 
          summarise(min_intensity_time = min(time), 
                    max_intensity_time = max(time))
      )
    
    #### ####
    # join all datasets: minute_data
    #### ####
    
    timePeriod %<>% 
      group_by(id, label) %>% 
      mutate(min_time = as.Date(max(min_HR_time, min_steps_time, min_intensity_time)) + 1, 
             max_time = as.Date(min(max_HR_time, max_steps_time, max_intensity_time)) - 1 + 
               lubridate::hours(23) + 
               lubridate::minutes(59))
    
    print(head(raw_HR))
    print(head(raw_steps))
    print(head(raw_intensity))
    
    reactive_data$timePeriod <- timePeriod
    
    raw_HR %<>% 
      left_join(select(timePeriod, id, label, min_time, max_time)) %>% 
      filter(time >= min_time, 
             time <= max_time) %>% 
      select(-jump_mins, -min_time, -max_time)
    
    raw_steps %<>% 
      left_join(select(timePeriod, id, label, min_time, max_time)) %>% 
      filter(time >= min_time, 
             time <= max_time) %>% 
      select(-jump_mins, -min_time, -max_time)
    
    raw_intensity %<>% 
      left_join(select(timePeriod, id, label, min_time, max_time)) %>% 
      filter(time >= min_time, 
             time <= max_time) %>% 
      select(-jump_mins, -min_time, -max_time)
    
    minute_data <- raw_HR %>% 
      left_join(raw_steps) %>% 
      left_join(raw_intensity)
    
    saveRDS(minute_data, "./data/preprocess_minute_data.RDS")
    reactive_list$message <- "saved preprocess_minute_data.RDS"
    reactive_data
  })
  
  output$files <- renderDataTable({
    reactive_data()$files
  })
  
  output$timePeriod <- renderDataTable({
    reactive_data()$timePeriod
  })
  
}