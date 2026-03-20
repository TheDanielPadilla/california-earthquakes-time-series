library(dplyr)
library(fpp3)
library(ggplot2)

cat("Loading combined tsibble data...\n")
quakes_ts <- readRDS("california_earthquakes_master_ts.rds")

# Phase 4: Modeling & Forecasting
cat("Fitting ARIMA and State-Space (ETS) Models...\n")

# ETS represents Error, Trend, Seasonality, equivalent to State-Space Models in fpp3
fit <- quakes_ts |>
  model(
    arima = ARIMA(count),
    ets = ETS(count) # State-space model
  )

cat("Model evaluation metrics...\n")
# Evaluate model performance (AICc usually)
metrics <- glance(fit) |> arrange(Region, AICc)
print(metrics)

# Save the metrics to a CSV for easy inclusion in a report if desired
# We must drop list columns (like ar_roots, ma_roots) to save as CSV
metrics_clean <- metrics |> select(-where(is.list))
write.csv(metrics_clean, "model_metrics.csv", row.names = FALSE)

cat("Generating 12-month forecasts...\n")
# Forecast
fc <- fit |> forecast(h = "12 months")

# Plot forecasts
p_fc <- fc |>
  autoplot(quakes_ts |> filter(year(Month) >= 2020), level = NULL) +
  facet_wrap(~ Region, ncol = 1, scales = "free_y") +
  labs(
    title = "12-Month Earthquake Forecasts (M >= 3.0)",
    subtitle = "Comparing ARIMA and ETS (State-Space) Models",
    y = "Count"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("forecasts_plot.png", p_fc, width = 10, height = 8, dpi = 300)

# We can also plot prediction intervals for the best model (let's say ARIMA)
p_best_fc <- fc |>
  filter(.model == "arima") |>
  autoplot(quakes_ts |> filter(year(Month) >= 2020), level = 80) +
  facet_wrap(~ Region, ncol = 1, scales = "free_y") +
  labs(
    title = "12-Month Earthquake Forecasts (M >= 3.0)",
    subtitle = "ARIMA Model with 80% Prediction Intervals",
    y = "Count"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("arima_forecasts_with_intervals.png", p_best_fc, width = 10, height = 8, dpi = 300)

cat("Successfully generated forecasts and plots: forecasts_plot.png, arima_forecasts_with_intervals.png\n")
