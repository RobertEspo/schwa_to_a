# load libs & data
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))


# model f1
f1_gam <- gam(
  hz ~ session +                              # linear shift per session
    s(percent, by = session, k = 9) +   # smooth trajectory per session
    s(percent, participant, bs = "fs", k = 5),  # random smooth per participant
  data = dat_long_f1,
  method = "REML"
)

summary(f1_gam)

plot_smooth(f1_gam,
            view = "percent",
            plot_all = "session",
            rm.ranef = FALSE)

# model f2
f2_gam <- gam(
  hz ~ session +                              # linear shift per session
    s(percent, by = session, k = 9) +   # smooth trajectory per session
    s(percent, participant, bs = "fs", k = 5),  # random smooth per participant
  data = dat_long_f2,
  method = "REML"
)

summary(f2_gam)

plot_smooth(f2_gam,
            view = "percent",
            plot_all = "session",
            rm.ranef = FALSE)

###

# Predictions for F2
pred_f2 <- predict(f2_gam, newdata = dat_long_f2, type = "response", se.fit = TRUE)
dat_long_f2$hz_pred <- pred_f2$fit
dat_long_f2$se <- pred_f2$se.fit

# Predictions for F1
pred_f1 <- predict(f1_gam, newdata = dat_long_f1, type = "response", se.fit = TRUE)
dat_long_f1$hz_pred <- pred_f1$fit
dat_long_f1$se <- pred_f1$se.fit

# -------------------------
# 2. Merge F1 & F2
# -------------------------
df_vowel <- dat_long_f2 %>%
  select(participant, session, percent, f2_pred = hz_pred) %>%
  left_join(
    dat_long_f1 %>% select(participant, session, percent, f1_pred = hz_pred),
    by = c("participant", "session", "percent")
  )

# -------------------------
# 3. Plot F1-F2 vowel space with gganimate
# -------------------------
ggplot(df_vowel, aes(x = f2_pred, y = f1_pred, color = session, group = participant)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_path(alpha = 0.7) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)", title = "Vowel space trajectories") +
  theme_minimal()

  transition_time(percent) +
  ease_aes('linear')