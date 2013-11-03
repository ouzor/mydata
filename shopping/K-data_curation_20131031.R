# Split K pages to two

library(png)

dat.folder <- "/Users/juusoparkkinen/Documents/workspace/Rdrafts/bonusdata/K-data_processed/"

## SPLIT K-DATA PNG'S TO HALF ########

# Go through pictures with data
counter <- 1
# Take only the same time span as in S-data
for (i in 6:10) {

  # Read original figure
  filename <- paste0(dat.folder, "K-data_split_",i,".png")
  message(filename)
  temp.png <- readPNG(filename)
  
  # Split to two
  split1 <- temp.png[1:(nrow(temp.png)/2), ]
  split2 <- temp.png[(nrow(temp.png)/2):nrow(temp.png), ]

  # Write halfs
  writePNG(split1, paste0(dat.folder, "K-data_half_",counter,".png"))
  counter <- counter + 1
  writePNG(split2, paste0(dat.folder, "K-data_half_",counter,".png"))
  counter <- counter + 1
}


## REMOVE LINES FROM K-DATA PNG'S #########

for (i in 1:10) {
  
  # Read half a page
  temp.png <- readPNG(paste0(dat.folder, "K-data_half_",i,".png"))
  # Remove lines (function given below)
  temp.png.linesremoved <- RemoveLines(temp.png)
  # Write new figure
  writePNG(temp.png.linesremoved, paste0(dat.folder, "K-data_half_linesremoved_",i,".png"))
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

k.raw <- scan(file=file.path(dat.folder, "K-data_raw.txt"), what="character", sep="\n")
k.dat <- k.raw

# Delete some character
to.remove <- c("I", "\\|", " i", "]", "1 1 1 ", "1 1 1", "   ", "  ")

for (char in to.remove)
  k.dat <- gsub(char, "", k.dat)

# Write
write(k.dat, file=file.path(dat.folder, "K-data_curated.txt"), ncolumns=1)


# k.raw <- scan(file=file.path(dat.folder, "K-data_curated2.txt"), what="character", sep="\n")
# k.dat <- k.raw
# # # Delete first character from each
# # k.dat <- sapply(k.raw, function(x) substr(x, start=2, stop=length(x)))
# 
# # Delete some character
# to.remove <- c()
# 
# #k.dat <- k.dat[41:length(k.dat)]
# for (char in to.remove)
#   k.dat <- gsub(char, "", k.dat)
# #k.dat <- c(k.raw[1:40], k.dat)
# 
# # Write
# write(k.dat, file=file.path(dat.folder, "K-data_curated3.txt"), ncolumns=1)
