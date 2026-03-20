library(dplyr)
library(fpp3)
library(ggplot2)
library(trelliscope)
library(purrr)

cat("Loading combined tsibble data...\n")
quakes_ts <- readRDS("california_earthquakes_master_ts.rds")

# Prepare Directories
dirs <- c("trelliscope/forecast_plots", "trelliscope/stl_plots", 
          "trelliscope/ets_plots", "trelliscope/residual_plots")
walk(dirs, ~if(!dir.exists(.x)) dir.create(.x, recursive = TRUE))

regions <- unique(quakes_ts$Region)
models <- c("arima", "ets")

# 1. Fit Models & Components
cat("Fitting Models & Computing Components...\n")
fit <- quakes_ts |>
  model(
    arima = ARIMA(count),
    ets = ETS(count)
  )

fc <- fit |> forecast(h = "12 months")

dcmp_stl <- quakes_ts |>
  model(stl = STL(count ~ trend(window = 21) + season(window = "periodic"))) |>
  components()

dcmp_ets <- fit |> select(Region, ets) |> components()

# -------------------------------------------------------------------------
# 2. GENERATE PNG PANELS
# -------------------------------------------------------------------------

# A. Forecast Plots (Historical + Prediction)
cat("Saving Forecast plots...\n")
hist_base <- quakes_ts |> filter(year(Month) >= 2018) |> as_tibble()

forecast_data <- expand.grid(Region = regions, Model = models, stringsAsFactors = FALSE) |>
  as_tibble() |>
  mutate(
    filename = paste0("forecast_plots/", Region, "_", Model, ".png"),
    abspath = file.path("trelliscope", filename)
  )

for(i in 1:nrow(forecast_data)) {
  reg <- forecast_data$Region[i]
  mdl <- forecast_data$Model[i]
  
  # Historical segment
  h_seg <- hist_base |> filter(Region == reg) |> select(Month, count) |> mutate(type = "Actual")
  # Forecast segment
  f_seg <- fc |> 
    filter(Region == reg, .model == mdl) |> 
    as_tibble() |> 
    mutate(
      interval = hilo(count, 80),
      lower = interval$lower,
      upper = interval$upper
    ) |>
    select(Month, .mean, lower, upper) |> 
    rename(count = .mean) |> 
    mutate(type = "Forecast")
    
  # Connect last actual to first forecast for seamless ribbon/line
  bridge <- h_seg |> 
    filter(Month == max(Month)) |> 
    mutate(type = "Forecast", lower = count, upper = count)
  
  p_plot <- bind_rows(h_seg |> mutate(lower = count, upper = count), bridge, f_seg) |>
    mutate(Month = as.Date(Month)) |>
    ggplot(aes(Month, count, color = type, group = type)) +
    geom_ribbon(aes(ymin = lower, ymax = upper, fill = type), alpha = 0.2, color = NA) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = c("Actual" = "black", "Forecast" = "blue")) +
    scale_fill_manual(values = c("Actual" = "white", "Forecast" = "blue")) +
    theme_minimal() +
    labs(title = paste(reg, mdl, "Forecast with 80% Intervals"), y = "Earthquakes (M>=3.0)")
    
  ggsave(forecast_data$abspath[i], p_plot, width = 8, height = 5)
}

# B. STL Decomposition
cat("Saving STL plots...\n")
stl_data <- tibble(Region = regions) |>
  mutate(
    filename = paste0("stl_plots/", Region, ".png"),
    abspath = file.path("trelliscope", filename)
  )

for(i in 1:nrow(stl_data)) {
  reg <- stl_data$Region[i]
  p_stl <- dcmp_stl |> filter(Region == reg) |> autoplot() + labs(title = paste("STL:", reg)) + theme_minimal()
  ggsave(stl_data$abspath[i], p_stl, width = 8, height = 6)
}

# C. ETS Decomposition
cat("Saving ETS plots...\n")
ets_data <- tibble(Region = regions) |>
  mutate(
    filename = paste0("ets_plots/", Region, ".png"),
    abspath = file.path("trelliscope", filename)
  )

for(i in 1:nrow(ets_data)) {
  reg <- ets_data$Region[i]
  p_ets <- dcmp_ets |> filter(Region == reg) |> autoplot() + labs(title = paste("ETS Decomposition:", reg)) + theme_minimal()
  ggsave(ets_data$abspath[i], p_ets, width = 8, height = 6)
}

# D. Residuals
cat("Saving Residual plots...\n")
residual_data <- forecast_data |>
  mutate(
    filename = paste0("residual_plots/", Region, "_", Model, ".png"),
    abspath = file.path("trelliscope", filename)
  )

for(i in 1:nrow(residual_data)) {
  reg <- residual_data$Region[i]
  mdl <- residual_data$Model[i]
  sub_fit <- fit |> filter(Region == reg) |> select(all_of(mdl))
  p_res <- gg_tsresiduals(sub_fit) + labs(title = paste(reg, mdl, "Residuals"))
  ggsave(residual_data$abspath[i], p_res, width = 8, height = 6)
}

# -------------------------------------------------------------------------
# 3. WRITE TRELLISCOPE DISPLAYS
# -------------------------------------------------------------------------
cat("Writing Trelliscope displays...\n")

# 1. Forecasts
forecast_data |>
  mutate(panel = panel_local(abspath)) |>
  select(Region, Model, panel) |>
  as_trelliscope_df(name = "earthquake_forecasts", path = "trelliscope", description = "Historical data overlaid with ARIMA/ETS Forecasts") |>
  write_trelliscope()

# 2. STL
stl_data |>
  mutate(panel = panel_local(abspath)) |>
  select(Region, panel) |>
  as_trelliscope_df(name = "earthquake_stl", path = "trelliscope", description = "Regional STL decomposition (Trend, Seasonality)") |>
  write_trelliscope()

# 3. ETS
ets_data |>
  mutate(panel = panel_local(abspath)) |>
  select(Region, panel) |>
  as_trelliscope_df(name = "earthquake_ets", path = "trelliscope", description = "Regional ETS state-space decomposition (Error, Trend, Seasonality)") |>
  write_trelliscope()

# 4. Residuals
residual_data |>
  mutate(panel = panel_local(abspath)) |>
  select(Region, Model, panel) |>
  as_trelliscope_df(name = "earthquake_residuals", path = "trelliscope", description = "Diagnostic residual plots for statistical validation") |>
  write_trelliscope()

cat("Project finished! All 4 interactive dashboards are ready in 'trelliscope/index.html'.\n")
