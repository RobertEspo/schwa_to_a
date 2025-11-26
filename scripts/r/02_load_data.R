# load libs
source(here::here("scripts","r","00_libs.R"))

# load raw data
dat_raw <- read_csv(here("data","dat.csv"))

# tidy dat
dat_tidy <- dat_raw %>%
  
  # remove f3 values
  select(-starts_with("f3_")) %>%
  
  # remove NA values
  drop_na() %>%

  # filter for target unstressed /a/
  filter(following_phone == "boundary") %>%
  
  # separate file name into participant, session, & word+repetition
  separate(file_name, into = c("participant","session","item"), sep = "_") %>%
  
  mutate(
    
    # separate word & repetition
    rep_num = str_extract(item, "\\d$") %>% as.numeric,
    rep_num = if_else(is.na(rep_num), 1, rep_num + 1),
    item = str_remove(item, "\\d$"),
    
    # clean session col
    session = as.factor(str_extract(session, "\\d+$"))
  ) %>%
  
  # computer f1 centroid
  rowwise() %>%
  mutate(f1_centroid = mean(c_across(starts_with("f1_")), na.rm = TRUE)) %>%
  ungroup() %>%
  
  # computer f2 centroid
  rowwise() %>%
  mutate(f2_centroid = mean(c_across(starts_with("f2_")), na.rm = TRUE)) %>%
  ungroup()

# make df long for formant percentages
dat_long <- dat_tidy %>%
  pivot_longer(
    cols = c(starts_with("f1_"), starts_with("f2_")) & 
      !ends_with("centroid"),
    names_to = c("formant", "percent"),
    names_pattern = "(f[12])_(.*)",
    values_to = "hz"
  ) %>%
  mutate(percent = as.numeric(percent),
         participant = as.factor(participant),
         item = as.factor(item))

# only f1 values in col "formant"
dat_long_f1 <- dat_long %>%
  filter(formant == "f1")

# only f2 values in col "formant"
dat_long_f2 <- dat_long %>%
  filter(formant == "f2")
