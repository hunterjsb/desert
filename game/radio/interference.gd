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
## An anomaly's crackle bursts this often, s, sounding this share of them.
const CRACKLE := 0.07
const CRACKLE_ON := 0.45


## How much storm stands in the way from a place toward a god, 0 to 1: the
## worst of the storm field along the ground bearing (degrees from -z), read
## from interference_near_m out to the god or interference_reach_m, whichever
## is nearer, closest together near you. The worst, not the mean: a storm
## wall anywhere on the way blocks it, so a storm close on your east cuts off
## everything east of you and nothing west, and what's lost says what lies
## which way.
static func along(field: WeatherField, x: float, z: float, bearing: float, metres: float, t: float,
		tuning: Tuning) -> float:
	var reach := minf(metres, tuning.interference_reach_m)
	var near := minf(tuning.interference_near_m, reach)
	var n := maxi(tuning.interference_samples, 2)
	var dir := Vector2(sin(deg_to_rad(bearing)), -cos(deg_to_rad(bearing)))
	var worst := 0.0
	for i in n:
		var d := near * pow(reach / maxf(near, 1.0), float(i) / (n - 1)) if near > 0.0 else reach * i / (n - 1)
		var at := Vector2(x, z) + dir * d
		worst = maxf(worst, field.storm_at(at.x, at.y, t))
	return clampf(worst, 0.0, 1.0)


## How much of a signal a storm on its way lets through, 0 to 1: none once
## the worst of it is past storm_blocks, less the nearer it gets to that.
static func let_through(storm: float, tuning: Tuning) -> float:
	return 1.0 - smoothstep(0.0, tuning.storm_blocks, storm)


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


## An anomaly's crackle at world time t: whether a burst sounds now (x, 0 or
## 1) and how high it's pitched (y, 0 to 1). Short and uneven, nothing like
## a storm's steady hiss.
static func crackle(t: float) -> Vector2:
	var slice := floori(t / CRACKLE)
	return Vector2(1.0 if _chance([slice, "crackle"]) < CRACKLE_ON else 0.0, _chance([slice, "pitch"]))
