########################################################################################################
#
# MPCE Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Generating training data for Dedupe
#
# Author: Michael Falk
#
# Date: 19/11/18
#
########################################################################################################

# In an effort to improve the accuracy of our intelligent deduper, this script generates a few thousand
# training pairs for the model to work with.

library(tidyverse)
library(rjson)
library(magrittr)

# Import the data
data <- read_csv("combined_editions_illegal_books.csv")

# Initialise the list
training_data = list()
training_data$distinct = list()
training_data$match = list()

# Start with "distinct". We want 1000 random pairs of books that are not the same.
for (i in seq(1:1000)) {
  # Select first book from among those with super_book_codes
  book1 <- data %>%
    filter(!is.na(super_book_code)) %>% # books with codes
    sample_n(1) %>% # get one
    unlist() # convert to named vector
  
  # Select second, non-matching book
  book2 <- data %>%
    filter(!is.na(super_book_code) & # books with codes
           super_book_code != book1["super_book_code"]) %>% # that don't match book 1
    sample_n(1) %>% # get one
    unlist() # convert to named vector
  
  # Now add to the list
  training_data$distinct[[i]] <- list() # create new entry
  training_data$distinct[[i]][[1]] <- book1
  training_data$distinct[[i]][[2]] <- book2
}

# Now add to "matches." First we want to include all the illegal books that already have super_book_codes
coded_illegals <- data %>%
  filter(!is.na(UUID) & !is.na(super_book_code))

for (i in 1:nrow(coded_illegals)) {
  # Select first book from among those with super_book_codes
  book1 <- coded_illegals[i,] %>%
    unlist() # convert to named vector
  
  # Select second, matching book from among the rest
  book2 <- data %>%
    filter(super_book_code == book1["super_book_code"]) %>% # find books that match book 1
    sample_n(1) %>% # choose one
    unlist() # convert to named vector
  
  # Now add to the list
  training_data$match[[i]] <- list() # create new entry
  training_data$match[[i]][[1]] <- book1
  training_data$match[[i]][[2]] <- book2
}

# Add another 500 matches for good measure
start <- length(training_data$match) + 1 # start after the end of the illegal books matches (don't want to overwrite!)
for (i in start:(start + 500)) {
  # Select first book from among those with super_book_codes
  book1 <- data %>%
    filter(is.na(UUID) & # ignore illegal books, we've been through those already
             !is.na(super_book_code)) %>% # books with codes
    sample_n(1) %>% # get one
    unlist() # convert to named vector
  
  # Select second, matching book
  book2 <- data %>%
    filter(is.na(UUID) & # ignore illegal books
             !is.na(super_book_code) & # books with codes
             super_book_code == book1["super_book_code"]) %>% # that match book 1
    sample_n(1) %>% # get one
    unlist() # convert to named vector
  
  # Now add to the list
  training_data$match[[i]] <- list() # create new entry
  training_data$match[[i]][[1]] <- book1
  training_data$match[[i]][[2]] <- book2
}


training_json = toJSON(training_data) %>%
  str_replace_all("\\\"NA\\\"", "null") # change NAs into nulls
write(training_json, file = "marked_pairs.json")
