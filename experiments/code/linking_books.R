########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Another look at the banned books and MMF-2
#
# Authors: Michael Falk, Simon Burrows
#
# Date: 14/1/19
#
# On further discussion with Burrows, it turns out that the two sources of banned books data represent
# distinct kinds of event. The Bastille Registers record particular editions, wheras the banned books list
# essentially only records the super book. We therefore need to split these two datasets and run seperate
# data matching routines on them.
# 
# Moreover, the MMF-2 data join will probably work much better if we include author data, and pass it
# to Dedupe. Since both these tasks require the same kind of preprocessing, this single script
# deals with both problems.
#
########################################################################################################

# Load libraries and helper functions
# NB: You must have a local version of the 'manuscripts' and 'mmf' databases running for this to work.
source("init.R")

# DATA IMPORT

# Import all the data, keeping only the relevant fields.
all_banned <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT * FROM manuscript_titles_illegal ",
    "WHERE NOT record_status = 'DELETED'"
    )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  mutate_if(is.character, function(x) {x[nchar(x) < 1] <- NA; return(x)}) # Replace empty strings with NAs

bastille_register <- all_banned %>%
  # Get rid of the non-bastille books and the books that already have super book codes
  filter(!is.na(bastille_book_category),
         is.na(illegal_super_book_code)) %>%
  # Keep the columns relevant to the matching task:
  select(ID, illegal_full_book_title, illegal_author_name, illegal_date, bastille_imprint_full)

banned_books_list <- all_banned %>%
  # Ditch the bastille register
  filter(is.na(bastille_book_category)) %>%
  # Keep the columns relevant to the matching task:
  select(ID, illegal_full_book_title, illegal_author_name)

super_books <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT mb.super_book_code, mb.super_book_title, mba.author_type, ma.author_name FROM manuscript_books AS mb ",
    "    LEFT JOIN manuscript_books_editions AS mbe ",
    "        ON mbe.super_book_code = mb.super_book_code ",
    "    LEFT JOIN manuscript_books_authors AS mba ",
    "        ON mba.book_code = mbe.book_code ",
    "    LEFT JOIN manuscript_authors AS ma",
    "        ON ma.author_code = mba.author_code "
    )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  # Only keep rows with primary authors or no author at all
  filter(author_type == "primary" | is.na(author_type)) %>%
  distinct(super_book_code, author_name, .keep_all = T)

editions <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT me.book_code, me.full_book_title, me.stated_publishers, me.stated_publication_places, me.stated_publication_years, ",
    "mba.author_type, ma.author_name ",
    "FROM manuscript_books_editions AS me ",
    "    LEFT JOIN manuscript_books_authors AS mba ",
    "        ON me.book_code = mba.book_code ",
    "    LEFT JOIN manuscript_authors AS ma ",
    "        ON mba.author_code = ma.author_code "
  )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  # Only keep primary authors or books without known authors
  filter(author_type == "primary" | is.na(author_type))

mmf_books <- mmf %>%
  dbSendQuery("SELECT * FROM mmf_revised_data") %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  mutate_if(is.character, function(x) {x[nchar(x) < 1] <- NA; return(x)}) %>% # Replace empty strings with NAs
  # Transmute the tibble to keep only the necessary columns
  transmute(
    ID = ID,
    long_title = coalesce(Edition_Long_Title, Title_Long, Edition_Short_Title, Title_Short),
    date = coalesce(Edition_Publication_Year, Publication_Year),
    place = coalesce(Edition_Publication_Place, Publication_Place),
    author_surname = coalesce(Author_Edition_Surname, Author_Surname),
    author_forenames = coalesce(Author_Edition_Other_Names, Author_Other_Names),
    publisher = coalesce(Edition_Publication_Publisher, Publication_Publisher)
  ) %>%
  # Extract numeric information from the date column
  mutate(
    date = str_extract(date, "\\d{4}") # Just keep first four digits
  )

# PREPROCESSING & EXPORT FOR DEDUPE

# For each task, we want a single combined table that Dedupe can 'deduplicate'. Make sure to keep the index of the table we
# wish to update as a column in the table, in order to generate the relevant SQL.

## Task 1: The Banned Books List

# The banned books list records banned titles, and was used to assist book inspectors in eighteenth-century France.
# Though sometimes information about a particular edition was recorded, in general this list banned *titles*, i.e. super books
banned_books_list %>%
  # Make column names match the super_books table
  rename(
    super_book_title = illegal_full_book_title,
    author_name = illegal_author_name
    ) %>%
  # Join to super books data
  bind_rows(super_books) %>%
  # Remove extraneous column
  select(-author_type) %>%
  # Write to csv
  write_csv("internal/banned_books_list/banned_books_list_dddata.csv")

## Task 2: The Bastille Register

# The Bastille register records the particular editions that were found in the Bastille
# The imprint data for the bastille register is quite messy. The year is already in another column, so what we would
# ideally do is extract the place from the imprint notes.
publication_place <- bastille_register %>%
  # Extract imprints for preprocessing
  pull(bastille_imprint_full) %>%
  # Delete all notes that include the word "no or "not."
  str_remove("^.*\\b[Nn]ot?\\b.*$") %>%
  # Scrolling through, virtually all the useful notes have the same form:
  # the place name appears at the start of the string, it has letters and
  # punctuation marks but no digits in it, and it is followed immediately by
  # a comma, full stop or question mark. So first we delete everything before the first full stop/comma:
  str_match("(^[[:alpha:] \\[\\]]+)[,.?]") %>%
  .[,2] %>% # Just keep the second column (note capture group in above regex + documentatio of str_match)
  # Remove the phrase 'published' or 'printed in'
  str_remove("P.+ed in ") %>%
  # And delete all notes starting with 'contains'
  str_remove("Contains.+")
  
bastille_register %>%
  # Add extracted place data into table
  mutate(stated_publication_places = publication_place) %>%
  # Make column names match the edition data
  rename(
    full_book_title = illegal_full_book_title,
    author_name = illegal_author_name,
    stated_publication_years = illegal_date
    ) %>%
  # Combine with edition data
  bind_rows(editions) %>%
  # Remove extraneous columns
  select(-stated_publishers, -bastille_imprint_full, -author_type) %>%
  write_csv("internal/bastille_register/bastille_register_dddata.csv")

## Task 3: MMF-2

# MMF-2 records information about particular editions.

# MMF-2 has many editions from earlier than any of our other datasets. It also includes only fiction.
# We can use this information to limit our search field considerably.

# Only fetch editions from the database if they have Parisian keyword pk104: 'Romans':
fbtee_novels <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT me.book_code, me.full_book_title, me.stated_publishers, me.stated_publication_places, me.stated_publication_years, ",
    "mba.author_type, ma.author_name ",
    "FROM manuscript_books_editions AS me ",
    "    LEFT JOIN manuscript_books_authors AS mba ",
    "        ON me.book_code = mba.book_code ",
    "    LEFT JOIN manuscript_authors AS ma ",
    "        ON mba.author_code = ma.author_code ",
    "    LEFT JOIN manuscript_books AS mb ",
    "        ON me.super_book_code = mb.super_book_code ",
    "WHERE mb.parisian_keyword = 'pk104'"
  )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  # Only keep primary authors or books without known authors
  filter(author_type == "primary" | is.na(author_type)) %>%
  # Rename columns to fit with MMF-2 data
  rename(
    long_title = full_book_title,
    publisher = stated_publishers,
    date = stated_publication_years,
    place = stated_publication_places
  ) %>%
  # Do same preprocessing on the date
  mutate(
    date = str_extract(date, "\\d{4}")
  ) %>%
  # Drop superfluous author_type column
  select(-author_type)

# Can we limit it just to within FBTEE's date range?
fbtee_range <- fbtee_novels %>%
  select(date) %>%
  drop_na() %>%
  summarise(
    min = min(date),
    max = max(date)
  )
# No, because that would hardly exclude any.

# How many unique dates are in the FBTEE data?
fbtee_novels %>%
  select(date) %>%
  drop_na() %>%
  summarise(
    date = length(unique(date))
  )
# 53

# How many MMF-2 novels are knocked out if we only allow editions from years present in the FBTEE data?
fbtee_years <- fbtee_novels %>%
  select(date) %>%
  drop_na() %>%
  pull(date)

mmf_books %>%
  filter(
    date %in% fbtee_years
  ) %>%
  mutate(author_name = paste(author_surname, author_forenames, sep = ", ")) %>%
  select(-author_surname, -author_forenames) %>%
  bind_rows(fbtee_novels) %>%
  write_csv("internal/mmf_2/mmf_2_dddata.csv")
# That has reduced the number of rows by 66%, and surely hasn't knocked out too many possible links.
# Onwards!

# EXAMINING THE DEDUPED DATA

# Now the data has been passed to Dedupe and exported again, we can have a look at it and see how well
# the models did at linking our datasets.

mmf_linked <- read_csv("internal/mmf_2/mmf_deduped.csv") %>%
  select(-X1) # Drop column for pandas index

bastille_linked <- read_csv("internal/bastille_register/bas_reg_deduped.csv") %>%
  select(-X1) # Drop column for pandas index

banned_linked <- read_csv("internal/banned_books_list/banned_books_deduped.csv") %>%
  select(-X1) # Drop column for pandas index

# For how many books was a link found?
mmf_linked %>%
  filter(!is.na(cluster)) %>% # Filter out unclustered books
  group_by(cluster) %>%
  filter(
    any(!is.na(book_code)), # Only want clusters with at least one FBTEE book
    any(!is.na(ID)) # And at least one MMF book
  ) %>%
  ungroup() %>%
  arrange(cluster) %T>% # Sort into clusters...
  print(n = Inf) %>% #... and have a look at them
  write_csv("internal/mmf_2/mmf_deduped_filtered_sorted.csv") # Then export
