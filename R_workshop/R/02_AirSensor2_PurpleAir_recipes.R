# 02_AirSensor2_PurpleAir_recipes.R
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
  browseURL("https://github.com/MazamaScience/ASIC-2024/tree/main/R_workshop#spatial-data")
  stop("VERSION_ERROR:  Please upgrade to MazamaSpatialUtils 0.8.7 or later.")
}

# Check that the working directory is set properly
if ( !stringr::str_detect(getwd(), "R_workshop$") ) {
  stop("WD_ERROR:  Please set the working directory to 'R_workshop/'")
}

# Open reference docs in a web browser
browseURL("https://mazamascience.github.io/AirSensor2/reference/index.html")

library(AirMonitor)
library(AirSensor2)

# Set up spatial data from default directories
initializeMazamaSpatialUtils()

# ----- API Keys ---------------------------------------------------------------

library(dotenv)
dotenv::load_dot_env()

PURPLE_AIR_API_KEY <- Sys.getenv("PURPLE_AIR_API_KEY")

# Check the key
PurpleAir_checkAPIKey(PURPLE_AIR_API_KEY)

# ----- PurpleAir Synoptic (PAS) -----------------------------------------------

# We need to access and enhance sensor metadata before we download the
# timeseries data needed to make a 'monitor' object.

# Create a PAS object
pas <-
  pas_createNew(
    api_key = PURPLE_AIR_API_KEY,
    fields = PurpleAir_PAS_MINIMAL_FIELDS,
    countryCodes = "US",
    stateCodes = "WA",
    counties = c("Okanogan"),
    lookbackDays = 1,
    location_type = 0 # Outside
  )

if ( !exists("pas") ) load("data/pas.rda")

# It's a dataframe
class(pas)

# Metadata only field names
PurpleAir_PAS_MINIMAL_FIELDS  %>%
  stringr::str_split_1(",") %>%
  print(width = 75)

# New fields have been added
pas %>%
  names() %>%
  print(width = 75)

# Create an interactive map of sensor locations
pas_leaflet(pas)

# ----- PurpleAir Timeseries (PAT) ---------------------------------------------

# When things go well -----

LittleStartSchool_hourly <-
  pat_createHourly(
    pas = pas,
    sensor_index = "95189",        # MV Ambassador @ Little Start School
    startdate = "2026-01-01",
    enddate = "2026-01-08",
    api_key = PURPLE_AIR_API_KEY
  )

if ( !exists("LittleStartSchool_hourly") ) load("data/LittleStartSchool_hourly.rda")

# It's a list with two dataframes
class(LittleStartSchool_hourly)
names(LittleStartSchool_hourly)

# Metadata for a single sensor
dplyr::glimpse(LittleStartSchool_hourly$meta)

# Multi-parameter 'data' dataframe
head(LittleStartSchool_hourly$data)

# Multi-parameter plot for a quick visual QC
plot(LittleStartSchool_hourly$data)

# A/B channel comparisonplot
d <- LittleStartSchool_hourly$data
plot(d$datetime, d$pm2.5_atm, pch=1, cex=1.5, lwd=2, col=adjustcolor('black', 1.0))
points(d$datetime, d$pm2.5_atm_a, pch=15, col=adjustcolor('dodgerblue', 0.5))
points(d$datetime, d$pm2.5_atm_b, pch=15, col=adjustcolor('salmon', 0.5))

# Convert this PAT object into an AirMonitor "monitor" object using the EPA correction
LittleStartSchool <- pat_toMonitor(LittleStartSchool_hourly)

# Now a "mts_monitor" object
class(LittleStartSchool)

# A nice timeseries plot
LittleStartSchool %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE
  )

# See how much the data was corrected
points(d$datetime, d$pm2.5_atm, pch=1, cex=1.0, lwd=1.5, col=adjustcolor('black', 0.8))
legend("topright", legend=c("raw", "corrected"), pch=c(1, 15))


# High humidity -----

ConconullyStatePark_hourly <-
  pat_createHourly(
    api_key = PURPLE_AIR_API_KEY,
    pas = pas,
    sensor_index = "109354",        # Conconully State Park
    startdate = "2026-01-01",
    enddate = "2026-01-08"
  )

if ( !exists("ConconullyStatePark_hourly") ) load("data/ConconullyStatePark_hourly.rda")

# Multi-parameter plot for a quick visual QC
plot(ConconullyStatePark_hourly$data)

# A/B channel comparisonplot
d <- ConconullyStatePark_hourly$data
plot(d$datetime, d$pm2.5_atm, pch=1, cex=1.5, lwd=2, col=adjustcolor('black', 1.0))
points(d$datetime, d$pm2.5_atm_a, pch=15, col=adjustcolor('dodgerblue', 0.5))
points(d$datetime, d$pm2.5_atm_b, pch=15, col=adjustcolor('salmon', 0.5))

# Convert this PAT object into an AirMonitor "monitor" object using the EPA correction
ConconullyStatePark <- pat_toMonitor(ConconullyStatePark_hourly)

# A nice timeseries plot
ConconullyStatePark %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE
  )

# See how much the data was corrected
points(d$datetime, d$pm2.5_atm, pch=1, cex=1.0, lwd=1.5, col=adjustcolor('black', 0.8))
legend("topright", legend=c("raw", "corrected"), pch=c(1, 15))

# ----- Diurnal cycles ---------------------------------------------------------

# Oregon
Deschutes_pas <-
  pas_createNew(
    api_key = PURPLE_AIR_API_KEY,
    fields = PurpleAir_PAS_MINIMAL_FIELDS,
    countryCodes = "US",
    stateCodes = "OR",
    counties = c("Deschutes"),
    lookbackDays = 1,
    location_type = 0 # Outside
  )

if ( !exists("Deschutes_pas") ) load("data/Deschutes_pas.rda")

pas_leaflet(Deschutes_pas)

Deschutes_Public_Library_hourly <-
  pat_createHourly(
    api_key = PURPLE_AIR_API_KEY,
    pas = Deschutes_pas,
    sensor_index = "148777",
    startdate = "2026-04-25 00:00",
    enddate = "2026-04-30 06:00",
    timezone = "America/Los_Angeles"
  )

if ( !exists("Deschutes_Public_Library") ) load("data/Deschutes_Public_Library.rda")

Deschutes_Public_Library <- pat_toMonitor(Deschutes_Public_Library_hourly)

Deschutes_Public_Library %>%
  monitor_timeseriesPlot(shadedNight = TRUE, addAQI = TRUE)

# Using the AirMonitorPlots package

Deschutes_Public_Library %>%
  AirMonitorPlots::monitor_ggTimeseries()

Deschutes_Public_Library %>%
  AirMonitorPlots::monitor_ggDailyByHour()


