########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Helper function
#
# Authors: Michael Falk
#
# Date: 14/1/18
#
# This script loads the necessary libaries, connects to the local manuscripts and MMF databases,
# and defines a useful string similarity function for use in MPCE record linkage tasks.
#
########################################################################################################

library(tidyverse) # for data manipulation
library(magrittr) # for a more powerful piping operator
library(DBI) # to enable database connection
library(RMySQL) # a simple API for connecting to a MySQL database
library(stringdist) # string distance measures
library(httr)
library(xml2)

stringsimmatrix <- function(a, b, method = 'osa') {
  #
  # Computes a string similarity matrix for all pairs of words in two character vectors.
  #
  # Params:
  #   a: a character vector
  #   b: a character vector
  #   c: the chosen similarity method
  #
  message("Computing similarity using ", method, "...")
  
  # Start timer
  tick <- Sys.time()
  
  sim_vecs <- lapply(a, function(x) {
    stringsim(x, b, method = method) # Compare each item in a with all of b
  })
  sim_vecs <- unlist(sim_vecs) # Turn list into long vector
  sim_mat <- matrix(sim_vecs, nrow = length(a), ncol = length(b), byrow = T) # Reshape into matrix
  
  # End timer
  tock <- Sys.time()
  t <- tock - tick
  message("Complete. It took ", t, " second", if(t > 1){"s"}, ".")
  
  return(sim_mat)
}

compute_pairwise_similarities <- function(tbl, id_col, str_col, thresh = 0.8) {
  
  id_1 <- rlang::enquo(id_col)
  str_1 <- rlang::enquo(str_col)
  id_2 <- rlang::enquo(id_col)
  str_2 <- rlang::enquo(str_col)
  
  vec1 <- pull(tbl, !!str_1)
  vec2 <- pull(tbl, !!str_2)
  
  # First compute pairwise comparisons
  dist_mat <- stringdistmatrix(vec1, vec2, method = 'osa')
  row_len <- str_length(vec1) %>%
    matrix(length(vec1), length(vec1))
  col_len <- str_length(vec2) %>%
    matrix(length(vec2), length(vec2)) %>%
    t()
  fil_mat <- pmax(row_len, col_len)
  sim_mat <- 1 - (dist_mat / fil_mat)
  
  # Keep those that are above the threshold
  above_thresh <- which(sim_mat > thresh, arr.ind = T) %>%
    # Just keep lower triangle
    .[which(.[,1] > .[,2]),]
  
  if (length(dim(above_thresh)) == 2) {
    out <- tibble(
      id_1 = pull(tbl, !!id_1)[above_thresh[,1]],
      str_1 = pull(tbl, !!str_1)[above_thresh[,1]],
      id_2 = pull(tbl, !!id_2)[above_thresh[,2]],
      str_2 = pull(tbl, !!str_2)[above_thresh[,2]],
      osa = sim_mat[above_thresh]
    ) %>%
      mutate(
        cos = stringsim(as.character(str_1), as.character(str_2), method = "cosine")
      ) %>%
      arrange(desc(osa), desc(cos))
  } else {
    out = NULL
  }
  
  return(out)
}

parenthise <- function(tbl) {
  ###
  #
  # Exports tibble as a string of SQL-escaped records in parentheses
  #
  # Params:
  #   tbl: (tibble) a tibble of the data to be exported
  #
  ###
  
  out <- tbl %>% 
    # Put all the strings in quotation marks
    mutate_if(is.character, function(x) paste0('"', x, '"')) %>%
    # Paste them together
    unite(col = "rows", sep = ", ") %>%
    # Put parentheses around each row
    mutate(
      rows = paste0("(", rows, ")")
    ) %>%
    # Collapse into a character vector
    pull(rows) %>%
    # paste
    paste(collapse = ", ") 
  
  return(out)
}

fetch_table <- function(con, tbl_name) {
  # Helper function that selects an entire table.
  #
  # Params:
  #   con (connection): the databse where the table is
  #   tbl_name (str): the name of the table in the database
  #
  # Returns:
  #   out (tbl): a tibble of the data
  
  query <- paste0("SELECT * FROM ", tbl_name)
  
  out <- con %>%
    dbSendQuery(query) %>%
    fetch(n = Inf) %>%
    as_tibble()
  
  return(out)
}

# manuscripts <- dbConnect(MySQL(), user="root", dbname="manuscripts", host="localhost")
# mmf <- dbConnect(MySQL(), user="root", dbname="mmf", host="localhost")
# test <- dbConnect(MySQL(), user="root", dbname="test", host="localhost")
mpce <- dbConnect(MySQL(), user="root", dbname="mpce1", host="localhost")

source("geonames_helper_functions.R")
