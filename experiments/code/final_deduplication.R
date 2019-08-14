# Final deduplication

# Now that all the data has been uploaded, and data entry work as begun on the
# confiscations dataset, it is time to thoroughly deduplicate the agents,
# works and editions.

source('init.R')

agent <- mpce %>% fetch_table('agent')
edition <- mpce %>% fetch_table('edition') %>%
  mutate(clipped_title = str_sub(full_book_title, end = 50))
work <- mpce %>% fetch_table('work') %>%
  mutate(clipped_title = str_sub(work_title, end = 50))
attribution <- mpce %>% fetch_table('edition_author')
profession <- mpce %>% fetch_table('profession')
agent_prof <- mpce %>% fetch_table('agent_profession')
addresses <- mpce %>% fetch_table('agent_address')
place <- mpce %>% fetch_table('place')
author_type <- mpce %>% fetch_table('author_type')

# Compute string similarity on names/titles
agent_dupes <- compute_pairwise_similarities(agent, agent_code, name)
work_dupes <- compute_pairwise_similarities(work, work_code, clipped_title)

# For the editions, let's do it year by year.
ed_all_auths <- attribution %>%
  left_join(author_type, by = c('author_type' = 'id')) %>%
  left_join(agent, by = c('author' = 'agent_code')) %>%
  transmute(
    edition_code = edition_code,
    author = str_glue("{name} ({type})")
  ) %>%
  group_by(edition_code) %>%
  summarise(authors = paste0(author, collapse = "; ")) %>%
  mutate(authors = str_remove(authors, "^NA \\([A-Za-z]+\\);?\\s?")) %>%
  filter(nchar(authors) > 0)

edition_dupes <- edition %>%
  mutate(clipped_year = str_sub(imprint_publication_years, end=4)) %>%
  group_by(clipped_year) %>%
  group_split() %>%
  map_dfr(compute_pairwise_similarities, id_col = edition_code, str_col = clipped_title) %>%
  left_join(ed_all_auths, by = c("id_1" = "edition_code")) %>%
  rename(authors_1 = authors) %>%
  left_join(ed_all_auths, by = c("id_2" = "edition_code")) %>%
  rename(authors_2 = authors) %>%
  left_join(edition, by = c("id_1" = "edition_code")) %>%
  rename(
    title_1 = full_book_title,
    imprint_place_1 = imprint_publication_places,
    imprint_publisher_1 = imprint_publishers,
    imprint_year_1 = imprint_publication_years,
    edition_status_1 = edition_status,
    format_1 = edition,
    pages_1 = pages,
    vols_1 = number_of_volumes,
    notes_1 = notes,
    work_code_1 = work_code
  ) %>%
  left_join(edition, by = c("id_2" = "edition_code")) %>%
  rename(
    title_2 = full_book_title,
    imprint_place_2 = imprint_publication_places,
    imprint_publisher_2 = imprint_publishers,
    imprint_year_2 = imprint_publication_years,
    edition_status_2 = edition_status,
    format_2 = edition,
    pages_2 = pages,
    vols_2 = number_of_volumes,
    notes_2 = notes,
    work_code_2 = work_code
  ) %>%
  select(
    edition_1 = id_1,
    title_1,
    authors_1,
    imprint_place_1,
    imprint_year_1,
    imprint_publisher_1,
    format_1,
    pages_1,
    vols_1,
    edition_status_1,
    notes_1,
    work_code_1,
    edition_2 = id_2,
    title_2,
    authors_2,
    imprint_place_2,
    imprint_year_2,
    imprint_publisher_2,
    format_2,
    pages_2,
    vols_2,
    edition_status_2,
    notes_2,
    work_code_2,
    osa,
    cos
  ) %>%
  filter(
    imprint_place_1 == imprint_place_2,
    imprint_publisher_1 == imprint_publisher_2,
    format_1 == format_2,
    vols_1 == vols_2,
    work_code_1 == work_code_2,
    (!is.na(imprint_place_1) && !is.na(imprint_place_2)),
    (!is.na(imprint_publisher_1) && !is.na(imprint_publisher_2)),
    (!is.na(format_1) && !is.na(format_2))
  ) %T>%
  write_excel_csv("editions_pairwise_comparison_filtered.csv", na = "")
  
# Add some extra data to allow for manual checking
agent_dupes %>%
  left_join(
    select(
      agent,
      agent_code,
      other_names_1 = other_names,
      title_1 = title,
      designation_1 = designation,
      status_1 = status,
      notes_1 = notes
      ),
      by = c("id_1" = "agent_code")
    ) %>%
  left_join(
    select(
      agent,
      agent_code,
      other_names_2 = other_names,
      title_2 = title,
      designation_2 = designation,
      status_2 = status,
      notes_2 = notes
    ),
    by = c("id_2" = "agent_code")
  ) %>%
  select(id_1, str_1, designation_1, id_2, str_2, designation_2) %>%
  print(n = 50)

# Another view on things: duplicated names
agent %>%
  mutate(notes = str_glue_data(.x = ., "({.$agent_code}) {.$notes}"),
         designation = str_glue_data(.x = ., "({.$agent_code}) {.$designation}"),
         title = str_glue_data(.x = ., "({.$agent_code}) {.$title}")) %>%
  group_by(name) %>%
  filter(n() > 1) %>%
  summarise(codes = paste0(agent_code, collapse='; '),
            designation = paste0(designation, collapse='; '),
            title = paste0(title, collapse = '; '),
            notes = paste0(notes, collapse=' ;')) %>%
  write_excel_csv(path = 'duplicated_agent_names.csv')

edition %>%
  mutate(clipped_year = str_sub(imprint_publication_years, 1, 4)) %>%
  group_by(clipped_title, clipped_year) %>%
  filter(n() > 1) %>%
  ungroup()

work %>%
  mutate(illegality_notes = str_glue_data(.x = ., "({.$work_code}) {.$illegality_notes}"),
         categorisation_notes = str_glue_data(.x = ., "({.$work_code}) {.$categorisation_notes}")) %>%
  group_by(work_title) %>%
  filter(n() > 1) %>%
  summarise(codes = paste0(work_code, collapse=';'),
            illegality_notes = paste0(illegality_notes, collapse='; '),
            categorisation_notes = paste0(categorisation_notes, collapse='; ')) %T>%
  print() %>%
  write_excel_csv(path = 'duplicated_work_titles.csv')

# Also export pairwise comparisons
sample_edition <- edition %>%
  left_join(filter(attribution, author_type == 1), by="edition_code") %>%
  left_join(agent, by = c("author" = "agent_code")) %>%
  group_by(work_code) %>%
  sample_n(1) %>%
  ungroup() %>%
  transmute(
    work_code = work_code,
    sample_edition = str_glue_data(.x = ., "{.$full_book_title}, by {.$name}. ({.$imprint_publication_places}, {.$imprint_publication_years})")
  )
  
work_dupes %>%
  # Need to provide a sample edition
  left_join(
    select(
      sample_edition,
      work_code,
      sample_edition_1 = sample_edition
    ),
    by = c("id_1" = "work_code")
  ) %>%
  left_join(
    select(
      sample_edition,
      work_code,
      sample_edition_2 = sample_edition
    ),
    by = c("id_2" = "work_code")
  ) %>%
  write_excel_csv(path = "pairwise_work_comparisons.csv")

# Add more information to agent_dupes, and export

sample_authored_edition <- edition %>%
  left_join(attribution, by = "edition_code") %>%
  group_by(author) %>%
  sample_n(1) %>%
  ungroup() %>%
  transmute(
    agent_code = author,
    author_of = paste0(full_book_title, " (", imprint_publication_places, ", ", imprint_publication_places, ")"))

all_profs_for_agent <- agent_prof %>%
  left_join(profession, by = "profession_code") %>%
  group_by(agent_code) %>%
  summarise(professions = paste0(profession_type, collapse = "; "))

agent_address <- addresses %>%
  left_join(place, by = "place_code") %>%
  group_by(agent_code) %>%
  summarise(addresses = paste0(name, collapse = "; "))

agent_personal <- agent %>%
  transmute(
    agent_code = agent_code,
    title_and_desig = paste0(title, " / ", designation),
    notes = notes
  ) %>%
  left_join(all_profs_for_agent, by = "agent_code") %>%
  left_join(sample_authored_edition, by = "agent_code") %>%
  left_join(agent_address, by = "agent_code")
  
agent_dupes %>%
  left_join(agent_personal, by = c("id_1" = "agent_code")) %>%
  left_join(agent_personal, by = c("id_2" = "agent_code")) %>%
  select(
    agent_1 = id_1,
    name_1 = str_1,
    title_and_desig_1 = title_and_desig.x,
    notes_1 = notes.x,
    professions_1 = professions.x,
    author_of_1 = author_of.x,
    addresses_1 = addresses.x,
    agent_2 = id_2,
    name_2 = str_2,
    title_and_desig_2 = title_and_desig.y,
    notes_2 = notes.y,
    professions_2 = professions.y,
    author_of_2 = author_of.y,
    addresses_2 = addresses.y,
    osa = osa,
    cos = cos
  ) %T>%
  print() %>%
  write_excel_csv("pairwise_agent_comparison.csv")
