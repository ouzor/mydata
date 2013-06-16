# How I read? - Introduction to Scoopinion reading behavior data with R
### Juuso Parkkinen - @ouzor
### 16.6.2012




---

### Read and preprocess data

Read the JSON data file and preprocess reads data (see details in the [source code](scoopinion_functions.R))


```r
source("scoopinion_functions.R")
reads.df <- PreprocessScoopinionData(filename = "my_scoopinion_data.json")
```



---
### Filter data

Read code comments for details


```r
# Remove rare languages
table(reads.df$article.language)
```

```
## 
##  de  en  fi  it 
##   1 257 620   1
```

```r
reads.df <- droplevels(subset(reads.df, article.language %in% c("en", "fi")))

# Remove rare months
table(reads.df$Year.Month)
```

```
## 
## 2012-06 2012-07 2012-08 2012-09 2012-10 2012-11 2012-12 2013-01 2013-02 
##      29     141      49      36      22      23     161     177      99 
## 2013-03 2013-04 
##     139       1
```

```r
reads.df <- droplevels(subset(reads.df, Year.Month != "2013-04"))

# Study reads with repeating 'article.title'
repeats <- table(reads.df$article.title)
repeats <- repeats[repeats > 2]
print(repeats)
```

```
## 
##                                Anonyymit eläimet 
##                                                3 
##                                           Fok_it 
##                                                4 
##                                     Fok_it — Nyt 
##                                               14 
##                                       Sarjakuvat 
##                                               46 
## The Man Who Killed Osama bin Laden... Is Screwed 
##                                                4 
##                                       Yle Areena 
##                                               25
```

```r
# Based on this, remove comics and Yle Areena
reads.to.remove <- which(reads.df$article.title %in% c("Anonyymit eläimet", 
    "Fok_it", "Fok_it — Nyt", "Sarjakuvat", "Yle Areena"))
message("Removed ", length(reads.to.remove), " reads")
```

```
## Removed 92 reads
```

```r
reads.df <- droplevels(reads.df[-reads.to.remove, ])

# Remove very long articles
ggplot(reads.df, aes(x = article.word_count)) + geom_histogram(binwidth = 500)
```

![plot of chunk filter](http://i.imgur.com/MKHIK2m.png) 

```r
reads.df <- droplevels(subset(reads.df, article.word_count < 5000))
```


---
### Top sites

List top read article sites and to referrers (the site from which the read article was clicked)


```r
# Most commonly read sites
head(sort(table(reads.df$article.site.name), decreasing = T), 10)
```

```
## 
##                    HS.fi                      YLE             Ilta-Sanomat 
##                      185                       81                       63 
##                Iltalehti               Lifehacker            Taloussanomat 
##                       35                       20                       19 
## Uuden Suomen Puheenvuoro         Suomen kuvalehti             The Guardian 
##                       17                       16                       16 
##       The New York Times 
##                       15
```

```r

# Top referring sites
head(sort(table(reads.df$referrer), decreasing = T), 10)
```

```
## 
##                   https://www.facebook.com/ 
##                                         173 
##            https://www.scoopinion.com/issue 
##                                         110 
##                 https://www.scoopinion.com/ 
##                                          73 
##                           http://www.hs.fi/ 
##                                          70 
##                                             
##                                          59 
##            https://www.scoopinion.com/daily 
##                                          19 
##                  http://www.scoopinion.com/ 
##                                          18 
## http://www.iltasanomat.fi/?ref=hs-tf-promo1 
##                                          14 
##                      https://www.google.fi/ 
##                                          12 
##                          http://www.yle.fi/ 
##                                          10
```


---
### Study reading time vs. word count

Scatter plot of average reading time vs. word count, with estimated means. 


```r
ggplot(reads.df, aes(x = article.word_count, y = article.average_time, colour = article.language)) + 
    geom_point(position = position_jitter(width = 0, height = 10)) + geom_smooth(data = subset(reads.df, 
    article.average_time > 0))
```

![plot of chunk word_vs_time1](http://i.imgur.com/B2NoIHV.png) 


My personal reading time vs. words.read


```r
ggplot(reads.df, aes(x = words_read, y = total_time, colour = article.language)) + 
    geom_point()
```

![plot of chunk word_vs_time2](http://i.imgur.com/uTNXwgm.png) 


My personal reading time vs. article word count


```r
ggplot(reads.df, aes(x = article.word_count, y = total_time, colour = article.language)) + 
    geom_point()
```

![plot of chunk word_vs_time3](http://i.imgur.com/mGL1aKr.png) 


*COMMENT: There appears to be a threshold for too high reading speed (a bit higher than 4 words / second)*
*COMMENT: There are also a lot of reads with zero words read, probably some measuring errors. But why some articles have 'average_time' zero?*

Personal words.read vs. article word count

```r
ggplot(reads.df, aes(x = article.word_count, y = words_read, colour = article.language)) + 
    geom_abline(slope = 1, linetype = "dashed") + geom_jitter()
```

![plot of chunk word_vs_time4](http://i.imgur.com/1Jh5S3H.png) 


Compare my reading speed (total_time) to average


```r
ggplot(reads.df, aes(x = article.average_time, y = total_time, colour = article.language)) + 
    geom_abline(slope = 1, linetype = "dashed") + geom_jitter()
```

![plot of chunk word_vs_time5](http://i.imgur.com/87UIaug.png) 



---
### Plot reading behaviour over time

Histogram of daily reads count


```r
# Histogram of daily reading counts
ggplot(reads.df, aes(x = Date, fill = article.language)) + geom_histogram(position = "stack", 
    binwidth = 1) + facet_wrap(~Year, ncol = 1, scales = "free_x")
```

![plot of chunk time1](http://i.imgur.com/iVpd2lw.png) 


Histogram of reading counts by weekdays, split by months


```r
# Histogram of daily reading counts
ggplot(reads.df, aes(x = WeekDay, fill = article.language)) + geom_histogram(position = "stack", 
    binwidth = 1) + facet_wrap(~Year.Month, ncol = 5) + theme(axis.text.x = element_text(angle = 45, 
    vjust = 0.8))
```

![plot of chunk time2](http://i.imgur.com/cgWayh5.png) 


Study monthly averages for 10 most read sites. Add vertical line for HS paywall, introduced 20.11.2013.


```r
top10.sites <- names(head(sort(table(reads.df$article.site.name), decreasing = T), 
    10))
top10.df <- droplevels(subset(reads.df, article.site.name %in% top10.sites))
# Compute monthly averages
top10.montly.df <- plyr::ddply(top10.df, c("article.site.name", "Year.Month"), 
    summarise, Average_reads = length(id))

# Position of HS paywall
paywall.pos <- which(unique(top10.montly.df$Year.Month) == "2012-11")
ggplot(top10.montly.df, aes(x = Year.Month, y = Average_reads, colour = article.site.name)) + 
    geom_path(aes(group = article.site.name)) + geom_vline(xintercept = paywall.pos, 
    linetype = "dashed") + annotate("text", x = paywall.pos + 0.1, y = 40, label = "HS paywall introduced 20.11.2012", 
    hjust = 0)
```

![plot of chunk time3](http://i.imgur.com/c7ALJLs.png) 



