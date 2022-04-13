#ui

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(plotly)

options(shiny.maxRequestSize = 100*1024^2)

#### ####
# header
#### ####
header <- dashboardHeader()

#### ####
# sidebar
#### ####
sidebar <- dashboardSidebar(
  sidebarMenu(
    fileInput("zip", "Choose zip", accept = ".zip")
  ) 
)

#### ####
# body
#### ####
body <- dashboardBody(
  fluidRow(
    box(
      title = "message", 
      width=12, 
      verbatimTextOutput("message")
    )
  ),
  fluidRow(
    box(
      title = "files", 
      width=12, 
      dataTableOutput("files")
    )
  ), 
  fluidRow(
    box(
      title = "timePeriod", 
      width=12, 
      dataTableOutput("timePeriod")
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