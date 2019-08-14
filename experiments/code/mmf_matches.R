########################################################################################################
#
# MMF Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: How many MMF books appear in the FBTEE data?
#
# Authors: Michael Falk, Simon Burrows
#
# Date: 8/1/19
#
########################################################################################################

# Load environment
source("init.R")

# Get the books...
fbtee_super_books <- manuscripts %>%
  dbSendQuery("SELECT * FROM manuscript_books") %>%
  fetch(n = Inf) %>%
  as.tibble()

mmf_super_books <- mmf %>%
  dbSendQuery("SELECT * FROM mmf_revised_data") %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  filter(nchar(Title_Long) > 1)

sim_mat <- stringsimmatrix(fbtee_super_books$super_book_title, mmf_super_books$Title_Long)

# The matrix has one row for each FBTEE book and one column for each MMF book. So we want the best result for each column.
top_idx <- sim_mat %>%
  t() %>%
  apply(1, which.max)
top_score <- sim_mat %>%
  t() %>%
  apply(1, max)

# Matches
matches <- mmf_super_books %>%
  transmute(mmf_title = Title_Long,
            matched_fbtee_title = fbtee_super_books$super_book_title[top_idx],
            osa = top_score) %>%
  arrange(desc(osa)) %>%
  filter(osa > 0.7)


# When were the MMF books published?
mmf_super_books %>%
  mutate(date = as.integer(Publication_Date)) %>%
  select(date) %>%
  drop_na() %>% # Get rid of junk
  filter(date > 1700 & date < 1801) %>% # Get rid of more junk
  group_by(date) %>%
  summarise(n = n()) %>%
  ggplot(aes(date, n)) +
  geom_line()

# Try clipping the titles
fbtee_clipped <- fbtee_super_books %>%
  pull(super_book_title) %>%
  str_sub(start = 1, end = 30)
mmf_clipped <- mmf_super_books %>%
  pull(Title_Long) %>%
  str_sub(start = 1, end = 30)

clipped_mat <- stringsimmatrix(fbtee_clipped, mmf_clipped)

clipped_idx <- clipped_mat %>%
  t() %>%
  apply(1, which.max)
clipped_score <- clipped_mat %>%
  t() %>%
  apply(1, max)

clipped_matches <- mmf_super_books %>%
  transmute(mmf_title = Title_Long,
            matched_fbtee_title = fbtee_super_books$super_book_title[clipped_idx],
            osa = clipped_score,
            lcs = stringsim(mmf_title, matched_fbtee_title, method = "lcs"),
            cos = stringsim(str_sub(mmf_title, start = 1, end = 30), str_sub(matched_fbtee_title, start = 1, end = 30), method = "cos"),
            mean = (osa + lcs + cos)/3) %>%
  filter(mean > 0.65) %>%
  arrange(desc(mean))

# Clip at 50: no difference whatsoever...
# Clip at 30: finds a few hundred matches.

# Another approach: just focus on the FBTEE titles that are already tagged as novels
fbtee_novels_only <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT * FROM manuscript_books ",
    "WHERE parisian_keyword = 'pk104' "
  )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>%
  mutate(title_clipped = str_sub(super_book_title, start = 1, end = 30))

# Ditch all this. We need to use authorship data too.

fbtee_books_authors  <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT mb.super_book_code, mb.super_book_title, ma.author_name",
    "FROM manuscript_books AS mb ",
    "    LEFT JOIN manuscript_books_editions AS mbe ",
    "        ON mbe.super_book_code = mb.super_book_code ",
    "    LEFT JOIN manuscript_books_authors AS mba ",
    "        ON mba.book_code = mbe.book_code ",
    "    LEFT JOIN manuscript_authors AS ma ",
    "        ON mba.author_code = ma.author_code ",
    "WHERE mba.author_type = 'primary'"
  )) %>%
  fetch(n = Inf) %>%
  as.tibble()
