
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
  select(2,3,4,9)%>% 
  mutate(date=map(date,~lubridate::mdy_hms(.,quiet=TRUE))) %>% 
  unnest(date) %>% 
  mutate(year=lubridate::year(date))%>% 
  
  lm_data<-data %>% 
  unnest(text) %>% 
  unnest_tokens(word, text) %>% 
  add_count(year) %>%
  rename(year_total = n)


get_sentiments("loughran") %>%
  count(sentiment, sort = TRUE)

letter_sentiment <- lm_data %>%
  inner_join(get_sentiments("loughran"))



letter_sentiment %>%
  count(year, year_total, sentiment) %>%
  filter(sentiment %in% c("positive", "negative", 
                          "uncertainty", "litigious")) %>%
  mutate(sentiment = factor(sentiment, levels = c("negative",
                                                  "positive",
                                                  "uncertainty",
                                                  "litigious"))) %>%
  ggplot(aes(year, n / year_total, fill = sentiment)) +
  geom_area(position = "identity", alpha = 0.5) +
  labs(y = "Relative frequency", x = NULL,
       title = "Sentiment analysis of Fed speeches",
       subtitle = "Using the Loughran-McDonald lexicon")        


letter_sentiment %>%
  count(sentiment, word) %>%
  filter(sentiment %in% c("positive", "negative", 
                          "uncertainty", "litigious")) %>%
  group_by(sentiment) %>%
  top_n(15) %>%
  ungroup %>%
  mutate(word = reorder(word, n)) %>%
  mutate(sentiment = factor(sentiment, levels = c("negative",
                                                  "positive",
                                                  "uncertainty",
                                                  "litigious"))) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(alpha = 0.8, show.legend = FALSE) +
  coord_flip() +
  scale_y_continuous(expand = c(0,0))+
  facet_wrap(~sentiment, scales = "free") +
  labs(x = NULL, y = "Total number of occurrences",
       title = "Words driving sentiment scores in Fed speeches",
       subtitle = "From the Loughran-McDonald lexicon")



sentiment_index<-letter_sentiment %>%
  count(date, sentiment) %>% 
  filter(sentiment %in% c("positive", "negative")) %>% 
  group_by(date) %>% 
  mutate(sum=sum(n)) %>% 
  pivot_wider(names_from = sentiment, values_from = n) %>% 
  mutate(sentiment=(positive-negative)/sum)


library(hrbrthemes)

sentiment_index %>% 
  mutate(year=lubridate::year(date)) %>% 
  filter(year>2018) %>% 
ggplot(aes(x=date, y=sentiment)) +
  geom_line( color="#69b3a2", linewidth=0.5, alpha=0.8) +
  theme_ipsum() +
  ggtitle("Evolution of Fed Sentiment index") 
