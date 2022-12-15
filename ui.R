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
      h2("raw data exploration"), 
      fluidPage(
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Missing values",
            plotOutput("missingness")
          )
        ), 
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Intensity Levels",
            plotOutput("scatter")
          )
        )
      )
    ),
    tabItem(
      tabName = "tab_processing",
      h2("processing decisions"), 
      fluidPage(
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Wear heatmap",
            plotOutput("wear_heatmap")
          )
        ), 
        tabBox(
          title = "",
          width=12,
          tabPanel(
            "Time Use",
            plotOutput("time_use")
          )
        )
      )
    ),
    tabItem(
      tabName = "tab_summaries",
      h2("pa summaries"), 
      fluidPage(
        box(
          title = "Basic summary",
          width=12,
          plotOutput("basic_summary")
        ), 
        box(
          title = "Sedentary Behavior",
          width=12,
          plotOutput("sedentary_behavior_summary")
        ), 
        box(
          title = "Time Use",
          width=12,
          plotOutput("time_use_summary")
        )
      )
    ),
    tabItem(
      tabName = "tab_downloads",
      h2("downloads"),
      downloadButton("daily_data", "Daily data"), 
      downloadButton("daily_summary", "Daily summary")
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
