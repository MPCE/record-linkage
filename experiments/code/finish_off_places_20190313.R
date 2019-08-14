########################################################################################################
#
# MPCE Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Hopefully the final look at the place data before we reexamine the book imprints.
#
# Authors: Michael Falk
#
# Date: 13/03/19
#
########################################################################################################

source('init.R')

tagged_places <- read_csv("internal/geonames/place_final_20180218.csv")
sb_checked_places <- readxl::read_xlsx("internal/geonames/SB_checked_unmatched_places_20190312.xlsx") %>%
  filter(str_detect(Accept, "^[Yy]es")) %>% # Keep only changes SB has accepted (all but one)
  select(place_code, new_gn_id = geonameId, new_lat = geonames_lat, new_lng = geonames_lng, new_notes = Notes)

# A little helper to redo distance from Neuchatel
neu_coords <- tagged_places %>% filter(place_code == "pl283") %>% select(geoname_lat, geoname_lng) %>% as_vector() %>% unname()
dist_neuchatel <- purrr::partial(pracma::haversine, loc1 = neu_coords)


# All the data is in tagged_places, which was derived from Simon's master spreadsheet and checked against the database.
places_out <- tagged_places %>%
  left_join(sb_checked_places, by = "place_code") %>%
  # Splice in the new data SB has corrected
  mutate(
    notes = paste(notes, new_notes, sep = ";"),
    notes = str_remove(notes, "NA;NA|;NA|NA;"),
    notes = ifelse(nchar(notes) == 0, NA, notes),
    geoname_lat = coalesce(geoname_lat, new_lat),
    geoname_lng = coalesce(geoname_lng, new_lng),
    geoname = coalesce(geoname, new_gn_id)
  ) %>%
  select(-new_notes, -new_lat, -new_lng, -new_gn_id)

# Calculate the distance from Neuchatel
calculated_distance <- places_out %>%
  select(place_code, geoname_lat, geoname_lng) %>%
  drop_na() %>%
  mutate(
    distance_from_neuchatel = map2(geoname_lat, geoname_lng, .f = function(x,y) dist_neuchatel(loc2 = c(x,y)))
  ) %>%
  unnest() %>%
  select(place_code, distance_from_neuchatel)

places_out %<>%
  select(-distance_from_neuchatel) %>%
  left_join(calculated_distance, by = "place_code") %>%
  rename(
    latitude = geoname_lat,
    longitude = geoname_lng
  )

# Field definitions for exporting to MySQL:
place_table_schema = c(
  place_code = "char(5) PRIMARY KEY",
  name = "varchar(50)",
  alternative_names = "varchar(255)",
  town = "varchar(50)",
  C18_lower_territory = "varchar(50)",
  C18_sovereign_territory = "varchar(50)",
  C21_admin = "varchar(50)",
  C21_country = "varchar(50)",
  geographic_zone = "varchar(50)",
  BSR = "varchar(50)",
  HRE = "bit",
  EL = "bit",
  IFC = "bit",
  P = "bit",
  HE = "bit",
  HT = "bit",
  WT = "bit",
  PT = "bit",
  PrT = "bit",
  distance_from_neuchatel = "double",
  latitude = "decimal(10,8)",
  longitude = "decimal(10,8)",
  geoname = "int",
  notes = "varchar(1000)"
)


# Test on local copy
manuscripts %>% dbSendQuery("SET NAMES utf8") %>% dbFetch(n = Inf)
dbWriteTable(manuscripts, "place", places_out, row.names = F, field.types = place_table_schema, overwrite = T)
  
# Okay, the script works, so we can now apply it to the online version of the database.
online_manuscripts <- RMariaDB::dbConnect(RMariaDB::MariaDB(), dbname = "manuscripts", user = "thedotsquad", password = rstudioapi::askForPassword(), encoding = "utf8")
online_manuscripts %>% dbExecute("SET NAMES utf8")
online_manuscripts %>%
  dbWriteTable("places", places_out, row.names = F, field.types = place_table_schema, overwrite = T)
