library(httr2)
library(jsonlite)
library(dplyr)
library(lubridate)
library(sf)
library(fpp3)

# Define bounding box for California
# min longitude, min latitude, max longitude, max latitude
bbox <- "-124.4,32.5,-114.1,42.0"

# Set up the USGS API URL
base_url <- "https://earthquake.usgs.gov/fdsnws/event/1/query"

# We'll fetch data from 1980 to present, M>=3.0
# The API has a limit of 20,000 events per request, so we might need to chunk it
# For simplicity in this demo, let's just pull the last 10 years (2014-2024)
# If it hits the limit, we'll refine the query.

start_date <- "2014-01-01"
end_date <- "2024-01-01"
min_mag <- 3.0

request <- request(base_url) |>
  req_url_query(
    format = "geojson",
    starttime = start_date,
    endtime = end_date,
    minmagnitude = min_mag,
    minlongitude = -124.4,
    maxlongitude = -114.1,
    minlatitude = 32.5,
    maxlatitude = 42.0
  )

cat("Fetching data from USGS...\n")
response <- req_perform(request)

if (resp_status(response) == 200) {
  cat("Data successfully downloaded. Processing...\n")
  
  # Parse the GeoJSON response
  geojson_data <- resp_body_string(response)
  
  # Read into an sf object
  # sf can natively read geojson strings
  quakes_sf <- st_read(geojson_data, quiet = TRUE)
  
  # Extract coordinates and properties
  quakes_df <- quakes_sf |>
    mutate(
      lon = st_coordinates(geometry)[,1],
      lat = st_coordinates(geometry)[,2],
      # time is in milliseconds since epoch
      time = as_datetime(time / 1000)
    ) |>
    as_tibble() |>
    select(id, time, mag, place, lon, lat)
  
  # Create a monthly tsibble
  quakes_ts <- quakes_df |>
    mutate(Month = yearmonth(time)) |>
    group_by(Month) |>
    summarise(
      count = n(),
      max_mag = max(mag, na.rm = TRUE),
      mean_mag = mean(mag, na.rm = TRUE)
    ) |>
    as_tsibble(index = Month)
  
  # Save the raw sf object and the aggregated tsibble
  saveRDS(quakes_sf, "california_earthquakes_raw.rds")
  saveRDS(quakes_ts, "california_earthquakes_ts.rds")
  
  cat("Data saved to california_earthquakes_raw.rds and california_earthquakes_ts.rds\n")
  cat("Successfully fetched", nrow(quakes_df), "earthquakes.\n")
  
} else {
  cat("Failed to fetch data. Status code:", resp_status(response), "\n")
}
