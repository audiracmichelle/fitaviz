function(input, output) {
  
  output$menu <- renderMenu({
    if(nrow(time_period()) == 0) {
      sidebarMenu(
        menuItem(
          "Compartment 1", 
          startExpanded = TRUE, 
          menuSubItem("Data preparation", tabName = "tab_preparation")
        )
      )
    } else {
      participants <- time_period()$id
      updateSelectizeInput(
        inputId = "exploration_participants",
        choices = participants,
        selected = participants[1:min(5, length(participants))]
      )
      updateSelectizeInput(
        inputId = "processing_participants",
        choices = participants,
        selected = participants[1:min(5, length(participants))]
      )
      updateSelectInput(
        inputId = "intraday_participant",
        choices = participants,
        selected = participants[1]
      )
      updateDateInput(
        inputId = "intraday_date",
        value = as.Date(time_period()$min_time[time_period()$id == participants[1]]),
        min = as.Date(time_period()$min_time[time_period()$id == participants[1]]),
        max = as.Date(time_period()$max_time[time_period()$id == participants[1]])
      )
      
      sidebarMenu(
        menuItem(
          "Compartment 1",
          startExpanded = TRUE,
          menuSubItem("Data preparation", tabName = "tab_preparation"),
          menuSubItem("Data exploration", tabName = "tab_exploration")
        ), 
        menuItem(
          "Compartment 2",
          startExpanded = TRUE,
          menuSubItem("Data processing", tabName = "tab_processing")
        ), 
        menuItem(
          "Compartment 3",
          startExpanded = TRUE,
          menuSubItem("Data summaries", tabName = "tab_summaries"),
          menuSubItem("Data downloads", tabName = "tab_downloads")
        )
      )
    }
  })

  minute_data <- reactiveVal(tibble())
  time_period <- reactiveVal(tibble())
  
  output$time_period <- renderDataTable({
    zip_path <- req(input$zip$datapath)
    
    fitabase_files <- read_fitabase_files(zip_path)
    time_period(fitabase_files$time_period)
    minute_data(prep_minute_data(fitabase_files))
    rm(fitabase_files)
    
    time_period() %>%
      select(id, label, min_time, max_time, is_valid_time_period)
  })
  
  reactive_data <- reactive({
    reactive_data <- list()
    
    reactive_data$fitibble <- fitibble(
      minute_data(), 
      nonwear_method = input$nonwear, 
      adherent_args = list(hours_between = input$hours_between),
      valid_day_method = input$valid_day_method
    )
    reactive_data$daily_summary <- prep_daily_summary(reactive_data$fitibble)
    
    reactive_data
  })
  
  observeEvent(input$exploration_participants, {
    updateSelectizeInput(inputId = "processing_participants", 
                         selected = input$exploration_participants)
  })
  
  observeEvent(input$processing_participants, {
    updateSelectizeInput(inputId = "exploration_participants", 
                         selected = input$processing_participants)
  })
  observeEvent(input$intraday_participant, {
    updateDateInput(
      inputId = "intraday_date",
      value = as.Date(time_period()$min_time[time_period()$id == input$intraday_participant]),
      min = as.Date(time_period()$min_time[time_period()$id == input$intraday_participant]),
      max = as.Date(time_period()$max_time[time_period()$id == input$intraday_participant])
    )
  })
  
  output$missingness <- renderPlot({
    minute_data() %>% 
      filter(id %in% input$exploration_participants) %>% 
      plot_missingness()
  })
  
  output$scatter <- renderPlot({
    reactive_data()$fitibble %>% 
      filter(id %in% input$exploration_participants) %>% 
      plot_intensity_scatter()
  })
  
  output$wear_heatmap <- renderPlot({
    reactive_data()$fitibble %>% 
      filter(id %in% input$exploration_participants) %>% 
      plot_wear_heatmap()
  })
  
  output$time_use <- renderPlot({
    plot_time_use(reactive_data()$fitibble, id = 1)
  })
  
  output$intra_day <- renderPlot({
    reactive_data()$fitibble %>% 
      plot_intraday(id = input$intraday_participant, 
                    date = input$intraday_date)
  })
  
  output$basic_summary <- renderPlot({
    plot_ci(reactive_data()$daily_summary, type = "basic")
  })
  
  output$sedentary_behavior_summary <- renderPlot({
    plot_ci(reactive_data()$daily_summary, type = "sedentary_behavior")
  })
  
  output$time_use_summary <- renderPlot({
    plot_ci(reactive_data()$daily_summary, type = "time_use")
  })
  
  output$daily_data <- downloadHandler(
    filename = "daily_data.csv",
    content = function(file) {
      readr::write_csv(prep_daily_data(reactive_data()$fitibble), file)
    }
  )
  
  output$daily_summary <- downloadHandler(
    filename = "daily_summary.csv",
    content = function(file) {
      readr::write_csv(reactive_data()$daily_summary, file)
    }
  )
  
}