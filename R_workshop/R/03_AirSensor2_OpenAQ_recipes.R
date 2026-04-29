# 03_AirSensor2_OpenAQ_recipes.R
#
# This script contains small chunks of R code (aka "recipes") that demonstrate
# how to work with the AirSensor2 package to access, manipulate and display
# sensor data available through the PurpleAir API.
#
# This script assumes that you have already installed the following packages:
#  - AirMonitor
#  - AirSensor2

# Check that the AirMonitor package is recent enough
if ( packageVersion("AirMonitor") < "0.4.5" ) {
  stop("VERSION_ERROR:  Please upgrade to AirMonitor 0.4.5 or later.")
}

# Check that the Sensor2 package is recent enough
if ( packageVersion("AirSensor2") < "0.6.0" ) {
  stop("VERSION_ERROR:  Please upgrade to AirSensor2 0.6.0 or later.")
}

# Check that the MazamaSpatialUtils package is recent enough
if ( packageVersion("MazamaSpatialUtils") < "0.8.7" ) {
  browseURL("https://github.com/MazamaScience/ASIC-2026/tree/main/R_workshop#spatial-data")
  stop("VERSION_ERROR:  Please upgrade to MazamaSpatialUtils 0.8.7 or later.")
}

# Check that the working directory is set properly
if ( !stringr::str_detect(getwd(), "R_workshop$") ) {
  stop("WD_ERROR:  Please set the working directory to 'R_workshop/'")
}


library(AirMonitor)
library(AirSensor2)

# Set up spatial data from default directories
initializeMazamaSpatialUtils()

# ----- API Keys ---------------------------------------------------------------

library(dotenv)
dotenv::load_dot_env()

OPENAQ_API_KEY <- Sys.getenv("OPENAQ_API_KEY")

# Set the key once
openaq::set_api_key(OPENAQ_API_KEY)

# ----- "Locations" dataframe --------------------------------------------------

locations <-
  OpenAQ_createLocations(
    countryCodes = "US",
    stateCodes = "IL",
    counties = "Cook",
    api_key = OPENAQ_API_KEY # Not needed if we openaq::set_api_key()
  )

# It's a dataframe
class(locations)

# Mix of fields from MazamaLocationUtils and OpenAQ
locations %>%
  names() %>%
  print(width = 75)

# Lets explore different OpenAQ "providers"
table(locations$provider_name)

# Per-provider subsets
clarity <- locations %>% dplyr::filter(provider_name == "Clarity")
airnow <- locations %>% dplyr::filter(provider_name == "AirNow")
airgradient <- locations %>% dplyr::filter(provider_name == "AirGradient")

# Use MazamaLocationUtils to create a fancy leaflet map
map <-
  MazamaLocationUtils::table_leaflet(
    clarity,
    extraVars = c("id", "locationName", "start", "end", "owner_name", "provider_name"),
    radius = 5, fillColor = "blue"
  )

map <- MazamaLocationUtils::table_leafletAdd(
  map,
  airnow,
  extraVars = c("id", "locationName", "start", "end", "owner_name", "provider_name"),
  radius = 10, fillColor = "black"
)

map <- MazamaLocationUtils::table_leafletAdd(
  map,
  airgradient,
  extraVars = c("id", "locationName", "start", "end", "owner_name", "provider_name"),
  radius = 5, fillColor = "red"
)

print(map)

# ----- Sensor "lifespans" -----------------------------------------------------

# Plot all lifespans
locations %>%
  OpenAQ_lifespanPlot()

# Label AirGradient locations
airgradient %>%
  OpenAQ_lifespanPlot(
    showLocation = TRUE,
    main = "AirGradient Sensors in Chicago",
    cex = 0.6,
    lwd = 2,
    moreSpace = 0.3
  )

# Label AirGradient locations
airgradient %>%
  OpenAQ_lifespanPlot(
    showLocation = TRUE,
    locationIdentifier = "id",
    main = "AirGradient Sensor IDs in Chicago (by id)",
    cex = 0.6,
    lwd = 2,
    moreSpace = 0.3
  )

# ----- Hourly time series data ------------------------------------------------

# AirGradient provides multi-parameter raw data

airgradient_raw <-
  OpenAQ_downloadRawData(
    locations_id = 1370216,
    parameters = c("pm25", "temperature", "relativehumidity"),
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    api_key = OPENAQ_API_KEY
  )

# It's a dataframe
class(airgradient_raw)

head(airgradient_raw)

airgradient_raw %>% plot()

# Clarity provides already-corrected PM2.5

clarity_raw <-
  OpenAQ_downloadRawData(
    locations_id = 6207297,
    parameters = c("pm25", "temperature", "relativehumidity"),
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    api_key = OPENAQ_API_KEY
  )

head(clarity_raw)

# AirNow provides already-corrected PM2.5

airnow_raw <-
  OpenAQ_downloadRawData(
    locations_id = 3301366,
    parameters = c("pm25", "temperature", "relativehumidity"),
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    api_key = OPENAQ_API_KEY
  )

head(airnow_raw)

# ----- Creating 'monitor' objects ---------------------------------------------

# AirNow
airnow_monitor <-
  OpenAQ_createMonitor(
    locations = locations,
    locations_id = 3301366,
    parameter = "pm25",
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    timezone = "America/Chicago",
    api_key = OPENAQ_API_KEY
  )

names(airnow_monitor)

airnow_monitor %>%
  monitor_getData() %>%
  head()

# Or, more directly
head(airnow_monitor$data)

airnow_monitor %>%
  AirMonitor::monitor_timeseriesPlot(shadedNight = TRUE, addAQI = TRUE)

# Clarity
clarity_monitor <-
  OpenAQ_createMonitor(
    locations = locations,
    locations_id = 6207297,
    parameter = "pm25",
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    timezone = "America/Chicago",
    api_key = OPENAQ_API_KEY
  )

clarity_monitor %>%
  monitor_getData() %>%
  head()

# AirGradient
airgradient_monitor <-
  OpenAQ_createMonitor(
    locations = locations,
    locations_id = 1370216,
    parameter = "pm25",
    startdate = "2026-04-01",
    enddate = "2026-04-15",
    timezone = "America/Chicago",
    api_key = OPENAQ_API_KEY
  )

airgradient_monitor %>%
  AirMonitor::monitor_timeseriesPlot(shadedNight = TRUE, addAQI = TRUE)

Chicago <-
  monitor_combine(
    airgradient_monitor,
    airnow_monitor,
    clarity_monitor
  )


Chicago %>%
  AirMonitor::monitor_timeseriesPlot(shadedNight = TRUE, addAQI = TRUE)

# Fancy plots with the AirMonitorPlots package
Chicago %>%
  AirMonitorPlots::monitor_ggDailyHourlyBarplot()


