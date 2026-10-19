class_name LivingCity
extends RefCounted
## The last nomad city: a raft of salvaged chassis, shields and turbines,
## moored for weeks on the far side, then casting off for a leg further on
## with the water, away from Tu, made at the storms' own pace so none behind
## it gains. It's hidden: its scouts' chatter is heard only a few km off, its
## lights only at night. Its nomads still pray to the Walker, which logs each
## one as a bearing from where it stood. Pure in the seed and world time, so
## a save keeps nothing of it.

## Its chatter's five motifs: each a run of reed tones, no words.
const STORM := &"storm"
const TETHER := &"tether"
const MOVING := &"moving"
const CLEAR := &"clear"
const POSITION := &"position"
const MOTIFS: Array[StringName] = [STORM, TETHER, MOVING, CLEAR, POSITION]
## How each motif's tones run, high to low, for the line in view.
const SHAPES := {STORM: "¯ - _", TETHER: "_ _ - -", MOVING: "_ - ¯", CLEAR: "- ¯ ¯ -",
	POSITION: "_ - ¯ - _ ¯ - ¯"}
## Every this many motifs, it gives its place.
const POSITION_EVERY := 4
## Its schedule is laid out from this far back, s, so its log reaches before a run.
const SINCE := -60.0 * 24.0 * 60.0
## A leg looks this many ways for one that keeps it on the far side.
const TRIES := 12

var history: History
var run_seed: int

var _tuning: Tuning
var _radius: float
var _day: float
## Its moorings and legs, laid out as far as asked: each leg as
## [where it was moored, when it casts off, when it arrives, where].
var _legs: Array[Array] = []
var _rng := RandomNumberGenerator.new()
## When each nomad prayed, as far as asked, and the draws that lay them out.
var _prayers := PackedFloat64Array()
var _prayer_rng := RandomNumberGenerator.new()
var _khz: float
## The last motif worked out, and for which field and slot.
var _motif := &""
var _motif_for := []


func _init(world_history: History, seed_value: int, tuning: Tuning) -> void:
	history = world_history
	run_seed = seed_value
	_tuning = tuning
	_radius = world_history.radius
	_day = tuning.day_minutes * 60.0
	_rng.seed = hash([seed_value, "city"])
	_prayer_rng.seed = hash([seed_value, "prayers"])
	var band := tuning.city_band_khz
	_khz = snappedf(lerpf(band.x, band.y, _rng.randf()), 1.0)
	var from := deg_to_rad(_rng.randf_range(tuning.city_from_tu_degrees.x, tuning.city_from_tu_degrees.y))
	var first := Sphere.toward(history.sub_tu, _rng.randf() * TAU, from)
	_legs.append(_leg(first, SINCE + _moored() * _rng.randf()))
	_prayers.append(SINCE + _prayer_gap())


## Its carrier, kHz: its own, the same every day.
func carrier() -> float:
	return _khz


## Where it is on the sphere at world time t.
func at(t: float) -> Vector3:
	var leg := _leg_at(t)
	if t <= leg[1]:
		return leg[0]
	return (leg[0] as Vector3).slerp(leg[3], clampf((t - leg[1]) / (leg[2] - leg[1]), 0.0, 1.0)).normalized()


## Whether it's making a leg at world time t.
func moving(t: float) -> bool:
	var leg := _leg_at(t)
	return t > leg[1] and t < leg[2]


## Its leg under way or the next it makes from world time t: [moored at, casts off, arrives, to].
func leg(t: float) -> Array:
	return _leg_at(t)


## The last `count` prayers to the Walker at or before world time t, latest
## first: each when it was, where the Walker stood then, and the bearing from
## there to the city, rad clockwise from north.
func contacts(gods: Gods, t: float, count: int) -> Array[Dictionary]:
	while _prayers[-1] <= t:
		_prayers.append(_prayers[-1] + _prayer_gap())
	var out: Array[Dictionary] = []
	var i := _prayers.bsearch(t, false) - 1
	while i >= 0 and out.size() < count:
		var when := _prayers[i]
		var from := gods.home(&"walker", when)
		out.append({"t": when, "from": from, "bearing": Sphere.bearing(from, at(when))})
		i -= 1
	return out


## Which motif its chatter plays in the slot holding world time t, from what's
## true at the city then: a storm due within city_warn_s on clear air, storm
## coming; else under way, city moving; else a storm on it, tether in; else
## all clear; and every few slots, moored with no storm due, its place.
## `field` and `ground` are the storm field and the city's place in world metres.
func motif(field: WeatherField, ground: Vector2, t: float) -> StringName:
	var slot := slot_start(t)
	# Read once a slot: it holds for the slot.
	if _motif_for == [field, slot]:
		return _motif
	_motif_for = [field, slot]
	_motif = _motif_in(field, ground, slot)
	return _motif


func _motif_in(field: WeatherField, ground: Vector2, slot: float) -> StringName:
	var stormy := field.raw_storm_at(ground.x, ground.y, slot) > 0.0
	if not stormy and field.next_change(ground.x, ground.y, slot, _tuning.city_warn_s, Weather.FORECAST_STEP) < INF:
		return STORM
	if moving(slot):
		return MOVING
	if floori(slot / _tuning.city_chatter_every) % POSITION_EVERY == POSITION_EVERY - 1:
		return POSITION
	return TETHER if stormy else CLEAR


## When the slot holding world time t began.
func slot_start(t: float) -> float:
	return floorf(t / _tuning.city_chatter_every) * _tuning.city_chatter_every


## Its place written in star positions, as its nomads navigate: the height of
## the pole star over its horizon, or south of the line of the southern pair,
## its latitude; and how far the stars have turned over it since its
## midnight, degrees, its local time, which set against yours is its longitude.
func stars(t: float, day: DayCycle) -> String:
	var p := at(t)
	var lat := rad_to_deg(Sphere.latitude(p))
	var turn := roundi(day.time_of_day(t, Sphere.longitude(p)) * 360.0) % 360
	return "%s %d° · turn %03d°" % ["pole" if lat >= 0.0 else "pair", roundi(absf(lat)), turn]


func _leg_at(t: float) -> Array:
	while _legs[-1][2] <= t:
		var last: Array = _legs[-1]
		_legs.append(_leg(last[3], last[2] + _moored()))
	if t < _legs[0][2]:
		return _legs[0]
	var lo := 0
	var hi := _legs.size() - 1
	while lo < hi:
		var mid := (lo + hi) / 2
		if _legs[mid][2] <= t:
			lo = mid + 1
		else:
			hi = mid
	return _legs[lo]


## A leg from where it's moored, casting off at `cast`: on, with the water,
## away from Tu give or take a right angle, and kept on the far side.
func _leg(from: Vector3, cast: float) -> Array:
	var metres := _rng.randf_range(_tuning.city_leg_m.x, _tuning.city_leg_m.y)
	var away := Sphere.bearing(from, -history.sub_tu)
	var band := _tuning.city_from_tu_degrees
	var to := from
	for k in TRIES:
		var tried := Sphere.toward(from, away + _rng.randf_range(-0.5, 0.5) * PI, metres / _radius)
		var off := rad_to_deg(history.from_tu(tried))
		to = tried
		if off >= band.x and off <= band.y:
			break
		if k == TRIES - 1:
			# Out of the band every way: back toward its middle.
			var middle := deg_to_rad((band.x + band.y) * 0.5)
			var toward := away if history.from_tu(from) < middle else away + PI
			to = Sphere.toward(from, toward, metres / _radius)
	return [from, cast, cast + metres / _tuning.city_speed, to]


func _moored() -> float:
	return _rng.randf_range(_tuning.city_moored_days.x, _tuning.city_moored_days.y) * _day


func _prayer_gap() -> float:
	return _prayer_rng.randf_range(_tuning.city_prayer_days.x, _tuning.city_prayer_days.y) * _day
