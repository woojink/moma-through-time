library(data.table)
library(ggplot2)
library(lubridate)
library(dplyr)

# Load data
data <- read.csv('./datasets/MoMA_Exhibitions_ArtistsCurators.csv', fileEncoding="macroman")
data <- as.data.frame(data)

movements <- read.csv('./datasets/ArtistsArtContemporaryMovements.csv', fileEncoding="macroman")
movements <- data.table(movements)

gender_data <- read.csv('datasets/MoMAartist_data_w_bom.csv', fileEncoding="macroman")
gender_data <- data.table(gender_data)

##############################
# Data Clean-Up
# Rename for consistency
colnames(data)[7:8] <- c('StartDate', 'EndDate')

# Convert to datetime objects with lubridate
data$StartDate <- ymd(data$StartDate)
data$EndDate <- ymd(data$EndDate)
data$StartYear <- year(data$StartDate)

# Pick only artists/performer
data <- data[data$role=="Artist/Participant",]

# Clean up incorrect data
data[25767,]$EndDate <- ymd("1976-04-28")
data[data$ExhNumber==127,]$StartDate <- ymd('1941-04-30')
data[data$ExhNumber==127,]$EndDate <- ymd('1941-05-06')
data[data$ExhNumber==324,]$EndDate <- NA

# Clean up nationality data
levels(data$Nationality)[c(45, 49)] <- ""

# For the selected exhibits part of the permanent collection (exhibit 909)
# data[data$ExhNumber==909,]$EndDate <- ymd('1990-04-16') # Exhibit
data[data$ExhNumber==909,]$EndDate <- NA # Exclude entirely

# Date ranges
min(data$EndDate, na.rm=TRUE)
max(data$EndDate, na.rm=TRUE)

##############################
# Exhibition Length
data$ExhibitionLength <- (data$EndDate-data$StartDate)

# Total exhibits each year (Manuel)
exhibits.by.year <- data %>%
  group_by(StartYear) %>%
  summarise(exhibits.by.year = n_distinct(ExhTitle))
exhibits.by.year <- data.table(exhibits.by.year)

# Group by display name to determine total days shown for every artist
total.by.artist <- aggregate(ExhibitionLength ~ DisplayName, data, sum)
total.by.artist <- total.by.artist[total.by.artist$DisplayName != "",]
total.by.artist <- total.by.artist[order(total.by.artist$ExhibitionLength, decreasing=TRUE),]
colnames(total.by.artist)[2] <- "LifetimeExhibitionLength"

num.artists <- 50
top_artists <- total.by.artist[1:num.artists,]
top_artists$Rank <- c(1:num.artists)
write.csv(top_artists$DisplayName, file="data/top_artist_list.csv", row.names=FALSE, fileEncoding="UTF-8")

# Group by nationality
total.by.country <- aggregate(ExhibitionLength ~ Nationality, data, sum)
total.by.country <- total.by.country[total.by.country$Nationality != "",]
total.by.country <- total.by.country[order(total.by.country$ExhibitionLength, decreasing=TRUE),]
colnames(total.by.country)[2] <- "LifetimeExhibitionLength"

num.countries <- 15
top.countries <- total.by.country[1:num.countries,]
top.countries$Rank <- c(1:num.countries)
write.csv(top.countries$Nationality, file="data/top_country_list.csv", row.names=FALSE, fileEncoding="UTF-8")

#########################
# Determine exhibition counts per artist/year combination with data table
dt <- data.table(data)
setkeyv(dt, c('DisplayName', 'StartYear'))
dt[, count:=.N, by = list(DisplayName, StartYear)]
dt <- unique(dt)
dt.export <- dt[,.(ExhTitle, StartDate, EndDate, DisplayName, 
                   Nationality, ExhibitionLength, StartYear, count)]

dt.country <- data.table(data)
setkeyv(dt.country, c('Nationality', 'StartYear'))
dt.country[, count:=.N, by = list(Nationality, StartYear)]
dt.country <- unique(dt.country)
dt.country.export <- dt.country[,.(Nationality, StartYear, count)]

# Pretty plots with exhibits per year
# ggplot(dt.export, aes(x=StartYear, y=count, group=DisplayName)) + geom_line(alpha=0.05)
# ggplot(dt.export, aes(x=StartYear, y=count, group=DisplayName)) + geom_point(alpha=0.05)

top_artists.dt <- dt.export[dt.export$DisplayName %in% top_artists$DisplayName,]
top_artists.dt <- top_artists.dt[!is.na(top_artists.dt$StartYear),]

top_countries.dt <- dt.country.export[dt.country.export$Nationality %in% top.countries$Nationality,]
top_countries.dt <- top_countries.dt[!is.na(top_countries.dt$StartYear),]

# Joins: Pick only artists in the top artists list
top_artists <- data.table(top_artists)
setkey(top_artists, DisplayName)
setkey(top_artists.dt, DisplayName)
top_artists.dt <- top_artists.dt[top_artists, nomatch=0]

# Joins: Put movement info in the main list, also create a list with only tagged artists
setkey(top_artists.dt, DisplayName)
setkey(movements, Artist)
top_artists.dt <- merge(top_artists.dt, movements, by.x="DisplayName", by.y="Artist", all.x=TRUE)
only.tagged.artists <- top_artists.dt[movements, nomatch=0]
only.tagged.artists2 <- top_artists[movements, nomatch=0]

# Export to csv
write.csv(top_artists.dt, file="data/top_artists.csv", row.names=FALSE, fileEncoding="UTF-8")
write.csv(top_countries.dt, file="data/top_countries.csv", row.names=FALSE, fileEncoding="UTF-8")
write.csv(only.tagged.artists, file="data/artists_movements.csv", row.names=FALSE, fileEncoding="UTF-8")
write.csv(only.tagged.artists2, file="data/artists_movements2.csv", row.names=FALSE, fileEncoding="UTF-8")