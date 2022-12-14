# ui

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(plotly)

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
      menuSubItem("PA summaries", tabName = "tab_summaries"),
      menuSubItem("Downloads", tabName = "tab_downloads")
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
          title = "File upload", 
          width=12,  
          fileInput("zip", "Fitabase zip file", accept = ".zip"), #will not execute the reactive function that loads the data
          verbatimTextOutput("upload_message")#,  
          #verbatimTextOutput("upload_status") #a quick fix to force the execution of the reactive function that loads the data
        ), 
        box(
          title = "Data preparation summary", 
          width=12,  
          dataTableOutput("timePeriod")
        ), 
      )
    ),
    tabItem(
      tabName = "tab_exploration",
      fluidPage(
        box(
          title = "Missing values",
          width=12,
          plotOutput("missingness")
        ), 
        box(
          title = "Intensity levels",
          width=12,
          plotOutput("scatter")
        )
      )
    ),
    tabItem(tabName = "tab_processing",
            h2("processing decisions"), 
            textInput(
              label = "Intensity column name",
              inputId = "intensity_colname", 
              value = "intensity"),
            textInput(
              label = "Intensity levels",
              inputId = "intensity_levels", 
              value = "c(sedentary = 0, light = 1, moderate = 2, active = 3)"
            )
    ),
    tabItem(tabName = "tab_summaries",
            h2("pa summaries")
    ),
    tabItem(tabName = "tab_downloads",
            h2("downloads")
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
