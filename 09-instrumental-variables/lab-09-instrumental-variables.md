---
title: 'EC 421 Lab 9: Instrumental Variables'
author: "Emmett Saulnier"
date: "3/7/2022"
output: 
  html_document:
    theme: flatly
    toc: yes
    toc_depth: 1
    toc_float: yes
    keep_md: yes
---



Today is our last lab! I am going to show you how to implement **Instrumental Variables**, which is something you will talk about in lecture on Wednesday --- so we'll give you a soft introduction to the topic today. 

I will be hosting a review session during lab time next **Monday 3/14 at 4pm** (during regular lab hours). Come with any questions you have in preparation for the final exam the next day! I'll have your third problem set's graded either Tuesday or Wednesday, remember that the fourth problem set is already out, but it is optional for you to turn in.

# Causality   

We use methods like instrumental variables to try to estimate the **causal** effect of some variable on another. Remember the main assumption we need in order to interpret a causal effect in linear regression is exogeneity, $E[u_i|X]=0$, our explanatory variables must be uncorrelated with any other variables that are not included in the regression, but also affect the outcome variable ---  the $x$'s must be uncorrelated with the error term, $u$. 

One way to ensure that exogeneity holds is by running an experiment, randomly assigning treatment (the $x$ you are interested in). The randomization ensures that the expected value of the error term is the same across the treated and untreated groups. This is exactly how medical researchers learn about the effectiveness of various drug treatments --- they have a set of subjects and randomly assign each subject to either receive the treatment or get a placebo. Since everyone has the same likelihood of being in the treatment or control groups, any outside factors that affect the outcome will be equalized across the two groups. 

However, there are many situations where we would like to know causal effects, but it is impossible (or too expensive) to run an experiment --- this is the area of expertise for applied economists! Let's say we want to know the effect of years of schooling on income. In order to have a true experiment here, you would need to take a set of kids, and randomly assign them to have different numbers of years of schooling, and then measure their income some number of years later. That's a really hard experiment to run! First, you'd have to find a large enough group of people willing to have their education be dictated by the experiment. Second, you would have to wait years for that education to happen and then more years to measure subsequent income outcomes. 

So what do we do? Find examples in real life (observational data) where there has been some situation that mimics an experiment, or a "natural experiment", such that we believe exogeneity holds. Instrumental variables is one method of recovering a causal treatment effect when you have a natural experiment.  

# Instrumental Variables 

Let's say we want to estimate the effect of years of education on income,  

$$inc_i = \beta_0 + \beta_1 educ_i + u_i$$
But we know that exogeneity does **not** hold, $E[u|educ] \neq 0$, so our estimate of $\beta_1$ would be biased if we estimated this model using OLS. Why would exogeneity not hold? $u_i$ contains some measure of 'natural ability', which we cannot observe. Further, someone with more income might choose to get more school because their parents were wealthy. Or, growing up wealthy puts more pressure on kids to go to college.  

The key intuition for instrumental variables comes from thinking about the variation in our $x$, we want to isolate the exogenous part of $x$, the part that is not correlated with the error term, from the endogenous part, the part that is correlated with the error term. The exogenous variation is the "good" variation that will identify the causal effect of schooling on income.  

## What is an instrument?  

We can isolate the exogenous variation in $x$ with an **instrument**, an instrument is a variable $z_i$ that is...  

  1. **Relevant**: It is correlated with the explanatory variable. $Cov(x_i, z_i) \neq 0$   
  2. **Exogenous**: Uncorrelated with the disturbance. $Cov(z_i, u_i) = 0$

If these requirements hold, we can use just the variation in $x$ that is explained by $z$ to estimate the casusal effect of $x$ on $y$.  

Relevance is the easier of the two requirements, since we can actually measure and test the relationship between the instrument and $x$, just regress $x$ on $z$ and run a t-test for the significance of the coefficient on $z$. Exogeneity is **not testable**, in the same way that exogeneity is not testable in the standard OLS framework.  

In our example of estimating the effect of schooling on income, we need some variable that is correlated with schooling, but does not affect income directly. Let's brainstorm a bit...

- **Test Scores**: Standardized test scores are also going to be correlated with education level, people with higher scores likely have higher education. However, this would fail exogeneity for the same reason that education fails exogeneity! Test scores are likely to be correlated with parent's income, which is correlated with income.  
- **DuckID Number**: This is exogenous, it is a (somewhat) randomly assigned ID number, and thus will not be correlated with anything that affects income. BUT, it won't be relevant, because it also won't be correlated with education!  
- **Proximity to a college**: This is probably relevant, places closer to a college likely have higher education on average. It is also plausibly exogenous --- distance to a college shouldn't have any real effect on income.  

Let's move forward with proximity to a college as an instrument for years of education, this comes from [Card (1993)](https://davidcard.berkeley.edu/papers/geo_var_schooling.pdf). 

## How do we use a valid instrument?   

Implementing instrumental variables is often called Two Stage Least Squares (TSLS), because we'll use two regressions. First, we'll regress $x$ on our instrument $z$ and grab the fitted values $\hat{x}$ (predictions of $x$). Second, we'll regress our outcome $y$ on the predicted $x$'s from the first stage. 

The first stage isolates the variation in $x$ that comes from our instrument $z$ --- this is the "good" variation we are looking for, because it is exogenous! The first stage predictions $\hat{x}$ will not be correlated with any of the other factors affecting $y$ that are not in our model. Let's look at some equations to try to nail this down. The first stage is given by  

$$x_i = \gamma_0 + \gamma_1 z_i + \varepsilon_i$$

We'll estimate this using OLS, and get fitted values, $\hat{x}_i = \hat{\gamma}_0 + \hat{\gamma}_1z_i$. Now lets plug those fitted values into our main equation of interest

$$y_i = \beta_0 + \beta_1 \hat{x}_i + v_i$$
We want exogeneity to hold in this equation, which requires $Cov(\hat{x}_i,v_i)=0$. But let's plug in the equation for $\hat{x}$, 

\begin{align}
  Cov(\hat{x}_i,v_i)&=Cov(\hat{\gamma}_0 + \hat{\gamma}_1z_i, v_i) \\
   &= \hat{\gamma}_1 Cov(z_i, v_i) \\
   Cov(\hat{x}_i,v_i)&= 0
\end{align}

Where $Cov(z_i, v_i)=0$ by our exogeneity assumption about the instrument. So exogeneity holds in the second stage regression! $\hat{\beta}^{IV}_1$ will be an unbiased estimate for $\beta_1$!  

# Implementation in `R`   

There are lots of packages that are able to implement instrumental variables in `R`, but we'll start by manually estimating TSLS ourselves to help understand what is going on under the hood.  

### Two stage least squares (TSLS)   

As described above, there are a few steps in estimating an instrumental variables model. 

1. Find an instrument and convince yourself and others that it is exogenous     
2. Estimate the first stage, testing for relevance with a t or F test 
3. Grab the fitted values from the first stage  
4. Estimate your main regression using those fitted values   


First we'll load packages and the data --- the data are in the `AER` package.  


```r
# Loading packages 
library(pacman)
p_load(tidyverse, fixest, AER, skimr)

# This loads the data
data("CollegeDistance")

# Let's rename it 
income_df = CollegeDistance

# And remove the original
rm(CollegeDistance)
```

Remember to always look at your data before you run off and start estimating things!! The documentation for this data can be seen using `?CollegeDistance`


```r
skim(income_df)
```


Table: Data summary

|                         |          |
|:------------------------|:---------|
|Name                     |income_df |
|Number of rows           |4739      |
|Number of columns        |14        |
|_______________________  |          |
|Column type frequency:   |          |
|factor                   |8         |
|numeric                  |6         |
|________________________ |          |
|Group variables          |None      |


**Variable type: factor**

|skim_variable | n_missing| complete_rate|ordered | n_unique|top_counts                    |
|:-------------|---------:|-------------:|:-------|--------:|:-----------------------------|
|gender        |         0|             1|FALSE   |        2|fem: 2600, mal: 2139          |
|ethnicity     |         0|             1|FALSE   |        3|oth: 3050, his: 903, afa: 786 |
|fcollege      |         0|             1|FALSE   |        2|no: 3753, yes: 986            |
|mcollege      |         0|             1|FALSE   |        2|no: 4088, yes: 651            |
|home          |         0|             1|FALSE   |        2|yes: 3887, no: 852            |
|urban         |         0|             1|FALSE   |        2|no: 3635, yes: 1104           |
|income        |         0|             1|FALSE   |        2|low: 3374, hig: 1365          |
|region        |         0|             1|FALSE   |        2|oth: 3796, wes: 943           |


**Variable type: numeric**

|skim_variable | n_missing| complete_rate|  mean|   sd|    p0|   p25|   p50|   p75|  p100|hist  |
|:-------------|---------:|-------------:|-----:|----:|-----:|-----:|-----:|-----:|-----:|:-----|
|score         |         0|             1| 50.89| 8.70| 28.95| 43.92| 51.19| 57.77| 72.81|▂▆▇▇▂ |
|unemp         |         0|             1|  7.60| 2.76|  1.40|  5.90|  7.10|  8.90| 24.90|▅▇▂▁▁ |
|wage          |         0|             1|  9.50| 1.34|  6.59|  8.85|  9.68| 10.15| 12.96|▃▅▇▂▁ |
|distance      |         0|             1|  1.80| 2.30|  0.00|  0.40|  1.00|  2.50| 20.00|▇▁▁▁▁ |
|tuition       |         0|             1|  0.81| 0.34|  0.26|  0.48|  0.82|  1.13|  1.40|▇▃▇▇▃ |
|education     |         0|             1| 13.81| 1.79| 12.00| 12.00| 13.00| 16.00| 18.00|▇▂▂▃▁ |

Cool, it looks like we have income in the `wage` variable, and distance to a college (in 10's of miles) as `distance`, as well as a lot of other variables describing the students. Let's run a "naive" OLS model. 


```r
# Naive OLS 
mod_ols = feols(
  data = income_df, 
  fml = wage ~ education + urban + gender + ethnicity + unemp + income
)

# Summary of results  
etable(mod_ols, vcov = "HC1")
```

```
##                               mod_ols
## Dependent Var.:                  wage
##                                      
## (Intercept)         8.686*** (0.1588)
## education            -0.0039 (0.0106)
## urbanyes             0.0786. (0.0425)
## genderfemale        -0.0764* (0.0370)
## ethnicityafam     -0.5337*** (0.0546)
## ethnicityhispanic -0.5163*** (0.0439)
## unemp              0.1352*** (0.0072)
## incomehigh         0.1810*** (0.0429)
## _________________ ___________________
## S.E. type         Heteroskedast.-rob.
## Observations                    4,739
## R2                            0.11322
## Adj. R2                       0.11190
## ---
## Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

These results are saying that there is no statistically significant effect of education on wages.  

**Q**: Why is it naive to run this model?  

Now we can attempt to remedy the bias in the OLS model by running TSLS. We have to first estimate the first stage by regressing `education` on `distance`, thus we are instrumenting education with distance to a college. *Note that we want to include all of the same control varibles we did in the original regression.*


```r
# First stage regression
mod_fs = feols(
  data = income_df, 
  fml = education ~ distance + urban + gender + ethnicity + unemp + income
)

etable(mod_fs, vcov = "HC1")
```

```
##                                mod_fs
## Dependent Var.:             education
##                                      
## (Intercept)         13.68*** (0.0851)
## distance          -0.0728*** (0.0119)
## urbanyes             -0.0355 (0.0639)
## genderfemale          0.0155 (0.0510)
## ethnicityafam     -0.4034*** (0.0684)
## ethnicityhispanic   -0.1450* (0.0669)
## unemp                0.0166. (0.0095)
## incomehigh         0.7944*** (0.0586)
## _________________ ___________________
## S.E. type         Heteroskedast.-rob.
## Observations                    4,739
## R2                            0.06142
## Adj. R2                       0.06003
## ---
## Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

These results give us two important things. First, distance to a college is a relevant instrument, it's coefficient is significantly different than zero. The sign makes sense as well, the further you are from a college, the less education you receive. 

Now we need to grab the fitted values from the first stage regression and add them to the original data   


```r
# Grabbing fitted values  
income_df$fit_education = fitted.values(mod_fs)
```

Finally, we can run the original regression, but use `fit_education` rather than `education`. 


```r
# Naive OLS 
mod_tsls = feols(
  data = income_df, 
  fml = wage ~ fit_education + urban + gender + ethnicity + unemp + income
)

# Summary of results  
etable(mod_tsls, vcov = "HC1")
```

```
##                              mod_tsls
## Dependent Var.:                  wage
##                                      
## (Intercept)            -1.372 (1.673)
## education          0.7337*** (0.1225)
## urbanyes              0.0237 (0.0435)
## genderfemale        -0.0902* (0.0370)
## ethnicityafam     -0.2467*** (0.0718)
## ethnicityhispanic -0.3971*** (0.0478)
## unemp              0.1349*** (0.0068)
## incomehigh        -0.4262*** (0.1088)
## _________________ ___________________
## S.E. type         Heteroskedast.-rob.
## Observations                    4,739
## R2                            0.12012
## Adj. R2                       0.11882
## ---
## Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

*Q*: What is the causal effect of education on income? 

And that's all there is to it! 

### `fixest`  

In one of its many, many features, the `fixest` allows us to estimate instrumental variables regression without having to manually run the first and second stages. The formula is now `y ~ x_1 + x_2 | x_endo ~ z`, where `x_1` and `x_2` are control variables, `x_endo` is the variable of interest, and `z` is your instrument. *Note: If you have no control variables, it is* `y ~ 1 | x_endo ~ z`.      


```r
# Fitting an IV model
mod_iv = feols(
  data = income_df, 
  fml = wage ~ urban + gender + ethnicity + unemp + income | education ~ distance
)

etable(mod_iv, vcov = "HC1")
```

```
##                                mod_iv
## Dependent Var.:                  wage
##                                      
## (Intercept)            -1.372 (2.328)
## education          0.7337*** (0.1709)
## urbanyes              0.0237 (0.0644)
## genderfemale        -0.0902. (0.0529)
## ethnicityafam       -0.2467* (0.0962)
## ethnicityhispanic -0.3971*** (0.0742)
## unemp              0.1349*** (0.0099)
## incomehigh         -0.4262** (0.1540)
## _________________ ___________________
## S.E. type         Heteroskedast.-rob.
## Observations                    4,739
## R2                           -0.79990
## Adj. R2                      -0.80256
## ---
## Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

You can also see the results for the first stage using `stage = 1` as an argument in `etable` or `summary`.


```r
etable(mod_iv, vcov = "HC1", stage = 1)
```

```
##                                mod_iv
## Dependent Var.:             education
##                                      
## (Intercept)         13.68*** (0.0851)
## distance          -0.0728*** (0.0119)
## urbanyes             -0.0355 (0.0639)
## genderfemale          0.0155 (0.0510)
## ethnicityafam     -0.4034*** (0.0684)
## ethnicityhispanic   -0.1450* (0.0669)
## unemp                0.0166. (0.0095)
## incomehigh         0.7944*** (0.0586)
## _________________ ___________________
## S.E. type         Heteroskedast.-rob.
## Observations                    4,739
## R2                            0.06142
## Adj. R2                       0.06003
## ---
## Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```
