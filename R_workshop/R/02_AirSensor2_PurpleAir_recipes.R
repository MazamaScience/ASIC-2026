# AirSensor2

###pak::pak("mazamascience/AirSensor2")

# ----- Working with PurpleAir data --------------------------------------------

library(dotenv)
dotenv::load_dot_env()

library(AirSensor2)
initializeMazamaSpatialUtils()

pas <-
  pas_createNew(
    api_key = Sys.getenv("PURPLE_AIR_API_KEY"),
    countryCodes = "US",
    stateCodes = "WA",
    counties = c("Okanogan"),
    lookbackDays = 0, # all historical sensors
    location_type = 0
  )

pas_leaflet(pas)


pat_hourly <-
  pat_createHourly(
    api_key = Sys.getenv("PURPLE_AIR_API_KEY"),
    pas = pas,
    sensor_index = "109354",
    startdate = "2026-01-01",
    enddate = "2026-01-08",
    timezone = "UTC",
    verbose = TRUE
  )

monitor <- pat_toMonitor(pat_hourly)


# ------------------------------------------------------------------------------



