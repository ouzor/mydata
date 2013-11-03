# Script for parsing bonusdata from S-Market

dat.folder <- "/Users/juusoparkkinen/Documents/workspace/Rdrafts/bonusdata/"

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
