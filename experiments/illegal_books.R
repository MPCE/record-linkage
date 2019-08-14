# Will we get the banned books done?
source('init.R')
work <- fetch_table(mpce, "work")
edition <- fetch_table(mpce, "edition")
bastille <- fetch_table(mpce, "bastille_register_record") %>%
  mutate(work_code = ifelse(nchar(work_code) == 0, NA, work_code),
         edition_code = ifelse(nchar(edition_code) == 0, NA, edition_code),
         title = str_remove(title, "<z?spk\\d+>")) %>%
  filter(is.na(work_code))
banned <- fetch_table(mpce, "banned_list_record") %>%
  mutate(work_code = ifelse(nchar(work_code) == 0, NA, work_code),
         title = str_remove(title, "<z?spbk\\d+>"))

# Each bastille book needs an edition_code
# Each banned book needs a work_code

banned_clipped <- str_sub(banned$title, 1, 50)
bastille_clipped <- str_sub(bastille$title, 1,  50)
work_clipped <- str_sub(work$work_title, 1, 50)


work_banned <- str_length(work_clipped) %>%
  matrix(data = ., nrow = length(banned_clipped), ncol = length(work_clipped), byrow = T)
work_bastille <- str_length(work_clipped) %>%
  matrix(data = ., nrow = length(bastille_clipped), ncol = length(work_clipped), byrow = T)
banned_len <- str_length(banned_clipped) %>%
  matrix(data = ., nrow = length(banned_clipped), ncol = length(work_clipped), byrow = F)
bastille_len <- str_length(bastille_clipped) %>%
  matrix(nrow = length(bastille_clipped), ncol = length(work_clipped), byrow = F)

banned_dist <- stringdistmatrix(banned_clipped, work_clipped, method = "osa")
banned_norm_mat <- pmax(banned_len, work_banned)
banned_sim <- 1 - (banned_dist / banned_norm_mat)

banned_matches <- which(banned_sim > 0.8, arr.ind = T)

banned_out <- bind_cols(banned[banned_matches[,1],], work[banned_matches[,2],], osa = banned_sim[banned_matches]) %>%
  select(ID, title, author, date, folio, notes, work_code = work_code1, work_title, osa)
banned_dupes <- compute_pairwise_similarities(banned, ID, title) %>%
  left_join(banned, by = c('id_1' = 'ID')) %>%
  left_join(banned, by = c('id_2' = 'ID')) %>%
  select(
    id_1,
    title_1 = str_1,
    author_1 = author.x,
    date_1 = date.x,
    folio_1 = folio.x,
    notes_1 = notes.x,
    id_2,
    title_2 = str_2,
    author_2 = author.y,
    date_2 = date.y,
    folio_2 = folio.y,
    notes_2  = notes.y
  )

write_excel_csv(banned_out, "banned_books_work_codes.csv", na = "")
write_excel_csv(banned_dupes, "banned_books_duplicates.csv", na = "")

bastille_dist <- stringdistmatrix(bastille_clipped, work_clipped)
bastille_norm_mat <- pmax(bastille_len, work_bastille)
bastille_sim = 1 - (bastille_dist / bastille_norm_mat)
bastille_matches = which(bastille_sim > 0.8, arr.ind = T)

bastille_out <- bind_cols(
  bastille[bastille_matches[,1],],
  work[bastille_matches[,2],],
  osa = bastille_sim[bastille_matches]
) %>%
  select(ID, bastille_title = title, author_name, imprint, work_code = work_code1, work_title, osa) %>%
  arrange(desc(osa)) %T>%
  write_excel_csv("bastille_work_codes.csv", na = "")

bastille_dupes = compute_pairwise_similarities(bastille, ID, title) %>%
  left_join(bastille, by = c('id_1' = 'ID')) %>%
  left_join(bastille, by = c('id_2' = 'ID')) %>%
  select(
    id_1,
    title_1 = str_1,
    category_1 = category.x,
    notes_1 = notes.x,
    author_1 = author_name.x,
    imprint_1 = imprint.x,
    id_2,
    title_2 = str_2,
    category_2 = category.y,
    notes_2 = notes.y,
    author_2 = author_name.y,
    imprint_2 = imprint.y,
    osa
  ) %>%
  arrange(desc(osa)) %>%
  write_excel_csv("bastille_duplicates.csv", na = "")
