# Script for parsing bonusdata from S-Market

# Copyright (C) 2013 Juuso Parkkinen.
# Contact: <http://ouzor.github.com/contact>. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify
# it under the terms of the FreeBSD License (keep this notice):
  # http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Scan all files to a vector
files <- dir("TEMP_TXT/", pattern="S-data")
# Reorder files properly
temp1 <- sapply(strsplit(files, split="split_"), function(x) x[2])
temp2 <- sapply(strsplit(temp1, split="\\."), function(x) x[1])
files <- files[order(as.numeric(temp2))]
raw.dat <- c()
for (file in files)
  raw.dat <- c(raw.dat, scan(paste("TEMP_TXT/", file, sep=""), what="character", quote="", sep="\n"))

# Identify shopping events based on rows with "Yhteensä", marks the end of an event
event.ends <- grep("Yhteensä", raw.dat)

# Extract shopping event info
events.raw <- list()
for (ei in seq(event.ends)) {
  # Collect repated shopping in the same shop
  ri <- 2
  date.sums <- raw.dat[event.ends[ei]-1]
  while (!length(grep("Päivämäärä", raw.dat[event.ends[ei]-ri]))) {
    date.sums <- c(date.sums, raw.dat[event.ends[ei]-ri])
    ri <- ri + 1
  }
  shop <- raw.dat[event.ends[ei]-ri-2]
  events.raw[[ei]] <- date.sums
  names(events.raw)[ei] <- shop
}

# Get year info for events
years <- as.character(2012:2010)
events.year <- rep(NA, length(events.raw))
for (year in years)
  events.year[sapply(events.raw, function(x) length(grep(year, x))) >0] <- year

# Process raw event data
events.df <- data.frame()
for (ei in seq(events.raw)) {
  # Use only valid years
  valid.inds <- grep(events.year[ei], events.raw[[ei]])
  if (length(valid.inds)) {
    # Extract dates and sums for each datesum-event
    for (vi in valid.inds) {
      # Split by year
      temp1 <- unlist(strsplit(events.raw[[ei]][vi], split=events.year[ei]))
      # Fix date
      date.temp <- paste(temp1[1], events.year[ei], sep="")
      date.temp <- gsub("-", ".", date.temp)
      date.temp <- gsub(" ", "", date.temp)
      date.temp <- gsub("_", "", date.temp)
      
      # Fix sum/value
      temp2 <- unlist(strsplit(temp1[2], split=" "))
      val.temp <- as.numeric(gsub(",", ".", temp2[2]))
      events.df <- rbind(events.df, data.frame(Shop=names(events.raw)[ei], DateRaw=date.temp, Value=val.temp))
    }
  }
}

# Remove NA's
events.df <- na.omit(events.df)

# Remove AUTOMAA
events.df <- events.df[-grep("AUTOMAA", events.df$Shop),]

# Transform to Date format
events.df$Date <- as.Date(events.df$DateRaw, format="%d.%m.%Y")

# Add shop categories
shop.cats <- rep("Other", nrow(events.df))
events.df$Shop <- toupper(events.df$Shop)
shop.cats[grep("ALEPA", events.df$Shop)] <- "Alepa"
shop.cats[grep("ABC", events.df$Shop)] <- "ABC"
shop.cats[grep("S-MARKET", events.df$Shop)] <- "S-Market"
shop.cats[grep("PRISMA", events.df$Shop)] <- "Prisma"
events.df$ShopCategory <- shop.cats

# Save
save(events.df, file="S-data_Events_20130526.RData")

# Plot
library(ggplot2)
p1 <- ggplot(events.df, aes(x=Date, y=ShopCategory, size=Value, colour=ShopCategory)) + geom_point()
p2 <- ggplot(events.df, aes(x=Date, y=ShopCategory, size=Value, colour=ShopCategory)) + geom_point(position=position_jitter(width=0, height=0.2)) + scale_size_continuous(range=c(2, 10))
ggsave(p2, file="S-data_Events_20130526.png")
