# This file is for messing around with stuff

require(RCurl)
require(httr)
require(rvest)
set_config( config( ssl_verifypeer = 0L ) )

case_number <- "10SL-CR09964-0butt"

# Get search results
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
xpath <- "/html/body/table/tr[2]/td/table/tr[position()>1]/td/table/tr[2]/td[2]"
descriptions <- charges_resp %>% read_html() %>% html_nodes(xpath = xpath) %>%
  html_text(trim = T) %>% gsub("[\r\n\t]", "", .)
xpath <- "/html/body/table/tr[2]/td/table/tr[position()>1]/td/table/tr[3]/td[2]"
dates <- charges_resp %>% read_html() %>% html_nodes(xpath = xpath) %>% html_text(trim = T)
xpath <- "/html/body/table/tr[2]/td/table/tr[position()>1]/td/table/tr[3]/td[4]"
codes <- charges_resp %>% read_html() %>% html_nodes(xpath = xpath) %>% html_text(trim = T)
xpath <- "/html/body/table/tr[2]/td/table/tr[position()>1]/td/table/tr[4]/td[2]"
ocns <- charges_resp %>% read_html() %>% html_nodes(xpath = xpath) %>% html_text(trim = T)
xpath <- "/html/body/table/tr[2]/td/table/tr[position()>1]/td/table/tr[4]/td[6]"
agencies <- charges_resp %>% read_html() %>% html_nodes(xpath = xpath) %>% html_text(trim = T)

# Build final df
result <- data.frame(case_number = case_number, case_style = case_style,
                     description = descriptions, date = dates, code = codes,
                     ocn = ocns, agency = agencies, stringsAsFactors = F) %>% tbl_df

# Can I just grab the whole thing
xpath <- "/html/body/table/tr[2]/td/table/tr[2]"
charges_resp %>% read_html() %>% html_nodes(xpath = xpath)

