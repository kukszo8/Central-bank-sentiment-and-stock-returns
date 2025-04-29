library(tidyverse)
library(elmer)

data <- read_rds("fed_speeches.rds")

set.seed(123)

examples <- data |> 
  sample_n(10)

example_texts <- examples |> 
  pull(text) |> 
  map_chr(str_flatten, collapse = "\n\n")

# elmer

chat <- chat_openai(model = "gpt-4o-mini")

type_forward_guidence <- type_object(
  "Analyze the following central bank text and extract details related to forward guidance.",
  tool = type_enum(
    description = "Specify the forward guidance tool mentioned",
    values = c("interest rates", "quantitative easing", "other", "none")
  ),
  magnitude = type_number(
    'Indicate the magnitude of the forward guidance, including its direction (positive or negative).'
  ),
  condition = type_string(
    "Conditions under which the forward guidance applies, if specified."
  ),
  time_horizon = type_string(
    'Identify the time frame for which the forward guidance is valid or relevant.'
  )
)

example_result <- map(example_texts, ~ chat$extract_data(.x, type = type_forward_guidence))

examples

example_texts[[3]] |> 
  cat(file = "example.txt")

example_result |> 
  map_df(~ as_tibble(.x)) |> 
  mutate(date = examples$date, .before = 1) |> 
  View()
