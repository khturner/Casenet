require(shiny)

shinyUI(fluidPage(
  titlePanel("Collate Case.net charges, judgements, and sentences"),
  sidebarLayout(
    sidebarPanel(
      h3("Input case numbers:"),
      tags$textarea(id="case_numbers", rows=10, cols=25),
      submitButton("Submit!"),
      "Contact Keith Turner", a("(khturner@gmail.com)", href="mailto:khturner@gmail.com"),
      "with questions, comments, or to report bugs",
      width = 3
    ),
    mainPanel(
      dataTableOutput("results"),
      downloadButton("download", "Download"),
      width = 9
    )
  )
))
