require(shiny)
require(dplyr)
require(RCurl)
require(httr)
require(rvest)
require(readr)
set_config( config( ssl_verifypeer = 0L ) )

getChargesHTML <- function(case_number) {
  tryCatch({
    # Search for case
    search_url <- "https://www.courts.mo.gov/casenet/cases/caseFileSearch.do"
    search_headers <- list(courtId = "SW",
                           inputVO.caseNo = case_number,
                           findButton="Find",
                           inputVO.courtId="SW",
                           inputVO.caseNumber="",
                           inputVO.errFlag="Y",
                           inputVO.ocnNo="")
    search_resp <- POST(search_url, body = search_headers, encode = "form") 
    
    # Get case header
    case_header_url <- "https://www.courts.mo.gov/casenet/cases/header.do"
    
    # Extract circuit number from awful HTML tree
    xpath <- "/html/body/table/tbody/tr[2]/td/form/table/tr[2]/td/table/tr/td/table/tr[2]/td[3]/a"
    circuit <- search_resp %>% read_html() %>% html_node(xpath = xpath) %>%
      html_attr("href") %>% gsub("^.*', '([^']*)'.*$", "\\1", .)
    
    # Get case style while it's easy to get at
    xpath <- "/html/body/table/tbody/tr[2]/td/form/table/tr[2]/td/table/tr/td/table/tr[2]/td[4]"
    case_style <- search_resp %>% read_html() %>% html_node(xpath = xpath) %>% html_text(trim = T)
    
    case_header_headers <- list(inputVO.caseNumber = case_number,
                                inputVO.courtId = circuit)
    case_header_resp <- POST(case_header_url, body = case_header_headers, encode = "form")
    
    # Get charges
    charges_url <- "https://www.courts.mo.gov/casenet/cases/charges.do"
    
    # Extract headers from awful XML tree
    xpath <- "/html/body/table/tr[1]/td/table/tbody/tr[2]/td/table/tbody/tr[2]/td/form/input"
    inputs <- case_header_resp %>% read_html() %>% html_nodes(xpath = xpath)
    charges_headers <- html_attr(inputs, "value")
    names(charges_headers) <- html_attr(inputs, "name")
    charges_headers <- charges_headers %>% as.list
    charges_resp <- POST(charges_url, body = charges_headers, encode = "form")
    
    # Collect data
    xpath <- "/html/body/table/tr[1]/td/table/tbody/tr[2]/td/table/tbody/tr[1]/td/table"
    toptable <- charges_resp %>% read_html %>% html_nodes(xpath = xpath) %>% as.character %>%
      gsub("&amp;nbsp", "", .)
    xpath <- "//table[@class='detailRecordTable']"
    maintable <- charges_resp %>% read_html %>% html_nodes(xpath = xpath) %>% as.character
    c(toptable, maintable)
  }, error = function(e) { "" })
}

shinyServer(function(input, output) {

  chargesHTML <- reactive({
    case_numbers <- strsplit(input$case_numbers, "\n")[[1]] %>% gsub(" ", "", .) %>% toupper
    result <- c()
    if (length(case_numbers) > 0) {
      withProgress({
        for (i in 1:length(case_numbers)) {
          setProgress(i / length(case_numbers))
          case_number <- case_numbers[i]
          result <- c(result, getChargesHTML(case_number))
        }
      }, value = 0, message = "Retrieving cases...")
      HTML(result)
    } else {
      HTML("Please enter cases")
    }
  })
  
  output$results <- renderUI({ chargesHTML() })
})
