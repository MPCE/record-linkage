# A Question: How many of the Bastille Register books from FBTEE-1 have been picked up in the banned books data entry?

library(tidyverse) # for data manipulation
library(magrittr) # for a more powerful piping operator
library(DBI) # to enable database connection
library(RMySQL) # a simple API for connecting to a MySQL database
library(stringdist) # string distance measures

manuscripts <- dbConnect(MySQL(), user="root", dbname="manuscripts", host="localhost")

super_books <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT * FROM manuscript_books ",
    "WHERE illegality LIKE '%Poin%' "
    )) %>%
  fetch(n = Inf) %>%
  as.tibble()

bastille <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT * FROM manuscript_titles_illegal ",
    "WHERE CHAR_LENGTH(bastille_book_category) > 0 "
  )) %>%
  fetch(n = Inf) %>%
  as.tibble() %>% 
  mutate( # get rid of that crappy thing that's been added to matched banned books titles
    illegal_full_book_title = str_remove(illegal_full_book_title, " <.+>")
  )

# How many have been matched?
sim_mat <- lapply(super_books$super_book_title, function(x) {
  sim_vec <- stringsim(x, bastille$illegal_full_book_title, method = 'osa')
}) %>%
  unlist() %>%
  matrix(nrow = nrow(super_books), ncol = nrow(bastille), byrow = T)

# Which titles have a similarity higher than thresh?
thresh <- 0.841 # This was set by testing a number of thresholds and choosing the one where the string match was wrong
titles <- which(sim_mat > thresh, arr.ind = T)
matches <- bastille[titles[,'col'],] %>%
  select(illegal_full_book_title, illegal_super_book_code) %>%
  mutate(matched_super_book = super_books[titles[,'row'],]$super_book_title,
         matched_super_book_code = super_books[titles[,'row'],]$super_book_code,
         sim = sim_mat[which(sim_mat > thresh)]) %>%
  arrange(desc(sim))

# Which is highest row we know to be incorrect?
matches %>%
  filter(nchar(illegal_super_book_code) > 0 &
    illegal_super_book_code != matched_super_book_code)

# How many new matches have we made?
matches %>%
  filter(nchar(illegal_super_book_code) == 0) %>%
  nrow()


# What are the top matches for each Bastille book already in the super_book data?
# In principle, every book from FBTEE-1 should be in the new banned books data
sim_mat <- lapply(super_books$super_book_title, function(x) {
  sim_vec <- stringsim(x, bastille$illegal_full_book_title, method = 'lcs')
}) %>%
  unlist() %>%
  matrix(nrow = nrow(super_books), ncol = nrow(bastille), byrow = T)

top_cols <- apply(sim_mat, 1, which.max)
top_colscores <- apply(sim_mat, 1, max)

top_matches_rw <- super_books %>% # Rowise top matches
  mutate(matched_illegal_title = bastille[top_cols,]$illegal_full_book_title, # get titles of top matches
         matched_illegal_code = bastille[top_cols,]$illegal_super_book_code, # get codes of top matches
         banned_has_code = str_length(matched_illegal_code) > 1, # does the banned book have a super_book_code?
         banned_code_same = super_book_code == matched_illegal_code, # if so, are the codes the same?
         score = top_colscores) %>%
  select(super_book_code, super_book_title, matched_illegal_title, score, banned_has_code, banned_code_same) %>%
  arrange(desc(score))

# Now we can measure how this procedure did.
# How many did it get right and wrong, to our best knowledge?
top_matches_rw %>%
  group_by(banned_has_code, banned_code_same) %>%
  summarise(n = n())
# It seems to have made more correct matches than false ones, but not by much.

# We can also do it the opposite way: what is the top match for each book in our banned books dataset?
top_rows <- apply(sim_mat, 2, which.max)
top_rowscores <- apply(sim_mat, 2, max)

top_matches_cw <- bastille %>% # Columnwise top matches
  mutate(matched_super_title = super_books[top_rows,]$super_book_title, # get titles of top matches
         matched_super_code = super_books[top_rows,]$super_book_code, # get codes of top matches
         banned_has_code = str_length(illegal_super_book_code) > 1, # does the banned book have a super_book_code?
         banned_code_same = matched_super_code == illegal_super_book_code, # if so, are the codes the same?
         score = top_rowscores) %>%
  select(illegal_super_book_code, illegal_full_book_title, matched_super_title, score, banned_has_code, banned_code_same) %>%
  arrange(score)

# Now we can measure how this procedure did.
# How many did it get right and wrong, to our best knowledge?
top_matches_cw %>%
  group_by(banned_has_code, banned_code_same) %>%
  summarise(n = n())


# How many of the bastille books have super_book_codes of books that are not marked 'Poin'?
# That is, how many bastille books were missed in FBTEE-1?
old_to_drop <- bastille %>%
  filter(str_length(illegal_super_book_code) == 11) %>% # Keep only titles with old superbook codes
  left_join(super_books, by = c("illegal_super_book_code" = "super_book_code")) %>%
  filter(is.na(super_book_title)) %>%
  select(illegal_super_book_code, illegal_full_book_title, illegal_notes) %>%
  pull(illegal_super_book_code)
# There are apparently 13 books in the banned books data that have older super_book_codes, but those
# old super_books were NOT marked 'Poin' in FBTEE-1.

bastille_filtered <- bastille %>%
  filter(!illegal_super_book_code %in% old_to_drop, # drop the books that we know are not in the 'poin' data
         str_length(illegal_super_book_code) < 12) # The z-superbooks have codes 12 characters long

# What are the top matches for each Bastille book already in the super_book data?
# In principle, every book from FBTEE-1 should be in the new banned books data
sim_mat <- lapply(super_books$super_book_title, function(x) {
  sim_vec <- stringsim(x, bastille_filtered$illegal_full_book_title, method = 'qgram')
}) %>%
  unlist() %>%
  matrix(nrow = nrow(super_books), ncol = nrow(bastille_filtered), byrow = T)

top_cols <- apply(sim_mat, 1, which.max)
top_colscores <- apply(sim_mat, 1, max)

top_matches_rw <- super_books %>% # Rowise top matches
  mutate(matched_illegal_title = bastille_filtered[top_cols,]$illegal_full_book_title, # get titles of top matches
         matched_illegal_code = bastille_filtered[top_cols,]$illegal_super_book_code, # get codes of top matches
         banned_has_code = str_length(matched_illegal_code) > 1, # does the banned book have a super_book_code?
         banned_code_same = super_book_code == matched_illegal_code, # if so, are the codes the same?
         score = top_colscores) %>%
  select(super_book_code, super_book_title, matched_illegal_title, score, banned_has_code, banned_code_same) %>%
  arrange(desc(score))

# Now we can measure how this procedure did.
# How many did it get right and wrong, to our best knowledge?
top_matches_rw %>%
  group_by(banned_has_code, banned_code_same) %>%
  summarise(n = n())

# Having removed the confounding books seems to have improved matters a little.
# Let's have a look at the mistakes, though:
top_matches_rw %>%
  filter(banned_has_code == T,
         banned_code_same == F)

# Let's strip out those les and las, and also put everything to lower.
# Find all the parentheticals in super_book_title, and turn them into a regex for searching through the bastille titles
para_re <- str_extract_all(super_books$super_book_title, '\\(.{0,10}\\)') %>%
  unlist() %>%
  unique() %>%
  str_replace_all("[()]", "") %>%
  sapply(function(x) {
  low <- str_to_lower(x)
  if (str_sub(x, start = -1) == "'") { # if the string ends in an apostrophe
    end <- "" # then we want no matching criterion
  } else { # if not
    end <- "(\\s|$)" # we only want a match at the end of the string or at a word boundary
  }
  out <- paste0("(^|\\s)", low, end)
}) %>%
  paste(collapse = "|")


# Apply it
bastille_pre <- bastille_filtered %>%
  mutate(preprocessed_title = str_to_lower(illegal_full_book_title),
         preprocessed_title = str_replace_all(preprocessed_title, '\\(.{0,10}\\)', ' '),
         preprocessed_title = str_replace_all(preprocessed_title, para_re, " "),
         preprocessed_title = str_trim(preprocessed_title))
super_books_pre <- super_books %>%
  mutate(preprocessed_title = str_to_lower(super_book_title),
         preprocessed_title = str_replace_all(preprocessed_title, '\\(.{0,10}\\)', ' '),
         preprocessed_title = str_replace_all(preprocessed_title, para_re, " "),
         preprocessed_title = str_trim(preprocessed_title))

sim_mat <- lapply(super_books_pre$preprocessed_title, function(x) {
  sim_vec <- stringsim(x, bastille_pre$preprocessed_title, method = 'cosine')
}) %>%
  unlist() %>%
  matrix(nrow = nrow(super_books), ncol = nrow(bastille_pre), byrow = T)

# We can also do it the opposite way: what is the top match for each book in our banned books dataset?
top_rows <- apply(sim_mat, 2, which.max)
top_rowscores <- apply(sim_mat, 2, max)

top_matches_cw <- bastille_pre %>% # Columnwise top matches
  mutate(matched_super_title = super_books[top_rows,]$super_book_title, # get titles of top matches
         matched_super_code = super_books[top_rows,]$super_book_code, # get codes of top matches
         banned_has_code = str_length(illegal_super_book_code) > 1, # does the banned book have a super_book_code?
         banned_code_same = matched_super_code == illegal_super_book_code, # if so, are the codes the same?
         score = top_rowscores) %>%
  select(illegal_super_book_code, illegal_full_book_title, matched_super_title, score, banned_has_code, banned_code_same) %>%
  arrange(score)

# Now we can measure how this procedure did.
# How many did it get right and wrong, to our best knowledge?
top_matches_cw %>%
  group_by(banned_has_code, banned_code_same) %>%
  summarise(n = n())

# Other way
top_cols <- apply(sim_mat, 1, which.max)
top_colscores <- apply(sim_mat, 1, max)

top_matches_rw <- super_books_pre %>% # Rowise top matches
  mutate(matched_illegal_title = bastille_pre[top_cols,]$illegal_full_book_title, # get titles of top matches
         matched_illegal_code = bastille_pre[top_cols,]$illegal_super_book_code, # get codes of top matches
         banned_has_code = str_length(matched_illegal_code) > 1, # does the banned book have a super_book_code?
         banned_code_same = super_book_code == matched_illegal_code, # if so, are the codes the same?
         score = top_colscores) %>%
  select(super_book_code, super_book_title, matched_illegal_title, score, banned_has_code, banned_code_same) %>%
  arrange(desc(score))

top_matches_rw %>%
  group_by(banned_has_code, banned_code_same) %>%
  summarise(n = n())
