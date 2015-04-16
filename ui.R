require(shiny)


shinyUI(fluidPage(

tags$head(
          tags$link(rel = "stylesheet", type = "text/css", href = "pdatheme.css")
),

##------------------------------------------------------DOCUMENT HEADER

fluidRow(
  column(12, 
         tags$h2("PDA PACING DASHBOARD"),
         tags$br(),
         span(id='sub',"This dashboard evaluates how the current month metrics are pacing against the prior month."),
         tags$br(),
         tags$p(),
         tags$br()
)
),tags$p(),

tabsetPanel(

  ##------------------------------------------------------PDA TOTAL PANEL
  tabPanel(tags$span(id="tab","PDATeam.com STATS"),
           tags$br(),
           div(
             fluidRow(
               column(4,
                      tags$div(id='section',"VISIT PACING"),tags$br(),
                      
                      fluidRow(id="bText1","CURRENT MONTH VISITS ARE PACING AT"),
                      fluidRow(id="eText",textOutput("visitpacing")),
                      fluidRow(id="bText2","COMPARED TO THE PREVIOUS MONTH"),
                      
                      tags$br(),tags$hr(),tags$br(),
                      
                      
                      fluidRow(id="bText1","CURRENT MONTH VISITS"),
                      fluidRow(id="eText",textOutput("visitcurrent"))
               ),
               
               column(8,
                      tags$div(id="section","VISIT CHART"),
                      
                      plotOutput("visitchart", height=550, width = "auto") 
               )
             )
           ),
           
           tags$p(),
           div(
             fluidRow(
               column(4,
                      tags$div(id='section',"LEAD PACING"),tags$br(),
                      
                      fluidRow(id="bText1","CURRENT MONTH LEADS ARE PACING AT"),
                      fluidRow(id="eText",textOutput("leadpacing")),
                      fluidRow(id="bText2","COMPARED TO THE PREVIOUS MONTH"),
                      
                      tags$br(),tags$hr(),tags$br(),
                      
                      
                      fluidRow(id="bText1","CURRENT MONTH LEADS"),
                      fluidRow(id="eText",textOutput("leadcurrent"))
               ),
               
               column(8,
                      tags$div(id="section","LEAD CHART"),
                      
                      plotOutput("leadchart", height=550, width = "auto") 
               )
             )
           )
             
  )
  
)#END TAB SET    
))##END


