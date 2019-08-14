########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Matching new persons in the confiscation data
#
# Authors: Michael Falk
#
# Date: 16/1/19, 21/1/19
#
# The consignment data from the confiscations dataset contains many new names. Are there any
# duplicates? And do any of the names appear in our existing person data?
#
# Update 21/1/19: Include place and profession data to help disambiguate persons.
#
########################################################################################################

source("init.R")
library(readxl)
outdir <- "internal/confiscations/"

##### SECTION 1: MATCHING THE PERSON DATA #####

# When this script was run, the local version of the manuscripts database had been updated, so that all
# known 'clients' had been given person codes.

# Updated: 3612 rows
# Not updated: 3217 rows

# Include place and profession data in query
person <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT p.person_code, p.person_name, pp.profession_code, pr.profession_type, pl.place_code, pl.name ",
    "FROM people AS p ",
    "    LEFT JOIN people_professions AS pp ",
    "        ON p.person_code = pp.person_code ",
    "    LEFT JOIN professions AS pr ",
    "        ON pr.profession_code = pp.profession_code ",
    "    LEFT JOIN clients_people AS cp ",
    "        ON cp.person_code = p.person_code ",
    "    LEFT JOIN clients_addresses AS ca ",
    "        ON ca.client_code = cp.client_code ",
    "    LEFT JOIN places AS pl ",
    "        ON pl.place_code = ca.place_code;"
    )
    ) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  # Concatenate duplicates caused by multiple professions or places
  group_by(person_code, person_name) %>%
  summarise_if(
    is.character,
    paste,
    collapse = "; "
  ) %>%
  ungroup() %>%
  # Fix NAs that have been stringified by 'paste':
  mutate_if(
    is.character,
    function(x) {
      idx = str_detect(x, "^NA$") # Find all 'NAs'
      x[idx] <- NA # Replace with actual NAs
      return(x) # Return vector
    }
  ) %>%
  rename(place_name = name)

confiscations <- read_xls(paste0(outdir, "confiscation_20190116.xls"), sheet = "Amalgamated sheet") %>%
  rename(standard_name = `Names_standardised of Persons confiscated from`,
         ID = `Confiscation Record ID (order on sheet)`,
         stated_profession = Stated_Profession) %>%
  filter(!str_detect(`Client code`, "^c.\\d{4}$")) # Filter out people who already have a client code


# How many names have been standardised?
confiscations %>%
  group_by(null_name = is.null(standard_name)) %>%
  summarise(n = n())

confiscations %>%
  group_by(less_than_2 = nchar(standard_name) < 2) %>%
  summarise(n = n())
# All have a standardised name

# Roll up the confiscations to get rid of duplicates
confiscations %<>%
  group_by(standard_name, stated_profession) %>%
  summarise(confiscation_row_ID = paste(ID, collapse = ", "))

# Run the fuzzy match:
mat <- stringsimmatrix(person$person_name, confiscations$standard_name)

# Most promising matches:
most_promising <- which(mat > 0.6, arr.ind = T)

out <- person[most_promising[,"row"],] %>%
  bind_cols(
    confiscations[most_promising[,"col"],]
  ) %>%
  select(standard_name, stated_profession, person_name, person_code, profession_type, place_code, place_name, confiscation_row_ID) %>%
  mutate(osa = mat[most_promising],
         cos = stringsim(person_name, standard_name, method = "cos"),
         lcs = stringsim(person_name, standard_name, method = "lcs"),
         mean = (osa + cos + lcs)/3) %>%
  filter(mean > 0.7) %>%
  arrange(standard_name, desc(mean))

# Export to spreadsheet for Simon to look at
write_csv(out, paste0(outdir, "confiscation_person_match.csv"))

##### SECTION 2: TRY UPLOADING DATA INTO REMADE TABLE #####

# What are the columns that we need?
required_columns <- test %>%
  dbSendQuery("DESCRIBE consignment") %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  pull(Field)

out_sql_tbl <- confiscations %>%
  transmute(
    ID = 1:nrow(confiscations),
    UUID = map_chr(ID, function(x) UUIDgenerate(TRUE)),
    confiscation_register_ms = Document,
    confiscation_register_folio = Folio,
    customs_register_ms = as.numeric(`Custom register Ms number`),
    customs_register_folio = `customs register folio`,
    ms_21935_folio = `Ms 21,935 folio`,
    shipping_number = `Shipping number`,
    marque = Marque,
    inspection_date = `Date of entry`,
    addressee_name = standard_name,
    addressee_title = Title,
    addressee = NA, # Need to confirm person matches
    origin_text = `Places came from`,
    origin_code = NA, # Need to do place match
    residual_collector_name = `Person who signs_standardised`,
    residual_collector = NA, # Need to confirm person matches
    collector_signed = as.numeric(!is.na(`Signed confiscation register`)), # Convert to logical then numeric
    acquit_a_caution = NA, # Burrows to enter data
    confiscation_register_notes = `Notes (from MS 21,933-5)`,
    customs_register_notes = `correction notes (from customs registers)`
  )

# Check that columns exactly match those of table in database
if (all(colnames(out_sql_tbl) == required_columns)) {
  f <- file(paste0(outdir, "insert_into_consignment.sql"), open = "wt", encoding = "UTF-8")
  # Then generate SQL
  out_sql <- out_sql_tbl %>%
    mutate_if(is.character, function(x) paste0('"', x, '"')) %>%
    unite(col = "rows", sep = ",") %>%
    mutate(
      rows = paste0("(", rows, ")")
    ) %>%
    # Collapse into a character vector
    pull(rows) %>%
    # paste
    paste(collapse = ",\n") %>%
    str_replace_all("\\bNA\\b", "NULL") %>%
    (function(x) paste0("INSERT INTO consignment VALUES\n", x, ";")) %T>%
    write(f)
  close(f)
}

# Execute it
test %>%
  dbSendQuery(out_sql) %>%
  dbClearResult()

# That SQL has been executed, let's see how it went...
consignment <- test %>%
  dbSendQuery("SELECT * FROM consignment") %>%
  fetch(n = Inf) %>%
  as.tibble()
