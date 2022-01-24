---
title: "EC 421 Lab 3: Plotting with `ggplot2`"
author: "Emmett Saulnier"
date: "1/24/2022"
output: 
  html_document:
    theme: flatly
    toc: yes
    toc_depth: 1
    toc_float: yes
    keep_md: yes
---


# Introduction  

Last week we did a quick overview of data visualization with `ggplot2`, this week, we'll spend some more time with the package -- getting into the weeds a bit. Data visualization is a very important topic, being able to tell the story of your data with visuals is much more compelling than with tables and numbers. 

Hopefully this won't take the entire class period, and I will leave the rest of the time for you to ask me question about the problem set. Note that I have office hours on **Thursday from 1-2pm** if you have any questions.  

The `ggplot2` package is built on an underlying ["grammar of graphics"](https://vita.had.co.nz/papers/layered-grammar.pdf), as created by `R` legend [Hadley Wickham](https://hadley.nz/). He has a very good (and free) chapter on data visualization in [R for Data Science](https://r4ds.had.co.nz/data-visualisation.html). 

There are five components that make up a graphic...  

  1. A default dataset with mappings of variables to aesthetics  
  2. One or more layers, each layer is one of the following: A geometric object, statistical transformation, position adjustment, or (optionally) a dataset with set of aesthetic mappings  
  3. A scale for each aesthetic  
  4. A coordinate system  
  5. The facet specification  
  
We'll talk about each one of these in turn, but first, we need some data. The [USDA Economic Research Service](https://www.ers.usda.gov/data-products/county-level-data-sets/download-data/) has unemployment data at the county level for each year between 2000 and 2019. **[Click here to download it yourself](https://www.ers.usda.gov/webdocs/DataFiles/48747/Unemployment.xlsx?v=825.8)**. Once it has downloaded, put that excel sheet into a folder named "data" inside your EC421 project folder that we set up last week (or whatever project you are using for this lab).

Unfortunately these data need a bit of cleaning. They are **not tidy**, there is a separate column for each year's civilian labor force, unemployed population, and unemployment rate. We want there to be one column for these three variables (that is: labor force, unemployed, and unemployment rate) and then give year its own column. I want to spend most of today talking about `ggplot2`, so I'll move through this quickly so you can just copy and paste the following bit of code into your script to clean the data, but feel free to talk to me after lab or in office hours about any questions you have.  



```r
# Loading packages
library(pacman)
p_load(tidyverse, here, readxl, janitor)

# Cleaning the unemployment data 
unemp_df =
  read_xlsx( # Function that can read excel files
    path = here("data/Unemployment.xlsx"), # Change this if you don't have a "data" folder
    sheet = "Unemployment Med HH Income", # The sheet we want to read
    skip = 4 # Skip the first 4 rows of data since they are empty
  ) |> 
  clean_names() |> # making column names lowercase
  pivot_longer( # Tidying the data
    cols = starts_with(c("civilian","employed","unemploy","med")), # Columns I want to pivot
    names_to = c(".value","year"), # Names for new columns
    names_pattern = '(.*)_(\\d{4})' # Fill in ".value" with correct name
  ) |> # Converting metro_2013 to a character column
  mutate(metro_2013 = as.character(metro_2013))
```

Let's use the tools we already know to learn a bit about these data.  


```r
# Number of rows 
nrow(unemp_df)
```

```
## [1] 68775
```

```r
# Number of columns
ncol(unemp_df)
```

```
## [1] 13
```

```r
# Summary
summary(unemp_df)
```

```
##   fips_code            state            area_name        
##  Length:68775       Length:68775       Length:68775      
##  Class :character   Class :character   Class :character  
##  Mode  :character   Mode  :character   Mode  :character  
##                                                          
##                                                          
##                                                          
##                                                          
##  rural_urban_continuum_code_2013 urban_influence_code_2013  metro_2013       
##  Min.   :1.000                   Min.   : 1.00             Length:68775      
##  1st Qu.:2.000                   1st Qu.: 2.00             Class :character  
##  Median :6.000                   Median : 5.00             Mode  :character  
##  Mean   :4.939                   Mean   : 5.19                               
##  3rd Qu.:7.000                   3rd Qu.: 8.00                               
##  Max.   :9.000                   Max.   :12.00                               
##  NA's   :1176                    NA's   :1176                                
##      year           civilian_labor_force    employed           unemployed      
##  Length:68775       Min.   :       38    Min.   :       34   Min.   :       3  
##  Class :character   1st Qu.:     5173    1st Qu.:     4825   1st Qu.:     298  
##  Mode  :character   Median :    12067    Median :    11252   Median :     754  
##                     Mean   :   141473    Mean   :   132948   Mean   :    8525  
##                     3rd Qu.:    32851    3rd Qu.:    30872   3rd Qu.:    2044  
##                     Max.   :163140305    Max.   :157154185   Max.   :14860707  
##                     NA's   :176          NA's   :176         NA's   :176       
##  unemployment_rate median_household_income med_hh_income_percent_of_state_total
##  Min.   : 0.800    Min.   : 24732          Min.   : 39.92                      
##  1st Qu.: 4.100    1st Qu.: 46309          1st Qu.: 76.52                      
##  Median : 5.500    Median : 53505          Median : 87.13                      
##  Mean   : 6.225    Mean   : 55875          Mean   : 89.63                      
##  3rd Qu.: 7.600    3rd Qu.: 62327          3rd Qu.:100.00                      
##  Max.   :29.400    Max.   :151806          Max.   :234.52                      
##  NA's   :176       NA's   :65582           NA's   :65583
```


# Aesthetics  

Aesthetics are some visual aspect of the plot -- examples include the x-axis, y-axis, color, fill, size, shape, and transparency. You use these aesthetics to display different properties of the data... things that you can perceive on the graphic you are making. You map aesthetics using the `mapping` argument in `ggplot()`, which takes a list of aesthetic mappings that you create using the `aes()` function. For example, lets make a scatter plot of median household income versus the unemployment rate in 2019 by mapping unemployment rate to the x aesthetic and median household income to the y aesthetic.  


```r
# Simple scatter plot of income vs unemployment
ggplot(
  data = unemp_df |> filter(year == 2019), # Filtering data to just 2019 
  mapping = aes(# Aesthetic mappings
    x = unemployment_rate, 
    y = median_household_income
)) + 
  geom_point()# Adding the point layer
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-3-1.png)<!-- -->

Unsurprisingly, there is a negative relationship between unemployment and income -- counties with higher unemployment rates tend to have lower median incomes. We can dig into this relationship a bit further using another variable in the data: the `metro_2013` variable tells us whether a county is considered as being part of a metropolitan area or not. Let's add that to the color aesthetic to see if urban and rural counties are different from each other.


```r
# Simple scatter plot of income vs unemployment
ggplot(
  data = unemp_df |> filter(year == 2019), # Filtering data to just 2019 
  mapping = aes(
    x = unemployment_rate, 
    y = median_household_income, 
    color = metro_2013
)) + 
  geom_point() # Adding the point layer
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-4-1.png)<!-- -->

We just as easily could have mapped the metro area to `shape` or `alpha` (transparency).


```r
# Left plot: shape
ggplot(
  data = unemp_df |> filter(year == 2019), # Filtering data to just 2019 
  mapping = aes(
    x = unemployment_rate, 
    y = median_household_income, 
    shape = metro_2013
)) + geom_point() # Adding the point layer

# Right plot: transparency
ggplot(
  data = unemp_df |> filter(year == 2019), # Filtering data to just 2019 
  mapping = aes(
    x = unemployment_rate, 
    y = median_household_income, 
    alpha = metro_2013
)) + geom_point() # Adding the point layer
```

<img src="lab-03-ggplot_files/figure-html/figures-side-1.png" width="50%" /><img src="lab-03-ggplot_files/figure-html/figures-side-2.png" width="50%" />

Sometimes it is tempting to put as many aesthetics as you can on your plot, but usually three aesthetics (i.e. x, y, and color) is about as much as people can make sense of in a single graphic. 

You can also manually change aesthetics **outside** of the `mapping` argument. Say you wanted to change the shape of every point to a square, then you can just add `shape = 0` to the `geom_point` function call (Note: [Here are the codes for shapes in R](https://bookdown.org/roy_schumacher/r4ds/visualize_files/figure-html/shapes-1.png)). 


```r
# Simple scatter plot of income vs unemployment
ggplot(data = unemp_df |> filter(year == 2019)) + 
  geom_point(
    mapping = aes(x = unemployment_rate, y = median_household_income), 
    shape = 0
  ) 
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-5-1.png)<!-- -->

*Note: Another common stumbling block is where to put the `+` sign. You must put it at the end of lines rather than at the beginning of lines. For example, the following code chunk will not work!*


```r
# Will give you an error since + is on new line
ggplot(data = unemp_df, aes(x = unemployment_rate, y = median_household_income))
+ geom_point()
```

# Scales  

Each aesthetic has an associated scale. For x and y, this corresponds to the axis range and breaks. For color and fill the scale is the palette of colors assigned to different values. `ggplot` will pick a reasonable default scale for each aesthetic (as it has in all of the above examples without us manually altering them). 

There are lots of different functions that can be used to change scales, but they all begin with `scale_` followed by the name of the aesthetic you want to change (i.e. `scale_x_continuous` or `scale_color_viridis_c`). There are typically three things inputs you might want to give to a scale function: values for the scale, labels for the scale, and a name for the aesthetic. Let's look at an example. 


```r
ggplot(unemp_df, aes(x = unemployment_rate, y = median_household_income/1e3, color = metro_2013)) + 
  geom_point() +
  scale_color_manual(
    values = c("red","black"), # What colors to we want to plot 
    labels = c("Non-Metro","Metro"), # Labels for the legend
    name = "Metro Status" # Name on the legend
  ) + 
  scale_x_continuous(
    limits = c(0,30), # changing the range 
    breaks = seq(0,30,by = 5), # marks every 5 units
    name = "Unemployment Rate" # Axis label 
  ) + 
  scale_y_continuous(
    limits = c(0,140),
    breaks = seq(0,140, by = 20),
    name = "Median Income ('000 dollars)"
  )
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-7-1.png)<!-- -->

*Note that you can add scale transformations when you are assigning aesthetic mappings, like I did above changing the units on median household income to thousands of dollars). The [scales](https://scales.r-lib.org/) package handles this in a more robust way.* 

There are some nice color palettes built into `ggplot` that look very nice and don't require you to manually choose colors, my favorite is `scale_color_viridis_c` for continuous variables (or `scale_color_viridis_d` for discrete variables). See [this vignette](https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html) for more options on the viridis color palettes.  


```r
ggplot(
  data = unemp_df, 
  mapping = aes(
    x = unemployment_rate, 
    y = median_household_income/1e3, 
    color = rural_urban_continuum_code_2013
  )
) + 
  geom_point() +
  scale_color_viridis_c(name = "Rural-Urban Continuum")
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-8-1.png)<!-- -->


# Facets  

As an alternative to adding variables as aesthetics, you can add variables as facets. Facets show separate plots for different subsets of the data. These are particularly useful for categorical variables, allowing you to create separate plots for each level of the categorical value. 

For example. we can use the same framework as above, but use `metro_2013` as a facet rather than an aesthetic. you do this by adding `facet_wrap()` as another layer of your `ggplot` call. Inside `facet_wrap()` you specify the facet using the `facets` argument, which can be either a character vector with the variable names that you want to facet by (i.e. `facets = "metro_2013"`), or a formula (i.e. `facets = ~metro_2013`).


```r
# Faceting by metro_2013
ggplot(data = unemp_df |> filter(year == 2019)) + 
  geom_point(
    mapping = aes(x = unemployment_rate, y = median_household_income)
  ) +
  facet_wrap(facets = ~metro_2013)
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-9-1.png)<!-- -->

# Geometric Objects  

I've mentioned that `ggplot` works using layers a few times, but I haven't actually explained what that means yet. Let's start by checking to see what happens if we just use the `ggplot` function without anything added to it... 


```r
# ggplot call with no geoms added to it 
ggplot(data = unemp_df, aes(x = unemployment_rate, y = median_household_income))
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-10-1.png)<!-- -->

It comes up as a blank plot because we haven't told it what type of geometric object we want to look at. The ggplot function creates the base dataset by mapping variables to aesthetics, but it does not have a default type of geometric object that gets plotted. That is because you can use many different types of geometric objects to visualize the same data!  

Geometric objects, or *geoms* are all the different types of shapes or graphics that you might want to plot. We've already used some (i.e. `geom_point` and `geom_line` ), but there are many of these (see a reference list [here](https://ggplot2.tidyverse.org/reference/)). You add the geom layers on top of the base `ggplot`, and the layer inherits the data and aesthetic mappings from `ggplot` by default.

One common geom we might add on top of a scatter plot is `geom_smooth()`, which finds the mean of y conditional on x using different smoothing functions --- `method = "lm"` corresponds to OLS. 


```r
# Adding geom_smooth
ggplot(
  data = unemp_df |> filter(year == 2019), 
  mapping = aes(x = unemployment_rate, y = median_household_income)
) + 
  geom_point() +
  geom_smooth(method = "lm")
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-11-1.png)<!-- -->

**Q: How would we find the actual equation for the smoothed line above? What is the interpretation of the coefficient? Is it significant?**


Note that not all aesthetics work with all geoms. For example, lines do not have `shape`, but they do have `linetype`. Two more useful geoms are `geom_histogram` and `geom_density`, which take an `x` and plot the distribution. We can also get conditional distributions by adding a categorical variable to the fill or color aesthetic.


```r
ggplot(data = unemp_df |> filter(year == 2019), mapping = aes(x = unemployment_rate)) +
  geom_histogram(binwidth = 0.5) 

# Now adding year as an aesthetic
ggplot(
  data = unemp_df |> filter(year %in% 2009:2014), 
  mapping = aes(x = unemployment_rate, fill = year)
) +
  geom_density(color = NA, alpha = 0.4) 
```

<img src="lab-03-ggplot_files/figure-html/unnamed-chunk-12-1.png" width="50%" /><img src="lab-03-ggplot_files/figure-html/unnamed-chunk-12-2.png" width="50%" />

Each geom inherits the aesthetics and data of the base `ggplot` call by default, but you can change the data or aesthetics within a specific geom --- as an example, we can plot the density of unemployment across all years on top of distributions for individual years.


```r
ggplot() +
  geom_density( # Specific year's distribution
    data = unemp_df |> filter(year %in% 2009:2014), 
    mapping = aes(x = unemployment_rate, fill = year),
    color = NA, 
    alpha = 0.4
  ) +
  geom_density( # All years
    data = unemp_df, 
    mapping = aes(x = unemployment_rate)
  ) 
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-13-1.png)<!-- -->

# Accessories   

This is still just an introduction to plotting in `ggplot`, but there are two final things I want to leave you with today. 

### Labels

We have seen that the names of different aesthetics can be changed using a scale function for each aesthetic, but sometimes all you want to do is change the name and not the scale, which can be a bit tedious to write out for multiple aesthetics. Luckily the `labs()` function is an easy and quick way to do this. As an added bonus, we can also change the title, subtitle, and caption in that same function.


```r
ggplot(unemp_df |> filter(year == 2019), aes(x = unemployment_rate, y = median_household_income)) +
  geom_point() +
  labs(
    title = "Median Income vs Unemployment Rate",
    subtitle = "An example for labs() function",
    caption = "The plot shows county level data for 2019.",
    # You can also name any aesthetic
    x = "Unemployment Rate",
    y = "Median Household Income"
  )
```

![](lab-03-ggplot_files/figure-html/unnamed-chunk-14-1.png)<!-- -->

Similarly `xlab()`, `ylab()`, and `ggtitle()` can do x, y, and title+subtitle+caption labels individually.

### Themes

We can change pretty much any visual aspect of the graphic that you want to make --- including the background color, font type and size (for each label), grid lines, legend position, and many more. It is a bit tedious to do this all yourself, luckily there are many themes out there that make nice looking plots without you having to remember all of the argument names and specs. 

A couple of my favorites are `theme_classic()` and `hrbrthemes::theme_ipsum()` (Remember to install/load `hrbrthemes` to use `theme_ipsum`), but there are probably hundreds of other options that you can pick for your plots. [Here](https://ggplot2-book.org/polishing.html) are a few, or you can search something like "ggplot themes" on google. These functions have a `base_size` argument that you can use to make the text bigger/smaller


```r
# Left plot: classic theme
ggplot(unemp_df |> filter(year == 2019),aes(x = unemployment_rate, y = median_household_income)) +
  geom_point() + 
  theme_classic() +
  ggtitle("Classic Theme")

# Right plot: ipsum
ggplot(unemp_df |> filter(year == 2019),aes(x = unemployment_rate, y = median_household_income)) +
  geom_point() + 
  hrbrthemes::theme_ipsum(base_size = 18) + # increasing base size
  ggtitle("Ipsum Theme")
```

<img src="lab-03-ggplot_files/figure-html/unnamed-chunk-15-1.png" width="50%" /><img src="lab-03-ggplot_files/figure-html/unnamed-chunk-15-2.png" width="50%" />


## Answer to regression question above: 


```r
# Regressing income on unemployment 
lm(median_household_income ~ unemployment_rate, data = unemp_df |> filter(year == 2019)) |> summary()
```

```
## 
## Call:
## lm(formula = median_household_income ~ unemployment_rate, data = filter(unemp_df, 
##     year == 2019))
## 
## Residuals:
##    Min     1Q Median     3Q    Max 
## -26619  -8935  -2376   5527  89023 
## 
## Coefficients:
##                   Estimate Std. Error t value Pr(>|t|)    
## (Intercept)        71506.9      675.7  105.82   <2e-16 ***
## unemployment_rate  -3965.3      160.7  -24.68   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 13280 on 3191 degrees of freedom
##   (82 observations deleted due to missingness)
## Multiple R-squared:  0.1602,	Adjusted R-squared:   0.16 
## F-statistic: 608.8 on 1 and 3191 DF,  p-value: < 2.2e-16
```

This means that a 1pp increase in the 2019 unemployment rate in a county is associated with a $3965.3 decrease in 2019 median income. It is statistically significant, but not causally interpretable. 

