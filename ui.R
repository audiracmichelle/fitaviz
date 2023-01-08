library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyBS)
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
      bsTooltip("nonwear", 
                "Fitbit is not equipped with a component that distinguish minutes the device is worn, thus processing methods are used to determine non-wear time. Full details of the methods in the Processing Parameters tab.",
                "right", 
                options = list(container = "body")),
      sliderInput(inputId = "hours_between", 
                  label = "Adherent hours between", 
                  min = 0, 
                  max = 24, 
                  value = c(8, 20), 
                  step = 1), 
      bsTooltip("hours_between", 
                "The adherent wear rule is applied at a minute-level data and is related to the study’s wear intructions. We say that a minute of wear is adherent when it occurs between the hours of the day that adhere to the study design and the wear instructions.",
                "right", 
                options = list(container = "body")),
      radioButtons(inputId = "valid_day_method",
                   label = "Valid day method",
                   choices = c("Valid adherent hours" = "valid_adherent_hours",
                               "Valid step count" = "valid_step_count")), 
      bsTooltip("valid_day_method", 
                "Cycles in PA are assumed to occure on a daily basis. The valid day criteria determine which days to include in an analysis.", 
                "right", 
                options = list(container = "body")), 
      conditionalPanel(
        condition = "input.valid_day_method == 'valid_adherent_hours'", 
        sliderInput(
          inputId = "minimum_adherent_hours",
          label = "Minimum adherent hours",
          min = 0, 
          max = 24, 
          value = 10, 
          step = 1
        ), 
        bsTooltip("minimum_adherent_hours", 
                  "Minimum number of hours of adherent wear in a day to consider it valid.", 
                  "right", 
                  options = list(container = "body"))
      ), 
      conditionalPanel(
        condition = "input.valid_day_method == 'valid_step_count'", 
        sliderInput(
          inputId = "minimum_step_count",
          label = "Minimum step count",
          min = 0,
          max = 5000,
          value = 1000, 
          step = 500
        ), 
        bsTooltip("minimum_step_count", 
                  "Minimum number of steps in a day to consider it valid.", 
                  "right", 
                  options = list(container = "body"))
      )
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
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Data upload",
            fileInput("zip", "Fitabase zip file", accept = ".zip"), 
            shinycssloaders::withSpinner(dataTableOutput("time_period"))
          ), 
          tabPanel(
            "Data preparation description",
            HTML(read_file("guides/guide_preparation.html"))
          )
        )
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
          ), 
          tabPanel(
            "Plot description",
            HTML(read_file("guides/guide_missing.html"))
          )
        ), 
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Intensity Levels",
            shinycssloaders::withSpinner(plotOutput("scatter"))
          ), 
          tabPanel(
            "Plot description",
            HTML(read_file("guides/guide_intensity.html"))
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
          ), 
          tabPanel(
            "Plot description",
            HTML(read_file("guides/guide_heatmap.html"))
          )
        ),
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Time Use",
            shinycssloaders::withSpinner(plotOutput("time_use"))
          ), 
          tabPanel(
            "Plot description",
            HTML(read_file("guides/guide_timeuse.html"))
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
