library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyWidgets)
library(tidyverse)
library(magrittr)
library(fitibble)

options(shiny.maxRequestSize = 750*1024^2) #750MB=750*1024^2

#### ####
# header
#### ####
header <- dashboardHeader(
  title = "Fitaviz"
)

#### ####
# sidebar
#### ####
sidebar <- dashboardSidebar(
  sidebarMenu(
    id = "tabs",
    menuItemOutput("menu"), 
    conditionalPanel(
      condition = "input.tabs == 'tab_processing' || input.tabs == 'tab_summaries'",
      radioButtons(inputId = "nonwear",
                   label = "Nonwear method",
                   choices = c(
                     "Missing HR" = "missing_HR", 
                     "Missing HR along zero steps" = "missing_HR_zero_steps",
                     "Choi on HR" = "choi_HR",
                     "Choi on steps" = "choi_steps", 
                     "None" = "none"
                   )), 
      sliderInput(inputId = "hours_between", 
                  label = "Adherent hours between", 
                  min = 0, 
                  max = 24, 
                  value = c(8, 20), 
                  step = 1), 
      radioButtons(inputId = "valid_day_method",
                   label = "Valid day method",
                   choices = c("Valid adherent hours" = "valid_adherent_hours",
                               "Valid step count" = "valid_step_count"))
    )
  )
)

#### ####
# body
#### ####
body <- dashboardBody(
  tabItems(
    tabItem(
      tabName = "tab_preparation", 
      fluidPage(
        box(
          width=12, 
          headerBorder = FALSE, 
          fileInput("zip", "Fitabase zip file", accept = ".zip")
        ), 
        #verbatimTextOutput("upload_status"),
        shinycssloaders::withSpinner(dataTableOutput("time_period"))
      )
    ),
    tabItem(
      tabName = "tab_exploration", 
      h2("Raw data exploration"), 
      fluidPage(
        box(
          title = "Participants", 
          width=12, 
          selectizeInput(inputId = "exploration_participants",
                         label = 'Choose a maximum of 10 participants to plot.', 
                         choices = NULL, 
                         options = list(minItems = 1, maxItems = 10))
        ),
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Missing values",
            shinycssloaders::withSpinner(plotOutput("missingness"))
          )
        ), 
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Intensity Levels",
            shinycssloaders::withSpinner(plotOutput("scatter"))
          )
        )
      )
    ),
    tabItem(
      tabName = "tab_processing",
      h2("Processing decisions"), 
      fluidPage(
        box(
          title = "Participants", 
          width=12, 
          selectizeInput(inputId = "processing_participants",
                         label = 'Choose a maximum of 10 participants to plot.', 
                         choices = NULL, 
                         options = list(minItems = 1, maxItems = 10))
        ),
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Wear heatmap",
            shinycssloaders::withSpinner(plotOutput("wear_heatmap"))
          )
        ),
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Time Use",
            shinycssloaders::withSpinner(plotOutput("time_use"))
          )
        ), 
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Intra-day",
            selectInput(inputId = "intraday_participant", 
                        label = "Choose a participant", 
                        choices = NULL), 
            dateInput(inputId = "intraday_date", 
                      label = "Choose a date"),
            shinycssloaders::withSpinner(plotOutput("intra_day"))
          )
        )
      )
    ),
    tabItem(
      tabName = "tab_summaries",
      h2("PA summaries"), 
      fluidPage(
        box(
          title = "Basic summary",
          width=12,
          shinycssloaders::withSpinner(plotOutput("basic_summary"))
        ), 
        box(
          title = "Sedentary Behavior",
          width=12,
          shinycssloaders::withSpinner(plotOutput("sedentary_behavior_summary"))
        ), 
        box(
          title = "Time Use",
          width=12,
          shinycssloaders::withSpinner(plotOutput("time_use_summary"))
        )
      )
    ),
    tabItem(
      tabName = "tab_downloads",
      h2("Downloads"), 
      fluidPage(
        box(
          title = "Daily data summary",
          width=6,
          downloadButton("daily_data", "Daily data")
        ), 
        box(
          title = "Daily summary",
          width=6,
          downloadButton("daily_summary", "Daily summary")
        )
      )
    )
  )
)

#### ####
# page
#### ####
dashboardPage(
  header,
  sidebar, 
  body
)
