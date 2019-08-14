########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Linking to Geonames
#
# Authors: Michael Falk
#
# Date: 22/01/2019, 29/01/2019
#
# One aspiration of MPCE is to release the project in the form of linked open data. To do that, we need
# to create some links... One obvious place to start is---place. Can we link all the places in our
# datasets to a 'populated place' in the geonames gazeteer?
#
########################################################################################################

source("init.R")
library(httr)
library(xml2)
library(pracma) # For haversine distance function
library(stringdist)

my_name = "michaelgfalk"

place <- manuscripts %>%
  dbSendQuery("SELECT * FROM places") %>%
  fetch(n = Inf) %>%
  as_tibble()

##### SECTION 1: SEARCH GEONAMES FOR ALL PLACES IN CURRENT DATA #####

results <- place %>%
  pull(name) %>%
  tolower() %>%
  lapply(FUN = gn_ser)

names(results) <- pull(place, place_code)

result_tbl <- results %>%
  map_dfr(gn_parse, .id = "place_code")

# How many places have a corresponding populated place in geonames?
result_tbl %>%
  group_by(place_code) %>%
  summarise(pop_place = any(fcode == "PPL")) %>%
  group_by(pop_place) %>%
  summarise(n = n())

# Only eighteen have no populated place... which are they?
result_tbl %>%
  group_by(place_code) %>%
  summarise(pop_place = any(fcode == "PPL")) %>%
  filter(!pop_place) %>%
  left_join(place, by = "place_code") %>%
  select(place_code, pop_place, name, alternative_names)
# It looks like the problem might be that the place names are in French.

##### SECTION 2: FIND MOST LIKELY TRUE MATCHES #####

# Let's get the closest geoname for a populated place for each FBTEE place
closest_PPLs <- result_tbl %>%
  # The code for populated place is 'PPL'
  filter(fcode == "PPL") %>%
  # Join to place data
  left_join(select(place, place_code, name, latitude, longitude, C21_country), by = "place_code") %>%
  # Only consider records in the same country
  filter(countryName == C21_country) %>%
  mutate(
    gn_lat = as.numeric(lat),
    gn_lng = as.numeric(lng)
  ) %>%
  mutate(
    dist = hav(gn_lat, gn_lng, latitude, longitude)
  ) %>%
  group_by(place_code) %>%
  arrange(desc(dist)) %>%
  slice(n = 1)
  

# Test to see how fast haversine function is...
system.time(closest_PPLs %>% transmute(dist = hav(gn_lat, gn_lng, latitude, longitude)))

##### SECTION 3: IMPROVING THE MATCHES #####

# The first approach worked well in some respects. We were able to download 1000s of possible matches quickly from
# geonames, and the haversine function was lightening-fast, even when comparing 10s of 1000s of pairs.

# But many of the matches were disappointing...

closest_PPLs %>%
  filter(tolower(toponymName) == tolower(name.y)) # Only 87 exact matches by name after comparing coordinates...

result_tbl %>%
  select(-name) %>%
  left_join(select(place, place_code, name), by = "place_code") %>%
  filter(tolower(toponymName) == tolower(name)) # Yet there were 1586 exact name matches in the original data...

# To improve:

# Should include all resutls that begin with a 'P'
result_tbl %>%
  filter(str_detect(fcode, "^P")) # 20000 rows
result_tbl %>%
  filter(fcode == "PPL") # 16000 rows

# Make use of alternative names.

# How many are there?
max_names <- place %>%
  filter(!is.na(alternative_names)) %>% # Look at places with alternative names
  pull(alternative_names) %>% # Pull out those alternatives
  str_extract_all(",", simplify = TRUE) %>% # Find all the columns
  ncol() %>% # How many columns in resulting matrix? (i.e. what is the max number of commas for any given place)
  sum(1) # Add one to get the maximum number of alternative names a given place has

place_expanded <- place %>%
  select(place_code, name, alternative_names, C21_country, latitude, longitude) %>% 
  separate(col = alternative_names, into = paste0("alt_", 1:max_names), sep = ",") %>%
  gather(
    key = name_type,
    value = place_name,
    -place_code,
    -C21_country,
    -latitude,
    -longitude
  ) %>%
  select(-name_type) %>%
  mutate_if(is.character, str_trim) %>%
  drop_na()

# Now try again...

result_tbl <- query_geonames(place_expanded, place_name, place_code, my_name)

result_joined <- result_tbl %>%
  select(-name, -countryCode) %>%
  inner_join(place_expanded, by = "place_code") %>%
  filter(
    countryName == C21_country, # Restrict to geonames in the same country as the FBTEE-place
    fcl == "P" # Just look at geonames for towns, villages etc.
    ) %>%
  mutate(
    string_sim = stringsim(tolower(toponymName), tolower(place_name)), # Find name similarity
    geo_dist = hav(as.numeric(lat), as.numeric(lng), latitude, longitude) # Find haversine distance
  ) %>%
  arrange(place_code)

# How many have an exact string match?
result_joined %>%
  filter(string_sim == 1) %>%
  distinct(place_code) %>%
  summarise(places_with_exact_name_matches = n())

# How many have more than one?
result_joined %>%
  mutate(zero_sdist = string_sim == 1) %>%
  group_by(place_code, zero_sdist) %>%
  summarise(number_exact = n()) %>%
  filter(zero_sdist == TRUE) %>%
  group_by(number_exact) %>%
  summarise(n = n())

# What are these places with multiple matches?
result_joined %>%
  filter(string_sim == 1) %>%
  group_by(place_code) %>%
  filter(n() > 2) %>%
  ungroup() %>%
  arrange(place_code, geo_dist) %>%
  print(n = Inf)

# Selecting a geoname. After trial and error, this looks like a good set of rules of thumb
result_joined %>%
  filter(
    geo_dist < 4, # Only match if the geoname is less than 4km from the FBTEE-place by haversine distance,
    string_sim > 0.6
    ) %>%
  arrange(
    place_code,
    geo_dist,
    fcode,
    desc(string_sim)
  ) %>%
  group_by(place_code) %>%
  slice(n = 1)

# Or we could try to do a mean of the two distance measures after filtering
final_matches <- result_joined %>%
  mutate(
    gd_scaled = scale_feature(pmin(geo_dist, 4)), # Clip geo_dist at 4km for purposes of scaling
    ss_scaled = scale_feature(1 - string_sim), # Convert similarity to distance measurement as well as scaling
    combined_measure = (gd_scaled + ss_scaled) / 2
  ) %>%
  group_by(place_code) %>%
  arrange(place_code, combined_measure) %>%
  slice(n = 1)

final_matches %>% 
  write_csv("internal/geonames/geonames_matched.csv")

# Which places didn't get a match?
place %>%
  filter(!place_code %in% result_tbl$place_code) %>%
  write_csv("internal/geonames/unmatched_places.csv")
