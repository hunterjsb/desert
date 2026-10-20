class_name Advisories
extends RefCounted
## The weather station's advisories (gonkhub, 2026-10-19: "interrupt at any
## time to issue a weather advisory - for anomalous weather events we may add
## in the future, or for abnormally large/fast sandstorms"). Each check reads
## the real storm field where the radio stands and says whether there's
## something to warn of: what it is (a kind and a moment, so each event is
## warned of once) and the words. The station breaks off whatever it's saying
## to read one aloud the moment it's due.
##
## Checks now: a sandstorm abnormally fast (riding a prevailing wind faster
## than nine in ten do) or abnormally large (lasting longer than nine in ten,
## looked ahead past the forecast). New kinds of weather add their own check
## to check(). The anomaly is left out on purpose: no forecast speaks of it.
## Each gives {kind, at, phrases}: at is when the event comes, world time, or
## NOW for one you're in; phrases, what the radio reads aloud, in its bank's
## recordings (Radio.clip).

## Two warnings of one kind this near in time are of the same event, s.
const SAME := 180.0
## An advisory's `at` for the storm you're in now, whenever it came.
const NOW := -1.0


## The first advisory due for a radio at world place x, z and time t, from
## its station's fresh reading: {kind, at, words}, or {} with none.
## Each check is one line here, in order; the first with something wins.
static func check(radio: Radio, reading: Dictionary, x: float, z: float, t: float) -> Dictionary:
	var found := _sandstorm(radio, reading, x, z, t)
	return found


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
	# In the bank's phrases, as the radio reads them: "Weather advisory. Fast
	# sandstorm, from the north-west. Four minutes. Moving, sixteen, metres a
	# second. Lasting, thirty minutes. Take shelter."
	var phrases := PackedStringArray(["Weather advisory.",
		"Fast and large sandstorm," if fast and large else ("Fast sandstorm," if fast else "Large sandstorm,"),
		"From the %s." % radio.say_point(reading.from)])
	phrases.append("On you now." if reading.stormy else Radio._sentence(Radio.spoken_span(comes - t)))
	if speed >= 1.0:
		phrases.append_array(PackedStringArray(["Moving,", Radio.number_words(roundi(speed)) + ",", "Metres a second."]))
	if lasts == INF:
		phrases.append_array(PackedStringArray(["Lasting more than,", Radio._sentence(Radio.spoken_span(
			tuning.advisory_look_minutes * 60.0))]))
	else:
		phrases.append_array(PackedStringArray(["Lasting,", Radio._sentence(Radio.spoken_span(lasts))]))
	phrases.append("Take shelter.")
	return {"kind": &"sandstorm", "at": NOW if reading.stormy else comes, "phrases": phrases}
