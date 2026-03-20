library(dplyr)
library(sf)
library(lubridate)
library(fpp3)

cat("Loading raw earthquake data...\n")
quakes_sf <- readRDS("california_earthquakes_raw.rds")

# Extract coordinates so we can filter by bounding box easily
quakes_df <- quakes_sf |>
  mutate(
    lon = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2],
    time = as_datetime(time / 1000)
  ) |>
  st_drop_geometry() |>
  as_tibble()

# Bounding boxes based on heatmap
# Northern CA (Mendocino Triple Junction)
# lon: ~[-125.5, -123], lat: ~[39.5, 41.5]
ncal_quakes <- quakes_df |>
  filter(lon >= -125.5, lon <= -123.0, lat >= 39.5, lat <= 41.5) |>
  mutate(Region = "Northern CA Hotspot")

# Southern CA (Salton Sea area)
# lon: ~[-116.5, -115], lat: ~[32.5, 33.5]
scal_quakes <- quakes_df |>
  filter(lon >= -116.5, lon <= -115.0, lat >= 32.5, lat <= 33.5) |>
  mutate(Region = "Southern CA Hotspot")

# All CA
all_quakes <- quakes_df |>
  mutate(Region = "All California")

# Combine datasets
combined_quakes <- bind_rows(all_quakes, ncal_quakes, scal_quakes)

# Create the master faceted tsibble
cat("Aggregating into monthly time series...\n")
quakes_master_ts <- combined_quakes |>
  mutate(Month = yearmonth(time)) |>
  group_by(Region, Month) |>
  summarise(
    count = n(),
    max_mag = max(mag, na.rm = TRUE),
    mean_mag = mean(mag, na.rm = TRUE),
    .groups = "drop"
  ) |>
  # It's possible some months had NO earthquakes >= 3.0 in a specific hotspot
  # We need to fill those with 0 so the time series is continuous
  as_tsibble(key = Region, index = Month) |>
  fill_gaps(count = 0)

saveRDS(quakes_master_ts, "california_earthquakes_master_ts.rds")
cat("Saved combined regional time series to california_earthquakes_master_ts.rds\n")

# Print summary to verify
print(quakes_master_ts |> features(count, features = c(n_obs = length)))
