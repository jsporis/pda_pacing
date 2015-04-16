require(RJDBC)
require(ggplot2)
require(reshape)
require(scales)


shinyServer(function(input, output) {

source("PDA_report.R")


## PDA VISITS
  
output$visitchart <- renderPlot({
    print(daily.chart)
  })


output$visitpacing <- renderText({
    visit_pacing_score
  })


output$visitcurrent <- renderText({
  visits.current
})




## PDA LEADS

output$leadchart <- renderPlot({
  print(daily.lead.chart)
})


output$leadpacing <- renderText({
  lead_pacing_score
})


output$leadcurrent <- renderText({
  leads.current
})




})