library(dplyr)
library(ggplot2)
library(tidyr)

cat("Loading combined tsibble data...\n")
quakes_ts <- readRDS("california_earthquakes_master_ts.rds")

# We need to extract the raw numeric series for the periodogram
all_ca <- quakes_ts |> filter(Region == "All California") |> pull(count)
ncal <- quakes_ts |> filter(Region == "Northern CA Hotspot") |> pull(count)
scal <- quakes_ts |> filter(Region == "Southern CA Hotspot") |> pull(count)

cat("Computing Smoothed Periodograms...\n")
# Calculate periodograms using base R, saving the output
# We use spans to smooth the periodogram to see general frequency peaks rather than noise
spec_all <- spec.pgram(all_ca, spans = c(3,3), plot = FALSE)
spec_ncal <- spec.pgram(ncal, spans = c(3,3), plot = FALSE)
spec_scal <- spec.pgram(scal, spans = c(3,3), plot = FALSE)

# Combine into a single dataframe for ggplot for easy comparison
spec_df <- data.frame(
  Frequency = c(spec_all$freq, spec_ncal$freq, spec_scal$freq),
  Spectrum = c(spec_all$spec, spec_ncal$spec, spec_scal$spec),
  Region = rep(
    c("All California", "Northern CA Hotspot", "Southern CA Hotspot"),
    c(length(spec_all$freq), length(spec_ncal$freq), length(spec_scal$freq))
  )
)

# Frequency is in cycles per observation (month). 
# A frequency of 1/12 = 0.0833 means one cycle per 12 months (annual cycle).

p_spec <- ggplot(spec_df, aes(x = Frequency, y = Spectrum, color = Region)) +
  geom_line(size = 0.8) +
  facet_wrap(~ Region, ncol = 1, scales = "free_y") +
  # Use log scale for Y axis which is standard for periodograms
  scale_y_continuous(trans = "log10") + 
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Smoothed Periodogram of Earthquake Frequencies",
    subtitle = "Analysis in the Spectral Domain to find hidden periodicities",
    x = "Frequency (cycles per month)",
    y = "Log Spectral Density"
  ) +
  # Add a vertical dashed line to mark the annual 12-month period (freq = 1/12)
  geom_vline(xintercept = 1/12, linetype = "dashed", color = "gray50") +
  # Add text annotation
  annotate("text", x = 1/12 + 0.02, y = max(spec_df$Spectrum), label = "Annual (12m)", size = 3, color = "gray50")

ggsave("spectral_density.png", p_spec, width = 8, height = 8, dpi = 300)

cat("Successfully generated Spectral Domain plot: spectral_density.png\n")
