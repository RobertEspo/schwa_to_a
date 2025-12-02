source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

average_trajectories <- ggplot(dat_gams, aes(x = mean_f2, y = mean_f1)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  facet_wrap(~session) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(title = 'Step: {frame_time}', x = 'F2 (Hz)', y = 'F1 (Hz)') +
  transition_time(step) +
  ease_aes('linear') +
  shadow_mark(past = TRUE, future = FALSE, alpha = 0.3)
  

anim_save(average_trajectories, here("assets","phonetics_final_figs","average_trajectories.gif"), renderer = gifski_renderer())

walk(
  names(dat_participants_processed),
  function(pname) {
    
    df <- dat_participants_processed[[pname]]
    
    p <- ggplot(df, aes(x = mean_f2, y = mean_f1)) +
      geom_point(alpha = 0.7, show.legend = FALSE) +
      facet_wrap(~session) +
      scale_y_reverse() +
      scale_x_reverse() +
      geom_text(aes(label = step)) +
      labs(
        title = paste0("Average Trajectory: ", pname),
        x = "F2 (Hz)",
        y = "F1 (Hz)"
      )
    
    # Save to file
    ggsave(
      filename = paste0("avg_trajectory_", pname, ".png"),
      plot = p,
      width = 8,
      height = 6,
      dpi = 300
    )
  }
)

average_trajectories_ems <- ggplot(dat_participants_processed$ems, 
                                   aes(x = mean_f2, y = mean_f1)) +
  geom_point(alpha = 0.7, show.legend = FALSE) +
  facet_wrap(~session) +
  scale_y_reverse() +
  scale_x_reverse() +
  labs(title = 'Step: {frame_time}', x = 'F2 (Hz)', y = 'F1 (Hz)') +
  transition_time(step) +
  ease_aes('linear') +
  shadow_mark(past = TRUE, future = FALSE, alpha = 0.3)

animate(average_trajectories_ems, renderer = gifski_renderer())

anim_save(here("assets","phonetics_final_figs","average_trajectories_ems.gif"), renderer = gifski_renderer())
