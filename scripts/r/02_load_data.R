# load libs
source(here::here("scripts","r","00_libs.R"))

# load raw data
dat_raw <- read_csv(here("data","dat.csv"))

# tidy dat
dat_tidy <- dat_raw %>%
  # filter for target unstressed /a/
  filter(following_phone == "boundary") %>%
  
  # separate file name into participant, session, & word+repetition
  separate(file_name, into = c("participant","session","word"), sep = "_") %>%
  
  mutate(
    
    # separate word & repetition
    rep_num = str_extract(word, "\\d$") %>% as.numeric,
    rep_num = if_else(is.na(rep_num), 1, rep_num + 1),
    word = str_remove(word, "\\d$"),
    
    # clean session col
    session = as.factor(str_extract(session, "\\d+$"))
  )