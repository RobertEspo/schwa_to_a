### load libs & data ###
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

### Empirical Data ###

# F1 normalized

dat_long <- dat_tidy_bda %>%
  pivot_longer(
    cols = c(f1_lob, f2_lob),
    names_to = "formant",
    values_to = "value",
    names_pattern = "(f[12])"
  )

dat_summary <- dat_long %>%
  group_by(session, participant, formant, stress) %>%
  summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop")

dat_delta <- dat_summary %>%
  filter(formant == "f1", session %in% c(0,6)) %>%
  pivot_wider(
    names_from = stress,
    values_from = mean_value,
    names_prefix = "stress_"
  ) %>%
  mutate(delta = stress_1 - stress_0)

p_f1_delta <- ggplot(dat_delta,
       aes(x = factor(session), y = delta, group = participant)) +
  geom_point(size = 4, alpha = 0.6) +
  geom_line(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    y = "F1 difference (Stressed - Unstressed)",
    x = "Session",
    color = "Participant"
  ) +
  ds4ling_bw_theme()

ggsave(
  filename = here::here("figs", "p_f1_delta.png"),
  plot = p_f1_delta,
  width = 12,
  height = 8,
  dpi = 300
)


### models ###

# do individuals get better with unstressed vowels over time?
# %%% m_f1 %%%

#
# forest plot
#

m_f1_simp_y_labs <- c(
  "Intercept",
  "Stressed syllable",
  "Session",
  "Stressed syllable x Session"
)

m_f1_simp_labs_tib <- tibble(
  y = m_f1_simp_y_labs,
  x = -0.25
) %>%
  mutate(y = fct_relevel(
    y,
    "Intercept",
    "Stressed syllable",
    "Session",
    "Stressed syllable x Session"
  ))

p_f1_forest <- as_tibble(m_f1) %>% 
  select(starts_with("b_")) %>% 
  pivot_longer(everything(), names_to = "Parameter", values_to = "Estimate") %>% 
  mutate(Parameter = case_when(
    Parameter == "b_Intercept" ~ "Intercept",
    Parameter == "b_stress1" ~ "Stressed syllable",
    Parameter == "b_session" ~ "Session",
    Parameter == "b_stress1:session" ~ "Stressed syllable x Session",
    TRUE ~ Parameter
  ),
  Parameter = fct_relevel(Parameter,
                          "Intercept",
                          "Stressed syllable",
                          "Session",
                          "Stressed syllable x Session")
  ) %>%
  ggplot(., aes(x = Estimate, y = Parameter)) + 
  coord_cartesian(xlim = c(-0.51, .51)) + 
  scale_x_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = 0, lty = 3) + 
  geom_text(data = m_f1_simp_labs_tib, hjust = 0, vjust = 0.5, size = 2.25, 
            aes(y = y, x = x, label = y), family = "Times") + 
  stat_halfeye(slab_alpha = 0.5, pch = 21, point_fill = "white", 
               slab_fill = viridis::viridis_pal(option = "B", begin = 0.25)(1), 
               point_size = 1.5) + 
  scale_y_discrete(limits = rev) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(x = NULL, y = NULL)

ggsave(
  filename = here::here("figs", "p_f1_forest.png"),
  plot = p_f1_forest,
  width = 12,
  height = 8,
  dpi = 300
)

#
# conditional effects
#

p_f1_ce <- conditional_effects(
  m_f1, 
  effects = "session:stress", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300)

p_gg_f1_ce <- plot(p_f1_ce, plot = FALSE, line_args = list(size = 4))[[1]] +
  scale_x_continuous(expand = c(0, 0)) +
  geom_line(aes(group = effect2__, color = effect2__), size = 1.5) +
  scale_color_manual(name = NULL, labels = c("unstressed /a/","stressed /a/"),
                     values = alpha(viridis::viridis_pal(option = "B", end = 0.85)(2), 0.1)) +
  labs(y = "Predicted normalized F1", x = "Week") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.7, .95),
    legend.direction = "horizontal",
    legend.key.size = unit(0.7, "cm"),
    legend.text.align = 0.5
  ) +
  guides(color = guide_legend(override.aes = list(fill = NA, size = 2)))

ggsave(
  filename = here::here("figs", "p_gg_f1_ce.png"),
  plot = p_gg_f1_ce,
  width = 8,
  height = 6,
  dpi = 300
)

# does amount of spanish input or english input predict increase?
# %%% m_f1_es_en_use %%%

#
# forest plot
#

m_f1_es_en_use_simp_y_labs <- c(
  "Intercept",
  "Session",
  "Total Spanish",
  "Total English",
  "Session x Total Spanish",
  "Session x Total English"
)

m_f1_es_en_use_simp_labs_tib <- tibble(
  y = m_f1_es_en_use_simp_y_labs,
  x = -0.25
) %>%
  mutate(y = fct_relevel(
    y,
    "Intercept",
    "Session",
    "Total Spanish",
    "Total English",
    "Session x Total Spanish",
    "Session x Total English"
  ))

p_f1_es_en_use_forest <- as_tibble(m_f1_es_en_use) %>% 
  select(starts_with("b_")) %>% 
  pivot_longer(everything(), names_to = "Parameter", values_to = "Estimate") %>% 
  mutate(Parameter = case_when(
    Parameter == "b_Intercept" ~ "Intercept",
    Parameter == "b_session" ~ "Session",
    Parameter == "b_spanTotal_c" ~ "Total Spanish",
    Parameter == "b_engTotal_c" ~ "Total English",
    Parameter == "b_session:spanTotal_c" ~ "Session x Total Spanish",
    Parameter == "b_session:engTotal_c" ~ "Session x Total English",
    TRUE ~ Parameter
  ),
  Parameter = fct_relevel(Parameter,
                          "Intercept",
                          "Session",
                          "Total Spanish",
                          "Total English",
                          "Session x Total Spanish",
                          "Session x Total English")
  ) %>%
  ggplot(., aes(x = Estimate, y = Parameter)) + 
  coord_cartesian(xlim = c(-0.26, .26)) + 
  scale_x_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = 0, lty = 3) + 
  geom_text(data = m_f1_es_en_use_simp_labs_tib, hjust = 0, vjust = 0.5, size = 2.25, 
            aes(y = y, x = x, label = y), family = "Times") + 
  stat_halfeye(slab_alpha = 0.5, pch = 21, point_fill = "white", 
               slab_fill = viridis::viridis_pal(option = "B", begin = 0.25)(1), 
               point_size = 1.5) + 
  scale_y_discrete(limits = rev) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(x = NULL, y = NULL)

ggsave(
  filename = here::here("figs", "p_f1_es_en_use.png"),
  plot = m_f1_es_en_use,
  width = 12,
  height = 8,
  dpi = 300
)

#
# conditional effects
# total spanish & english
#

p_f1_es_use_ce <- conditional_effects(
  m_f1_es_en_use, 
  effects = "session:spanTotal_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanTotal_c = c(-1, 1)))

p_f1_en_use_ce <- conditional_effects(
  m_f1_es_en_use, 
  effects = "session:engTotal_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(engTotal_c = c(-1, 1)))

# Spanish
df_es <- plot(p_f1_es_use_ce, plot = FALSE)[[1]]$data
df_es$language <- "Spanish"
df_es$condition <- as.factor(df_es$effect2__)  # 0 vs 1 for spanTotal_c

# English
df_en <- plot(p_f1_en_use_ce, plot = FALSE)[[1]]$data
df_en$language <- "English"
df_en$condition <- as.factor(df_en$effect2__)  # 0 vs 1 for engTotal_c

df_combined <- bind_rows(df_es, df_en)

p_gg_f1_es_en_use_ce <- ggplot(df_combined, aes(x = session, y = estimate__, color = language, linetype = condition)) +
  geom_line(size = 1.5) +
  scale_color_manual(name = NULL, labels = c("English","Spanish"),
                     values = viridis::viridis_pal(option = "B", end = 0.85)(2)) +  
  labs(x = "Week", y = "Predicted normalized F1", color = "Language", linetype = "SD") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.15, .85),
    legend.direction = "horizontal",
    legend.key.size = unit(0.8, "cm"),
    legend.text.align = 0.5
  )

ggsave(
  filename = here::here("figs", "p_gg_f1_es_en_use_ce.png"),
  plot = p_gg_f1_es_en_use_ce,
  width = 8,
  height = 6,
  dpi = 300
)

# does it matter if the input is native or non-native?
### m_f1_span_type_input

#
# forest plot
#

m_f1_es_en_use_simp_y_labs <- c(
  "Intercept",
  "Session",
  "Native",
  "Non-native",
  "Session x Native",
  "Session x Non-native"
)

m_f1_span_type_input_simp_labs_tib <- tibble(
  y = m_f1_es_en_use_simp_y_labs,
  x = -0.25
) %>%
  mutate(y = fct_relevel(
    y,
    "Intercept",
    "Session",
    "Native",
    "Non-native",
    "Session x Native",
    "Session x Non-native"
  ))

p_f1_span_type_input_forest <- as_tibble(m_f1_span_type_input) %>% 
  select(starts_with("b_")) %>% 
  pivot_longer(everything(), names_to = "Parameter", values_to = "Estimate") %>% 
  mutate(Parameter = case_when(
    Parameter == "b_Intercept" ~ "Intercept",
    Parameter == "b_session" ~ "Session",
    Parameter == "b_spanNat_c" ~ "Native",
    Parameter == "b_spanNonNat_c" ~ "Non-native",
    Parameter == "b_session:spanNat_c" ~ "Session x Native",
    Parameter == "b_session:spanNonNat_c" ~ "Session x Non-native",
    TRUE ~ Parameter
  ),
  Parameter = fct_relevel(Parameter,
                          "Intercept",
                          "Session",
                          "Native",
                          "Non-native",
                          "Session x Native",
                          "Session x Non-native")
  ) %>%
  ggplot(., aes(x = Estimate, y = Parameter)) + 
  coord_cartesian(xlim = c(-0.26, .26)) + 
  scale_x_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = 0, lty = 3) + 
  geom_text(data = m_f1_span_type_input_simp_labs_tib, hjust = 0, vjust = 0.5, size = 2.25, 
            aes(y = y, x = x, label = y), family = "Times") + 
  stat_halfeye(slab_alpha = 0.5, pch = 21, point_fill = "white", 
               slab_fill = viridis::viridis_pal(option = "B", begin = 0.25)(1), 
               point_size = 1.5) + 
  scale_y_discrete(limits = rev) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(x = NULL, y = NULL)

ggsave(
  filename = here::here("figs", "p_f1_span_type_input_forest.png"),
  plot = m_f1_span_type_input_forest,
  width = 12,
  height = 8,
  dpi = 300
)

#
# conditional effects
# native vs non-native input
#

p_m_f1_native_input_ce <- conditional_effects(
  m_f1_span_type_input, 
  effects = "session:spanNat_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanNat_c = c(-1, 1)))

p_m_f1_non_native_input_ce <- conditional_effects(
  m_f1_span_type_input, 
  effects = "session:spanNonNat_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanNonNat_c = c(-1, 1)))

# Native
df_nat <- plot(p_m_f1_native_input_ce, plot = FALSE)[[1]]$data
df_nat$input <- "native"
df_nat$condition <- as.factor(df_nat$effect2__)  # 0 vs 1 for spanNat_c

# Non-native
df_nn <- plot(p_m_f1_non_native_input_ce, plot = FALSE)[[1]]$data
df_nn$input <- "non native"
df_nn$condition <- as.factor(df_nn$effect2__)  # 0 vs 1 for engNonNat_c

df_combined <- bind_rows(df_nat, df_nn)

p_gg_f1_span_input_ce <- ggplot(df_combined, aes(x = session, y = estimate__, color = input, linetype = condition)) +
  geom_line(size = 1.5) +
  scale_color_manual(name = "Input", labels = c("Native","Non Native"),
                     values = viridis::viridis_pal(option = "B", end = 0.85)(2)) +
  scale_linetype_manual(name = "SD", values = c("-1" = "dashed", "1" = "solid")) +
  labs(x = "Week", y = "Predicted normalized F1") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.20, .85),
    legend.direction = "horizontal",
    legend.key.size = unit(0.8, "cm"),
    legend.text.align = 0.5
  ) +
  guides(
    color = guide_legend(order = 1),
    linetype = guide_legend(order = 2)
  )

ggsave(
  filename = here::here("figs", "p_gg_f1_span_input_ce.png"),
  plot = p_gg_f1_span_input_ce,
  width = 8,
  height = 6,
  dpi = 300
)

# here we can confirm that total input matters, not native or non-native
### m_f1_quant_vs_qual

#
# forest plot
#

m_f1_quant_vs_qual_simp_y_labs <- c(
  "Intercept",
  "Session",
  "Native",
  "Non-native",
  "Total Spanish",
  "Session x Native",
  "Session x Non-native",
  "Session x Total Spanish"
)

m_f1_quant_vs_qual_simp_labs_tib <- tibble(
  y = m_f1_quant_vs_qual_simp_y_labs,
  x = -0.25
) %>%
  mutate(y = fct_relevel(
    y,
    "Intercept",
    "Session",
    "Native",
    "Non-native",
    "Total Spanish",
    "Session x Native",
    "Session x Non-native",
    "Session x Total Spanish"
  ))

p_f1_quant_vs_qual_forest <- as_tibble(m_f1_quant_vs_qual) %>% 
  select(starts_with("b_")) %>% 
  pivot_longer(everything(), names_to = "Parameter", values_to = "Estimate") %>% 
  mutate(Parameter = case_when(
    Parameter == "b_Intercept" ~ "Intercept",
    Parameter == "b_session" ~ "Session",
    Parameter == "b_spanNat_c" ~ "Native",
    Parameter == "b_spanNonNat_c" ~ "Non-native",
    Parameter == "b_spanTotal_c" ~ "Total Spanish",
    Parameter == "b_session:spanNat_c" ~ "Session x Native",
    Parameter == "b_session:spanNonNat_c" ~ "Session x Non-native",
    Parameter == "b_session:spanTotal_c" ~ "Session x Total Spanish",
    TRUE ~ Parameter
  ),
  Parameter = fct_relevel(Parameter,
                          "Intercept",
                          "Session",
                          "Native",
                          "Non-native",
                          "Total Spanish",
                          "Session x Native",
                          "Session x Non-native",
                          "Session x Total Spanish")
  ) %>%
  ggplot(., aes(x = Estimate, y = Parameter)) + 
  coord_cartesian(xlim = c(-0.26, .26)) + 
  scale_x_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = 0, lty = 3) + 
  geom_text(data = m_f1_quant_vs_qual_simp_labs_tib, hjust = 0, vjust = 0.5, size = 2.25, 
            aes(y = y, x = x, label = y), family = "Times") + 
  stat_halfeye(slab_alpha = 0.5, pch = 21, point_fill = "white", 
               slab_fill = viridis::viridis_pal(option = "B", begin = 0.25)(1), 
               point_size = 1.5) + 
  scale_y_discrete(limits = rev) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(x = NULL, y = NULL)

ggsave(
  filename = here::here("figs", "p_f1_quant_vs_qual_forest.png"),
  plot = p_f1_quant_vs_qual_forest,
  width = 12,
  height = 8,
  dpi = 300
)

# does the type of non-native input matter?
### m_f1_qual

#
# forest plot
#

m_f1_qual_simp_y_labs <- c(
  "Intercept",
  "Session",
  "NN+",
  "NN=",
  "NN-",
  "Session x NN+",
  "Session x NN=",
  "Session x NN-"
)

m_f1_qual_simp_labs_tib <- tibble(
  y = m_f1_qual_simp_y_labs,
  x = -0.25
) %>%
  mutate(y = fct_relevel(
    y,
    "Intercept",
    "Session",
    "NN+",
    "NN=",
    "NN-",
    "Session x NN+",
    "Session x NN=",
    "Session x NN-"
  ))

p_f1_qual_forest <- as_tibble(m_f1_qual) %>% 
  select(starts_with("b_")) %>% 
  pivot_longer(everything(), names_to = "Parameter", values_to = "Estimate") %>% 
  mutate(Parameter = case_when(
    Parameter == "b_Intercept" ~ "Intercept",
    Parameter == "b_session" ~ "Session",
    Parameter == "b_spanBetter_c" ~ "NN+",
    Parameter == "b_spanSame_c" ~ "NN=",
    Parameter == "b_spanWorse_c" ~ "NN-",
    Parameter == "b_session:spanBetter_c" ~ "Session x NN+",
    Parameter == "b_session:spanSame_c" ~ "Session x NN=",
    Parameter == "b_session:spanWorse_c" ~ "Session x NN-",
    TRUE ~ Parameter
  ),
  Parameter = fct_relevel(Parameter,
                          "Intercept",
                          "Session",
                          "NN+",
                          "NN=",
                          "NN-",
                          "Session x NN+",
                          "Session x NN=",
                          "Session x NN-")
  ) %>%
  ggplot(., aes(x = Estimate, y = Parameter)) + 
  coord_cartesian(xlim = c(-0.26, .26)) + 
  scale_x_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = 0, lty = 3) + 
  geom_text(data = m_f1_qual_simp_labs_tib, hjust = 0, vjust = 0.5, size = 2.25, 
            aes(y = y, x = x, label = y), family = "Times") + 
  stat_halfeye(slab_alpha = 0.5, pch = 21, point_fill = "white", 
               slab_fill = viridis::viridis_pal(option = "B", begin = 0.25)(1), 
               point_size = 1.5) + 
  scale_y_discrete(limits = rev) + 
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(x = NULL, y = NULL)

ggsave(
  filename = here::here("figs", "p_f1_qual_forest.png"),
  plot = p_f1_qual_forest,
  width = 12,
  height = 8,
  dpi = 300
)

#
# conditional effects
# non-native input quality
#

p_m_f1_nn_better_ce <- conditional_effects(
  m_f1_qual, 
  effects = "session:spanBetter_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanBetter_c = c(-1, 1)))

p_m_f1_nn_same_ce <- conditional_effects(
  m_f1_qual, 
  effects = "session:spanSame_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanSame_c = c(-1, 1)))

p_m_f1_nn_worse_ce <- conditional_effects(
  m_f1_qual, 
  effects = "session:spanWorse_c", 
  re_formula = NA, 
  method = "posterior_epred", 
  spaghetti = TRUE, 
  ndraws = 300,
  int_conditions = list(spanWorse_c = c(-1, 1)))

# Better
df_better <- plot(p_m_f1_nn_better_ce, plot = FALSE)[[1]]$data
df_better$quality <- "Better"
df_better$condition <- as.factor(df_better$effect2__)  # -1 vs 1

# Same
df_same <- plot(p_m_f1_nn_same_ce, plot = FALSE)[[1]]$data
df_same$quality <- "Same"
df_same$condition <- as.factor(df_same$effect2__)  # -1 vs 1

# Worse
df_worse <- plot(p_m_f1_nn_worse_ce, plot = FALSE)[[1]]$data
df_worse$quality <- "Worse"
df_worse$condition <- as.factor(df_worse$effect2__)  # -1 vs 1

# Combine all three
df_combined <- bind_rows(df_better, df_same, df_worse)

p_gg_m_f1_qual_better_ce <- ggplot(df_combined %>% filter(quality %in% c("Better")), aes(x = session, y = estimate__, color = quality, linetype = condition)) +
  geom_line(size = 1.5) +
  scale_color_viridis_d(option = "B", end = 0.85, name = "Quality") +
  scale_linetype_manual(name = "Condition", values = c("-1" = "dashed", "1" = "solid")) +
  labs(x = "Week", y = "Predicted normalized F1") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.30, .85),
    legend.direction = "horizontal",
    legend.key.size = unit(0.8, "cm"),
    legend.text.align = 0.5
  )

ggsave(
  filename = here::here("figs", "p_gg_m_f1_qual_better_ce.png"),
  plot = p_gg_m_f1_qual_better_ce,
  width = 8,
  height = 6,
  dpi = 300
)

p_gg_m_f1_qual_worse_ce <- ggplot(df_combined %>% filter(quality %in% c("Better","Worse")), aes(x = session, y = estimate__, color = quality, linetype = condition)) +
  geom_line(size = 1.5) +
  scale_color_viridis_d(option = "B", end = 0.85, name = "Quality") +
  scale_linetype_manual(name = "Condition", values = c("-1" = "dashed", "1" = "solid")) +
  labs(x = "Week", y = "Predicted normalized F1") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.30, .85),
    legend.direction = "horizontal",
    legend.key.size = unit(0.8, "cm"),
    legend.text.align = 0.5
  )

ggsave(
  filename = here::here("figs", "p_gg_m_f1_qual_worse_ce.png"),
  plot = p_gg_m_f1_qual_worse_ce,
  width = 8,
  height = 6,
  dpi = 300
)

p_gg_m_f1_qual_same_ce <- ggplot(df_combined %>% filter(quality %in% c("Better","Worse","Same")), aes(x = session, y = estimate__, color = quality, linetype = condition)) +
  geom_line(size = 1.5) +
  scale_color_viridis_d(option = "B", end = 0.85, name = "Quality") +
  scale_linetype_manual(name = "Condition", values = c("-1" = "dashed", "1" = "solid")) +
  labs(x = "Week", y = "Predicted normalized F1") +
  ds4ling::ds4ling_bw_theme(base_size = 12) +
  theme(
    legend.background = element_blank(),
    legend.position = c(.30, .85),
    legend.direction = "horizontal",
    legend.key.size = unit(0.8, "cm"),
    legend.text.align = 0.5
  )

ggsave(
  filename = here::here("figs", "p_gg_m_f1_qual_same_ce.png"),
  plot = p_gg_m_f1_qual_same_ce,
  width = 8,
  height = 6,
  dpi = 300
)