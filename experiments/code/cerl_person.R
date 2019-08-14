########################################################################################################
#
# MPCE Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Persons and CERL
#
# Authors: Michael Falk
#
# Date: 27/2/19
#
########################################################################################################

library(httr)

person <- fetch_table(manuscripts, "people")

# Let's see what CERL throws up!

resp <- GET("https://data.cerl.org/thesaurus/_sru?version=1.2&operation=searchRetrieve&query=ct.personalname=charpentier,etienne&maximumRecords=25")

list <- content(resp) %>% as_list() %>% .$searchRetrieveResponse %>% .$records

list[[1]]$recordData$record$identifiers$identifier %@% "type"

# What do we want to get?

# The name - preferably with attributed 'inverted' if there is one
# The CERL id
# The biographical data
# The geographical note, if there is one



parse_cerl <- function(resp) {
  # Retrieves key information from CERL response
  i <- 0
  # Get content
  cont <- content(resp) %>% as_list() %>% .$searchRetrieveResponse %>% .$records
  
  # Define closure
  .parse_result <- function(cont) {
    # What do we want to know?
    message("Iteration ", i)
    # The name:
    name <- get_cerl_name(cont)
    # The cerl id:
    cerl_id <- cont$recordIdentifer %>% unlist()
    # The biographicalData:
    bio_data <- cont$recordData$record$info$biographicalData[[1]]
    if (is.null(bio_data)) {bio_data <- NA}
    # The activityNote
    activity_note <- cont$recordData$record$info$activityNote[[1]]
    if (is.null(activity_note)) {activity_note <- NA}
    # The geographicalNote
    geo_note <- cont$recordData$record$info$geographicalNote[[1]]
    if (is.null(geo_note)) {geo_note <- NA}
    
    i <<- i + 1
    
    out <- tibble(name = name, cerl_id = cerl_id, bio_data = bio_data, geo_note = geo_note)
  }
  
  out <- lapply(cont, .parse_result) %>% bind_rows()
  
  return(out)
}

get_cerl_name <- function(result) {
  # Get the name of the CERL person, preferring the inverted headingForm
  n_list <- result$recordData$record$nameForms
  nms <- unlist(n_list)
  types <- names(nms)
  attrs <- sapply(n_list, attributes)
  idx <- types == "headingForm" & attrs == "inverted"
  if (sum(idx) > 0) {
    name <- nms[idx][1]
  } else {
    name <- nms[1]
  }
  return(name)
}
