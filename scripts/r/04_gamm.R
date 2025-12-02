# load libs & data
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

# model f1
f1_gam <- gam(
  formula = f1 ~
    session +
    s(step, by = session, k = 9) +
    s(step, participant, bs = "fs", m = 1),
  data = dat_gams
)

summary(f1_gam)

# get model predictions
f1_gam_preds_1 <- predict_gam(f1_gam, exclude_terms = "s(step,participant)")

f1_gam_preds_2 <- predict_gam(
  f1_gam,
  length_out = 51,
  exclude_terms = "s(step,participant)"
)

f1_gam_preds_2 %>%
  plot(series = "step", comparison = "session")
