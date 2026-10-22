class_name Advisories
extends RefCounted
## Port Morgan Tower's advisories (gonkhub, 2026-10-19: "interrupt at any
## time to issue a weather advisory - for anomalous weather events we may add
## in the future, or for abnormally large/fast sandstorms"). Each check reads
## the real storm field where the radio stands and says whether there's
## something to warn of: what it is (a kind and a moment, so each event is
## warned of once) and the words. The station breaks off whatever it's saying
## to read one aloud the moment it's due. It reads them at the tower, and says
## where each is by a bearing and distance from the tower (gonkhub,
## 2026-10-21: "it should give a bearing and distance from the tower").
##
## Checks now: a sandstorm abnormally fast (riding a prevailing wind faster
## than nine in ten do) or abnormally large (lasting longer than nine in ten,
## looked ahead past the forecast), and, once the Walker's been taught the
## anomaly (Chart.upload), an anomaly within walker_flag_m of the tower. New kinds of weather add their own check to check(). Each gives
## {kind, at, words}: at is when the event comes, world time, or NOW for one
## at the tower now.

## Two warnings of one kind this near in time are of the same event, s.
const SAME := 180.0
## An advisory's `at` for the storm you're in now, whenever it came.
const NOW := -1.0


## The first advisory due from the tower at world place x, z and time t, from
## its fresh reading: {kind, at, words}, or {} with none.
## Each check is one line here, in order; the first with something wins.
static func check(radio: Radio, reading: Dictionary, x: float, z: float, t: float) -> Dictionary:
	var found := _sandstorm(radio, reading, x, z, t)
	if found.is_empty():
		found = _anomaly(radio, x, z, t)
	return found


## Where something is from the tower, as it says it: a bearing, degrees, and
## how far, km.
static func from_tower(degrees: float, metres: float) -> String:
	return "bearing %03d, %.1f kilometres from the tower" % [roundi(fposmod(degrees, 360.0)) % 360, metres / 1000.0]


## The anomaly whose heart stands nearest the tower within walker_flag_m: where
## it is from the tower and when it's at its full.
static func _anomaly(radio: Radio, x: float, z: float, t: float) -> Dictionary:
	if not radio.world.taught:
		return {}
	var best := {}
	for heart in radio.world.weather.field.anomalies_near(x, z, t, Tuning.current().walker_flag_m):
		if best.is_empty() or Vector2(heart.x - x, heart.z - z).length() < Vector2(best.x - x, best.z - z).length():
			best = heart
	if best.is_empty():
		return {}
	var off := Vector2(best.x - x, best.z - z)
	var when := "at its full now" if absf(best.peak - t) < 60.0 else (
		"at its full in %s" % Radio.span(best.peak - t) if best.peak > t else "fading")
	return {"kind": &"anomaly", "at": best.peak,
		"words": "Weather advisory. An anomalous storm, %s, %s. Keep clear." % [
			from_tower(radio.true_bearing(Radio.bearing(off)), off.length()), when]}


## A sandstorm on you or due within the forecast that rides a fast wind or
## lasts long: how fast it comes, measured by the wind it rides, and how long
## it lasts, looked ahead advisory_look_minutes from when it comes.
static func _sandstorm(radio: Radio, reading: Dictionary, x: float, z: float, t: float) -> Dictionary:
	if reading.is_empty() or (not reading.stormy and reading.change == INF):
		return {}
	var tuning := Tuning.current()
	var field := radio.world.weather.field
	var comes: float = t if reading.stormy else reading.change
	var speed := field.prevailing_at(comes).length()
	var look := tuning.advisory_look_minutes * 60.0
	var lasts := field.next_change(x, z, comes, look, Weather.FORECAST_STEP)
	var fast := speed >= tuning.advisory_fast_ms
	var large := lasts >= tuning.advisory_long_minutes * 60.0
	if not fast and not large:
		return {}
	var what := "a fast and large sandstorm" if fast and large else ("a fast sandstorm" if fast else "a large sandstorm")
	var when := "on you now" if reading.stormy else "in %s" % Radio.span(comes - t)
	var long := "lasting more than %d minutes" % roundi(tuning.advisory_look_minutes) if lasts == INF \
		else "lasting %d minutes" % roundi(lasts / 60.0)
	# Its front, riding the wind toward the tower: as far off as it'll come in.
	var where := "over the tower" if reading.stormy else from_tower(reading.from, speed * (comes - t))
	return {"kind": &"sandstorm", "at": NOW if reading.stormy else comes,
		"words": "Weather advisory. %s from the %s, %s, %s, %s%s. Take shelter." % [
			what[0].to_upper() + what.substr(1), radio.say_point(reading.from), where, when,
			"moving %d metres a second, " % roundi(speed) if speed >= 1.0 else "", long]}
