library(magrittr)
library(tidyverse)
library(tidytext)
library(tidyquant)
library(pins)
library(knitr)
library(fuzzyjoin)
library(rvest)
library(jsonlite)
library(ggplot2)


suppressMessages({
  tryCatch({
    od <- Microsoft365R::get_business_onedrive(tenant = "common")
    
    if (od$properties$owner$user$displayName == "Granát Marcell Péter") {
      board <- board_ms365(
        drive = od, 
        path = "csr_reports"
      )
    } else {
      shared_items <- od$list_shared_files()
      folder_to_board <- shared_items$remoteItem[[which(shared_items$name == "csr_reports")]]
      if (!exists("folder_to_board")) message("You need access to the data")
      board <- board_ms365(od, folder_to_board)
    }
    
  })
})