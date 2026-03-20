library(dplyr)
library(fpp3)
library(ggplot2)

cat("Loading combined tsibble data...\n")
quakes_ts <- readRDS("california_earthquakes_master_ts.rds")

# 1. STL Decomposition
cat("Running STL Decomposition...\n")
dcmp <- quakes_ts |>
  model(stl = STL(count ~ trend(window = 21) + season(window = "periodic")))

p_stl <- components(dcmp) |>
  autoplot() +
  labs(
    title = "STL Decomposition of Earthquake Frequencies (M >= 3.0)",
    subtitle = "Comparing All California vs Hotspots (2014-2024)"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("stl_decomposition.png", p_stl, width = 10, height = 8, dpi = 300)

# 2. Autocorrelation (ACF) Plot
cat("Generating ACF Plots...\n")
# We will use gg_tsdisplay but we need to do it slightly differently to show it nicely
# To avoid multiple pages, we will just plot the ACF manually using ACF() and autoplot()
p_acf <- quakes_ts |>
  ACF(count, lag_max = 36) |>
  autoplot() +
  facet_wrap(~ Region, ncol = 1, scales = "free_y") +
  labs(
    title = "Autocorrelation Function (ACF) of Earthquake Counts",
    subtitle = "Significant spikes indicate clustering (e.g. Omori's Law of aftershocks)",
    y = "ACF"
  ) +
  theme_minimal()

ggsave("acf_plot.png", p_acf, width = 8, height = 8, dpi = 300)

cat("Successfully generated Time Domain plots: stl_decomposition.png, acf_plot.png\n")
