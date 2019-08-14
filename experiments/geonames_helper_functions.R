########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Geonames helper functions
#
# Authors: Michael Falk
#
# Date: 8/3/18
#
# A set of functions for querying geonames.
#
########################################################################################################

gn_ser <- function(term_list, username) {
  # Helper function that queries geonames with the provided list of terms
  
  require(httr)
  # Allow a named or unnamed vector for convenience
  if (is.null(names(term_list))) {
    term_list <- list(q = term_list)
  }
  if (class(term_list) != "list") {
    term_list <- as.list(term_list)
  }
  term_list$username <- username
  # Search geonames:
  resp <- GET("http://api.geonames.org/", path = "search", query = term_list)
  return(resp)
}

gn_parse <- function(resp) {
  ##
  #
  # Helper function to parse geonames resultset
  #
  # Params:
  #   resp: a response object, from httr
  #
  # Returns:
  #   out: a tibble containing all returned results
  #
  ##
  
  require(httr)
  require(xml2)
  
  out <- resp %>%
    # Parse the results into an R object
    content("parsed") %>%
    # Convert to a list
    as_list() %>%
    # The list has one element called 'geonames' that contains all the results.
    # Remove this superluous level
    flatten() %>%
    # Only keep list elements called 'geoname'
    .[names(.) == "geoname"] %>%
    # Turn each geoname result into a tibble, and bind all of them by row
    map_dfr(as_tibble) %>%
    # Each element of this tibble is a list due. Unnest to convert the results to the correct type
    unnest()
  
  return(out)
  
}

query_geonames <- function(data, name_col, id_col, username) {
  # Conducts a query then parses the results.
  #
  # Arguments:
  #   data: a tbl
  #   name_col: the column with placenames in it
  #   id_col: the column with the place ids in it
  #
  # Returns:
  #   result: a tbl of the returned results
  
  # Enquote the column variables
  name_col <- enquo(name_col)
  id_col <- enquo(id_col)
  
  # Loop through the places and search geonames for them
  message("Querying geonames ...")
  result_list <- data %>%
    pull(!!name_col) %>%
    tolower() %>%
    lapply(FUN = gn_ser, username = username)
  
  # Associate each result in the list with the correct place_code
  names(result_list) <- pull(data, !!id_col)
  
  # Combine the results into a tibble
  message("Parsing results...")
  result <- result_list %>%
    map_dfr(gn_parse, .id = "place_code")
  
  return(result)
}

gn_lat_lng <- function(geoname_ids, username) {
  ##
  # Given a vector of geonames, returns the latitudes and longitudes.
  ##
  .get_lat_lng <- function(y) {
    resp <- httr::GET(
      url = "http://api.geonames.org",
      path = "get",
      query = list(
        geonameId = y,
        username = username # Get from enclosing function
      )
    )
    return(resp)
  }
  
  # Apply function to vector
  coord_list <- lapply(geoname_ids, .get_lat_lng)
  
}

hav <- function(lat1, long1, lat2, long2) {
  require(pracma)
  # Vectorized version of haversine function
  
  .haversine <- function(a, b, c, d) {
    if (anyNA(c(a,b,c,d))) {
      return(NA)
    } else {
      .loc1 <- c(a, b)
      .loc2 <- c(c, d)
      .dist <- haversine(.loc1, .loc2)
      return(.dist)
    }
  }
  
  out <- mapply(.haversine, lat1, long1, lat2, long2, USE.NAMES = F)
  
  return(out)
}

scale_feature <- function(x) {
  # Scales a feature to a linear distribution between 1 and 0.
  #
  # Parameters:
  #   x (dbl): a vector
  #
  # Returns:
  #   x_scaled (dbl): the scaled values of x
  
  x_max <- max(x)
  x_min <- min(x)
  x_scaled <- (x - x_min) / (x_max - x_min)
  return(x_scaled)
  
}

# Helper function to convert deg min sec
dec_degree <- function(vec) {
  ##
  # Args
  #   vec (chr): a character vector with degrees, minutes and seconds
  #
  # Returns
  #   dec_deg (num): a numeric vector of decimal degrees
  ##
  
  # Define conversion formula
  .form <- function(row) {
    # Assumes three columns of degrees, minutes, seconds
    if (length(row) == 0) {
      conv <- NA
      return(conv)
    } else {
      conv <- row[1] + (row[2] + row[3]/60)/60
      return(conv)
    }
  }
  
  dec_deg <- str_extract_all(vec, "\\d{1,2}(?=\\D)", simplify = T) %>% 
    # Convert character matrix to numeric
    apply(2, as.numeric) %>%
    # Apply formula rowise
    apply(1, .form)
  
  return(dec_deg)
  
}