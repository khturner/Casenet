require(shiny)

shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
      @import url('https://www.courts.mo.gov/casenet/styles/casenet.css');
    "))
  ),
  titlePanel("Collate Case.net charges, judgements, and sentences"),
  tabsetPanel(
    tabPanel("Input case numbers",
      tags$textarea(id="case_numbers", rows=10, cols=25),
      hr(),
      "Contact Keith Turner", a("(khturner@gmail.com)", href="mailto:khturner@gmail.com"),
      "with questions, comments, or to report bugs"
    ),
    tabPanel("Charges, judgements, sentences",
      htmlOutput("results")
    )
  )
))
