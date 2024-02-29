

########    LM dictionary   ########   


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



lm_sentiment<-letter_sentiment %>%
  count(date, sentiment) %>% 
  filter(sentiment %in% c("positive", "negative")) %>% 
  group_by(date) %>% 
  mutate(sum=sum(n)) %>% 
  pivot_wider(names_from = sentiment, values_from = n) %>% 
  mutate(lm_sentiment=(positive-negative)/sum)


library(hrbrthemes)

lm_sentiment %>% 
  mutate(year=lubridate::year(date)) %>% 
  filter(year>2018) %>% 
  ggplot(aes(x=date, y=lm_sentiment)) +
  geom_line( color="#69b3a2", linewidth=0.5, alpha=0.8) +
  theme_ipsum() +
  ggtitle("Evolution of Fed Sentiment index")


########    BN-dictionary   ########   


bn_sentiment_word<-data %>% 
  unnest(text) %>% 
  unnest_tokens(word, text,token="sentences") %>% 
  mutate(dovish_count=str_count(word,'collaps|contraction|dampen|decelerat|declin|decreas|delay|depression|destabili|deteriorat|difficul|diminish|disappear|downside|downswing|downturn|downward|fall|fragil|low|negative|poor|recession|slow|sluggish|small|struggling|sustainable|unfavourable|unstable|weak|worse'),
         hawk_count=str_count(word,'accelerat|better|boom|emerg|expansion|fast|favourabl|great|improve|increas|larger|positive|rais|ris|stabili|stable|strengthen|strong|unsustainable|upside|upswing|upturn|upward')) %>% 
  group_by(date) %>% 
  summarise(across(c(dovish_count,hawk_count), ~ sum(., na.rm = TRUE))) %>% 
  mutate(sum=dovish_count+hawk_count,
         bn_sent_index=(hawk_count-dovish_count)/sum)


##Compare the sentiment indices

bn_sentiment_word %>% 
  left_join(lm_sentiment %>% select(lm_sentiment),by="date") %>% 
  select(date,bn_sent_index,lm_sentiment) %>% 
  mutate(year=lubridate::year(date)) %>% 
  pivot_longer(c(-1,-4)) %>%
  ggplot(aes(date, value, group=name, color=name)) +
  geom_line() +
  facet_wrap(~name)



bn_sentiment_word %>% 
  left_join(lm_sentiment %>% select(lm_sentiment),by="date") %>% 
  select(date,bn_sent_index,lm_sentiment) %>% 
  mutate(dif=bn_sent_index-lm_sentiment,
         equal_check=case_when(
           (bn_sent_index>0&lm_sentiment>0) ~ "HAWKISH_egyezes",
           (bn_sent_index<0&lm_sentiment<0)~ "DOVISH_egyezes",
           TRUE~"nincs egyezes")) %>% 
  count(equal_check)



######## BN sentiment sentence  ########   


nouns= c("gdp|output|inflation|price")
hawk_sign=c("accelerat|better|boom|emerg|expansion|fast|favourabl|great|improve|increas|larger|positive|rais|ris|stabili|stable|strengthen|strong|unsustainable|upside|upswing|upturn|upward")
dow_sign=c("collaps|contraction|dampen|decelerat|declin|decreas|delay|depression|destabili|deteriorat|difficul|diminish|disappear|downside|downswing|downturn|downward|fall|fragil|low|negative|poor|recession|slow|sluggish|small|struggling|sustainable|unfavourable|unstable|weak|worse")


bn_sentiment<-data %>% 
  unnest(text) %>% 
  unnest_tokens(sentences, text,token="sentences") %>% 
  mutate(
    hawkish_n=str_count(sentences,hawk_sign),
    dovish_n=str_count(sentences,dow_sign),
    is_nouns=str_detect(sentences,nouns),
    is_nouns=ifelse(lead(is_nouns),TRUE,is_nouns),
    fin_stance=case_when(hawkish_n>dovish_n&is_nouns~"hawk",
                         hawkish_n<dovish_n&is_nouns~"dovish",
                         TRUE ~"OTHER"),
    char_n=str_length(sentences))

bn_sententence_sentiment <-bn_sentiment %>% 
  group_by(date) %>% 
  count(fin_stance) %>% 
  filter(fin_stance!="OTHER") %>% 
  pivot_wider(names_from=fin_stance,values_from=n,values_fill=0) %>% 
  mutate(sum=dovish+hawk,
    own_sent_index=(hawk-dovish)/(sum)) %>% 
  filter(sum>5)

##Correlation across the indices

bn_sentiment_word %>% 
  left_join(lm_sentiment %>% select(lm_sentiment),by="date") %>%
  left_join(bn_sententence_sentiment %>% select(own_sent_index),by="date") %>% 
  select(date,bn_sent_index,lm_sentiment,own_sent_index) %>% 
  select(-1) %>% 
  cor(use="pairwise.complete")



bn_sentiment_word %>% 
  left_join(lm_sentiment %>% select(lm_sentiment),by="date") %>% 
  left_join(bn_sententence_sentiment %>% select(own_sent_index),by="date") %>% 
select(date,bn_sent_index,lm_sentiment,own_sent_index) %>% 
  mutate(year=lubridate::year(date)) %>% 
  pivot_longer(c(-1,-5)) %>%
  ggplot(aes(date, value, group=name, color=name)) +
  geom_line() +
  facet_wrap(~name)
