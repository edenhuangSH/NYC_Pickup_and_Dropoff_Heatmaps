spark_home = "/data/spark/spark-2.0.1-bin-hadoop2.7/"
Sys.setenv(SPARK_HOME=spark_home)

library(sparklyr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)

config = spark_config()
config$`sparklyr.shell.driver-memory` = '8G'
config$`sparklyr.shell.executor-memory` = '16G'
sc = spark_connect(master = 'local', version='2.0.1', config = config)



# read in data, green and yellow taxi and uber
green  = spark_read_csv(sc, 'green', '/data/nyc-taxi-data/data/green_tripdata_2014-06.csv')
yellow = spark_read_csv(sc, 'yellow', '/data/nyc-taxi-data/data/yellow_tripdata_2014-06.csv')
uber   = spark_read_csv(sc, 'uber', '/data/nyc-taxi-data/data/uber-raw-data-jun14.csv')

fix_names = function(df)
{
  df %>%
    setNames(
      colnames(df) %>% 
        tolower() %>% 
        sub("[tl]pep_","",.) 
    )
}

green  = green  %>% fix_names()
yellow = yellow %>% fix_names()

### Task 1

# round lat and long to "raster" 
pickup_raster = function(df) {
    df %>% 
        select(pickup_longitude, pickup_latitude) %>%
        transmute(pickup_longitude = round(pickup_longitude, 3),
                  pickup_latitude  = round(pickup_latitude, 3)) %>%
        filter(pickup_latitude > 40.477, 
               pickup_latitude < 40.917,
               pickup_longitude > -74.259,
               pickup_longitude < -73.700) %>%
        group_by(pickup_longitude, pickup_latitude) %>%
        count() %>%
        collect()
}

dropoff_raster = function(df) {
    df %>% 
        select(dropoff_longitude, dropoff_latitude) %>%
        transmute(dropoff_longitude = round(dropoff_longitude, 3),
                  dropoff_latitude  = round(dropoff_latitude, 3)) %>%
        filter(dropoff_latitude > 40.477, 
               dropoff_latitude < 40.917,
               dropoff_longitude > -74.259,
               dropoff_longitude < -73.700) %>%
        group_by(dropoff_longitude, dropoff_latitude) %>%
        count() %>%
        collect()
}

uber_raster = function(df) {
    df %>% 
        select(Lat, Lon) %>%
        transmute(Lat = round(Lat,3), Lon = round(Lon,3)) %>%
        filter(Lat > 40.477, 
               Lat < 40.917,
               Lon > -74.259,
               Lon < -73.700) %>%
        group_by(Lat, Lon) %>%
        count() %>%
        collect()
}

    
green_pickup  = green %>% pickup_raster()
yellow_pickup = yellow %>% pickup_raster()
green_dropoff  = green %>% dropoff_raster()
yellow_dropoff = yellow %>% dropoff_raster()
uber_pickup = uber %>% uber_raster()

pickup = rbind(green_pickup,yellow_pickup)
pickup$group = c(rep("green",nrow(green_pickup)),rep("yellow",nrow(yellow_pickup)))


dropoff = rbind(green_dropoff,yellow_dropoff)
dropoff$group = c(rep("green",nrow(green_dropoff)),rep("yellow",nrow(yellow_dropoff)))




### Task 2
rush_summary = function (df) {
  df %>%
    mutate(pickup_hour = hour(pickup_datetime),
           dropoff_hour = hour(dropoff_datetime),
           if_rush_hour = (pickup_hour >= 7 & pickup_hour <= 10) | (dropoff_hour >= 7 & dropoff_hour <= 10))
}

## Rush hour taxi pickup
# Rush hour yellow cab pickup
rush_yellow_pickup = yellow %>%
  rush_summary() %>%
  filter(if_rush_hour == TRUE) %>%
  pickup_raster()
# Rush hour green cab pickup
rush_green_pickup = green %>%
  rush_summary() %>%
  filter(if_rush_hour == TRUE) %>%
  pickup_raster()
rush_pickup = rbind(rush_green_pickup, rush_yellow_pickup)
rush_pickup$group = c(rep("green",nrow(rush_green_pickup)), rep("yellow",nrow(rush_yellow_pickup)))

## Plot for rush hour taxi dropoffs
# Rush hour yellow cab dropoff
rush_yellow_dropoff = yellow %>%
  rush_summary() %>%
  filter(if_rush_hour == TRUE) %>%
  dropoff_raster()
# Rush hour green cab dropoff
rush_green_dropoff = green %>%
  rush_summary() %>%
  filter(if_rush_hour == TRUE) %>%
  dropoff_raster()
rush_dropoff = rbind(rush_green_dropoff, rush_yellow_dropoff)
rush_dropoff$group = c(rep("green",nrow(rush_green_dropoff)), rep("yellow",nrow(rush_yellow_dropoff)))

## Non-rush hour taxi pickups
# Non-rush hour yellow cab pickup
nonrush_yellow_pickup = yellow %>%
  rush_summary() %>%
  filter(if_rush_hour == FALSE) %>%
  pickup_raster()
# Non-rush hour green cab pickup
nonrush_green_pickup = green %>%
  rush_summary() %>%
  filter(if_rush_hour == FALSE) %>%
  pickup_raster()
non_rush_pickup = rbind(nonrush_green_pickup, nonrush_yellow_pickup)
non_rush_pickup$group = c(rep("green",nrow(nonrush_green_pickup)), rep("yellow",nrow(nonrush_yellow_pickup)))

## Non-rush hour taxi dropoffs
# Non-rush hour yellow cab dropoff
nonrush_yellow_dropoff = yellow %>%
  rush_summary() %>%
  filter(if_rush_hour == FALSE) %>%
  dropoff_raster()
# Non-rush hour green cab dropoff
nonrush_green_dropoff = green %>%
  rush_summary() %>%
  filter(if_rush_hour == FALSE) %>%
  dropoff_raster()
nonrush_dropoff = rbind(nonrush_green_dropoff, nonrush_yellow_dropoff)
nonrush_dropoff$group = c(rep("green",nrow(nonrush_green_dropoff)), rep("yellow",nrow(nonrush_yellow_dropoff)))

## Rush hour ubers
mutate_uber = uber %>% 
  mutate(Hour = regexp_extract(DateTime,"([0-9]+):([0-9]+)",1)) %>%
  mutate(if_rush_hour = (Hour >= 7 & Hour <= 10))
rush_uber =  mutate_uber %>%
  filter(if_rush_hour == T) %>%
  uber_raster()
## Non-rush hour ubers
nonrush_uber = mutate_uber %>%
  filter(if_rush_hour == F) %>%
  uber_raster()

## Write the data frames into RData file
save(pickup,dropoff,uber_pickup,rush_pickup,rush_dropoff,rush_uber,non_rush_pickup,nonrush_dropoff,nonrush_uber,
     file = "taxi_and_uber.RData")
