# Loading packages
library(pacman)
p_load(tidyverse, fixest, data.table, here, magrittr)

county_dt = fread(here("data/002-data.csv"))

# Number of states 
n_distinct(county_dt$state)

# Regressing black income on pct pop enslaved and total pop
mod_het = feols(
  data = county_dt, 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 +  pop_total_2010
)
summary(mod_het)

# Grabbing the residuals 
county_dt$resids_het = resid(mod_het)

# Plotting the residuals 
qplot(county_dt$pct_pop_enslaved_1860, county_dt$resids_het)
qplot(county_dt$pop_total_2010, county_dt$resids_het)

# GQ Test ------------------------------------------------
# Sorting data
county_dt %<>% arrange(pct_pop_enslaved_1860)

# Number of observations in each group and coefficients
n_gq = 316
k_gq = length(mod_het$coefficients)

# Running two separate regressions
mod_g1 = feols(
  data = head(county_dt, n = n_gq), 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 +  pop_total_2010
)
mod_g2 = feols(
  data = tail(county_dt, n = n_gq), 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 +  pop_total_2010
)

# Getting SSE for each group 
sse_g1 = sum(resid(mod_g1)^2)
sse_g2 = sum(resid(mod_g2)^2)

# Calculating test statistic
stat_gq = sse_g1/sse_g2

# Calculating p-value 
p_gq = pf(
  stat_gq,
  df1 = n_gq - k_gq,
  df2 = n_gq - k_gq,
  lower.tail = FALSE
)

# White Test ------------------------------------------------

# Regressing squared residuals on x terms 
mod_white = feols(
  data = county_dt,
  fml = resids_het^2 ~ 
    pct_pop_enslaved_1860 +  pop_total_2010 + 
    pct_pop_enslaved_1860:pop_total_2010 + 
    pct_pop_enslaved_1860^2 +  pop_total_2010^2
)

# Calculating test statistic 
stat_white = nrow(county_dt) * r2(mod_white, type = "r2") |> unname()

# Degrees of freedom (-1 for intercept)
k_white = length(mod_white$coefficients) - 1

# Calculating p-value 
p_white = pchisq(q = stat_white, df = k_white, lower.tail = FALSE)

# WLS  ------------------------------------------------
mod_wls = feols(
  data = county_dt, 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 +  pop_total_2010,
  weights = ~pop_black_2010
)
summary(mod_wls)

# With het-robust std errors
summary(mod_het, vcov = "hetero")

# Cluster ------------------------------------------------
summary(mod_het, cluster = ~state)

# Interpret ------------------------------------------------
mod_61 = feols(
  data = county_dt, 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 +  was_confederate,
  vcov = "hetero"
)
summary(mod_61)

mod_63 = feols(
  data = county_dt, 
  fml = income_black_2010 ~ pct_pop_enslaved_1860 + was_confederate + pct_pop_enslaved_1860:was_confederate,
  vcov = "hetero"
)
summary(mod_63)





