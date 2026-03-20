library(dplyr)
library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)

cat("Loading earthquake data...\n")
quakes_sf <- readRDS("california_earthquakes_raw.rds")

cat("Fetching map data for California...\n")
states <- ne_states(country = "united states of america", returnclass = "sf")
california <- states |> filter(name == "California")

cat("Generating Basic Point Map...\n")
p1 <- ggplot() +
  geom_sf(data = california, fill = "gray95", color = "gray50") +
  geom_sf(data = quakes_sf, aes(color = mag), size = 0.5, alpha = 0.4) +
  scale_color_viridis_c(name = "Magnitude") +
  theme_minimal() +
  labs(
    title = "Earthquakes in California (2014-2024)",
    subtitle = "Magnitude 3.0 and above",
    caption = "Data: USGS Earthquake Catalog"
  )

ggsave("california_earthquakes_map.png", p1, width = 8, height = 8, dpi = 300)

cat("Generating Kernel Density Heatmap...\n")
# Extract coordinates for stat_density_2d which needs a dataframe
quakes_coords <- quakes_sf |>
  mutate(
    lon = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2]
  ) |>
  st_drop_geometry()

p2 <- ggplot() +
  geom_sf(data = california, fill = "gray90", color = "gray50") +
  stat_density_2d(
    data = quakes_coords,
    aes(x = lon, y = lat, fill = after_stat(level)),
    geom = "polygon",
    alpha = 0.5,
    bins = 15
  ) +
  scale_fill_viridis_c(option = "inferno", name = "Density") +
  theme_minimal() +
  labs(
    title = "Earthquake Density Heatmap",
    subtitle = "Identifying Seismic Hotspots in California",
    x = "Longitude",
    y = "Latitude"
  )

ggsave("california_earthquake_heatmap.png", p2, width = 8, height = 8, dpi = 300)

cat("Maps saved: california_earthquakes_map.png, california_earthquake_heatmap.png\n")
