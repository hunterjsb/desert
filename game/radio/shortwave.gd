class_name Shortwave
extends RefCounted
## The shortwave band: 2 to 30 MHz, through a shortwave converter, the dial
## going on in kHz past the AM dial's top. It's above the ceiling the air
## puts over the AM dial, so what's sent from orbit gets down through it: the
## constellation is heard here, and only here (gonkhub's satellites, moved up
## through the ceiling). So is Tu. A giant planet roars on these frequencies,
## as Jupiter does at 10 to 40 MHz, and as Io gates Jupiter's loudest storms, Zan
## gates Tu's: the roar comes when Zan is at the right places round its orbit
## and Tu's own turn brings its source round, so it has a timetable you can
## learn. It's heard wherever Tu is in the sky, the stronger the higher, and
## never on the far side, which Zan's own bulk shields. Pure in world time.

const LOWEST := 2000.0
const HIGHEST := 30000.0


## Where a frequency, kHz, sits across the band, 0 at its bottom to 1 at its top.
static func share(khz: float) -> float:
	return clampf(inverse_lerp(LOWEST, HIGHEST, khz), 0.0, 1.0)


## How loud Tu's roar comes in at point p on the sphere, tuned to `khz`, at
## world time t, 0 to 1: Tu over the horizon (`tu`, the way to Tu from Zan's
## middle), the higher the stronger; the dial up where Tu sends, from
## tu_roar_khz's bottom to full at its top; and a storm on Tu, which comes only
## inside a window of Zan's orbit (tu_roar_phases, shares of a day, each
## tu_roar_window wide) while Tu's turn brings its source to face Zan (its turn
## within tu_roar_turn of facing, rad). In a storm it comes in slow swells, as
## Jupiter's long bursts do.
static func roar(p: Vector3, tu: Vector3, khz: float, t: float, tu_turn: float, tuning: Tuning) -> float:
	var up := smoothstep(0.0, 0.5, p.dot(tu))
	var dial := smoothstep(tuning.tu_roar_khz.x, tuning.tu_roar_khz.y, khz)
	if up <= 0.0 or dial <= 0.0:
		return 0.0
	return up * dial * storm(t, tu_turn, tuning) * swell(t)


## Whether Tu is storming on these frequencies at world time t, 0 to 1:
## inside one of Zan's orbital windows, and Tu turned to face its source.
static func storm(t: float, tu_turn: float, tuning: Tuning) -> float:
	var phase := fposmod(t / (tuning.day_minutes * 60.0), 1.0)
	var orbit := 0.0
	for at: float in tuning.tu_roar_phases:
		var off := absf(angle_difference(TAU * phase, TAU * at)) / TAU
		orbit = maxf(orbit, 1.0 - smoothstep(tuning.tu_roar_window * 0.35, tuning.tu_roar_window * 0.5, off))
	var facing := 1.0 - smoothstep(tuning.tu_roar_turn * 0.6, tuning.tu_roar_turn, absf(angle_difference(tu_turn, 0.0)))
	return orbit * facing


## A storm's slow swells, 0.2 to 1: a long burst every second or two.
static func swell(t: float) -> float:
	return 0.2 + 0.8 * pow(0.5 + 0.5 * sin(TAU * t / 1.7 + 0.8 * sin(t * 0.37)), 2.0)
