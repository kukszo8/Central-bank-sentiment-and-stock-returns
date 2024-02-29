#### Fama French returns ###
return_data<-read.csv("C:/Users/User/Documents/TDK_2.0/Fed sentiment and stock returns/F-F_Research_Data_5_Factors_2x3_daily.csv",sep=";",header = TRUE) %>% 
  tibble() %>% 
  mutate(date=as.Date(as.character(date),          # as.Date & as.character functions
                      format = "%Y%m%d"))

sent_combined<-bn_sentiment_word %>% 
  full_join(lm_sentiment %>% select(lm_sentiment),by="date") %>% 
  full_join(bn_sententence_sentiment %>% select(own_sent_index),by="date") %>% 
  select(date,bn_sent_index,lm_sentiment,own_sent_index) %>% 
  pivot_longer(-1) %>% 
  group_by(name) %>% 
  nest() %>% 
  mutate(data = map(data, ~drop_na(.)),
data=map(data,~mutate(.x,hour_check=lubridate::hour(date))),
data=map(data,~filter(.,hour_check<17)),
data = map(data, ~ mutate(.x, date=as.Date(substr(date,1,10)))),
data = map(data, ~select(.,-hour_check))) %>% 
  unnest() %>% 
  group_by(name,date) %>% 
  mutate(value_avg=mean(value)) %>% 
  distinct(name, name, .keep_all = TRUE) %>% 
  group_by(name) %>% 
  nest() 

join_df <- function(df_nest, df_other) {
  df_all <- left_join(df_nest, df_other, by = c("date" = "date"))
  return(df_all)
}

df_full<- sent_combined%>% 
  mutate(new_df = map(data, ~ join_df(., return_data))) %>% 
  select(-2) 

df_full %>%
  mutate(
    models = map(new_df, ~lm(value_avg~ SMB, data = .))) %>% 
  mutate(glance = map(models, broom::glance)) %>% 
  select(name, glance) %>%
  unnest(glance)






  
df_full <-df_full %>% 
 unnest(new_df)

reg_across_groups <- function(df, var) {
  
  var <- ensym(var)
  df <- df %>% 
    group_by(name) %>% 
    nest() 
  
  model_formula <- formula(paste0("value_avg ~", var ))
  
  df %>% 
    dplyr::mutate(model = purrr::map(data, ~lm(model_formula, data = .x)))
}


result_all<-
c("Mkt.RF","SMB", "HML","RMW","CMA") %>% 
  map(~ reg_across_groups(df_full, !!.x)) %>% 
  tibble() %>% 
  rename(data=1) %>% 
  mutate(names=c("Mkt.RF","SMB", "HML","RMW","CMA")) %>% 
  unnest(data) %>% 
  mutate(glance = map(model, broom::glance)) %>% 
  unnest(glance) %>% 
  arrange(p.value)


