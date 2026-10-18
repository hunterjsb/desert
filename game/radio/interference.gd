class_name Interference
extends RefCounted
## What the weather between a radio and a god does to the signal. The sand a
## storm lifts charges up and smears the band: the more storm there is along
## the way toward the god, the more of what it says is lost (distortion), the
## further its carrier slides off where you tuned it (warping), and the more
## often it drops out altogether (cutting). Deterministic in time, so the same
## storm garbles the same way.

## Glyphs a lost character comes through as.
const NOISE := "#%*~/\\:;=+"
## The distortion and the cuts change this often, s.
const SLICE := 0.6


## How much storm lies along the way from a place toward a god, 0 to 1: the
## storm field read at points along the ground bearing (degrees from -z), out
## to the god or interference_reach_m, whichever is nearer.
static func along(field: WeatherField, x: float, z: float, bearing: float, metres: float, t: float,
		tuning: Tuning) -> float:
	var reach := minf(metres, tuning.interference_reach_m)
	var n := maxi(tuning.interference_samples, 1)
	var dir := Vector2(sin(deg_to_rad(bearing)), -cos(deg_to_rad(bearing)))
	var total := 0.0
	for i in n:
		var at := Vector2(x, z) + dir * reach * (i + 0.5) / n
		total += field.storm_at(at.x, at.y, t)
	return clampf(total / n, 0.0, 1.0)


## How far the storm has slid a carrier off at world time t, kHz: a slow
## wander either way, as wide as the storm is thick.
static func warp(storm: float, t: float, id: StringName, tuning: Tuning) -> float:
	var h := float(hash(id) % 1000) * 0.01
	return tuning.storm_warp_khz * storm * (sin(t * 0.37 + h) + 0.5 * sin(t * 1.13 + 2.0 * h)) / 1.5


## Whether the signal has dropped out at world time t.
static func cut(storm: float, t: float, id: StringName, tuning: Tuning) -> bool:
	if storm <= 0.0:
		return false
	return _chance([id, floori(t / SLICE), "cut"]) < storm * tuning.storm_cuts


## A line as it comes through at `clean` (1 whole, 0 nothing): each character
## lost to noise with the rest's chance, spaces kept so its shape still shows.
static func distort(line: String, clean: float, t: float, id: StringName) -> String:
	var lost := clampf(1.0 - clean, 0.0, 1.0)
	if lost <= 0.0:
		return line
	var out := ""
	var slice := floori(t / SLICE)
	for i in line.length():
		var c := line[i]
		if c != " " and _chance([id, slice, i]) < lost:
			c = NOISE[hash([id, slice, i, "glyph"]) % NOISE.length()]
		out += c
	return out


static func _chance(key: Array) -> float:
	return float(hash(key) & 0xffffff) / float(0x1000000)
