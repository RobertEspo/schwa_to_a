# load libs & data
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

# Assign priors (these will be used for all models)
# I think normal(0, 0.5) is fairly wide for the changes in normalized f1, but...
f1_priors <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(cauchy(0, 1), class = "sd"),
  prior(cauchy(0, 1), class = "sigma")
)

# Okay, now the models. It'll be set up like this:

# %%% #
# Question the model is designed to answer
## Model
# Quick summary of answer
# %%% #

### more target-like behavior = increase in f1

###############################################################################

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
# Yes, f1 increases across sessions in general for unstressed /a/
# and they approach f1 values of stressed /a/.
# So they become more target-like over time!

# does amount of spanish input or english input predict increase?
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
# Veeeery weakly...
# higher spanish exposure weakly predicts faster f1 increase
# higher english exposure weakly predicts slower f1 increase
# so that's expected!

# does it matter if the input is native or non-native?
m_f1_span_type_input <- brm(
  f1_lob ~ 0 + Intercept + session * spanNat_c +
    session * spanNonNat_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_span_type_input")
)


# here we can confirm that total input matters, not native or non-native
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
# so native input still predicts slower f1 increase...
# but total input matters a lot more!

# does the type of non-native input matter?
m_f1_qual <- brm(
  f1_lob ~ 0 + Intercept + 
    session * spanBetter_c +
    session * spanSame_c +
    session * spanWorse_c +
    (1 + session | participant) +
    (1 | item),
  data = dat_tidy_bda %>% filter(stress == 0),
  warmup = 2000, iter = 4000, chains = 4,
  family = gaussian(),
  cores = 4,
  prior = f1_priors,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  file = here("models", "m_f1_qual")
)
# better spanish = slower f1 increase
# same spanish = moderate f1 increase
# worse spanish = moderate f1 increase