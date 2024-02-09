library("tidyverse")
library("rvest")
library("jsonlite")


url <- "https://www.federalreserve.gov/json/ne-speeches.json" 


data<-read_json(url) %>%
  tibble(date = map(., "d"),
         title = map(., "t"),
         speaker = map(., "s"),
         base_link=map(., "l")) %>% 
  unnest(base_link) %>% 
  mutate(
         fin_link=str_c("https://www.federalreserve.gov",base_link),
         page = map(fin_link, read_html),
         nodes = map(page, ~ html_nodes(., "p")),
         text = map(nodes, html_text))
