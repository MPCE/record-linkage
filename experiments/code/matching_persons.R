########################################################################################################
#
# MPCE Record Linkage Project
#
# Project: Mapping Print, Charting Enlightenment
#
# Script: Getting a handle on the person data
#
# Authors: Michael Falk, Simon Burrows
#
# Date: 17/12/18
#
########################################################################################################

# The big one... disambiguating the people.

source("init.R")

# All the person data...

clients <- manuscripts %>%
  dbSendQuery("SELECT * FROM clients") %>%
  fetch(n = Inf) %>%
  as.tibble()

people <- manuscripts %>%
  dbSendQuery("SELECT * FROM people") %>%
  fetch(n = Inf) %>%
  as.tibble()

clients_people <- manuscripts %>%
  dbSendQuery("SELECT * FROM clients_people") %>%
  fetch(n = Inf) %>%
  as.tibble()

booksellers <- manuscripts %>%
  dbSendQuery("SELECT * FROM manuscript_agents_booksellers") %>%
  fetch(n = Inf) %>%
  as.tibble()

inspectors <- manuscripts %>%
  dbSendQuery("SELECT * FROM manuscript_agents_inspectors") %>%
  fetch(n = Inf) %>%
  as.tibble()

dealers <- manuscripts %>%
  dbSendQuery("SELECT * FROM manuscript_dealers") %>%
  fetch(n = Inf) %>%
  as.tibble()

authors <- manuscripts %>%
  dbSendQuery("SELECT * FROM manuscript_authors") %>%
  fetch(n = Inf) %>%
  as.tibble()

person_keywords <- manuscripts %>%
  dbSendQuery(paste0(
    "SELECT * FROM keywords ",
    "WHERE tag_code = 't01'"
  )) %>%
  fetch(n = Inf) %>%
  as.tibble()

people_professions <- manuscripts %>%
  dbSendQuery("SELECT * FROM people_professions ") %>%
  fetch(n = Inf) %>%
  as.tibble()

# How are all these tables related?

## SECTION 1: CLIENTS AND PERSONS

# Join the tables
cp_joined <- clients %>%
  full_join(clients_people, by="client_code") %>%
  full_join(people, by="person_code")

# Does every client have a person code?
cp_joined %>%
  filter(is.na(person_code), !is.na(client_code)) %>%
  summarise(no_person_code = n())

# Apparently 52 clients lack a person code. Who are they?
cp_joined %>%
  filter(is.na(person_code), !is.na(client_code)) %>%
  select(client_code, client_name, partnership) %>%
  print(n = Inf)

# Do any person codes lack a client?
cp_joined %>%
  filter(is.na(client_code)) %>%
  select(person_code, person_name) %>%
  print(n = Inf)

# How many person codes refer to groups of clients?
cp_joined %>%
  select(person_code, client_code) %>%
  drop_na() %>%
  group_by(person_code) %>%
  summarise(clients_per_person_code = n()) %>%
  group_by(clients_per_person_code) %>%
  summarise(freq = n())

# Which are these person codes
cp_joined %>%
  select(person_code, person_name, client_code, client_name) %>%
  drop_na() %>%
  group_by(person_code) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  arrange(person_code) %>%
  print(n = Inf)

# Are there any client codes with multiple person codes?
# There should be many for partnerships, but we want to check for errors...
cp_joined %>%
  group_by(client_code) %>%
  filter(n() > 1) %>%
  select(client_code, client_name, person_code, person_name) %>%
  filter(!str_detect(client_name, "&|\\bet\\b")) %>%
  print(n = Inf)
# There do not seem to be too many errors here.

# Who are they?
cp_joined %>%
  group_by(person_code) %>%
  summarise(clients_per_person_code = n())

# Are there any glaring errors?
# Incorrectly assigned person codes:
cp_joined %>%
  select(client_name, person_name) %>% # get names
  drop_na() %>% # drop clients without persons and vice versa
  filter(!str_detect(client_name, "&|\\bet\\b|Soci")) %>% # drop partnerships and companies
  mutate(osa = stringsim(client_name, person_name, method = 'osa'),
         cosine = stringsim(client_name, person_name, method = 'cosine')) %>%
  arrange(osa, cosine) %>%
  filter(osa < 0.5)

# Do any of those persons without client codes have a profession?
# NB: people_professions is the only other table that refers to person_codes in the database
cp_joined %>%
  left_join(people_professions, by = "person_code") %>%
  filter(is.na(client_code), !is.na(profession_code)) %>%
  select(person_code, person_name, profession_code) %>%
  group_by(person_code, person_name) %>%
  summarise(num_professions = n())

## SECTION 2: NEW CLIENTS IN THE DEALER, BOOKSELLER AND INSPECTOR TABLES

# New clients have been given a code beginning with 'cm' or 'cp' rather than 'cl'.

# Check: are there any codes that don't fit this cm/cp/cl mould?
sum(
  dealers %>% filter(!str_detect(Client_Code, "cm|cl|cp")) %>% nrow(),
  booksellers %>% filter(!str_detect(Client_Code, "cm|cl|cp")) %>% nrow(),
  inspectors %>% filter(!str_detect(Client_Code, "cm|cl|cp")) %>% nrow()
) # co0001 

# How many of these 'cm/cp' clients are there?
sum(
  dealers %>% filter(str_detect(Client_Code, "cp")) %>% nrow(),
  booksellers %>% filter(str_detect(Client_Code, "cm")) %>% nrow(),
  inspectors %>% filter(str_detect(Client_Code, "cm")) %>% nrow()
) # 428

# Yeah, but how many are unique...
c(
  dealers %>% pull(Client_Code),
  booksellers %>% pull(Client_Code),
  inspectors %>% pull(Client_Code)
) %>%
  as_tibble() %>%
  filter(str_detect(value, "cm|cp")) %>%
  distinct() %>%
  nrow()
# 419.

# Looking closely at JE's code, it turns out that manuscript_agents_booksellers is never referred to.
# Does it contain any necessary information?
sum(booksellers$Client_Code %in% dealers$Client_Code) / nrow(booksellers)
# No. Every client code from manuscript_agents_booksellers is represented in manuscript_agents_dealers

# Are the inspectors included in the dealers table too?
sum(inspectors$Client_Code %in% dealers$Client_Code) / nrow(inspectors)
# No, there are some inspectors who aren't there.

# Are there any duplicate codes?
dealers %>%
  left_join(inspectors, by = "Client_Code") %>%
  drop_na() %>%
  filter(Dealer_Name != Agent_Name) %>%
  select(Client_Code, Dealer_Name, Agent_Name)

## SECTION 3: AUTHORS

# Are there any authors among the clients?
ca_mat <- stringsimmatrix(authors$author_name, clients$client_name, method = 'osa')
# Get list of possible joins:
clients_authors <- which(ca_mat > 0.8, arr.ind = T)
# Have a look at them...
ca_join <- tibble(
  client_code = clients[clients_authors[,2],]$client_code,
  client_name = clients[clients_authors[,2],]$client_name,
  author_code = authors[clients_authors[,1],]$author_code,
  author_name = authors[clients_authors[,1],]$author_name,
  osa = ca_mat[clients_authors],
  cosine = stringsim(client_name, author_name, method = 'cosine')
) %>%
  arrange(desc(osa), desc(cosine)) %>%
  left_join(clients_people, by="client_code") %>%
  select(client_code, person_code, everything()) %>%
  distinct(author_code, .keep_all = T) %T>%
  print(n = Inf)
# 121 rows, maybe 100 actual matches

# Run seperate match against person table
pa_mat <- stringsimmatrix(authors$author_name, people$person_name, method = 'osa')
people_authors <- which(pa_mat > 0.8, arr.ind = T)
# Have a look at them...
pa_join <- tibble(
  person_code = people[people_authors[,2],]$person_code,
  person_name = people[people_authors[,2],]$person_name,
  author_code = authors[people_authors[,1],]$author_code,
  author_name = authors[people_authors[,1],]$author_name,
  osa = pa_mat[people_authors],
  cosine = stringsim(person_name, author_name, method = 'cosine')
) %>%
  arrange(desc(osa), desc(cosine)) %>%
  distinct(author_code, .keep_all = T) %>%
  left_join(clients_people, by = "person_code") %>%
  select(person_code, client_code, person_name, author_code, author_name, osa, cosine) %T>%
  print(n = Inf)
# 138 rows, maybe around 100 good matches.

write_excel_csv(pa_join, "internal/author_person.csv")

# Clients without person codes
no_person_codes <- clients %>%
  filter(partnership == 0, !client_code %in% clients_people$client_code) %>%
  select(client_code, client_name, partnership, notes)

no_person_codes %>%
  write_excel_csv("internal/clients_without_person_codes.csv")

no_person_matrix <- stringsimmatrix(no_person_codes$client_name, people$person_name, method = 'osa')
no_name_names <- which(no_person_matrix > 0.8, arr.ind = T)
# No matches


## SECTION 4: KEYWORDS

# Is there a person corresponding to any of the keywords at the moment?
kp_mat <- stringsimmatrix(person_keywords$keyword, people$person_name)
top_kp_matches <- apply(kp_mat, 1, which.max)
top_kp_scores <- apply(kp_mat, 1, max)
kp_join <- tibble(
  keyword_code = person_keywords$keyword_code,
  keyword = person_keywords$keyword,
  person_code = people$person_code[top_kp_matches],
  person_name = people$person_name[top_kp_matches],
  osa = top_kp_scores,
  cosine = stringsim(keyword, person_name, method = "cosine")
) %>%
  arrange(desc(osa), desc(cosine)) %>%
  filter(osa > 0.8) %T>%
  print(n = Inf)
# It seems that there are only 6-7 matches.

# How about with the authors?
ka_mat <- stringsimmatrix(person_keywords$keyword, authors$author_name)
top_ka_matches <- apply(ka_mat, 1, which.max)
top_ka_scores <- apply(ka_mat, 1, max)
ka_join <- tibble(
  keyword_code = person_keywords$keyword_code,
  keyword = person_keywords$keyword,
  author_code = authors$author_code[top_ka_matches],
  author_name = authors$author_name[top_ka_matches],
  osa = top_ka_scores,
  cosine = stringsim(keyword, author_name, method = "cosine")
) %>%
  arrange(desc(osa), desc(cosine)) %>%
  filter(osa > 0.7) %T>%
  print(n = Inf)
