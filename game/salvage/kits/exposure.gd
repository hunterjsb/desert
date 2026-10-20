class_name Exposure
extends RefCounted
## Whether a site is buried, partly exposed or exposed, and how far between:
## a pure function of the weather at its place, so a site's state at any
## moment is known without anyone having watched it. Two parts. The settled
## sand is the weather's work over the last half day, read on fixed ticks.
## The storm's own: while a storm works on a site its big dunes move, a
## minute at a time, laying it bare or burying it again, and once the storm
## lets go the sand comes back within minutes. Both are read between their
## ticks, so the sand on a site never jumps. Where it lies among the dunes
## weighs both (dune_at): a windward face or crest is stripped harder, a lee
## buried harder.

enum { BURIED, PARTLY, EXPOSED }
const NAMES: Array[String] = ["buried", "partly exposed", "exposed"]
## A level runs from 0, buried, through 1, the partly exposed look, to 2, dug out.
const DUG_OUT := 2.0
## The storm's work is read a minute at a time.
const SURGE_STEP_S := 60.0

static var _lock := Mutex.new()

## The dune term reads the dunes this far up and down the wind, m: a face's
## slope, a crest over the ground round it, a crest upwind sheltering a lee.
const FACE_M := 6.0
const CREST_M := 50.0
const LEE_M: Array[float] = [8.0, 16.0, 32.0, 64.0, 128.0]


## A site's readings kept by tick, so asking every frame costs a lookup. The
## numbers are the same however they're come by.
class Memo:
	var readings := {}
	var settled := {}
	var works := {}
	var surges := {}
	var keeps := {}


## How hard the weather is at a place and moment, 0 to 1: how deep into a
## storm, or how far the wind blows past the prevailing wind's strongest,
## whichever is harder. Finds read it too.
static func reading(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var storm := clampf(field.raw_storm_at(x, z, t) / tuning.exposure_storm_full, 0.0, 1.0)
	var gale := clampf((field.wind_at(x, z, t).length() - tuning.exposure_calm_wind)
		/ (tuning.exposure_gale_wind - tuning.exposure_calm_wind), 0.0, 1.0)
	return maxf(storm, gale)


## The settled sand the weather has taken off a place by a tick, m. Each tick
## of the window a storm strips by how hard it blew and the wind lays some
## back, and the older the tick the more has drifted back since, so one big
## storm strips a lot, calm lets the sand return, and nothing is a hard timer.
static func stripped(field: WeatherField, x: float, z: float, t: float, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	return stripped_at(field, x, z, floori(t / (tuning.site_exposure_step_minutes * 60.0)), tuning, memo, dune)


## The same by its tick.
static func stripped_at(field: WeatherField, x: float, z: float, tick: int, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	var step := tuning.site_exposure_step_minutes * 60.0
	var known: Variant = _recall(memo, &"settled", tick)
	if known != null:
		return known
	var count := maxi(1, roundi(tuning.site_exposure_hours * 60.0 / tuning.site_exposure_step_minutes))
	var strip := tuning.site_strip_m * (1.0 + tuning.site_dune_strip * maxf(dune, 0.0))
	var back := tuning.site_return_m * (1.0 + tuning.site_dune_bury * maxf(-dune, 0.0))
	var sum := 0.0
	for k in count:
		var r: Variant = _recall(memo, &"readings", tick - k)
		if r == null:
			r = reading(field, x, z, (tick - k) * step, tuning)
			_keep(memo, &"readings", tick - k, r, count)
		sum += (strip * float(r) - back) * (1.0 - float(k) / count)
	var out := maxf(sum, 0.0)
	_keep(memo, &"settled", tick, out, 4)
	return out


## The settled sand at a moment, between its ticks: a tick behind, so it's
## only ever the weather that has been.
static func settled(field: WeatherField, x: float, z: float, t: float, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	var at := t / (tuning.site_exposure_step_minutes * 60.0)
	var tick := floori(at)
	return lerpf(stripped_at(field, x, z, tick - 1, tuning, memo, dune), stripped_at(field, x, z, tick, tuning, memo, dune),
		at - tick)


## The sand a storm working on a place has moved off it by a minute's tick, m:
## each minute its heart moves sand off where the dunes are moving off and
## onto where they're moving on, and what it moved comes back as the minutes
## pass. Never below none.
static func surge_at(field: WeatherField, x: float, z: float, tick: int, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	var known: Variant = _recall(memo, &"surges", tick)
	if known != null:
		return known
	var count := maxi(1, roundi(tuning.site_surge_window_minutes * 60.0 / SURGE_STEP_S))

	var off := 1.0 + tuning.site_dune_strip * maxf(dune, 0.0)
	var on := 1.0 + tuning.site_dune_bury * maxf(-dune, 0.0)
	var sum := 0.0
	var weight := 1.0
	for k in count:
		var work: Variant = _recall(memo, &"works", tick - k)
		if work == null:
			work = _work(field, x, z, (tick - k) * SURGE_STEP_S, tuning)
			_keep(memo, &"works", tick - k, work, count)
		sum += float(work) * (off if float(work) > 0.0 else on) * weight
		var keep: Variant = _recall(memo, &"keeps", tick - k)
		if keep == null:
			var heart := smoothstep(0.0, tuning.exposure_storm_full,
				field.raw_storm_at(x, z, (tick - k) * SURGE_STEP_S))
			var minutes := lerpf(tuning.site_wake_return_minutes, tuning.site_surge_return_minutes, heart)
			keep = exp(-SURGE_STEP_S / (minutes * 60.0))
			_keep(memo, &"keeps", tick - k, keep, count)
		weight *= float(keep)
	var out := maxf(sum, 0.0)
	_keep(memo, &"surges", tick, out, 4)
	return out


## The storm's work at a moment, between its ticks, a tick behind.
static func surge(field: WeatherField, x: float, z: float, t: float, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	var at := t / SURGE_STEP_S
	var tick := floori(at)
	return lerpf(surge_at(field, x, z, tick - 1, tuning, memo, dune), surge_at(field, x, z, tick, tuning, memo, dune),
		at - tick)


## All the sand taken off a place at a moment, m: the settled sand and the storm's.
static func taken(field: WeatherField, x: float, z: float, t: float, tuning: Tuning, memo: Memo = null,
		dune := 0.0) -> float:
	return settled(field, x, z, t, tuning, memo, dune) + surge(field, x, z, t, tuning, memo, dune)


## Where a place lies among the dunes, -1 to 1: toward 1 on a windward face or
## a crest, which the wind strips; toward -1 on a slip face or in the lee of a
## crest upwind, where what it carries falls out. Pure in the dunes alone and
## the run's long-term wind, which they face, so a worker can read it.
static func dune_at(shape: TerrainShape, x: float, z: float, tuning: Tuning) -> float:
	var down := shape.downwind()
	var here := shape.dunes(x, z)
	var climb := (shape.dunes(x + down.x * FACE_M, z + down.y * FACE_M)
		- shape.dunes(x - down.x * FACE_M, z - down.y * FACE_M)) / (2.0 * FACE_M)
	var low := minf(shape.dunes(x - down.x * CREST_M, z - down.y * CREST_M),
		shape.dunes(x + down.x * CREST_M, z + down.y * CREST_M))
	var slip := smoothstep(0.2, 0.45, -climb)
	var bared := maxf(smoothstep(0.02, 0.15, climb), smoothstep(2.0, 10.0, here - low) * (1.0 - slip))
	var lee := slip
	for s in LEE_M:
		var tall := shape.dunes(x - down.x * s, z - down.y * s) - here
		if tall > tuning.lee_tall.x:
			lee = maxf(lee, (1.0 - smoothstep(tuning.lee_heights.x, tuning.lee_heights.y, s / tall))
				* smoothstep(tuning.lee_tall.x, tuning.lee_tall.y, tall))
	return clampf(bared - lee, -1.0, 1.0)


## A site's state, from the sand taken off it against how deep it lies: under
## a third of its depth stripped, buried; under all of it, partly exposed.
static func state(depth: float, taken_m: float) -> int:
	if taken_m >= depth:
		return EXPOSED
	return PARTLY if taken_m >= depth / 3.0 else BURIED


## How far it's come out of the sand, 0 to DUG_OUT: buried until a third of
## its depth is off, then steadily out until all of it is.
static func level(depth: float, taken_m: float) -> float:
	if depth <= 0.0:
		return DUG_OUT
	return clampf(3.0 * taken_m / depth - 1.0, 0.0, DUG_OUT)


static func _work(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var heart := clampf(field.raw_storm_at(x, z, t) / tuning.exposure_storm_full, 0.0, 1.0)
	if heart <= 0.0:
		return 0.0
	return tuning.site_surge_m * heart * field.dune_shift_at(x, z, t)


static func _recall(memo: Memo, which: StringName, tick: int) -> Variant:
	if memo == null:
		return null
	_lock.lock()
	var got: Variant = (memo.get(which) as Dictionary).get(tick)
	_lock.unlock()
	return got


## Kept, and the oldest let go once it holds more than a window's worth.
static func _keep(memo: Memo, which: StringName, tick: int, value: float, window: int) -> void:
	if memo == null:
		return
	_lock.lock()
	var into: Dictionary = memo.get(which)
	into[tick] = value
	if into.size() > window * 2 + 8:
		for old: int in into.keys():
			if old < tick - window - 2:
				into.erase(old)
	_lock.unlock()
