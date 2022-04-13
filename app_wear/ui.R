#ui.R

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(plotly)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(
    sidebarMenu(
      radioButtons(inputId = "nonwear",
                   label = "Nonwear: (missing steps and) ",
                   choices = c(
                     "missing HR" = "missing_HR", 
                     "missing HR along zero steps" = "missing_HR_zero_steps",
                     "predicted" = "pred"
                   ),
                   selected = 'missing_HR'), 
      radioButtons(inputId = "eight_to_eight",
                   label = "Eight to eight",
                   choices = c(
                     "on" = "on", 
                     "off" = "off"
                   ),
                   selected = 'off'), 
      sliderInput(inputId = "adherent", 
                  label = "Min adherent hours", 
                  min = 0, 
                  max = 24, 
                  value = 10, 
                  step = 1), 
      sliderInput(inputId = "thresholds", 
                  label = "Step per min thresholds", 
                  min = 5, 
                  max = 100, 
                  value = c(15,60), 
                  step = 1)
    )
  ),
  dashboardBody(
    fluidRow(
      box(
        title = "Daily data", 
        footer = "Observation period of participants. Color represents the daily number of hours of wear or non-wear.", 
        width = 6,
        plotOutput("weartime"), 
        collapsible = TRUE
      ),
      box(
        title = "Weartime heatmap", 
        footer = "Participants' proportion of weartime for each hour of the day and day of the week within the observation period.", 
        width = 6,
        plotOutput("weartime_heatmap"), 
        collapsible = TRUE
      ), 
      # box(
      #   title = "Daily weartime", 
      #   width = 6, 
      #   plotOutput("weartime"), 
      #   collapsible = TRUE
      # ), 
      box(
        title = "Daily total steps", 
        footer = "Total number of steps per day for each participant.",
        width = 6, 
        plotOutput("steps"), 
        collapsible = TRUE
      ), 
      box(
        title = "Sedentary bout length", 
        footer = "q25-q75 ribbons and median length of sedentary bouts in a day.",
        width = 6, 
        plotOutput("sedentary_bout"), 
        collapsible = TRUE
      ), 
      box(
        "Time (total number of minutes per day) spent in sedentary activity, light activity (LIPA) or moderate to vigorous activity (MVPA).",
        title = "PA allocation", 
        footer = "Classification of activity-level based on steps per min cut-offs.",
        width = 12, 
        plotOutput("pa"), 
        collapsible = TRUE
      ), 
      box(
        "Participants can be stratified into tertiles according to the average daily proportions of weartime in sedentary activity. Tertile cutoff points from Gilchrist et al:",
        br(), 
        "* Most active group: less than 0.74",
        br(), 
        "* Middle group: between 0.74 and 0.815",
        br(), 
        "* Less active group: more than 0.815",
        footer = "In the paper the original units of the tertile cut-offs are total number of minutes in a 16 hour day (709.7 - 782.6  min/16-h day).",
        title = "Summary", 
        width = 12, 
        dataTableOutput('table'), 
        collapsible = TRUE
      )#
      # box(
      #   title = "Sedentary time trend", 
      #   width = 12, 
      #   plotOutput("trend_filter"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   title = "Sedentary seasonal component", 
      #   width = 12, 
      #   plotOutput("seasonal"), 
      #   collapsible = TRUE
      # )
    )
  )
)
