# load libs
source(here::here("scripts","r","00_libs.R"))

# load raw data
dat_raw <- read_csv(here("data","data_formants.csv"))

# tidy dat
dat_tidy <- dat_raw %>%
  
  # remove f3 values
  select(time, f1, f2, source_file) %>%
  
  # remove NA values
  drop_na() %>%
  
  # separate file name into participant, session, & word+repetition
  separate(source_file, into = c("participant","session","item", "delete_me"), sep = "_") %>%
    
  select(-delete_me) %>%
  
  mutate(
    # separate word & repetition
    rep_num = str_extract(item, "\\d$") %>% as.numeric,
    rep_num = if_else(is.na(rep_num), 1, rep_num + 1),
    item = str_remove(item, "\\d$"),
    
    # clean session col
    session = as.factor(str_extract(session, "\\d+$"))
  ) %>%
  mutate(participant = as.factor(participant))

dat_participants <- dat_tidy %>%
  group_by(participant) %>%
  group_split() %>%
  setNames(unique(dat_tidy$participant))

dat_participants_processed <- lapply(
  dat_participants,
  function(df) {
    df %>%
      group_by(session, item, rep_num) %>%
      mutate(
        norm_time = (time - min(time)) / (max(time) - min(time)),
        step = round(norm_time * 10) + 1
      ) %>%
      ungroup() %>%
      select(-norm_time) %>%
      mutate(
        rep_num = as.factor(rep_num),
        step = as.numeric(step)
      ) %>%
      group_by(session, step) %>%
      summarize(
        mean_f1 = mean(f1),
        mean_f2 = mean(f2),
        .groups = "drop"
      )
  }
)

dat_gams <- dat_tidy %>%
  group_by(session, item, rep_num) %>%
  mutate(norm_time = (time - min(time)) / (max(time) - min(time)),
         step = round(norm_time * 10) + 1) %>%
  ungroup() %>%
  select(-norm_time) %>%
  mutate(
    rep_num = as.factor(rep_num),
    step = as.numeric(step)
  ) %>%
  group_by(session, step) %>%
  summarize(mean_f1 = mean(f1),
            mean_f2 = mean(f2))
