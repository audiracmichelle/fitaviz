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
                   label = "Nonwear: missing steps and ",
                   choices = c(
                     "missing HR" = "missing_HR", 
                     "missing HR along zero steps" = "missing_HR_zero_steps"
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
                  step = 1),
      radioButtons(inputId = "trend_input",
                   label = "Trend input",
                   choices = c(
                     "steps" = "steps",
                     "sedentary prop" = "sedentary_prop",
                     "lipa prop" = "lipa_prop",
                     "mvpa prop" = "mvpa_prop",
                     "sedentary bout mean" = "sedentary_bout_mean"
                   ),
                   selected = 'sedentary_prop')
    )
  ),
  dashboardBody(
    fluidRow(
      # box(
      #   title = "Weartime heatmap", 
      #   width = 6,
      #   plotOutput("weartime_heatmap"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   title = "Daily weartime", 
      #   width = 6, 
      #   plotOutput("weartime"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   title = "Daily total steps", 
      #   width = 6, 
      #   plotOutput("steps"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   title = "Sedentary bout length", 
      #   width = 6, 
      #   plotOutput("sedentary_bout"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   title = "PA allocation", 
      #   width = 12, 
      #   plotOutput("pa"), 
      #   collapsible = TRUE
      # ), 
      # box(
      #   "(Gilchrist) Tertile cutoff points:",
      #   br(), 
      #   "709.7(0.74) - 782.6(0.815) min/16-h day (proportion of weartime)",
      #   title = "Summary", 
      #   width = 12, 
      #   tableOutput('table'), 
      #   collapsible = TRUE
      # ), 
      box(
        title = "Time trend", 
        width = 12, 
        plotOutput("trend_filter"), 
        collapsible = TRUE
      ), 
      box(
        title = "Day of week activity component", 
        width = 12, 
        plotOutput("seasonal"), 
        collapsible = TRUE
      )
    )
  )
)
