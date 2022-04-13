#server.R

library(tidyverse)
library(magrittr)
library(lubridate)
library(reticulate)
library(DT)

foo = reticulate::import('foo')
get_consecutive_ids <- function(x) {
  consecutive_ids = foo$get_consecutive_ids(x)
  consecutive_ids = lapply(consecutive_ids, unlist)
  consecutive_ids = lapply(consecutive_ids, function(x) {x[is.nan(x)] <- as.numeric(NA); x})
  consecutive_ids
}
tf = reticulate::import('tf')

data <- readRDS("../data/preprocess_minute_data_1.RDS")

data %<>%
  mutate(id = as.character(id), 
         hour = hour(time), 
         weekday = wday(date, label = TRUE), 
         eight_to_eight = (hour >= 8) & (hour < 20), 
         steps_is_zero = (steps == 0), 
         steps_is_zero = if_else(is.na(steps_is_zero), FALSE, steps_is_zero))

shinyServer(function(input, output, session) {
  
  reactive_data <- reactive({
    #nonwear
    if(input$nonwear == "missing_HR_zero_steps") {
      minute_data <- data %>% 
        mutate(weartime = !(is.na(HR) & steps_is_zero | is.na(steps)))
    }
    if(input$nonwear == "missing_HR") {
      minute_data <- data %>% 
        mutate(weartime = !(is.na(HR) | is.na(steps)))
    }
    #eight_to_eight
    if(input$eight_to_eight == "on") {
      minute_data %<>% 
        mutate(weartime = weartime & eight_to_eight)
    }
    #adherent
    minute_data %<>%
      group_by(id, date) %>% 
      mutate(adherent_day = (sum(weartime) / 60) >= input$adherent, 
             adherent_mins = adherent_day * sum(weartime)) %>% 
      ungroup()
    
    #adherent_gathered_data
    ts_gather <- minute_data %>%
      distinct(id, date, weekday, adherent_day)
    
    adherent_gathered_data <- ts_gather %>% 
      left_join(minute_data %>% 
                  filter(weartime, 
                         adherent_day))
    
    adherent_gathered_data %<>% 
      mutate(sedentary = (steps < input$thresholds[1]), 
             lipa = (steps >= input$thresholds[1] & steps < input$thresholds[2]), 
             mvpa = (steps >= input$thresholds[2]))
    
    daily_data <- adherent_gathered_data %>% 
      group_by(id, date, weekday, adherent_day, adherent_mins) %>% 
      summarise(sedentary = sum(sedentary), 
                lipa = sum(lipa), 
                mvpa = sum(mvpa)) %>% 
      mutate(sedentary_prop = sedentary / adherent_mins, 
             lipa_prop = lipa / adherent_mins, 
             mvpa_prop = mvpa / adherent_mins)
    
    #adherent_minute_data
    ts_minute <- minute_data %>%
      distinct(id, time, date, 
               hour, weekday, eight_to_eight, 
               weartime, adherent_day, adherent_mins)
    
    adherent_minute_data <- ts_minute %>% 
      left_join(minute_data %>% 
                  filter(weartime, 
                         adherent_day))
    
    adherent_minute_data %<>% 
      mutate(sedentary = (steps < input$thresholds[1]), 
             lipa = (steps >= input$thresholds[1] & steps < input$thresholds[2]), 
             mvpa = (steps >= input$thresholds[2]), 
             is_sedentary = if_else(is.na(sedentary), FALSE, sedentary) * 1)
    
    adherent_minute_data %<>%
      group_by(id, date) %>%
      mutate(sedentary_streak_id = get_consecutive_ids(is_sedentary)[[2]]) %>%
      ungroup()
    
    daily_data %<>% 
      left_join(adherent_minute_data %>%
                  filter(!is.na(sedentary_streak_id)) %>%
                  group_by(id, date, sedentary_streak_id) %>%
                  summarise(streak_length = n()) %>%
                  group_by(id, date) %>%
                  summarise(sedentary_bout_q25 = quantile(streak_length, 0.25), 
                            sedentary_bout_median = median(streak_length), 
                            sedentary_bout_mean = mean(streak_length), 
                            sedentary_bout_q75 = quantile(streak_length, 0.75)))
    # #trend
    # out = tapply(
    #   daily_data$sedentary_prop,
    #   daily_data$id,
    #   tf$adjust_trend_and_seasonality, 
    #   lam = 30.0)
    # 
    # trend = lapply(1:length(out), function(i) {
    #   data.frame(trend=out[[i]]$trend,id=names(out)[i], date_id=1:length(out[[i]]$trend))
    # }) %>% 
    #   bind_rows()
    # 
    # daily_data %<>%
    #   group_by(id) %>% 
    #   mutate(date_id=1:n()) %>% 
    #   left_join(trend, by=c("date_id", "id"))
    # 
    # #seasonal
    # seasonal = lapply(1:length(out), function(i) {
    #   data.frame(seasonal=out[[i]]$seasonal,id=names(out)[i], date_id=1:length(out[[i]]$seasonal))
    # }) %>% 
    #   bind_rows() %>% 
    #   filter(date_id <= 7) %>% 
    #   left_join(select(daily_data, date_id, id, weekday), by=c("id", "date_id")) %>% 
    #   arrange(id, weekday) %>% 
    #   group_by(id) %>% 
    #   mutate(seasonal = seasonal - seasonal[1])
    
    #reactive_data
    reactive_data = list()
    reactive_data[['minute_data']] <- minute_data
    reactive_data[['adherent_gathered_data']] <- adherent_gathered_data
    reactive_data[['daily_data']] <- daily_data
    # reactive_data[['seasonal']] <- seasonal
    
    reactive_data
  })

  output$weartime <- renderPlot({
        reactive_data()$minute_data %>% 
          select(id,date,weartime) %>% 
          group_by(id, date) %>%
          summarise(wear = sum(weartime) / 60, 
                    non_wear = 24 - wear) %>% 
          pivot_longer(cols = c("wear", "non_wear")) %>% 
          mutate(name = str_replace_all(name, "_", " ")) %>% 
          ggplot() +
          geom_bar(aes(x=date, y=value, fill=name), 
                   stat="identity")  +
          facet_wrap(~id, nrow=4) + 
          theme_minimal() +
          theme(legend.position = "bottom") +
          labs(y="hours in a day", fill="")
  })
    
  output$weartime_heatmap <- renderPlot({
    reactive_data()$minute_data %>% 
      group_by(id, hour, weekday) %>% 
      summarise(weartime_prop = sum(weartime) / n()) %>% 
      ggplot(aes(x = weekday, y = hour, fill = weartime_prop)) +
      geom_tile() + 
      facet_wrap(~id, nrow=4) + 
      theme(legend.position = "bottom") + 
      labs(fill = "proportion\nof weartime")
  })
  
  # output$weartime <- renderPlot({
  #   reactive_data()$minute_data %>%
  #     group_by(id, date) %>%
  #     summarise(weartime = sum(weartime) / 60) %>%
  #     ggplot() +
  #     geom_line(aes(x=date, y=weartime, col=id)) +
  #     theme(legend.position = "bottom")
  # })
  
  output$steps <- renderPlot({
    reactive_data()$adherent_gathered_data %>% 
      group_by(id, date) %>% 
      summarise(steps = sum(steps)) %>% 
      ggplot() + 
      geom_line(aes(x=date, y=steps, col=id)) + 
      theme(legend.position = "bottom") + 
      scale_y_continuous(labels = scales::comma)
  })
  
  output$sedentary_bout <- renderPlot({
    reactive_data()$daily_data %>%
      ggplot(aes(x = date))  + 
      geom_ribbon(aes(ymin = sedentary_bout_q25, 
                      ymax = sedentary_bout_q75, 
                      fill = id), alpha = 0.5, ) + 
      geom_line(aes(y = sedentary_bout_median, col = id)) +
      #facet_wrap(~id, nrow=4) + 
      theme_minimal() +
      theme(legend.position = "bottom") + 
      labs(y = "sedentary bout length") + 
      scale_y_continuous(labels = scales::comma)
  })
  
  output$pa <- renderPlot({
    reactive_data()$daily_data %>% 
        select(id, date, sedentary_prop, lipa_prop, mvpa_prop) %>% 
        pivot_longer(cols = c('sedentary_prop', 'lipa_prop', 'mvpa_prop')) %>% 
        mutate(name = str_replace_all(name, "_", " ")) %>% 
        ggplot() +
        geom_bar(aes(x=date, y=value, fill=name), 
                 stat="identity")  +
        facet_wrap(~id, nrow=4) + 
        theme_minimal() +
        theme(legend.position = "bottom") + 
        scale_fill_discrete(type = c("orange", "black", "yellow")) + 
        labs(fill = "", y = "proportion of the day")
  })
  
  output$table <- renderDataTable({
    reactive_data()$daily_data %>% 
      filter(adherent_day) %>% 
      group_by(id) %>% 
      summarise(sedentary_prop_mu = round(mean(sedentary_prop), digits=2), 
                lipa_prop_mu = round(mean(lipa_prop), digits=2), 
                mvpa_prop_mu = round(mean(mvpa_prop), digits=2),
                sedentary_bout_mu = round(mean(sedentary_bout_mean), digits=2)) 
  }, 
  rownames= FALSE, 
  colnames = c("id",
               "mean sedentary time",
               "mean lipa time",
               "mean mvpa time",
               "mean sedentary bout length")
  )
  
  # output$trend_filter <- renderPlot({
  #   ggplot(reactive_data()$daily_data, 
  #          aes(x=date, y=trend, color=is.na(sedentary_prop))) + 
  #     geom_line(aes(group=1), 
  #               size = 1.2, alpha = 0.6)+
  #     scale_color_manual(values=c("red", "grey"), labels=c("adherent", "non-adherent")) + 
  #     geom_point(data = reactive_data()$daily_data, 
  #                aes(x=date, y=sedentary_prop), 
  #                color="blue", alpha=0.3) + 
  #     facet_wrap(~id, scales = "free", ncol=1) +
  #     theme_minimal() +
  #     theme(legend.position="top") +
  #     labs(color="")
  # })
  # 
  # output$seasonal <- renderPlot({
  #   ggplot(reactive_data()$seasonal) +
  #     geom_line(aes(x=weekday, y=seasonal, group=id, color=id)) +
  #     theme_minimal()
  # })

})
