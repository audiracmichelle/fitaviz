# server

function(input, output) {
  reactive_list <- reactiveValues(
    upload_message = "Upload a fitabase zip file. Please wait while\nfitaviz finishes preparing the dataset for analysis."
  )

  output$upload_message <- renderText({
    reactive_list$upload_message
  })
  
  output$menu <- renderMenu({
    if(!reactive_list$upload_message == "") {
      sidebarMenu(
        menuItem(
          "Compartment 1", 
          startExpanded = TRUE, 
          menuSubItem("Data preparation", tabName = "tab_preparation")
        )
      )
    } else {
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
  
  reactive_data <- reactive({
    zip_path <- req(input$zip$datapath)
    reactive_list$upload_message <- ""
    reactive_data <- list()
    
    reactive_data$upload_status = "The analysis dataset is ready."

    ####
    # read files
    ####
    #zip_path <- "/Users/audiracmichelle/GitHub/audiracmichelle/fitbit/data/input/test.zip"
    fitabase_files <- read_fitabase_files(zip_path)
    reactive_data$timePeriod <- fitabase_files$time_period
    reactive_data$minute_data <- prep_minute_data(fitabase_files)
    rm(fitabase_files)
    reactive_data$fitibble <- fitibble(reactive_data$minute_data)
    reactive_data$daily_summary <- prep_daily_summary(reactive_data$fitibble)

    reactive_data
  })

  output$upload_status <- renderText({
    reactive_data()$upload_status
  })

  output$timePeriod <- renderDataTable({
    reactive_data()$timePeriod %>%
      select(id, label, min_time, max_time, is_valid_time_period)
  })
  
  output$missingness <- renderPlot({
    plot_missingness(reactive_data()$minute_data)
  })
  
  output$scatter <- renderPlot({
    plot_intensity_scatter(reactive_data()$fitibble)
  })
  
  output$wear_heatmap <- renderPlot({
    plot_wear_heatmap(reactive_data()$fitibble)
  })
  
  output$time_use <- renderPlot({
    plot_time_use(reactive_data()$fitibble, id = 1)
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