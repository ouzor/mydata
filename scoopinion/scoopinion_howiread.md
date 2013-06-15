# How I read? - Introduction to Scoopinion reading behavior data with R
### Juuso Parkkinen - @ouzor
### 15.6.2012




---

### Reading the data

Read the JSON data file


```r
# Use package 'rjson' to read the data
library(rjson)
scoop.raw <- fromJSON(file = "myscoopiniondata.json")
```


See what metadata is given


```r
# Check meta data
scoop.raw$meta
```

```
## $title
## [1] "Scoopinion data dump"
## 
## $version
## [1] "0.1"
## 
## $created_at
## [1] "2013-04-01T17:12:11+00:00"
```

---

### Preprocessing
The interesting part is the 'reads' data. Process it into analysable format:


```r
common.items <- c("id", "words_read", "created_at", "article.id", "article.title", 
    "article.url", "article.word_count", "article.average_time", "article.language", 
    "article.site.name", "article.site.id", "article.site.url")
temp.mat <- sapply(scoop.raw$reads, function(x) {
    res = unlist(x)
    return(res[names(res) %in% common.items])
})
# Produce a data frame
scoop.df <- data.frame(t(temp.mat))
# Transform some columns to numeric form
scoop.df[c("words_read", "article.word_count", "article.average_time")] <- sapply(scoop.df[c("words_read", 
    "article.word_count", "article.average_time")], function(x) as.numeric(as.vector(x)))
# Remove reads with missing data
scoop.df <- na.omit(scoop.df)
```


R has nice tools for handling Dates, with easy addition of weekday and month information:


```r
# Add date in a proper format
scoop.df$Date <- as.Date(sapply(strsplit(as.vector(scoop.df$created_at), split = "T"), 
    function(x) x[1]))
# Add weekdays
scoop.df$WeekDay <- factor(weekdays(scoop.df$Date), levels = c("Monday", "Tuesday", 
    "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
# Add months
scoop.df$Month <- factor(months(scoop.df$Date), levels = month.name)
# Add years
scoop.df$Year <- format(scoop.df$Date, format = "%Y")
# Add combined year-month information
scoop.df$Year.Month <- factor(paste(scoop.df$Year, scoop.df$Month, sep = " - "))
temp.ym <- paste(rep(c("2012", "2013"), each = length(month.name)), month.name, 
    sep = " - ")
scoop.df$Year.Month <- factor(scoop.df$Year.Month, levels = temp.ym)
# Cut away 2013 - April (only one read)
scoop.df <- droplevels(subset(scoop.df, Year.Month != "2013 - April"))
```


---
### Basic stuff


```r
# Most commonly read sites
head(sort(table(scoop.df$article.site.name), decreasing = T), 10)
```

```
## 
##                    HS.fi                      YLE             Ilta-Sanomat 
##                      231                      106                       63 
##                Iltalehti                Nyt-liite               Lifehacker 
##                       34                       32                       20 
##            Taloussanomat Uuden Suomen Puheenvuoro         Suomen kuvalehti 
##                       19                       17                       16 
##             The Guardian 
##                       16
```

```r

# Language distribution
table(scoop.df$article.language)
```

```
## 
##  de  en  fi  it 
##   1 257 617   1
```

```r

# Remove rare languages
scoop.df <- droplevels(subset(scoop.df, article.language %in% c("en", "fi")))

# Top referring sites (currently not included in the anlysis because they
# are missing from some reads) head(sort(table(scoop.df$referrer),
# decreasing=T), 5)
```



---
### Plot word counts against average reading times


```r
# Scatter plot of word count vs. average time, colour based on languages
ggplot(scoop.df, aes(x = article.word_count, y = article.average_time, colour = article.language)) + 
    geom_jitter()
```

![plot of chunk word_vs_time](http://i.imgur.com/Vfs98OX.png) 


---
### Plot reading behaviour over time, split by years


```r
# Histogram of daily reading counts
ggplot(scoop.df, aes(x = Date, fill = article.language)) + geom_histogram(position = "stack", 
    binwidth = 1) + facet_wrap(~Year, ncol = 1, scales = "free_x")
```

![plot of chunk time](http://i.imgur.com/XDfaIwR.png) 


---
### Plot reading counts for different weekdays



```r
# Histogram of weekday reading counts
ggplot(scoop.df, aes(x = WeekDay, fill = article.language)) + geom_histogram(position = "stack", 
    binwidth = 1) + facet_wrap(~Year.Month, ncol = 5) + theme(axis.text.x = element_text(angle = 45, 
    vjust = 0.8))
```

![plot of chunk weekday](http://i.imgur.com/G9bejkB.png) 


