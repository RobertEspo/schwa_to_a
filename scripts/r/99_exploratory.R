source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

dat_tidy_long_plots <- dat_tidy_wide %>%
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

dat_tidy_long_means <- dat_tidy_long_plots %>%
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