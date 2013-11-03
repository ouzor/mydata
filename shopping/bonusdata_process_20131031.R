# Script for analyzing and processing bonusdata

library(plyr)
library(lubridate)

library(RCurl)
library(rjson)

library(ggplot2)
library(RColorBrewer)
library(gridExtra)

library(ggmap)
library(sorvi)
theme_set(GetThemeMap())

# Package for sonification
library(playitbyr)
# Using csound 5.2
setCsoundLibrary("/Library/Frameworks/CsoundLib.framework/Versions/Current/lib_csnd.dylib")

# Package for animation
library(animation)

dat.folder <- "/Users/juusoparkkinen/Documents/workspace/Rdrafts/bonusdata/"


## PREROCESS DATA #########

# S-data was preprocessed in "S-data_read_20131031.R"
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
dat$ShopCategory <- shop.cats

# sort(table(droplevels(subset(dat, ShopCategory=="Other"))$Shop))


## ADD SHOP LOCATIONS #######


# Write shops down, fix by manually, and geocode with nominatim
shops.df <- data.frame(Shop.orig=sort(levels(dat$Shop)), Shop.curated=sort(levels(dat$Shop)))
write.csv(shops.df, row.names=FALSE, file=file.path(dat.folder, "Bonusdata_Shops_raw_20131031.csv"))
# # Manual curation here
shops.curated.df <- read.csv(file.path(dat.folder, "Bonusdata_Shops_curated_20131031.csv"), sep="\t")
# # Get geocodes from Nominatim (OpenStreetMap)
# shops.curated.df$Lat <- shops.curated.df$Lon <- NA
# for (i in 1:nrow(shops.curated.df)) {
#   Sys.sleep(1)
#   query <- gsub(" ", "+", as.vector(shops.curated.df$Shop.curated)[i])
#   message(query)
#   u <- paste0("http://nominatim.openstreetmap.org/search?q=",query,"&format=json")
#   geocode <- rjson::fromJSON(RCurl::getURI(u))
#   if (length(geocode)) {
#     message("Found ", length(geocode))
#     shops.curated.df$Lat[i] <- geocode[[1]]$lat
#     shops.curated.df$Lon[i] <- geocode[[1]]$lon
#   } else {
#     message("Not found")
#   }
# }
# shops.curated.df$Lat <- as.numeric(shops.curated.df$Lat)
# shops.curated.df$Lon <- as.numeric(shops.curated.df$Lon)
# save(shops.curated.df, file=file.path(dat.folder, "Bonusdata_Shop-locations_20131102.RData"))
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

load(file.path(dat.folder, "Bonusdata_20131103.RData"))

# Plot data by shop category and time
p <- ggplot(dat, aes(x=Date, y=ShopCategory, size=Value, colour=ShopCategory)) + geom_point(position=position_jitter(width=0, height=0.2)) + scale_size_continuous(range=c(2, 10))
#ggsave(p, width=8, height=6, file=file.path(dat.folder, "Bonusdata_ShopCategory-Time_20131102.png"))


# Get time span
span <- as.interval(dat$Date[nrow(dat)] - dat$Date[1], dat$Date[1],)
span.days <- as.period(span, unit="days")

# Create and test scales
x.scale <- scale_x_date(limits=c(as.Date(int_start(span)), as.Date(int_end(span))))
y.scale <- scale_y_continuous(limits=c(0, max(dat$CumValue)))
shop.cats <- unique(dat$ShopCategory)
col.scale <- scale_colour_discrete(drop=FALSE)
fill.scale <- scale_fill_discrete(drop=FALSE)

dat.init <- data.frame(Date=dat$Date[1], ShopCategory=factor(unique(dat$ShopCategory)), Value=0.01, CumValue=0.01, Lon=NA, Lat=NA)
levels(dat.init$ShopCategory) <- levels(dat.init$ShopCategory)[c(1,2,9,8,5,6,4,3,7)]

p.cum.bar2 <- ggplot(dat.init, aes(x=ShopCategory, fill=ShopCategory)) + geom_bar(aes(weight=Value)) + geom_bar(data=dat[1:50,], aes(weight=Value)) + y.scale + fill.scale + theme(legend.position="top")


## MAP PLOTS #######

## Map for Helsinki regio
Hel.bbox <- c(24.6, 60.12, 25.1, 60.32)
names(Hel.bbox) <- c("left", "bottom", "right", "top")
Hel.map <- get_map(location=Hel.bbox, source="stamen", maptype="toner")
p.hel.plain <- ggmap(Hel.map) + theme(legend.position="none")
p.map.hel <- p.hel.plain + geom_point(data=dat, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value))

## Map for whole Finland
Fin.bbox <- c(21.0, 59.5, 30.5, 65)
names(Fin.bbox) <- c("left", "bottom", "right", "top")
Fin.map <- get_map(location=Fin.bbox, source="stamen", maptype="toner")
p.fin.plain <- ggmap(Fin.map) + theme(legend.position="none")
p.map.fin <- p.fin.plain + geom_point(data=dat, aes(x=Lon, y=Lat, colour=ShopCategory, size=Value))

save.image(file.path(dat.folder, "bonusdata_image_20131103.RData"))


## SONIFICATION #######

load(file.path(dat.folder, "bonusdata_image_20131103.RData"))

# frames per second
fps <- 10

# ## TEST SONIFICATION
# dat.temp <- droplevels(dat[1:50,])
# temp.span <- as.interval(dat.temp$Date - dat.temp$Date[1], dat.temp$Date[1],)
# temp.days <- as.period(temp.span, unit="days")
# dat.temp$TimeInd <- temp.days@day
# dat.temp$ValueInvert <- max(dat.temp$Value) - dat.temp$Value# + 100
# maxTime <- temp.days[length(temp.days)]@day/fps
# # Cut values
# Ncuts <- 5
# dat.temp$ValueCut <- as.numeric(cut(dat.temp$Value, breaks=Ncuts)) 
# son <- sonify(dat.temp, sonaes(time = TimeInd, pitch = ValueCut, mod = ValueCut, indx = ValueCut)) 
# son <- son + shape_scatter() + scale_time_continuous(c(0, maxTime)) + scale_pitch_continuous(7 + c(0, Ncuts-1)) 
# sonsave(what=son, where=file.path(dat.folder, "animations/bonusdata_audio_temp_20131102.wav"))


temp.span <- as.interval(dat$Date - dat$Date[1], dat$Date[1],)
temp.days <- as.period(temp.span, unit="days")
dat$TimeInd <- temp.days@day
# Length of video in seconds
maxTime <- span.days@day/fps
#dat$ValueInvert <- max(dat$Value) - dat$Value# + 100
# Cut value to produce clean sounds
# Ncuts <- 5
# dat$ValueCut <- as.numeric(cut(dat$Value, breaks=Ncuts)) 
val.breaks <- c(0, 10, 20, 30, 50, 100, 500)
dat$ValueCut <- as.numeric(cut(dat$Value, breaks=val.breaks)) 
son <- sonify(dat, sonaes(time = TimeInd, pitch = ValueCut, mod = ValueCut, indx = ValueCut)) 
son <- son + shape_scatter() + scale_time_continuous(c(0, maxTime)) + scale_pitch_continuous(6 + c(0, length(val.breaks)-2)) 

#print(son)
sonsave(what=son, where=file.path(dat.folder, "animations/bonusdata_audio_V2_20131102.wav"))
# summary(son)

## ANIMATION ##########


ani.options(outdir=paste0(dat.folder, "animations"))

# Joint animation
ani.options(interval = 1/fps, nmax=span.days@day)#nrow(dat))
fade.length <- 10

# Define scales for size and alpha!
size.scale <- scale_size_continuous(limits=c(min(dat$Value), max(dat$Value)), range=c(8, 18))
alpha.scale <- scale_alpha_continuous(limits=c(0.0, 1), range=c(0, 1))

# Get subset of dat within the map range
dat.hel <- droplevels(subset(dat, dat$Lon >Hel.bbox["left"] & dat$Lon < Hel.bbox["right"] & dat$Lat > Hel.bbox["bottom"] & dat$Lat < Hel.bbox["top"]))

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
    p1 <- arrangeGrob(p.hel, p.fin, nrow=1, widths=c(0.59, 0.41))
    p2 <- arrangeGrob(p.cum, p1, nrow=2, heights=c(0.25, 0.75))
    print(p2)
  }
}, video.name="bonusdata_video_V3_20131103.mp4", clean=TRUE, other.opts = "-b:a 300k", ani.width=1280, ani.height=720)



## COMBINE AUDIO + VIDEO ############

message("this could probably be included into saveVideo")
setwd("bonusdata/animations/")
system("ffmpeg -i bonusdata_video_V2_20131102.mp4 -i bonusdata_audio_V2_20131102.wav bonusdata_audio_video_V2_20131102.mp4")