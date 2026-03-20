# California Earthquakes Time Series

A graduate level time series project analyzing earthquake activity in California from 2014 to 2024 using spatial visualization, time-domain analysis, spectral methods, forecasting, and a Trelliscope dashboard.

## Overview

This project examines patterns in California earthquake activity using monthly counts of earthquakes with magnitude 3.0 or greater. Using data from the U.S. Geological Survey (USGS) Earthquake Catalog API, I combined spatial exploration with time series methods to study localized seismic hotspots, evaluate temporal dependence, and generate baseline forecasts for future earthquake counts.

In addition to the written report, the project includes modular R scripts and Trelliscope dashboard components for interactive exploration.

## Research Questions

- Where are the main earthquake hotspots in California?
- Do monthly earthquake counts show meaningful seasonality?
- Is earthquake activity better explained by short-term clustering and temporal dependence?
- What do 12-month forecasts suggest for California and selected hotspot regions?

## Data

- **Source:** USGS Earthquake Catalog API
- **Location:** California
- **Time period:** 2014–2024
- **Filter:** Earthquakes with magnitude 3.0 or greater
- **Response variable:** Monthly earthquake counts

Two hotspot regions were identified through kernel density estimation:
- Mendocino Triple Junction (Northern California)
- Salton Sea / Brawley Seismic Zone (Southern California)

## Methods

### Spatial analysis
- Earthquake mapping
- Kernel density estimation (KDE) to identify hotspots

### Time-domain analysis
- STL decomposition
- Autocorrelation function (ACF) analysis

### Spectral analysis
- Smoothed periodograms to evaluate possible periodic behavior

### Forecasting
- ARIMA models
- ETS / state-space forecasting models

### Dashboard
- Trelliscope dashboard scripts for interactive exploration of earthquake patterns

## Key Findings

- Earthquake activity is spatially concentrated in a small number of California hotspot regions.
- STL decomposition suggests weak seasonality relative to the overall variability in counts.
- ACF analysis shows positive short-lag autocorrelation, consistent with clustering behavior.
- Spectral analysis provides little evidence of strong annual seasonality.
- ARIMA and ETS forecasts suggest mean-reverting behavior in earthquake counts after periods of elevated activity.
- Forecast uncertainty is wider for the northern hotspot than for the southern hotspot.

## Repository Structure

- `report/` – final report and source document
- `code/` – modular R scripts for data collection, mapping, analysis, and forecasting
- `dashboard/` – Trelliscope dashboard scripts
- `figures/` – plots and visual outputs
- `data/processed/` – processed R data files
- `model_output/` – model evaluation output

## Main Scripts

- `download_data.R` – downloads and prepares earthquake data
- `generate_maps.R` – creates maps and heatmaps
- `analyze_hotspots.R` – identifies and studies hotspot regions
- `time_domain_analysis.R` – STL decomposition and ACF analysis
- `spectral_analysis.R` – periodogram-based spectral analysis
- `modeling_and_forecasting.R` – ARIMA/ETS modeling and forecasting

## Tools

This project was completed in **R** using packages for:
- data access
- spatial analysis
- visualization
- time series modeling
- dashboard development

## Files to Start With

For a quick overview of the project, start with:
1. `report/earthquake_report.pdf`
2. `README.md`
3. the figures in `figures/`
4. `code/README.md` for script order

## Author
Daniel Padilla
