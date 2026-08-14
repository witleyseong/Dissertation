//used by crime-exposure calculation exposureSercice.js, journeyService.js


// radius of 50 meters 
const WALK_BUFFER_METERS = 50;

// category filter
// filters the crimes that is relevant for the user
const WALKING_RELEVANT_CATEGORIES = Object.freeze([
    "Violence and sexual offences",
    "Robbery",
    "Theft from the person",
    "Public order",
    "Anti-social behaviour",
    "Possession of weapons",
])

// it takes the dates from the start to end
const CRIME_DATA_EARLIEST_MONTH = "2023-06"
const CRIME_DATA_LATEST_MONTH = "2026-05"

//Prevents very short walking legs from inflating crime density by using
// the buffer radius as the minimum distance for exposure-per-km calculations.
const MIN_DENOMINATOR_KM = WALK_BUFFER_METERS / 1000;

// crimes per km inside the buffer of walk
const EXPOSURE_LOWER_MAX_PER_KM = 250;
const EXPOSURE_MODERATE_MAX_PER_KM = 950;

// Calculates the safety score from crime density (crimes/km) rather than
// total crime count, keeping the score consistent with the exposure levels.
// A score of 100 means no exposure, while the lower/moderate boundary scores 50.
const EXPOSURE_SCORE_HALF_LIFE_PER_KM = EXPOSURE_LOWER_MAX_PER_KM;


// The app measures historical recorded-crime exposure.
const RISK_TO_EXPOSURE_LEVEL = Object.freeze({
    safe:"lower",
    low:"lower",
    moderate:"moderate",
    high:"higher"
})

module.exports = {
  WALK_BUFFER_METERS,
  WALKING_RELEVANT_CATEGORIES,
  CRIME_DATA_EARLIEST_MONTH,
  CRIME_DATA_LATEST_MONTH,
  MIN_DENOMINATOR_KM,
  EXPOSURE_LOWER_MAX_PER_KM,
  EXPOSURE_MODERATE_MAX_PER_KM,
  EXPOSURE_SCORE_HALF_LIFE_PER_KM,
  RISK_TO_EXPOSURE_LEVEL,
};