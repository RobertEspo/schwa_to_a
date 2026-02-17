source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

dat_tidy_long <- dat_tidy_wide %>%
  rowwise() %>%
  mutate(id = paste(participant, session, item, rep, sep = "_")) %>%  # unique token ID
  ungroup() %>%
  pivot_longer(
    cols = starts_with("f1_") | starts_with("f2_"),
    names_to = c(".value", "step"),
    names_sep = "_"
  ) %>%
  mutate(step = as.numeric(step)) %>%
  mutate(
    stress = as.factor(case_when(
      stressed_a == 1 & unstressed_a == 0 ~ "stressed",
      stressed_a == 0 & unstressed_a == 1 ~ "unstressed",
      TRUE ~ NA
    ))) %>%
  na.omit()

dat_tidy_long_means <- dat_tidy_long %>%
  group_by(participant, session, step, stress) %>%
  summarise(
    mean_f1 = mean(f1, na.rm = TRUE),
    mean_f2 = mean(f2, na.rm = TRUE),
    .groups = "drop"
  )

average_trajectories <- ggplot(dat_tidy_long_means, aes(x = mean_f2, y = mean_f1)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  facet_wrap(~session) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(title = 'Step: {frame_time}', x = 'F2 (Hz)', y = 'F1 (Hz)') +
  transition_time(step) +
  ease_aes('linear') +
  shadow_mark(past = TRUE, future = FALSE, alpha = 0.3)

anim <- animate(
  average_trajectories,
  renderer = gifski_renderer(),
  width = 800,
  height = 600,
  fps = 10,          # frames per second
  duration = 5       # total duration in seconds
)

anim_save(
  filename = here("figs","average_trajectories.gif"),
  animation = anim
)

# unstressed only
walk(
  unique(dat_tidy_long_means$participant),
  function(pname) {
    
    df <- dat_tidy_long_means %>% filter(participant == pname,
                                         stress = "unstressed")
    
    # Create animation
    anim <- ggplot(df, aes(x = mean_f2, y = mean_f1)) +
      geom_point(alpha = 0.7) +
      facet_wrap(~session) +
      scale_y_reverse() +
      scale_x_reverse() +
      geom_text(aes(label = step), alpha = 0.5, size = 3) +
      labs(
        title = paste0("Participant: ", pname),
        x = "F2 (Hz)",
        y = "F1 (Hz)",
        subtitle = "Step: {frame_time}"
      ) +
      transition_time(step) +
      ease_aes('linear') +
      shadow_mark(past = TRUE, future = FALSE, alpha = 0.3)
    
    # Animate
    anim_out <- animate(anim, renderer = gifski_renderer(), width = 800, height = 600, fps = 10)
    
    # Save GIF
    anim_save(
      filename = here("figs", paste0("avg_trajectory_", pname, ".gif")),
      animation = anim_out
    )
  }
)

# unstressed and stressed
walk(
  unique(dat_tidy_long_means$participant),
  function(pname) {
    
    df <- dat_tidy_long_means %>% filter(participant == pname)
    
    anim <- ggplot(df, aes(x = mean_f2, y = mean_f1, color = stress)) +
      geom_point(alpha = 0.8, size = 3) +
      facet_wrap(~session) +
      scale_y_reverse() +
      scale_x_reverse() +
      scale_color_manual(values = c("stressed" = "red", "unstressed" = "blue")) +
      labs(
        title = paste0("Participant: ", pname),
        x = "F2 (Hz)",
        y = "F1 (Hz)",
        color = "Stress",
        subtitle = "Step: {frame_time}"
      ) +
      transition_time(step) +
      ease_aes('linear') +
      shadow_mark(past = TRUE, future = FALSE, alpha = 0.3)
    
    anim_out <- animate(anim, renderer = gifski_renderer(), width = 800, height = 600, fps = 10)
    
    anim_save(
      filename = here("figs", paste0("avg_trajectory_unstressed-and-stressed_", pname, ".gif")),
      animation = anim_out
    )
  }
)


################################################################################

bda_data <- dat_tidy_wide %>%
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
    f2_lob = (f1_mean - mean(f2_mean, na.rm = TRUE)) / sd(f1_mean, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(stress))

f1_priors <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(cauchy(0, 1), class = "sd"),
  prior(cauchy(0, 1), class = "sigma")
)
  
m_f1 <- brm(
  f1_lob ~ stress * session +
    (1 | participant) +
    (1 | item),
  data = bda_data,
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1")
)

conditional_effects(m_f1)

f2_priors <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(cauchy(0, 1), class = "sd"),
  prior(cauchy(0, 1), class = "sigma")
)

m_f2 <- brm(
  f2_lob ~ stress * session +
    (1 | participant) +
    (1 | item),
  data = bda_data,
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f2_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f2")
)

conditional_effects(m_f2)

