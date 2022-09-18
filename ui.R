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
    menuItemOutput("menu")
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
          fileInput("zip", "Fitabase zip file", accept = ".zip"),
          verbatimTextOutput("upload_message"), 
          verbatimTextOutput("upload_status")
        ), 
        dataTableOutput("timePeriod")
      )
    ),
    tabItem(
      tabName = "tab_exploration",
      fluidPage(
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Missing values",
            plotOutput("missingness")
          )
        )
      )
    ),
    tabItem(tabName = "tab_processing",
            h2("processing decisions")
    ),
    tabItem(tabName = "tab_summaries",
            h2("pa summaries")
    ),
    tabItem(tabName = "tab_downloads",
            h2("downloads")
    )
  )
)

# 
# body <- dashboardBody(
#   fluidPage(
#     box(
#       title = "Data Preparation",
#       width=12,
#       collapsible = T,
#       tabBox(
#         title = "",
#         width=12,
#         tabPanel("",
#                  verbatimTextOutput("message"),
#                  verbatimTextOutput("test")
#         ),
#         tabPanel("Missing values",
#                  plotOutput("missingness")
#         ),
#         tabPanel("Participant's ID summary",
#                  dataTableOutput("timePeriod")
#         )
#       )
#     ),
#     box(
#       title = "Data Exploration",
#       width=12,
#       collapsible = T,
#       tabBox(
#         title = "",
#         width=12,
#         tabPanel("",
#                  "xxx"
#         ),
#         tabPanel("Intensity levels",
#                  plotOutput("intensity_scatter")
#         )
#       )
#     ),
#     box(
#       title = "PA summaries",
#       width=12,
#       collapsible = T,
#       tabBox(
#         title = "",
#         width=12,
#         tabPanel("Tab1",
#                  "Tab content 1"
#         ),
#         tabPanel("Tab2",
#                  "Tab content 2"
#         )
#       )
#     )
#   )
# )

#### ####
# page
#### ####
dashboardPage(
  header,
  sidebar, 
  body
)
