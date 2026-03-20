# load libs & data
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

f1_priors <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(cauchy(0, 1), class = "sd"),
  prior(cauchy(0, 1), class = "sigma")
)

# do individuals get better with unstressed vowels over time?
m_f1 <- brm(
  f1_lob ~ 0 + Intercept + stress * session +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda,
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1")
)

# does amount of spanish input or english input matter?
m_f1_es_en_use <- brm(
  f1_lob ~ 0 + Intercept + session * spanTotal_c * engTotal_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress = 0),
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_en_use")
)

# compare quantity vs quality of spanish input w/ following 2 models
# only using unstressed /a/ in these models
m_f1_es_use <- brm(
  f1_lob ~ 0 + Intercept + session * spanTotal_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_es_use")
)

m_f1_span_type_input <- brm(
  f1_lob ~ 0 + Intercept + session * spanNat_c +
    session * spanNonNat_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_span_type_input")
)

m_f1_quant_vs_qual <- brm(
  f1_lob ~ 0 + Intercept + session * spanNat_c +
    session * spanNonNat_c +
    session * spanTotal_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_quant_vs_qual")
)


#### excluding session

m_f1_quant_vs_qual_wo_session <- brm(
  f1_lob ~ 0 + Intercept + spanNat_c + spanNonNat_c + spanTotal_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 1000, iter = 2000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_quant_vs_qual_wo_session")
)


###############################################################################

conditions <- data.frame(
  stress = setNames(c(0,1),
                       c("unstressed","stressed")))

m_f1_en_use_conditional <- conditional_effects(
  m_f1_en_use, 
  effects = "engTotal_c",
  re_formula = NA,
  method = "posterior_epred",
  spaghetti = TRUE,
  ndraws = 300
)

plot(m_f1_en_use_conditional, plot = FALSE, line_args = list(size = 4))[[1]] +
       aes(x = engTotal,
           y = estimate__) +
  geom_line(size = 1.5) +
  geom_ribbon(aes(ymin = lower__, ymax = upper__, fill = factor(stress)),
              alpha = 0.2,
              color = NA) +
  facet_wrap(~ stress) +
  labs(
    x = "English total",
    y = "Predicted F1"
  ) +
  ds4ling::ds4ling_bw_theme(base_size = 12)
  

m_f1_span_use_conditional <- conditional_effects(
  m_f1_en_use, 
  effects = "stress:engTotal_c",
  re_formula = NA,
  method = "posterior_epred",
  spaghetti = TRUE,
  ndraws = 200
)

plot(m_f1_span_use_conditional, plot = FALSE, line_args = list(size = 4))[[1]] +
  aes(x = engTotal_c,
      y = estimate__) +
  geom_line(size = 1.5) +
  facet_wrap(~ stress) +
  labs(
    x = "English Use",
    y = "Predicted F1"
  ) +
  guides(color = guide_legend(override.aes = list(fill = NA, size = 2))) +
  ds4ling::ds4ling_bw_theme(base_size = 12)

###############################################################################

# omnibus model

f1_omnibus_priors <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(cauchy(0, 1), class = "sd"),
  prior(cauchy(0, 1), class = "sigma"),
  prior(lkj(1), class = "cor")
)

m_f1_delta <- brm(
  delta_f1 ~ 0 + Intercept + spanTotal_c + spanNat_c + spanNonNat_c + 
  spanBetter_c + spanWorse_c + spanSame_c +
    engTotal_c +
    (1 + spanTotal_c + spanNat_c + spanNonNat_c + 
       spanBetter_c + spanWorse_c + spanSame_c + 
       engTotal_c | participant) +
    (1 | item),
  data = dat_tidy_bda_omnibus,
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_omnibus_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_delta")
)

conditional_effects(m_f1_omnibus)

m_f1_omnibus <- brm(
  f1_lob ~ 0 + Intercept + 
    session * spanTotal_c + 
    session * spanNat_c + 
    session * spanNonNat_c + 
    session * spanBetter_c + 
    session * spanWorse_c + 
    session * spanSame_c +
    session * engTotal_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda,
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_omnibus")
)

conditional_effects(m_f1_omnibus)

# lower vowels have higher f1
# higher vowels have low f1

# We expect increasing f1 for more native-like production.

# predictors to test
predictors <- c("spanNat_c", "spanNonNat_c", "spanSame_c", "spanBetter_c", "engTotal_c")

compute_delta <- function(pred_name){
  # build a 4-row grid: week0_low, week6_low, week0_high, week6_high
  df <- tibble(
    session = c(0, 6, 0, 6),
    spanNat_c    = 0,
    spanNonNat_c = 0,
    spanSame_c   = 0,
    spanBetter_c = 0,
    engTotal_c   = 0,
    spanTotal_c  = 0,
    spanWorse_c  = 0,
    participant  = NA,
    item         = NA
  )
  
  # set predictor values
  df[[pred_name]] <- c(-1, -1, 1, 1)
  
  # get posterior predictions
  ep <- posterior_epred(m_f1_omnibus, newdata = df, re_formula = NA)
  
  # ΔF1: week6 - week0 for low and high
  delta_low  <- ep[,2] - ep[,1]
  delta_high <- ep[,4] - ep[,3]
  
  # summarize
  tibble(
    predictor = pred_name,
    delta_low_mean = mean(delta_low),
    delta_low_CI_lower = quantile(delta_low, 0.025),
    delta_low_CI_upper = quantile(delta_low, 0.975),
    delta_high_mean = mean(delta_high),
    delta_high_CI_lower = quantile(delta_high, 0.025),
    delta_high_CI_upper = quantile(delta_high, 0.975)
  )
}

# apply to all predictors
delta_results <- lapply(predictors, compute_delta) %>% bind_rows()
delta_results
