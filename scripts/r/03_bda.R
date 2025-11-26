# load libs & data
source(here::here("scripts","r","00_libs.R"))
source(here::here("scripts","r","02_load_data.R"))

#######################
# model f2 trajectory #
#######################

# model formula
f2_formula <- bf(
  hz ~ session + s(percent, by = session, k = 5) +
     (1 | participant) + 
     (1 | item)
)

# take a look at priors

get_prior(f2_formula,
          family = gaussian(),
          data = dat_long_f2
)

# set weekly informative priors
priors_f2 <- c(
  set_prior("normal(1353, 200)", class = "Intercept"),  # intercept, bradlow 1995
  set_prior("normal(0, 75)", class = "b"),          # slopes / smooth weights
  set_prior("student_t(3, 0, 100)", class = "sds"),  # smooth wiggliness
  set_prior("student_t(3, 0, 100)", class = "sd"),   # random intercept SDs
  set_prior("student_t(3, 0, 100)", class = "sigma") # residual SD
)

# priors only model
f2_prior_model <- brm(
  formula = f2_formula,
  data = dat_long_f2,
  family = gaussian(),
  prior = priors_f2,
  chains = 4, cores = 4, iter = 2000,
  sample_prior = "only",
)

# visualize prior predictive check
pp_check(f2_prior_model, ndraws = 100)

# fit model
f2_bda <- brm(
  formula = f2_formula,
  data = dat_long_f2,
  family = gaussian(),
  chains = 4, cores = 4,
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  file = here("models","f2_bda.rds")
)

smooths <- conditional_smooths(f2_bda)
plot(smooths, ask = FALSE)

pp <- conditional_effects(f2_bda, "percent:session", points = TRUE)
plot(pp, points = TRUE)