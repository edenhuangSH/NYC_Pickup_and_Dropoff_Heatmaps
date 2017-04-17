# Team1_hw7

Source: http://www2.stat.duke.edu/~cr173/Sta523_Fa16/hw/hw7.html

## Background
Todd Schneider maintains a github repository with scripts and tools for downloading data on more than 1.3 billion taxi and uber originating in New York city. These data come from the NYC Taxi & Limousine Commission (yellow and green cabs) and from Uber via a Freedom of Information Law request by FiveThirtyEight. The raw data is quite large, roughly 214G on disk on Saxon.

## Task 1 - Pickup and Dropoff Heatmaps
Pick a month that has data for Yellow cabs, Green cabs, and ubers. Using either sparkr or sparklyr read all three monthly data sets into Spark. Using only the spark engine spatially aggregate the pickup and dropoff locations and count the number of pickups or dropoffs that occurred in that location. 

Plot the returned data using the longitude and latitude as x and y coordinates and determine the alpha (transparency) based on the counts (more pickups / dropoffs should be more opaque). The final goal is to produce 3 plots, a plot of all yellow and green cab pickups together (with points colored by cab type), a plot of all yellow and green cab dropoffs, and finally a plot of all uber pickups.

## Task 2 - Rush Hour Analysis
Here we will repeat the data analysis and plotting from Task 1 but we will add the additional factor of rush hour. Before aggregating, add a new column to each Spark Data Frame that indicates whether either the pickup or dropoff occured during the morning rush hours (7 - 10 am). 


