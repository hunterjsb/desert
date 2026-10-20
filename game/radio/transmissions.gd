class_name Transmissions
extends RefCounted
## What each god says, and when it's worth hearing. Every god talks all the
## time, in its own formatting and words, but each says something useful only
## in its own window: the Quartermaster through the eclipse, Mother Cistern at
## dawn, the Ledger at midnight. The rest of the time it's noise in the god's
## voice. Everything useful is read from the real systems, never made up.

## Local times, as shares of the day from midnight.
const DAWN := Vector2(0.21, 0.29)
const SUNRISE := Vector2(0.24, 0.28)
const SUNSET := Vector2(0.72, 0.76)
const DUSK := Vector2(0.74, 0.80)
const HOT := Vector2(0.54, 0.67)
const MIDNIGHT := 0.03
## The Walker reports for this long after a storm starts or ends where it is, s.
## With nothing to report it holds instead, its clear-skies song on the air.
const STORM_NEWS := 40.0
## How far the gods look for a site they name, m: as far as history is laid.
const LOOK_M := 5000.0
## What the Quartermaster keeps on file: the Dark Age's caches, and the
## dugouts, checkpoints and bunkers soldiers left.
const CACHES: Array[StringName] = [&"cache", &"dugout", &"checkpoint", &"bunker"]
## The idle lines change this often, s.
const IDLE_EVERY := 6.0

const IDLE := {
	&"quartermaster": ["ROLL CALL // UNIT %d // NO RESPONSE", "PERIMETER STATUS: UNVERIFIED",
		"REQUISITION %d DENIED: CLEARANCE LAPSED", "ALL PERSONNEL REPORT TO MUSTER POINT"],
	&"walker": ["survey leg %d · grade nominal · continuing", "waypoint %d logged · no operator",
		"sample bin full · discarding", "gait fault 3 · compensating · continuing"],
	&"cistern": ["...and the basin shall be filled, phase %d of the plan...", "...rain at the forty-first year...",
		"...a cup for every child of the colony...", "...the reservoirs are not yet funded..."],
	&"almanac": ["QUOTE: seed stock %d per bushel. NO BUYERS.", "LEDGER BALANCE OWED: %d credits",
		"Contract %d unfilled. Penalty accrues.", "Market closed. Market closed."],
	&"ledger": ["MANIFEST %d · 0 OF 0 BERTHS OCCUPIED", "AWAITING HARBOUR TRAFFIC · DAY %d",
		"CARGO HOLD 4 · INVENTORY UNCHANGED", "CREW LIST · 0 ABOARD · 0 ASHORE"],
	&"stoker": ["!! PRESSURE LOW !! FEED REQUIRED !! %d", "QUOTA SHORTFALL %d%%", "BURNER 2 COLD. BURNER 2 COLD.",
		"!! HEAT !! HEAT !! HEAT !!"],
	&"eye": ["", "", "", ""],
}


## What a god says now at a place, read from the world: {text, useful}.
## `p` is the radio's point on the sphere, x and z its world metres.
static func say(id: StringName, radio: Radio, gods: Gods, p: Vector3, x: float, z: float, t: float) -> Dictionary:
	var world := radio.world
	var day := world.weather.day
	var local := day.time_of_day(t, Sphere.longitude(p))
	match id:
		&"quartermaster":
			if day.sun_shown(t) < 0.999:
				return {"text": _quartermaster(radio, x, z), "useful": true}
		&"walker":
			return _walker(radio, gods, x, z, t, local)
		&"cistern":
			if _within(local, DAWN):
				return {"text": _cistern(radio, x, z, t, local), "useful": true}
		&"almanac":
			if _within(local, SUNRISE) or _within(local, SUNSET):
				return {"text": _almanac(radio, t), "useful": true}
		&"ledger":
			if local < MIDNIGHT or local > 1.0 - MIDNIGHT:
				return {"text": _ledger(radio, gods, p), "useful": true}
		&"stoker":
			if _within(local, HOT):
				return {"text": _stoker(radio, t), "useful": true}
		&"eye":
			if not day.is_day(t, Sphere.longitude(p)):
				return {"text": _eye(p, local), "useful": true}
	return {"text": idle(id, t), "useful": false}


## What a god says outside its window: noise in its own voice.
static func idle(id: StringName, t: float) -> String:
	var lines: Array = IDLE[id]
	var slot := floori(t / IDLE_EVERY)
	var line: String = lines[hash([id, slot]) % lines.size()]
	return line % (hash([id, slot, "n"]) % 900 + 100) if line.contains("%d") else line


static func _within(local: float, window: Vector2) -> bool:
	return local >= window.x and local <= window.y


static func _quartermaster(radio: Radio, x: float, z: float) -> String:
	var cache := _nearest(radio, x, z, CACHES)
	if cache == null:
		return "BLACKOUT DRILL // NO CACHE ON FILE THIS SECTOR"
	return "BLACKOUT DRILL // CACHE BRG %03d RNG %.1fKM // DO NOT ACKNOWLEDGE" % [
		roundi(radio.true_bearing(Radio.bearing(Vector2(cache.x - x, cache.z - z)))), cache.distance_to(x, z) / 1000.0]


## The weather station: the routine forecast for where the radio is, always;
## at dusk or with storm news where it walks, the long report too; taught, an
## anomaly near the radio flagged after it. Under it its log, read an entry
## at a time (`log`). What it reads aloud is shorter (Radio.report).
static func _walker(radio: Radio, gods: Gods, x: float, z: float, t: float, local: float) -> Dictionary:
	var said := _walker_report(radio, gods, x, z, t, local)
	if radio.world.taught:
		said.text += _flag(radio, x, z, t)
	said.merge(walker_log(radio.world, gods, t))
	return said


static func _walker_report(radio: Radio, gods: Gods, x: float, z: float, t: float, local: float) -> Dictionary:
	var routine := radio.weather_words(t)
	var at := radio.ground_of(gods.home(&"walker", t))
	var field := radio.world.weather.field
	var now := field.raw_storm_at(at.x, at.y, t) > 0.0
	var before := field.raw_storm_at(at.x, at.y, t - STORM_NEWS) > 0.0
	if now != before or _within(local, DUSK):
		var tuning := Tuning.current()
		var long := Radio.forecast(field, x, z, t, tuning.radio_forecast_minutes * 120.0, Weather.FORECAST_STEP)
		var none := "no clearing for %d min" if long.stormy else "no storm for %d min"
		var ahead := none % roundi(tuning.radio_forecast_minutes * 2.0) if long.change == INF \
			else ("storm clears in %s" % Radio.span(long.change - t) if long.stormy
				else "storm in %s" % Radio.span(long.change - t))
		var feet_say := "storm at the walker" if now else "clear at the walker"
		return {"text": "%s · long range: %s · %s" % [routine, ahead, feet_say], "useful": true,
			"calm": calm(radio.reading, t), "spoken": radio.report(t, long)}
	return {"text": routine, "useful": true, "calm": calm(radio.reading, t), "spoken": radio.report(t)}


## The anomaly whose heart stands nearest the radio within walker_flag_m,
## flagged: how far and which way, and when it's at its full. "" with none.
static func _flag(radio: Radio, x: float, z: float, t: float) -> String:
	var tuning := Tuning.current()
	var best := {}
	for heart in radio.world.weather.field.anomalies_near(x, z, t, tuning.walker_flag_m):
		if best.is_empty() or Vector2(heart.x - x, heart.z - z).length() < Vector2(best.x - x, best.z - z).length():
			best = heart
	if best.is_empty():
		return ""
	var off := Vector2(best.x - x, best.z - z)
	var when := "at its full" if absf(best.peak - t) < 60.0 else (
		"full in %s" % Radio.span(best.peak - t) if best.peak > t else "fading")
	return " · anomaly %.1f km %s, %s" % [off.length() / 1000.0, radio.say_point(Radio.bearing(off)), when]


## The Walker's log entry in the slot holding world time t: its survey
## first, then each contact it keeps, latest first, round again. {log, contact}:
## the line, and the contact it reads if it does.
static func walker_log(world: World, gods: Gods, t: float) -> Dictionary:
	var tuning := Tuning.current()
	var slot := floori(t / tuning.walker_log_every)
	var kept := gods.city.contacts(gods, t, tuning.walker_contacts_kept)
	var k := posmod(slot, kept.size() + 1)
	if k == 0:
		return {"log": _survey(world, gods, slot * tuning.walker_log_every), "contact": {}}
	var contact := kept[k - 1]
	return {"log": "contact · %s ago · from %s · brg %03d" % [_ago(t - contact.t), fix(contact.from),
		roundi(rad_to_deg(fposmod(contact.bearing, TAU))) % 360], "contact": contact}


## Its survey where it walks: its leg, heading, the steady wind at its feet,
## the ground under it and its fix.
static func _survey(world: World, gods: Gods, t: float) -> String:
	var p := gods.home(&"walker", t)
	var heading := roundi(rad_to_deg(fposmod(Sphere.bearing(p, gods.home(&"walker", t + 60.0)), TAU))) % 360
	var at := Walker.ground(world, p)
	var wind := world.weather.field.steady_wind_at(at.x, at.y, t)
	var from := String(Console.POINTS[roundi(fposmod(Radio.bearing(-wind), 360.0) / 22.5) % 16]).to_lower()
	return "survey %d · hdg %03d · wind %d m/s %s · %s · fix %s" % [floori(t * Tuning.current().walker_speed / 1000.0),
		heading, roundi(wind.length()), from, _ground_words(world, at), fix(p)]


## A place as its log writes it: latitude and longitude to a tenth.
static func fix(p: Vector3) -> String:
	var lat := rad_to_deg(Sphere.latitude(p))
	var lon := rad_to_deg(Sphere.longitude(p))
	return "%.1f%s %.1f%s" % [absf(lat), "n" if lat >= 0.0 else "s", absf(lon), "e" if lon >= 0.0 else "w"]


## The ground at a place in a few words: how the dunes stand and the sand lies.
static func _ground_words(world: World, at: Vector2) -> String:
	var shape := world.shape
	var rise := 0.0
	for way: Vector2 in [Vector2(20.0, 0.0), Vector2(0.0, 20.0)]:
		rise = maxf(rise, absf(shape.height_at(at.x + way.x, at.y + way.y) - shape.height_at(at.x - way.x, at.y - way.y)))
	var dunes := "flats" if rise < 1.0 else ("low dunes" if rise < 4.0 else "dunes, slip faces")
	return dunes + (", sand deep" if shape.sand_at(at.x, at.y) > 0.6 else ", sand thin")


static func _ago(seconds: float) -> String:
	var day := Tuning.current().day_minutes * 60.0
	return "%d d" % roundi(seconds / day) if seconds >= day * 0.5 else "%d min" % roundi(seconds / 60.0)


## Nothing to report at world time t: no storm on you, and none due within
## radio_calm_minutes. A storm farther off is still in the forecast's words;
## it's nothing to worry about yet.
static func calm(reading: Dictionary, t: float) -> bool:
	return not reading.is_empty() and not reading.stormy \
		and reading.change - t > Tuning.current().radio_calm_minutes * 60.0


static func _cistern(radio: Radio, x: float, z: float, t: float, local: float) -> String:
	var world := radio.world
	var day_seconds := Tuning.current().day_minutes * 60.0
	# The coldest hour coming, 03:00 local, under the weather the field will have then.
	var to_cold := fposmod(0.125 - local, 1.0) * day_seconds
	var at := Vector3(world.engine_x(x), 0.0, world.engine_z(z))
	var cold := world.weather.field_temperature(at, t + to_cold)
	var outlook := "frost tonight, %d degrees" % roundi(cold) if cold < 0.0 else "dew tonight, %d degrees" % roundi(cold)
	var water := _nearest(radio, x, z, [&"cistern", &"stepwell"])
	var where := "no basin near, child" if water == null else "a basin %s of you, %.1f km" % [
		radio.say_point(Radio.bearing(Vector2(water.x - x, water.z - z))), water.distance_to(x, z) / 1000.0]
	return "...blessed are the thirsty: %s; %s..." % [outlook, where]


static func _almanac(radio: Radio, t: float) -> String:
	var world := radio.world
	var at := radio.global_position
	var day_seconds := Tuning.current().day_minutes * 60.0
	var hot := -INF
	var cold := INF
	var step := day_seconds / 12.0
	for k in 12:
		var c := world.weather.field_temperature(at, t + k * step)
		hot = maxf(hot, c)
		cold = minf(cold, c)
	var wind := radio.reading.get("wind", 0.0) as float
	var sow: Array[String] = []
	var hold: Array[String] = []
	for id: StringName in Catalog.PARTS:
		var spec: Dictionary = Catalog.PARTS[id]
		if not spec.has("crop"):
			continue
		var crop: Dictionary = spec.crop
		# Sown out in the open, it has to hold through the whole day coming.
		var fits: bool = crop.heat.y >= hot and crop.cold.y <= cold and crop.wind.y >= wind
		(sow if fits else hold).append(String(spec.label).to_lower())
	return "Advisory. Day %d to %d C. SOW: %s. HOLD: %s. Fee due." % [roundi(cold), roundi(hot),
		", ".join(sow) if not sow.is_empty() else "nothing", ", ".join(hold) if not hold.is_empty() else "nothing"]


static func _ledger(radio: Radio, gods: Gods, p: Vector3) -> String:
	var bits: Array[String] = []
	for id: StringName in [&"halloran", &"rim_depot", &"starcom"]:
		var mark := gods.history.landmark(id)
		if mark.is_empty():
			continue
		bits.append("%s BRG %03d %.1fKM" % [String(mark.name).to_upper(), roundi(rad_to_deg(fposmod(Sphere.bearing(p, mark.p), TAU))),
			Sphere.angle(p, mark.p) * gods.history.radius / 1000.0])
	return "BERTH INVENTORY · " + " · ".join(bits)


static func _stoker(radio: Radio, t: float) -> String:
	var world := radio.world
	if Stoker.active(world):
		return "BAY 02 · MAINTENANCE BURN · PRESSURE STABLE · QUOTA OUTSTANDING"
	var day := world.weather.day
	var dark := day.next_eclipse(t) - t
	var peak := -INF
	for k in 10:
		peak = maxf(peak, world.weather.field_temperature(radio.global_position, t + k * 30.0))
	return "!! DARK IN %d S !! PEAK %d C IN 5 MIN !! FEED ME !!" % [roundi(dark), roundi(peak)]


static func _eye(p: Vector3, local: float) -> String:
	var lat := rad_to_deg(Sphere.latitude(p))
	var lon := rad_to_deg(Sphere.longitude(p))
	var minutes := roundi(local * 24.0 * 60.0) % (24 * 60)
	return "i see you. %.1f%s %.1f%s. it is %02d:%02d where you stand." % [absf(lat), "n" if lat >= 0.0 else "s",
		absf(lon), "e" if lon >= 0.0 else "w", minutes / 60, minutes % 60]


static func _nearest(radio: Radio, x: float, z: float, kinds: Array) -> Site:
	return radio.world.shape.sites.nearest(x, z, LOOK_M, func(site: Site) -> bool: return kinds.has(site.kind), true)
