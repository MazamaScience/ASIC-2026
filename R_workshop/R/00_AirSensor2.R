# Cole Brokamp's R package

###pak::pak("mazamascience/AirSensor2")

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

