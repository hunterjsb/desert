class_name Natural
extends RefCounted
## Natural radio: the bottom of the AM dial, under 30 kHz, very low
## frequencies, where nothing is sent at all and a long wire hears the moon's
## own. Every discharge of the sand charging up in a storm is a click, a
## sferic, heard tens of kilometres off, the faster the more storm there is and
## the nearer, so you hear a storm coming long before it shows. Now and then a
## discharge's crackle is caught in the field lines of Tu's magnetosphere and
## comes back drawn out, a whistler, a long falling tone, more often by night,
## as on Earth. A ferrite rod hears none of it; a long wire does. A camp's own
## power hums over it, so you walk out away from your gear to listen, as real
## listeners do. Pure in the seed, the weather and world time.

## Natural radio fills the dial up to the bottom of this span, kHz, and is
## gone at its top.
const BAND := Vector2(20.0, 30.0)
## The storm field is read along eight ways out from the radio, at these
## distances, m: the nearer, the more a storm there counts.
const RINGS: Array[float] = [1000.0, 3000.0, 6000.0, 12000.0, 20000.0, 30000.0]
## A whistler falls over this long, s.
const WHISTLE := 2.2


## How much of natural radio a frequency, kHz, is in, 0 to 1.
static func share(khz: float) -> float:
	return 1.0 - smoothstep(BAND.x, BAND.y, khz)


## How much storm is about for its sferics, 0 to 1: the worst storm along
## eight ways out, each counting less the farther off it is, out to vlf_reach_m.
static func storms(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var worst := field.storm_at(x, z, t)
	for i in 8:
		var way := Vector2.from_angle(TAU * i / 8.0)
		for d: float in RINGS:
			if d > tuning.vlf_reach_m:
				break
			worst = maxf(worst, field.storm_at(x + way.x * d, z + way.y * d, t) * (1.0 - d / tuning.vlf_reach_m))
	return clampf(worst, 0.0, 1.0)


## How many sferics a second, with this much storm about: a slow tick of far
## storms always, a crackle with one near.
static func rate(storms_about: float, tuning: Tuning) -> float:
	return lerpf(tuning.vlf_rate.x, tuning.vlf_rate.y, storms_about * storms_about)


## Where a whistler is in its fall at world time t, 0 just begun to 1 done,
## or -1 with none: each vlf_whistler_every s may bring one, the likelier the
## more storm about to set it off, and likelier by night.
static func whistler(run_seed: int, t: float, storms_about: float, night: bool, tuning: Tuning) -> float:
	var every := tuning.vlf_whistler_every
	var slot := floori(t / every)
	var chance := storms_about * (1.0 if night else 0.35)
	var roll := float(hash([run_seed, "whistler", slot]) & 0xffff) / 65535.0
	if roll >= chance:
		return -1.0
	var start := slot * every + (float(hash([run_seed, "whistler at", slot]) & 0xffff) / 65535.0) * (every - WHISTLE)
	var into := (t - start) / WHISTLE
	return into if into >= 0.0 and into < 1.0 else -1.0
