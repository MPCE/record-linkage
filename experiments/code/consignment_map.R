########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Mapping consignments
#
# Authors: Michael Falk
#
# Date: 18/02/19
#
# First attempt to put the consignments of banned books on the map.
#
########################################################################################################

source('init.R')
library(lubridate)
consignment <- mpce %>% fetch_table("consignment")
place <- mpce %>% fetch_table("place")

library(leaflet)
centre <- place %>% filter(name == "BOURGES") %>% rename(lat = geoname_lat, lng = geoname_lng)

consignment %>%
  filter(ymd(inspection_date))
  group_by(origin_code) %>%
  summarise(consignments_intercepted = n()) %>%
  left_join(
    place %>% select(place_code, geoname_lat, geoname_lng, name),
    by = c("origin_code" = "place_code")
  ) %>%
  leaflet() %>%
  # Centre on Bouge
  setView(lng = centre$lng, lat = centre$lat, zoom = 6) %>%
  # Render map
  addTiles() %>%
  # Add consignments
  addCircles(
    lng = ~geoname_lng,
    lat = ~geoname_lat,
    weight = 1,
    radius = ~consignments_intercepted * 300,
    popup = ~paste0(str_to_title(name), ": ", consignments_intercepted)
  )
