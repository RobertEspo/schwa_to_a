# load libs
source(here::here("scripts","r","00_libs.R"))

# load raw data
dat_raw <- read_csv(here("data","formant_dat.csv"))

# tidy dat
dat_tidy_wide <- dat_raw %>%
  
  # remove unnecessary cols
  select(
    file_name:f2_90,
    -word
  ) %>%
  
  # separate file name into participant and two temporary cols
  separate(., file_name, into = c("participant","temp1","temp2"), sep = "_") %>%
  
  # separate temp1 into task type & session number
  extract(temp1, into = c("task","session"),
          regex = "(prodShadow)(\\d+)") %>%
  
  # separate temp2 into word and repetition
  extract(temp2, into = c("item","rep"),
          regex = "([a-zA-Z]+)(\\d*)"
  ) %>%
  
  # recode repetition col
  mutate(
    rep = as.integer(rep),
    rep = if_else(is.na(rep), 1L, rep + 1L),
    
  # add duration
  dur = end_time - start_time,
  
  # add (un)stressed /a/ cols
  unstressed_a = as.factor(if_else(following_phone == "boundary" & phoneme == "a", 1, 0)),
  stressed_a = as.factor(if_else(unstressed_a == 0 & phoneme == "a", 1, 0))
  ) %>%
  mutate(
    participant = as.factor(participant),
    session = as.factor(session),
    item = as.factor(item),
    rep = as.factor(rep),
    phoneme = as.factor(phoneme)
  )
