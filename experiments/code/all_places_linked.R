########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Places and Confiscations Revisited
#
# Authors: Michael Falk
#
# Date: 13/2/19
#
# Burrows has completed his revision of the consignment data and place data in spreadsheet form.
# This script converts the relevant tables into SQL. It also has a first go at plotting
# the consignment data on a map.
#
########################################################################################################

source('init.R')
cons_new_places <- readxl::read_xlsx("internal/confiscations/SB_confiscations_final.xlsx", sheet = "New places")
consignment <- readxl::read_xlsx("internal/confiscations/SB_confiscations_final.xlsx")
place <- read_csv("internal/geonames/SB_master_place_list.csv") %>%
  rename(place_code = X1)
unmatched_place <- readxl::read_xlsx("internal/geonames/SB_unmatched.xlsx")
place_db <- fetch_table(manuscripts, "places")
place_new_db <- fetch_table(manuscripts, "manuscript_places")
geonames_checked <- readxl::read_xlsx("internal/geonames/SB_geonames_checked.xlsx")

##### SECTION 1: CONSOLIDATE PLACE DATA #####

# First we need to gather the data in geonames_checked
place_geoname <- geonames_checked %>%
  mutate(geoname = ifelse(str_to_lower(Accept) == "yes", geonameId, `ALT Geomeld`)) %>%
  select(place_code, geoname, geoname_lat, geoname_lng)

# Now get the geonames from cons_new_places
place_geoname <- cons_new_places %>%
  filter(latitude != 'Null') %>%
  transmute(
    place_code = `Place code`,
    geoname = as.numeric(`Geonames code`),
    geoname_lat = dec_degree(latitude),
    geoname_lng = dec_degree(longitude)
    ) %>%
  # Add to place_geonames tbl
  bind_rows(place_geoname)

# And the geonames from unmatched_place

# First of all, these ones need a geoname. SB has recorded the toponymName from geonames
# Query geonames:
unmatched_geonames <- unmatched_place %>%
  query_geonames(toponymName, place_code, "michaelgfalk")

# Filter out correct results:
place_geoname <- unmatched_place %>%
  left_join(unmatched_geonames, by = "place_code") %>%
  # Measure distances between SB's coords and geonames'
  mutate(
    geoname_lat = dec_degree(geoname_lat), # SB's deg-min-sec coords
    geoname_lng = dec_degree(geoname_lng),
    lat = as.numeric(lat), # The decimal coords just downloaded from geonames
    lng = as.numeric(lng),
    dist = hav(geoname_lat, geoname_lng, lat, lng), # Haversine distance
    geonameId = as.numeric(geonameId)
  ) %>%
  # Keep closest geoname
  arrange(place_code, dist) %>%
  group_by(place_code) %>%
  slice(1) %>%
  # Create join
  select(place_code, geoname = geonameId, geoname_lat, geoname_lng) %>%
  bind_rows(place_geoname)

place_geoname %<>% drop_na()

# That means we have assigned 563 geonames to our places... but there are 605 places in SB's master spreadsheet.
# There were two typos in SB's master list - Dinan had place code pm526 instead of the correct pm536,
# and the place code for pl135 - DEUZ had been dropped somehow.
place_geoname %>%
  filter(!place_code %in% place$place_code) # Every place we have assigned a geoname is in SB's master list

place_new_db %>%
  filter(!Place_Code %in% place$place_code) # Every place in manuscript_places appears in SB's master list (checked for consistency MF 20190218)

place %>%
  filter(!place_code %in% place_geoname$place_code,
         !place_code %in% place_new_db$Place_Code) %>%
  print(n = Inf)

cons_new_places %>%
  filter(!`Place code` %in% place$place_code) # ALl the new confiscation places are in SB's master list

place_final <- place %>%
  left_join(place_geoname, by = "place_code") %>%
  # Remove old FBTEE lat-lng
  select(-latitude, -longitude) %>%
  # Add other notes
  left_join(
    select(cons_new_places,
           `Place code`,
           `Identification notes`),
    by = c("place_code" = "Place code")
  ) %>%
  left_join(
    select(unmatched_place,
           place_code,
           unmatched_note = notes),
    by = "place_code"
  ) %>%
  left_join(
    transmute(geonames_checked,
              place_code,
              gn_conf_note = paste0("Confirmation: ", Notes),
              gn_conf_note = str_remove(gn_conf_note, "Confirmation: NA")),
    by = "place_code"
  ) %>%
  mutate(
    notes = paste(notes, unmatched_note, gn_conf_note, `Identification notes`, sep = " "),
    notes = str_remove_all(notes, "\\bNA\\b|\\bNULL\\b"),
    notes = str_trim(notes),
    notes = ifelse(nchar(notes) < 1, NA, notes),
  ) %>%
  select(-`Identification notes`, -gn_conf_note, -unmatched_note)

# Export spreadsheet for SB of the places without geonames
place_final %>%
  filter(is.na(geoname)) %T>%
  print(n = Inf) %>%
  write_excel_csv("internal/geonames/20190218_places_without_geonames.csv")

place_db <- manuscripts %>% fetch_table("places")

place_final %>%
  filter(is.na(geoname),
         !place_code %in% place_db$place_code)

place_final %>%
  write_csv("internal/geonames/place_final_20180218.csv")



