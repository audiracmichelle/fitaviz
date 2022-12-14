# server
library(fitibble)

function(input, output) {
  reactive_list <- reactiveValues(
    upload_message = "Upload a fitabase zip file.\nWait while fitaviz finishes preparing the dataset for analysis.\nThe rest of the compartment tabs remain empty until data is succesfully loaded."
  )

  output$upload_message <- renderText({
    reactive_list$upload_message
  })
  
  observeEvent(input$zip, {
    reactive_list$upload_message <- "Successful file upload and data preparation.\nWhen switching to a new tab, give the plots a few seconds to render.\nRestart the app to upload new data"
    
    ####
    # read files
    ####
    # zip_path = "/Users/audiracmichelle/GitHub/audiracmichelle/fitbit/data/input/export_1.zip"
    fitabase_files <- read_fitabase_files(input$zip$datapath)
    reactive_list$timePeriod <- fitabase_files$time_period
    reactive_list$minute_data <- prep_minute_data(fitabase_files)
    
    rm(fitabase_files)  
  })
  
  reactive_data <- reactive({
    fitibble(
      reactive_list$minute_data
    )
  })

  # output$upload_status <- renderText({
  #   input_data()$upload_status
  # })

  output$timePeriod <- renderDataTable({
    reactive_list$timePeriod %>%
      select(id, label, min_time, max_time, is_valid_time_period)
  })
  
  output$missingness <- renderPlot({
    reactive_list$minute_data %>% 
      plot_missingness()
  })
  
  output$scatter <- renderPlot({
    reactive_data() %>% 
      plot_intensity_scatter()
  })

}