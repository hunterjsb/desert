class_name Exposure
extends RefCounted
## Whether a site is buried, partly exposed or exposed: decided purely from
## the storm history at its place up to the moment its ground is built,
## against how deep its era lies. Read on fixed ticks of world time, so ground
## built any time within one tick is the same however you came to it.

enum { BURIED, PARTLY, EXPOSED }
const NAMES: Array[String] = ["buried", "partly exposed", "exposed"]


## How hard the weather is at a place and moment, 0 to 1: how deep into a
## storm, or how far the wind blows past the prevailing wind's strongest,
## whichever is harder. Finds read it too.
static func reading(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var storm := clampf(field.raw_storm_at(x, z, t) / tuning.exposure_storm_full, 0.0, 1.0)
	var gale := clampf((field.wind_at(x, z, t).length() - tuning.exposure_calm_wind)
		/ (tuning.exposure_gale_wind - tuning.exposure_calm_wind), 0.0, 1.0)
	return maxf(storm, gale)


## The sand the weather has taken off a place, m. Each tick of the window a
## storm strips by how hard it blew and the wind lays some back, and the older
## the tick the more has drifted back since, so one big storm strips a lot,
## calm lets the sand return, and nothing is a hard timer.
static func stripped(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var step := tuning.site_exposure_step_minutes * 60.0
	var count := maxi(1, roundi(tuning.site_exposure_hours * 60.0 / tuning.site_exposure_step_minutes))
	var last := floorf(t / step) * step
	var sum := 0.0
	for k in count:
		var work := tuning.site_strip_m * reading(field, x, z, last - k * step, tuning) - tuning.site_return_m
		sum += work * (1.0 - float(k) / count)
	return maxf(sum, 0.0)


## A site's state, from the sand taken off it against how deep it lies: under
## a third of its depth stripped, buried; under all of it, partly exposed.
static func state(depth: float, taken: float) -> int:
	if taken >= depth:
		return EXPOSED
	return PARTLY if taken >= depth / 3.0 else BURIED
