---
title: "EC 421 Lab 6: Joining tables together"
author: "Emmett Saulnier"
date: "2/14/2022"
output: 
  html_document:
    theme: flatly
    toc: yes
    toc_depth: 1
    toc_float: yes
    keep_md: yes
---




So far, we have only worked with single data tables that have all of the information we use already contained inside of it. However, commonly we are pulling data together from multiple sources and have to figure out how to merge them together. There are a lot of ways to do this, and we'll cover all of the ways offered in the `tidyverse`, something that you all are hopefully becoming quite familiar with. Pretty much every single day that I do some sort of data analysis, I am merging tables together.  

This lab will be particularly useful to anyone who plans on working in a "data analyst" type role at a private company. Most companies store their data in what are called relational databases. These databases consist of many tables that are all connected via keys, or ID's. For example, the database might have one table that has a row for every customer with information about the customers and a unique customer ID. Then there could be another table with a row for each sale the company makes that includes the customer ID for the customer who purchased their product. This way, the customer's information only needs to be stored in one place, and then can be merged, or "joined", to the sale table when needed. Relational databases are typically accessed using a different coding language called SQL, but learning how to join tables together in `R` will help you pick up SQL very quickly. 

Let's start as usual by loading the packages we'll need for today.


```r
# Loading packages
library(pacman)
p_load(tidyverse, magrittr)
```


*This lab leans heavily on notes from [Colleen O'Briant](https://cobriant.github.io/).*  

# Binding 

#### Binding vectors

We've already seen `rbind` and `cbind`: they treat the inputs as either rows or columns, and then binds them together. Let's make up a simple example to demonstrate how these work. 


```r
name = c("Pam", "George", "Sandy")
favorite = c("Glazed Yams", "Leeks", "Daffodils")
```

**Q01**: What will the dimensions be for the output of these two lines of code?


```r
rbind(name, favorite)
cbind(name, favorite)
```

Binding vectors can be useful, but it's likely more common for you to be working with data frames.

#### Binding data frames

You can also use `rbind` and `cbind` to bind data frames. We'll create two using `favorite` and a new vector, `work`.


```r
# Create some data frames for us to work with
name_fav_df = cbind(name, favorite)
name_work_df = cbind(name, work = c("Bus Driver", NA, "Shopkeeper"))
```

`cbind` treats the objects as columns, so they're put side-by-side:
$$\begin{bmatrix}
  A, B \\
\end{bmatrix}$$


```r
cbind(name_fav_df, name_work_df)
```

```
##      name     favorite      name     work        
## [1,] "Pam"    "Glazed Yams" "Pam"    "Bus Driver"
## [2,] "George" "Leeks"       "George" NA          
## [3,] "Sandy"  "Daffodils"   "Sandy"  "Shopkeeper"
```

`rbind` treats the objects as rows, so they're stacked:
$$\begin{bmatrix}
  A \\
  B \\
\end{bmatrix}$$


```r
rbind(name_fav_df, name_work_df) #notice how rbind doesn't care about column names
```

```
##      name     favorite     
## [1,] "Pam"    "Glazed Yams"
## [2,] "George" "Leeks"      
## [3,] "Sandy"  "Daffodils"  
## [4,] "Pam"    "Bus Driver" 
## [5,] "George" NA           
## [6,] "Sandy"  "Shopkeeper"
```

`dplyr` has very similar functions `bind_rows` and `bind_cols`. They work best with tibbles, so we'll go ahead and create tibble versions of our data.

```r
name_fav_tib = as_tibble(name_fav_df)
name_work_tib = as_tibble(name_work_df)

bind_cols(name_fav_tib, name_work_tib)
```

```
## New names:
## * name -> name...1
## * name -> name...3
```

```
## # A tibble: 3 × 4
##   name...1 favorite    name...3 work      
##   <chr>    <chr>       <chr>    <chr>     
## 1 Pam      Glazed Yams Pam      Bus Driver
## 2 George   Leeks       George   <NA>      
## 3 Sandy    Daffodils   Sandy    Shopkeeper
```


```r
# bind_rows pays attention to column names and will create NAs
bind_rows(name_fav_tib, name_work_tib)
```

```
## # A tibble: 6 × 3
##   name   favorite    work      
##   <chr>  <chr>       <chr>     
## 1 Pam    Glazed Yams <NA>      
## 2 George Leeks       <NA>      
## 3 Sandy  Daffodils   <NA>      
## 4 Pam    <NA>        Bus Driver
## 5 George <NA>        <NA>      
## 6 Sandy  <NA>        Shopkeeper
```

Note that when you use these binding functions, the data is just stacked together as is without any regard to the actual meaning of the data. For example, if we sort one of the tables differently and then use `bind_cols` (or `cbind`), the names will no longer match. This was a common mistake in the last problem set.  


```r
# Mismatched names 
bind_cols(name_fav_tib, arrange(name_work_tib,name))
```

```
## New names:
## * name -> name...1
## * name -> name...3
```

```
## # A tibble: 3 × 4
##   name...1 favorite    name...3 work      
##   <chr>    <chr>       <chr>    <chr>     
## 1 Pam      Glazed Yams George   <NA>      
## 2 George   Leeks       Pam      Bus Driver
## 3 Sandy    Daffodils   Sandy    Shopkeeper
```

#### Recycling

Another behavior to note is that `cbind` and `rbind` will recycle, but `dplyr::bind_cols` and `dplyr::bind_rows` will not. There aren't many contexts where you actually want recycling to happen. 


```r
cbind(name_fav_df, sex = c("female", "male"))

bind_cols(name_fav_tib, sex = c("female", "male")) #Error
```

# Set operations

The `dplyr` set operation functions are `union`, `intersect`, and `setdiff`. These set operations treat observations (rows) as if they were set elements. They work with an entire row of a data frame, comparing the values for each variable. *Note: `tribble()` is just another function used to create a tibble that uses an easy to read row-by-row layout*.


```r
table_1 = tribble(
  ~"name", ~"favorites",
  #------|--------
  "Pam", "Glazed Yams",
  "George", "Leeks",
  "Sandy", "Daffodils"
)

table_2 = tribble(
  ~"name", ~"favorites",
  #------|--------
  "Pam", "Glazed Yams",
  "Gus", "Fish Tacos"
)
```

`union` will give you all the observations (rows) that appear in either or both tables. This is similar to `bind_rows`, but `union` will remove duplicates.


```r
union(table_1, table_2)
```

```
## # A tibble: 4 × 2
##   name   favorites  
##   <chr>  <chr>      
## 1 Pam    Glazed Yams
## 2 George Leeks      
## 3 Sandy  Daffodils  
## 4 Gus    Fish Tacos
```

`intersect` will give you only the observations that appear both in `table_1` and in `table_2`: in the intersection of the two tables.


```r
intersect(table_1, table_2)
```

```
## # A tibble: 1 × 2
##   name  favorites  
##   <chr> <chr>      
## 1 Pam   Glazed Yams
```

`setdiff(table_1, table_2)` gives you all the observations in `table_1` that are not in `table_2`.


```r
setdiff(table_1, table_2)
```

```
## # A tibble: 2 × 2
##   name   favorites
##   <chr>  <chr>    
## 1 George Leeks    
## 2 Sandy  Daffodils
```

**Q02**: What will the output of this code be?  

```r
# What is the output?
setdiff(table_2, table_1)
```


# Mutating joins

Joins are one way to solve the sorting problem that I described above and are incredibly useful. These are the real workhorses of data manipulation.

#### Keys  

Before we move on to the different types of joins, we have to talk about **keys**. A key is a variable, or set of variables that uniquely identifies an observation. In our simple example above, the key would be the `name` column. Typically these are some sort of ID number or code. For example, in many county level datasets, counties are identified with a county FIPS code and a state FIPS code (*Note: Names are often unreliable keys because people or places may have the same names, just like there are counties with the same names in different states*).

#### Joins 

A mutating join takes the first table and adds columns from the second table. First, the function matches rows based on the keys. It combines the key variable into one new column, then pulls in the variables from the left hand side table, and finally pulls in the variables from the right hand side table. There are 4 mutating joins: `inner_join`, `full_join`, `left_join`, and `right_join`. The difference between these functions are how rows that do not match between the two columns are treated. These Venn diagrams are useful representations of what is happening when using a join function.

<img src="sql-joins.png" width="446" style="display: block; margin: auto;" />

Here we'll create some simple data to demonstrate how they work.


```r
# We'll create 2 new data frames to learn mutating joins:

favorites = tribble(
  ~"name", ~"fav",
  #------|--------
  "Pam", "Glazed Yams",
  "George", "Leeks",
  "Sandy", "Daffodils"
)

jobs = tribble(
  ~"name", ~"work",
  #------|--------
  "Pam", "Bus Driver",
  "Gus", "Bartender",
  "Sandy", "Shopkeeper"
)
```

#### `inner_join`

`inner_join(x, y)` matches pairs of observations whenever their keys are equal. We use `by = ` for the key, or variable you want to join on.  


```r
inner_join(favorites, jobs, by = "name")
```

```
## # A tibble: 2 × 3
##   name  fav         work      
##   <chr> <chr>       <chr>     
## 1 Pam   Glazed Yams Bus Driver
## 2 Sandy Daffodils   Shopkeeper
```

It is important to note that unmatched rows from both tables are excluded from the output. Be careful using inner joins because you might accidentally be losing a lot of data without realizing it if your keys are messed up. 

#### `full_join`

`full_join(x, y)` is the first type of *outer* join. It will keep all observations from both tables, even if their keys do not match.


```r
full_join(favorites, jobs, by = "name")
```

```
## # A tibble: 4 × 3
##   name   fav         work      
##   <chr>  <chr>       <chr>     
## 1 Pam    Glazed Yams Bus Driver
## 2 George Leeks       <NA>      
## 3 Sandy  Daffodils   Shopkeeper
## 4 Gus    <NA>        Bartender
```

You can see that using the full join, we have all four names, with `NA` values filled in for the names that were missing in one of the tables.

#### `left_join`

`left_join(x, y)` is another type of join that will keep all of the observations from `x` (the table on the left hand side) and add columns from `y` for every row that matches on the key. 


```r
left_join(favorites, jobs, by = "name")
```

```
## # A tibble: 3 × 3
##   name   fav         work      
##   <chr>  <chr>       <chr>     
## 1 Pam    Glazed Yams Bus Driver
## 2 George Leeks       <NA>      
## 3 Sandy  Daffodils   Shopkeeper
```

**Q03**: What names will appear in this table? 

```r
left_join(jobs, favorites, by = "name")
```

#### `right_join`

`right_join(x, y)` works the same as left join, but instead of keeping all rows of `x`, it keeps all rows of `y` (the right hand table). Note that `left_join(x,y)` is essentially equivalent to `right_join(y,x)`, so usually right join isn't necessary (just use left instead), but there might be some cases where it is useful.


```r
right_join(favorites, jobs, by = "name")
```

```
## # A tibble: 3 × 3
##   name  fav         work      
##   <chr> <chr>       <chr>     
## 1 Pam   Glazed Yams Bus Driver
## 2 Sandy Daffodils   Shopkeeper
## 3 Gus   <NA>        Bartender
```

```r
# Note the above is basically equivalent to 
left_join(jobs, favorites, by = "name")
```

```
## # A tibble: 3 × 3
##   name  work       fav        
##   <chr> <chr>      <chr>      
## 1 Pam   Bus Driver Glazed Yams
## 2 Gus   Bartender  <NA>       
## 3 Sandy Shopkeeper Daffodils
```


#### Duplicate Keys  

So far we have been using tables where the key (`name`) is unique in both tables. However, this is not always the case. Let's examine two cases:

  1. One table has duplicate keys: This can be a useful way to add information to a table. Let's say that Gus and Sandy now have two jobs


```r
# Lets say Gus has two jobs
jobs_dup = tribble(
  ~"name", ~"work",
  #------|--------
  "Pam", "Bus Driver",
  "Gus", "Bartender",
  "Gus", "Mailman",
  "Sandy", "Shopkeeper",
  "Sandy", "Uber Driver"
)
```

Let's see what happens when we join this to the `favorites` table 


```r
# Joining with duplicates
left_join(jobs_dup, favorites, by = "name")
```

```
## # A tibble: 5 × 3
##   name  work        fav        
##   <chr> <chr>       <chr>      
## 1 Pam   Bus Driver  Glazed Yams
## 2 Gus   Bartender   <NA>       
## 3 Gus   Mailman     <NA>       
## 4 Sandy Shopkeeper  Daffodils  
## 5 Sandy Uber Driver Daffodils
```

  We can see that Sandy's favorite has been duplicated. 

  2. The second case is when both tables have duplicates in them. It generates every possible combination of rows that have the same key. This usually means that there is some problem with your keys, but sometimes can also be useful. Let's use a simpler example to start for this one.
  

```r
# Creating data frames
x_df = tibble(key = 1, x = 1:3)
y_df = tibble(key = 1, y = 1:3)

# joining together
inner_join(x_df, y_df, by = "key")
```

```
## # A tibble: 9 × 3
##     key     x     y
##   <dbl> <int> <int>
## 1     1     1     1
## 2     1     1     2
## 3     1     1     3
## 4     1     2     1
## 5     1     2     2
## 6     1     2     3
## 7     1     3     1
## 8     1     3     2
## 9     1     3     3
```

This is what is called a "cartesian join". Let's create a new `favorites` table with duplicate keys as another example.


```r
# Favorites table with duplicates
favorites_dup = tribble(
  ~"name", ~"fav",
  #------|--------
  "Pam", "Glazed Yams",
  "George", "Leeks",
  "Sandy", "Daffodils",
  "Sandy", "Broccoli"
)
```

**Q04**: How many rows will be in the output of this code? 

```r
full_join(favorites_dup, jobs_dup, key = "name")
```

#### Defining the key columns  

There are multiple ways to define the key column in these functions. 

   - By default, `by = NULL` will match on all of the columns with the same name in both tables. This works sometimes, but I strongly recommend **not** to leave `by` blank, and be clear about what you are joining on.  
   - A character vector, `by = "key"` for a single key, or `by = c("key1","key2")` for multiple keys. These are what we have used thus far, and work if the keys have the same name in both tables. 
   - A named character vector, `by = c("key.x" = "key.y")`, which can be used to match keys if their names are different in the tables you are trying to join. `key.x` is the name of the variable in the left hand table and `key.y` is the name of the variable on the right hand table. 
   

```r
# Lets change the name from one
favorites_dup %<>% rename(name_fav = name)

# Joining with different column names in each table
left_join(favorites_dup, jobs, by = c("name_fav" = "name"))
```

```
## # A tibble: 4 × 3
##   name_fav fav         work      
##   <chr>    <chr>       <chr>     
## 1 Pam      Glazed Yams Bus Driver
## 2 George   Leeks       <NA>      
## 3 Sandy    Daffodils   Shopkeeper
## 4 Sandy    Broccoli    Shopkeeper
```

Notice that the key column is renamed to be whatever the `x` table has as the key name.

# Filtering joins

Filtering joins match observations the same way that mutating joins do using keys, but they do not add columns together like mutating joins. Instead, they are just used to filter the observations from a table.

dplyr has 2 types of filtering joins: `semi_join` and `anti_join`.

#### `semi_join`

`semi_join(x, y)` keeps all rows in `x` where the key matches in `y`.

```r
semi_join(favorites, jobs, by = "name")
```

```
## # A tibble: 2 × 2
##   name  fav        
##   <chr> <chr>      
## 1 Pam   Glazed Yams
## 2 Sandy Daffodils
```


**Q05**: What names will appear in this table?

```r
# What will be the output? Just submit the names.
semi_join(jobs, favorites, by = "name")
```

#### `anti_join`

`anti_join(x, y)` keeps rows in x as long as the key **doesn't** have a match in y. 

```r
anti_join(favorites, jobs, by = "name")
```

```
## # A tibble: 1 × 2
##   name   fav  
##   <chr>  <chr>
## 1 George Leeks
```

These are particularly useful for help figuring out why your joins *aren't* working. You can check to see which rows in your data do not have matches, which might point you in the right direction on some issue with your code or in the data itself. 

**Q06**: Who will be in this output?

```r
# What will be the output?
anti_join(jobs, favorites, by = "name")
```

Note that only the existence of a match matters for filtering joins, thus if there are duplicate keys as discussed above, the output will **not** generate more duplicate rows. It will just keep rows that have a match (for `semi_join`) or rows that do not have a match (for `anti_join`).


```r
# No cartesian join here
semi_join(favorites_dup, jobs_dup, by = c("name_fav"="name"))
```

```
## # A tibble: 3 × 2
##   name_fav fav        
##   <chr>    <chr>      
## 1 Pam      Glazed Yams
## 2 Sandy    Daffodils  
## 3 Sandy    Broccoli
```

# Resources

* [R for Data Science Chapter on Relational Data](https://r4ds.had.co.nz/relational-data.html)
* [Datacamp Course on Joining Data](https://learn.datacamp.com/courses/joining-data-with-dplyr-in-r)  
* [RStudio cheat sheets](https://www.rstudio.com/resources/cheatsheets/) (See "Data transformation with dplyr")
