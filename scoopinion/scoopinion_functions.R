# Functions for processing Scoopinion data

PreprocessScoopinionData <- function(filename) {
  
  # Load required packages
  require(rjson)
  require(reshape2)
  
  # Read scoopinion data from json file
  message("Preprocessing Scoopinion data from ", filename, "...", appendLF=FALSE)
  scoop.raw <- rjson::fromJSON(file=filename)
  
  # Check that data is in expected format
  stopifnot(all(sapply(scoop.raw$reads, length)==7))
  stopifnot(all(sapply(scoop.raw$reads, function(x) length(x$article))==9))
  stopifnot(all(sapply(scoop.raw$reads, function(x) length(x$article$site))==4))
  
  ExtractReadData <- function(read) {
    # Remove author information
    read$article <- read$article[names(read$article) != "authors"]
    # Change all NULLs to NAs
    read[which(sapply(read, is.null))] <- NA
    read$article[which(sapply(read$article, is.null))] <- NA
    read$article$site[which(sapply(read$article$site, is.null))] <- NA  
    return(unlist(read))
  }
  reads.mat <- sapply(scoop.raw$reads, ExtractReadData)
  stopifnot(is.matrix(reads.mat))
  reads.df <- as.data.frame(t(reads.mat))
  
  # Fix format to numeric 
  reads.df$total_time <- as.numeric(as.vector(reads.df$total_time))
  reads.df$words_read <- as.numeric(as.vector(reads.df$words_read))
  reads.df$progress <- as.numeric(as.vector(reads.df$progress))
  reads.df$article.word_count <- as.numeric(as.vector(reads.df$article.word_count))
  reads.df$article.average_time <- as.numeric(as.vector(reads.df$article.average_time))
  
  # Separate date and time from 'created_at'
  reads.df$Date <- as.Date(sapply(strsplit(as.vector(reads.df$created_at), split="T"), "[", 1))
  reads.df$Time <- gsub("Z", "", sapply(strsplit(as.vector(reads.df$created_at), split="T"), "[", 2))
  
  # Add Weekday, Year, and Year-Month info
  reads.df$WeekDay <- factor(weekdays(reads.df$Date), levels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
  reads.df$Year <- format(reads.df$Date, format = "%Y")
  reads.df$Year.Month <- format(reads.df$Date, format = "%Y-%m")
  
  # Return data
  message("DONE")
  return(reads.df)
}