source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

dat_tidy %>%
  na.omit %>%
  group_by(session) %>%
  summarize(f1_centroid_mean = mean(f1_centroid),
            f1_centroid_sd = sd(f1_centroid),
            f2_centroid_mean = mean(f2_centroid),
            f2_centroid_sd = sd(f2_centroid))

dat_tidy %>%
  na.omit %>%
  group_by(participant, session) %>%
  summarize(f1_centroid_mean = mean(f1_centroid),
            f1_centroid_sd = sd(f1_centroid),
            f2_centroid_mean = mean(f2_centroid),
            f2_centroid_sd = sd(f2_centroid))

ggplot(dat_tidy, aes(x = f2_centroid, y = f1_centroid, color = session)) +
  geom_point(alpha = 0.7, size = 3) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)", title = "Vowel space by session") +
  
  # spanish /a/ from bradlow 1995
  geom_point(aes(x = 1353, y = 638), color = "red", size = 4, shape = 8) +
  geom_text(aes(x = 1353, y = 638, label = "/a/"), color = "red", vjust = -1, size = 5) +
  
  # english schwa from flemming 2009
  geom_point(aes(x = 1772, y = 665), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1772, y = 665, label = "/ə/"), color = "blue", vjust = -1, size = 5) +
  
  # english /a/ from bradlow 1995
  geom_point(aes(x = 1244, y = 780), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1244, y = 780, label = "/ɑ/"), color = "blue", vjust = -1, size = 5)


ggplot(dat_tidy, aes(x = f1_centroid, color = session)) +
  geom_boxplot()

ggplot(dat_tidy, aes(x = f2_centroid, color = session)) +
  geom_boxplot()

ggplot(dat_tidy, aes(x = f1_centroid, color = session)) +
  facet_wrap(~participant) +
  geom_boxplot()

ggplot(dat_tidy, aes(x = f2_centroid, color = session)) +
  facet_wrap(~participant) +
  geom_boxplot()

dat_long <- dat_tidy %>%
  select(-f1_centroid, -f2_centroid) %>%
  pivot_longer(
    cols = matches("f[12]_\\d+"),
    names_to = c("formant", "percent"),
    names_pattern = "(f[12])_(\\d+)",
    values_to = "value"
  ) %>%
  mutate(percent = as.numeric(percent))

dat_wide <- dat_long %>%
  pivot_wider(names_from = formant, values_from = value)

dat_avg <- dat_wide %>%
  group_by(session, percent) %>%
  summarise(
    f1_mean = mean(f1, na.rm = TRUE),
    f2_mean = mean(f2, na.rm = TRUE)
  )

ggplot(dat_avg, aes(x = f2_mean, y = f1_mean)) +
  geom_point() +
  geom_line() +
  geom_text(aes(label=percent)) +
  facet_wrap(~session) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)", title = "Average F1/F2 trajectory across time") +
  
  # spanish /a/ from bradlow 1995
  geom_point(aes(x = 1353, y = 638), color = "red", size = 4, shape = 8) +
  geom_text(aes(x = 1353, y = 638, label = "/a/"), color = "red", vjust = -1, size = 5) +
  
  # english schwa from flemming 2009
  geom_point(aes(x = 1772, y = 665), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1772, y = 665, label = "/ə/"), color = "blue", vjust = -1, size = 5) +
  
  # english /a/ from bradlow 1995
  geom_point(aes(x = 1244, y = 780), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1244, y = 780, label = "/ɑ/"), color = "blue", vjust = -1, size = 5)

dat_avg_participants <- dat_wide %>%
  group_by(percent, session, participant) %>%
  summarise(
    f1_mean = mean(f1, na.rm = TRUE),
    f2_mean = mean(f2, na.rm = TRUE)
  )

ggplot(dat_avg_participants, aes(x = f2_mean, y = f1_mean, color = session)) +
  geom_point() +
  geom_line() +
  facet_wrap(~ participant) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)", title = "Average F1/F2 trajectory across time") +
  
  # spanish /a/ from bradlow 1995
  geom_point(aes(x = 1353, y = 638), color = "red", size = 4, shape = 8) +
  geom_text(aes(x = 1353, y = 638, label = "/a/"), color = "red", vjust = -1, size = 5) +
  
  # english schwa from flemming 2009
  geom_point(aes(x = 1772, y = 665), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1772, y = 665, label = "/ə/"), color = "blue", vjust = -1, size = 5) +
  
  # english /a/ from bradlow 1995
  geom_point(aes(x = 1244, y = 780), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1244, y = 780, label = "/ɑ/"), color = "blue", vjust = -1, size = 5)

ggplot(dat_avg_participants %>% 
         filter(session %in% c(0,6))) +
         aes(x = f2_mean, y = f1_mean, color = session) +
  geom_line() +
  geom_text(aes(label=percent)) +
  facet_wrap(~ participant) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)", title = "Average F1/F2 trajectory across time") +
  
  # spanish /a/ from bradlow 1995
  geom_point(aes(x = 1353, y = 638), color = "red", size = 4, shape = 8) +
  geom_text(aes(x = 1353, y = 638, label = "/a/"), color = "red", vjust = -1, size = 5) +
  
  # english schwa from flemming 2009
  geom_point(aes(x = 1772, y = 665), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1772, y = 665, label = "/ə/"), color = "blue", vjust = -1, size = 5) +
  
  # english /a/ from bradlow 1995
  geom_point(aes(x = 1244, y = 780), color = "blue", size = 4, shape = 8) +
  geom_text(aes(x = 1244, y = 780, label = "/ɑ/"), color = "blue", vjust = -1, size = 5)

