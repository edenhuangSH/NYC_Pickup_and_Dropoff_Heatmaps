spark_home = "/data/spark/spark-2.0.1-bin-hadoop2.7/"
Sys.setenv(SPARK_HOME=spark_home)

library(sparklyr)
library(dplyr)
library(ggplot2)
library(tidyr)

config = spark_config()
config$`sparklyr.shell.driver-memory` = '8G'
config$`sparklyr.shell.executor-memory` = '16G'
sc = spark_connect(master = 'local', version='2.0.1', config = config)



# read in data, green and yellow taxi and uber
green  = spark_read_csv(sc, 'green', '/data/nyc-taxi-data/data/green_tripdata_2014-06.csv')
yellow = spark_read_csv(sc, 'yellow', '/data/nyc-taxi-data/data/yellow_tripdata_2014-06.csv')
uber   = spark_read_csv(sc, 'uber', '/data/nyc-taxi-data/data/uber-raw-data-jun14.csv')

# round lat and long to "raster" 
pickup_raster = function(df) {
    df = setNames(df, tolower(colnames(df)))
    df %>% 
        select(pickup_longitude, pickup_latitude) %>%
        transmute(pickup_longitude = round(pickup_longitude, 3),
                  pickup_latitude  = round(pickup_latitude, 3)) %>%
        group_by(pickup_longitude, pickup_latitude) %>%
        count() %>%
        collect()
}

dropoff_raster = function(df) {
    df = setNames(df, tolower(colnames(df)))
    df %>% 
        select(dropoff_longitude, dropoff_latitude) %>%
        transmute(dropoff_longitude = round(dropoff_longitude, 3),
                  dropoff_latitude  = round(dropoff_latitude, 3)) %>%
        group_by(dropoff_longitude, dropoff_latitude) %>%
        count() %>%
        collect()
}

uber_raster = function(df) {
    df %>% 
        select(Lat, Long) %>%
        transmute(Lat = round(Lat), Long = round(Lat)) %>%
        group_by(Lat, Long) %>%
        count() %>%
        collect()
}

    
green_pickup  = green %>% pickup_raster()
yellow_pickup = yellow %>% pickup_raster()
green_dropoff  = green %>% dropoff_raster()
yellow_dropoff = yellow %>% dropoff_raster()
uber_pickup = uber %>% uber_raster()
