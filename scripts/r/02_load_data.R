# load libs
source(here::here("scripts","r","00_libs.R"))

# load models
list2env(
  setNames(
    lapply(list.files(here::here("models"), "\\.rds$", full.names = TRUE), readRDS),
    tools::file_path_sans_ext(basename(list.files(here::here("models"), "\\.rds$", full.names = TRUE)))
  ),
  envir = .GlobalEnv
)

# demographic data
demographic_dat <- read_csv(here("data","demographic_dat.csv"))

# language use dat
lang_use_dat <- read_csv(here("data","lang_use_dat.csv"))


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
    session = as.numeric(session),
    item = as.factor(item),
    rep = as.factor(rep),
    phoneme = as.factor(phoneme)
  )

dat_tidy_bda <- dat_tidy_wide %>%
  rowwise() %>%
  mutate(
    f1_mean = mean(c_across(starts_with("f1_")), na.rm = TRUE),
    f2_mean = mean(c_across(starts_with("f2_")), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    stress = as.factor(case_when(
      stressed_a == 1 & unstressed_a == 0 ~ 1,
      stressed_a == 0 & unstressed_a == 1 ~ 0,
      TRUE ~ NA
    ))) %>%
  group_by(participant) %>%
  mutate(
    f1_lob = (f1_mean - mean(f1_mean, na.rm = TRUE)) / sd(f1_mean, na.rm = TRUE),
    f2_lob = (f2_mean - mean(f2_mean, na.rm = TRUE)) / sd(f2_mean, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(stress)) %>% 
  left_join(demographic_dat %>% mutate( # add demographic dat
    participant = name) %>% select(   
    participant, age, yrsStudySpan,
    liveSpanCntry, liveSpanCntryLength,
    l2Exposure, fluency),
    by = "participant") %>%
  left_join(lang_use_dat %>% mutate(
    participant = as.factor(name),
    session = as.numeric(week),
    rateOverall = rateOveral) %>% select(
      participant, session,
      spanTotal, spanNat, spanNonNat,
      spanBetter, spanWorse, spanSame,
      engTotal, rateSpeak, rateUnderstand,
      rateOverall, extraCurParticipate
    ), by = c("participant","session")) %>%
  mutate( # center lang use data
    spanTotal_c = scale(spanTotal)[, 1],
    spanNat_c = scale(spanNat)[, 1],
    spanNonNat_c = scale(spanNonNat)[, 1],
    spanBetter_c = scale(spanBetter)[, 1],
    spanWorse_c = scale(spanWorse)[, 1],
    spanSame_c = scale(spanSame)[, 1],
    engTotal_c = scale(engTotal)[, 1],
    
    extraCurParticipate = as.factor(extraCurParticipate)
  )

dat_participant <- dat_tidy_bda %>%
  group_by(participant) %>%
  summarize(
    spanTotal = mean(spanTotal, na.rm = TRUE),
    spanNat = mean(spanNat, na.rm = TRUE),
    spanNonNat = mean(spanNonNat, na.rm = TRUE),
    spanBetter = mean(spanBetter, na.rm = TRUE),
    spanWorse = mean(spanWorse, na.rm = TRUE),
    spanSame = mean(spanSame, na.rm = TRUE),
    engTotal = mean(engTotal, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    spanTotal_c = scale(spanTotal)[,1],
    spanNat_c = scale(spanNat)[,1],
    spanNonNat_c = scale(spanNonNat)[,1],
    spanBetter_c = scale(spanBetter)[,1],
    spanWorse_c = scale(spanWorse)[,1],
    spanSame_c = scale(spanSame)[,1],
    engTotal_c = scale(engTotal)[,1]
  )

dat_tidy_bda_omnibus <- dat_tidy_bda %>%
  filter(session %in% c(0,6),
         stress == 0) %>%
  mutate(session = if_else(session == 0, "start","end")) %>%
  group_by(participant, item, rep, session) %>%
  summarize(mean_f1_z = mean(f1_lob, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = session, values_from = mean_f1_z) %>%
  mutate(delta_f1 = start - end) %>%
  left_join(dat_participant, by = "participant")

