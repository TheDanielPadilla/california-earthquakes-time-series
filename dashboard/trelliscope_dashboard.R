library(dplyr)
library(fpp3)
library(ggplot2)
library(trelliscope)

cat("Loading combined tsibble data and fitting models...\n")
quakes_ts <- readRDS("california_earthquakes_master_ts.rds")

# Re-fit the simple models for the interactive dashboard
fit <- quakes_ts |>
  model(
    arima = ARIMA(count),
    ets = ETS(count) 
  )

cat("Generating forecasts...\n")
fc <- fit |> forecast(h = "12 months")

cat("Building Trelliscope Dashboard...\n")

# 1. Historical Data
hist_base <- quakes_ts |>
  filter(year(Month) >= 2018) |>
  as_tibble() |>
  select(Region, Month, count) |>
  mutate(type = "Historical")

# Duplicate historical data for each model so they overlay in the facet panels
hist_arima <- hist_base |> mutate(.model = "arima")
hist_ets <- hist_base |> mutate(.model = "ets")

# 2. Forecast Data
fc_df <- fc |>
  as_tibble() |>
  select(Region, .model, Month, .mean) |>
  rename(count = .mean) |>
  mutate(type = "Forecast")

# Extract the VERY LAST historical point to append to the start of Forecast 
# so the lines connect seamlessly without using group=1 hacks
last_hist_arima <- hist_arima |> group_by(Region) |> filter(Month == max(Month)) |> mutate(type = "Forecast")
last_hist_ets <- hist_ets |> group_by(Region) |> filter(Month == max(Month)) |> mutate(type = "Forecast")

# Combine for plotting
plot_df <- bind_rows(hist_arima, hist_ets, last_hist_arima, last_hist_ets, fc_df) |>
  mutate(
    Region = as.factor(Region),
    .model = as.factor(.model),
    Month = as.Date(Month),
    type = factor(type, levels = c("Historical", "Forecast"))
  )

# Build standard ggplot
p <- ggplot(plot_df, aes(x = Month, y = count, color = type)) +
  geom_line(aes(group = type), linewidth = 1) +
  facet_panels(vars(Region, .model)) +
  labs(
    y = "Earthquake Count (M>=3.0)",
    x = "Date",
    title = "Interactive 12-Month Earthquake Forecasts"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Historical" = "black", "Forecast" = "blue"))

cat("Writing trelliscope output...\n")
p |> 
  as_trelliscope_df(
    name = "earthquake_forecasts", 
    description = "Interactive Forecasts for California Hotspots",
    path = "trelliscope"
  ) |> 
  write_trelliscope()

cat("Trelliscope dashboard successfully built in the 'trelliscope' directory.\n")
