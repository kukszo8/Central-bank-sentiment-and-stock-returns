
url <- "https://www.federalreserve.gov/json/ne-speeches.json" 


data<-read_json(url) %>%
  tibble(date = map(., "d"),
         title = map(., "t"),
         speaker = map(., "s"),
         base_link=map(., "l")) %>% 
  unnest(base_link)%>% 
  mutate(
    fin_link=str_c("https://www.federalreserve.gov",base_link),
    page = map(fin_link, read_html),
    nodes = map(page, ~ html_nodes(., "p")),
    text = map(nodes, html_text)) %>% 
  select(2,3,4,9) %>% 
  mutate(nchar=nchar(date),
         date=ifelse(nchar<15,str_c(date," 3:00:00 PM"),date)) %>% ##Correction of dates where hour and minute is not available
  mutate(date=map(date,~lubridate::mdy_hms(.,quiet=TRUE))) %>% 
  unnest(date) %>% 
  mutate(year=lubridate::year(date))


