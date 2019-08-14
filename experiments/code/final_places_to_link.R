########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Linking the last places
#
# Authors: Michael Falk
#
# Date: 18/02/19
#
# There were some final places without geonames. This script tries to geoparse them.
#
########################################################################################################


place <- read_csv("internal/geonames/place_final_20180218.csv")
no_geoname <- read_csv("internal/geonames/20190218_places_without_geonames.csv")
SB_master_list <- read_csv("internal/geonames/SB_master_place_list.csv") %>%
  rename(place_code = X1)


new_search <- no_geoname %>%
  # Add alternative names to search
  mutate(alternative_names = str_remove(alternative_names, ",.+")) %>%
  select(place_code, name, alternative_names) %>%
  gather(key = name_type, value = name, -place_code) %>%
  select(-name_type) %>%
  query_geonames(name, place_code, "michaelgfalk")

new_search %<>%
  left_join(select(SB_master_list, place_code, latitude, longitude, C21_country), by = "place_code")

new_search %>%
  mutate(
    fbtee_lat = dec_degree(latitude),
    fbtee_lng = dec_degree(longitude),
    geonames_lat = as.numeric(lat),
    geonames_lng = as.numeric(lng),
    dist = hav(fbtee_lat, fbtee_lng, geonames_lat, geonames_lng),
    geonames_url = paste0("http://www.geonames.org/", geonameId),
    name_sim = stringsim(toponymName, name)
  ) %>%
  group_by(place_code) %>%
  arrange(place_code, dist, desc(name_sim)) %>%
  slice(1) %>%
  select(
    place_code,
    fbtee_name = name,
    toponymName,
    distance = dist,
    name_sim,
    geonameId,
    geonames_url,
    fbtee_lat,
    fbtee_lng,
    geonames_lat,
    geonames_lng
  ) %>%
  write_excel_csv("internal/geonames/final_unmatched_places.csv")
  
