# Script for analyzing and processing bonusdata from S- and K-groups

# Copyright (C) 2013 Juuso Parkkinen.
# Contact: <juuso.parkkinen@iki.fi>. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify
# it under the terms of the FreeBSD License (keep this notice):
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Set folder path
dat.folder <- ""


## SPLIT K-DATA PNG'S TO HALF ########

library(png)

# Go through pictures with data
counter <- 1
# Take only the same time span as in S-data
for (i in 6:10) {
  
  # Read original figure
  filename <- paste0(dat.folder, "K-data_processed/K-data_split_",i,".png")
  message(filename)
  temp.png <- readPNG(filename)
  
  # Split to two
  split1 <- temp.png[1:(nrow(temp.png)/2), ]
  split2 <- temp.png[(nrow(temp.png)/2):nrow(temp.png), ]
  
  # Write halfs
  writePNG(split1, paste0(dat.folder, "K-data_processed/K-data_half_",counter,".png"))
  counter <- counter + 1
  writePNG(split2, paste0(dat.folder, "K-data_processed/K-data_half_",counter,".png"))
  counter <- counter + 1
}


## REMOVE LINES FROM K-DATA PNG'S #########

for (i in 1:10) {
  
  # Read half a page
  temp.png <- readPNG(paste0(dat.folder, "K-data_processed/K-data_half_",i,".png"))
  # Remove lines (function given below)
  temp.png.linesremoved <- RemoveLines(temp.png)
  # Write new figure
  writePNG(temp.png.linesremoved, paste0(dat.folder, "K-data_processed/K-data_half_linesremoved_",i,".png"))
}

# Function for removing lines from a given K-data figure
RemoveLines <- function(temp.png) {
  
  # Define areas to study
  table.left <- seq(500, 700)
  table.right <- seq(3000, 3200)
  # table.rows <- seq(2000, 2400)
  table.rows <- seq(1800, 2200)
  table.diff <- table.right[1] - table.left[1]
  left.box <- temp.png[table.rows, table.left]
  right.box <- temp.png[table.rows, table.right]
  # # Check
  # library(ggplot2)
  # library(reshape2)
  #   ggplot(melt(left.box), aes(x=Var2, y=-Var1, fill=value)) + geom_tile()
  #   ggplot(melt(right.box), aes(x=Var2, y=-Var1, fill=value)) + geom_tile()
  
  # Compute line sums
  left.linesum <- apply(left.box, 1, sum)
  right.linesum <- apply(right.box, 1, sum)
  # message("CHECK THAT THERE ARE SOME ZEROS!")
  
  # Get mean positions of zeros
  GetZeros <- function(linesum) {
    
    # Set line width to study
    line.width <- 8
    zeros.raw <- which(linesum==0)
    zeros <- list()
    while(length(zeros.raw) > 0) {
      inds.to.add <- which(zeros.raw-zeros.raw[1] < line.width)
      zeros[[length(zeros)+1]] <- zeros.raw[inds.to.add]
      zeros.raw <- zeros.raw[-inds.to.add]
    }
    return(zeros)
  }
  left.zero.means <- sapply(GetZeros(left.linesum), mean)
  right.zero.means <- sapply(GetZeros(right.linesum), mean)
  
  # If line at the begining of the right box but not on the left
  # Note! Should probably check the other way as well
  if (right.zero.means[1] < 5 & left.zero.means[1] > 5) {
    left.zero.means <- left.zero.means[-5]
    right.zero.means <- right.zero.means[-1]
  }
  
  # Estimate difference of mean positions
  mean.diffs <- left.zero.means - right.zero.means
  average.mean <- mean(mean.diffs)
  
  # Define difference of line positions on left and right (= tilt of the figure)
  line.step <- round(table.diff/average.mean)
  image.width <- ncol(temp.png)
  Nsteps <- ceiling(image.width/line.step)
  
  # Estimatte separation of lines (=gap between them)
  line.sep <- mean(left.zero.means[2:length(left.zero.means)] - left.zero.means[1:(length(left.zero.means)-1)])
  
  # Modifier because table.left is not exactly on the left
  modifier <- ceiling(mean(table.left)/line.step)
  
  # Copy and modify temp.png
  temp.png2 <- temp.png
  start.line <- table.rows[1] + left.zero.means[1]
  # For each line (up and down 20 lines from the start)
  for (li in seq(-18, 18)) {
    # Modify +- 10 pixel rows (more than line width)
    for (ri in seq(-10, 10)) {
      # Go through steps defined by tilt angle
      if (Nsteps==0) {
        temp.png2[round(li*line.sep) + ri + start.line + modifier, ] <- 1
      } else {
        for (ni in 1:(abs(Nsteps)-1))
          #          temp.png2[round(li*line.sep) + ni + ri + start.line + modifier,  1:abs(line.step) + (ni-1)*abs(line.step)] <- 1
          temp.png2[round(li*line.sep) -sign(Nsteps)*ni + ri + start.line + modifier,  1:abs(line.step) + (ni-1)*abs(line.step)] <- 1
        
      }
    }
  }
  return(temp.png2)
}


## CLEAN TXT FILE #########

k.raw <- scan(file=file.path(dat.folder, "K-data_processed/K-data_raw.txt"), what="character", sep="\n")
k.dat <- k.raw

# Delete some character
to.remove <- c("I", "\\|", " i", "]", "1 1 1 ", "1 1 1", "   ", "  ")

for (char in to.remove)
  k.dat <- gsub(char, "", k.dat)

# Write
write(k.dat, file=file.path(dat.folder, "K-data_processed/K-data_curated.txt"), ncolumns=1)


## READ S-DATA ############

# Scan manually curated text data file
raw.dat <- scan(file.path(dat.folder, "S-data_processed/S-data_curated.txt"), what="character", quote="", sep="\n")

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
datS.df <- data.frame()
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
      
      # Fix sum/value
      temp2 <- unlist(strsplit(temp1[2], split=" "))
      val.temp <- as.numeric(gsub(",", ".", temp2[2]))
      datS.df <- rbind(datS.df, data.frame(Shop=names(events.raw)[ei], Date=date.temp, Value=val.temp))
    }
  }
}

# Remove NA's
datS.df <- na.omit(datS.df)

# Remove number from the shop name
levels(datS.df$Shop) <- sapply(strsplit(levels(datS.df$Shop), split=" "), function(x) paste(x[2:length(x)], collapse=" "))
# Save
save(datS.df, file=file.path(dat.folder, "S-data_raw_20131031.RData"))


## COMBINE AND PROCESS S- AND K-DATA #########

library(plyr)
library(lubridate)

# Load preprocessed S-data
load(file.path(dat.folder, "S-data_raw_20131031.RData"))

# K-Data is already in easily readable format
datK.df<- read.table(file.path(dat.folder, "K-data_processed/K-data_curated_final.txt"), sep="\t", header=FALSE)
names(datK.df) <- c("Shop", "Date", "Value")
datK.df$Value <- as.numeric(gsub(",", ".", as.vector(datK.df$Value)))

# Combine S and K data into one data frame
dat <- rbind(cbind(datS.df, Group="S"), cbind(datK.df, Group="K"))

# Process Date information
dat$Date <- dmy(as.character(dat$Date))

# Start from November 2010, end at October 2012 => two years exactly
dat <- droplevels(subset(dat, Date >= ymd("2010-11-01") & Date <= ymd("2012-10-31")))

# Remove some lines
dat <- droplevels(subset(dat, !(Shop %in% c("AUTOMAA VANTAA", "NIEMI PALVELUT OY"))))

# Sum over replicates for one day
dat <- plyr::ddply(dat, c("Shop", "Date", "Group"), summarise, Value=sum(Value))

# Remove the biggest sums
dat <- droplevels(subset(dat, Value <= 250))

# Order by date
dat <- dat[order(dat$Date),]


## ADD SHOP CATEGORIES #####

library(RCurl)
library(rjson)

# Add shop categories
shop.cats <- rep("Other", nrow(dat))
#events.df$Shop <- toupper(events.df$Shop)
shop.cats[grep("ALEPA", dat$Shop)] <- "Alepa"
shop.cats[grep("ABC", dat$Shop)] <- "ABC"
shop.cats[grep("S-MARKET", dat$Shop)] <- "S-Market"
shop.cats[grep("PRISMA", dat$Shop)] <- "Prisma"
shop.cats[grep("K-market", dat$Shop)] <- "K-market"
shop.cats[grep("K-supermarket", dat$Shop)] <- "K-supermarket"
shop.cats[grep("K-citymarket", dat$Shop)] <- "K-citymarket"
shop.cats[grep("Intersport", dat$Shop)] <- "Intersport"

# Add categories to data and reorder
dat$ShopCategory <- factor(shop.cats)
dat$ShopCategory <- factor(dat$ShopCategory, levels=levels(dat$ShopCategory)[c(1,2,9,8,5,6,4,3,7)])

# sort(table(droplevels(subset(dat, ShopCategory=="Other"))$Shop))


## ADD SHOP LOCATIONS #######


# Write shops down, fix by manually, and geocode with nominatim
shops.df <- data.frame(Shop.orig=sort(levels(dat$Shop)), Shop.curated=sort(levels(dat$Shop)))
write.csv(shops.df, row.names=FALSE, file=file.path(dat.folder, "Bonusdata_Shops_raw_20131031.csv"))
# Manual curation here
shops.curated.df <- read.csv(file.path(dat.folder, "Bonusdata_Shops_curated_20131031.csv"), sep="\t")
# Get geocodes from Nominatim (OpenStreetMap)
shops.curated.df$Lat <- shops.curated.df$Lon <- NA
for (i in 1:nrow(shops.curated.df)) {
  Sys.sleep(1)
  query <- gsub(" ", "+", as.vector(shops.curated.df$Shop.curated)[i])
  message(query)
  u <- paste0("http://nominatim.openstreetmap.org/search?q=",query,"&format=json")
  geocode <- rjson::fromJSON(RCurl::getURI(u))
  if (length(geocode)) {
    message("Found ", length(geocode))
    shops.curated.df$Lat[i] <- geocode[[1]]$lat
    shops.curated.df$Lon[i] <- geocode[[1]]$lon
  } else {
    message("Not found")
  }
}
shops.curated.df$Lat <- as.numeric(shops.curated.df$Lat)
shops.curated.df$Lon <- as.numeric(shops.curated.df$Lon)
save(shops.curated.df, file=file.path(dat.folder, "Bonusdata_Shop-locations_20131102.RData"))


load(file.path(dat.folder, "Bonusdata_Shop-locations_20131102.RData"))

# Merge shop location data to shopping data
dat <- merge(dat, shops.curated.df[c("Shop.orig", "Lat", "Lon")], by.x="Shop", by.y="Shop.orig")

# Remove northest shops (too few)
dat <- droplevels(subset(dat, Lat < 65))

# Compute cumulative sums for shop categories
dat <- plyr::ddply(dat, c("ShopCategory"), transform, CumValue=cumsum(Value))

# Order by date (again)
dat <- dat[order(dat$Date),]

# Save preprocessed data
save(dat, file=file.path(dat.folder, "Bonusdata_20131103.RData"))


## BASIC PLOTS ######

library(ggplot2)
library(RColorBrewer)
library(gridExtra)

load(file.path(dat.folder, "Bonusdata_20131103.RData"))

# Define common scales for all plot
y.scale <- scale_y_continuous(limits=c(0, max(dat$CumValue)))
col.scale <- scale_colour_brewer(palette="Set1", drop=FALSE)
fill.scale <- scale_fill_brewer(palette="Set1", drop=FALSE)
size.scale <- scale_size_continuous(limits=c(min(dat$Value), max(dat$Value)), range=c(8, 18))
alpha.scale <- scale_alpha_continuous(limits=c(0.0, 1), range=c(0, 1))

dat.init <- data.frame(Date=dat$Date[1], ShopCategory=factor(levels(dat$ShopCategory), levels=levels(dat$ShopCategory)), Value=0.01, CumValue=0.01, Lon=NA, Lat=NA)

# Plot data by shop category and time
p <- ggplot(dat, aes(x=Date, y=ShopCategory, size=Value, colour=ShopCategory)) + geom_point(position=position_jitter(width=0, height=0.2)) + scale_size_continuous(range=c(2, 10)) + col.scale
ggsave(p, width=8, height=6, file=file.path(dat.folder, "Bonusdata_ShopCategory-Time_20131103.png"))


p.cum.test <- ggplot(dat.init, aes(x=ShopCategory, fill=ShopCategory)) + geom_bar(aes(weight=Value)) + geom_bar(data=dat, aes(weight=Value)) + y.scale + fill.scale + theme(legend.position="top")


## MAP PLOTS #######

library(ggmap)
library(sorvi)
theme_set(GetThemeMap())

## Map for Helsinki region
Hel.bbox <- c(24.6, 60.12, 25.1, 60.32)
names(Hel.bbox) <- c("left", "bottom", "right", "top")
Hel.map <- get_map(location=Hel.bbox, source="stamen", maptype="toner")
p.hel.plain <- ggmap(Hel.map) + theme(legend.position="none")
# Get subset of dat within the map range
dat.hel <- droplevels(subset(dat, dat$Lon >Hel.bbox["left"] & dat$Lon < Hel.bbox["right"] & dat$Lat > Hel.bbox["bottom"] & dat$Lat < Hel.bbox["top"]))
p.map.hel <- p.hel.plain + geom_point(data=dat.hel, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value)) + col.scale + size.scale
ggsave(p.map.hel + theme(legend.position="right") + scale_size_continuous(guide="none", range=c(5, 10)) + labs(colour=NULL), width=6, height=4, file=file.path(dat.folder, "Bonusdata_Helsinkimap.png"))

## Map for whole Finland
Fin.bbox <- c(21.0, 59.5, 30.5, 65)
names(Fin.bbox) <- c("left", "bottom", "right", "top")
Fin.map <- get_map(location=Fin.bbox, source="stamen", maptype="toner")
p.fin.plain <- ggmap(Fin.map) + theme(legend.position="none")
p.map.fin <- p.fin.plain + geom_point(data=dat, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value)) + col.scale + size.scale

# Save stuff
save.image(file.path(dat.folder, "bonusdata_image_20131103.RData"))


## SONIFICATION #######

# Package for sonification
library(playitbyr)
# Using csound 5.2
setCsoundLibrary("/Library/Frameworks/CsoundLib.framework/Versions/Current/lib_csnd.dylib")

# Load data so far
load(file.path(dat.folder, "bonusdata_image_20131103.RData"))

# Common settings for sonification and animation
span <- as.interval(dat$Date[nrow(dat)] - dat$Date[1], dat$Date[1],)
span.days <- as.period(span, unit="days")
# Frames per second
fps <- 10

# Length of video in seconds
maxTime <- (span.days@day+1)/fps

# Add day index to data
dat$TimeInd <- as.period(as.interval(dat$Date - dat$Date[1], dat$Date[1],), unit="days")@day


# Quantize values to produce clean sounds
val.breaks <- c(0, 10, 20, 30, 50, 100, 500)
dat$ValueCut <- as.numeric(cut(dat$Value, breaks=val.breaks)) 

# Use only two tones, based on group
dat$GroupVal <- as.numeric(dat$Group)

son <- sonify(dat, sonaes(time = TimeInd, pitch = GroupVal)) 
son <- son + shape_scatter(mod=1, indx=3) + scale_time_continuous(c(0, maxTime)) + scale_pitch_continuous(c(8,8+4/12))
sonsave(what=son, where=file.path(dat.folder, "animations/bonusdata_audio_V4_20131103.wav"))


## ANIMATION ##########

# Package for animation
library(animation)

# Animation options
ani.options(outdir=paste0(dat.folder, "animations"),
            interval = 1/fps,
            nmax=span.days@day+1,
            ani.width=1280,
            ani.height=720)
# Define duration of data point fading
fade.length <- 10

# Create video
saveVideo({
  for (i in 0:span.days@day) {
    i.date <- int_start(span) + ddays(i)

    # Plot cumulative values for shop categories
    cv.dat <- subset(dat, Date <= i.date)
    p.cum <- ggplot(dat.init, aes(x=ShopCategory, fill=ShopCategory)) + geom_bar(aes(weight=Value))
    p.cum <- p.cum + geom_bar(data=cv.dat, aes(weight=Value))
    p.cum <- p.cum + y.scale + fill.scale + theme(legend.position="bottom", legend.text=element_text(size=20)) + labs(fill=NULL) 
    
    # Plot Hel map
    hel.dat <- subset(dat.hel, Date <= i.date & Date >= i.date - ddays(fade.length))
    p.hel <- p.hel.plain
    if (nrow(hel.dat)) {
      hel.dat$Fade <- 1-as.period(as.interval(hel.dat$Date, i.date), unit="days")@day/fade.length    
      hel.dat <- hel.dat[order(hel.dat$Date),]
      p.hel <- p.hel + geom_point(data=hel.dat, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value, alpha=Fade)) + size.scale + alpha.scale + col.scale
    }
    
    # Plot Hel map
    fin.dat <- subset(dat, Date <= i.date & Date >= i.date - ddays(fade.length))
    p.fin <- p.fin.plain
    if (nrow(hel.dat)) {
      fin.dat$Fade <- 1-as.period(as.interval(fin.dat$Date, i.date), unit="days")@day/fade.length    
      fin.dat <- fin.dat[order(fin.dat$Date),]
      p.fin <- p.fin + geom_point(data=fin.dat, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value, alpha=Fade)) + size.scale + alpha.scale + col.scale
    }
    
    # Print together
    ii <- paste0(paste(rep(" ", 4-str_length(i)), collapse=""), i)
    p1 <- arrangeGrob(p.hel, p.fin, nrow=1, widths=c(0.59, 0.41), main=textGrob(label=paste0("Bonusta kertyy!  Päivä:", ii), gp=gpar(fontsize=30)))
    p2 <- arrangeGrob(p.cum, p1, nrow=2, heights=c(0.25, 0.75))
    print(p2)
  }
}, video.name="bonusdata_video_V4_20131103.mp4", clean=TRUE, other.opts = "-b:a 300k")


## COMBINE AUDIO + VIDEO ############

message("this could probably be included into saveVideo")
setwd("bonusdata/animations/")
system("ffmpeg -y -i bonusdata_video_V4_20131103.mp4 -i bonusdata_audio_V4_20131103.wav bonusdata_audio_video_V4_20131103.mp4")