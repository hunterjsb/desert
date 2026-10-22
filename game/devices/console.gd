class_name Console
extends Device
## The camp's computer: a rack standing tall, its whole front a screen. Its
## computer mods each read the weather field itself, never the felt weather,
## so a bubble doesn't blind them: the field has no pressure, humidity or
## sand, so those are derived from it (Tuning, Console). Every Console
## standing on one deck is one system, its instruments pooled. Its screen
## leads with the storm map, which takes in all the system reads: the more
## gear, the finer it is, and with less it coarsens, never going. Then every
## reading in detail as a table, the deck's electrics as a panel with each
## device's switches, and its log. A shield in the system is smart: with a
## radar it switches itself on as a front nears. Its one map lays over it
## what its gear can feed, each a filter switched on and off: the weather,
## the ground radar's survey and navigation. Its messages go out through
## its Terminal, a radio in its system sounding them and saying its battery
## running out, and its screen draws only when what it shows has changed.
## Use on the screen presses the key you aim at, a tab along its foot or a
## switch; use at the frame works its deck's trays.

## Its pages, numbered as older saves knew them: the Shield page's number is
## Power's now, so a save on it opens there; one on the Survey or Chart page,
## both on the Map now, opens on the Map.
enum Page { MAP, POWER, LOG, STATS }
## The tabs along its foot, in order.
const TABS: Array[Page] = [Page.MAP, Page.STATS, Page.POWER, Page.LOG]
const PAGE_NAMES := ["MAP", "POWER", "LOG", "STATS"]
## The Map's filters in their switches' order, each its switch's word.
const FILTERS := {"weather": "WEATHER", "survey": "SURVEY", "nav": "NAV"}
## The sender its own lines go out under.
const SENDER := "CON"
## What each computer mod is called in its own lines, by the stat it adds.
const INSTRUMENTS := {"anemometer": "ANEMOMETER", "barometer": "BAROMETER", "hygrometer": "HYGROMETER",
	"particle_sensor": "PARTICLE SENSOR", "radar": "RADAR", "ground_radar": "GROUND RADAR"}
## The survey lists this many of what lies nearest, two rows each.
const SURVEY_ROWS := 5
const POINTS := ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
## How hard a storm will hit: the most sand in this far of it past its
## front, m, read in these many steps.
const HIT_DEPTH := 1000.0
const HIT_STEPS := 4
## Sand's trend looks back this far, s.
const SAND_TREND := 30.0
## The barometer's history the stats page draws: this many readings, this
## far apart, s.
const HISTORY := 20
const HISTORY_EVERY := 30.0
## Storms riding a wind slower than this have no time to them, m/s.
const CLOSING := 0.5
## Its battery warnings are said again only once what's left climbs this far
## back over their line, so a charge wavering on it isn't announced over and over.
const REARM := 0.02
## With no radar, the map estimates this far round it, m: what a storm the
## barometer feels, carried by the wind, covers in its warning's reach.
const ESTIMATE_REACH := 6000.0
## The screen's pixels and the picture on its glass, m.
const PIXELS := Vector2i(580, 1080)
const PICTURE := Vector2(0.58, 1.08)
## Slower over the sand than this, m/s, the deck's own way is left out of
## what the stats page says of the wind.
const STILL := 0.5
## The highest rank the power page sets a device to.
const MOST_RANK := 5

var page := Page.MAP:
	set(to):
		page = to if to in TABS else Page.MAP
## The Map's filters switched off; each other one its gear feeds shows.
var filters_off: Array = []
var terminal := Terminal.new()
## What the save keeps of its terminal.
var log_lines: Array:
	get:
		return terminal.lines
	set(to):
		terminal.lines = to
## This Console's own readings, by what reads them; the screen shows those of
## every Console linked with it.
var readings := {}
## For the Walker (Chart): each anomaly tell its system witnessed, by tell,
## {t, value}; and the contacts it noted off the Walker's log, {t, lat, lon, brg}.
var evidence := {}
var bearings: Array = []
## Alerts given for the storm coming now, so each prints once, and whether
## the radar had a front within the smart shield's reach at the last read.
var _alerts := {}
var _front_near := false

var _tuning := Tuning.current()
var _read_at := -INF
var _forecast_at := -INF
var _screen_at := -INF
## The radar's last sweep: metres along each bearing to where the storm state
## differs from here, INF for nowhere in reach, and the next bearing.
var _sweep := PackedFloat32Array()
var _bearing := 0
## The storm map round it as last sampled whole, north row first: each cell's
## storm (-1 past the radar's reach), its sand as a share of a storm's heart
## and its humidity; the pass being sampled, a row at a time; its cells
## across, its reach, when its pass began, and a count of passes.
var _map := PackedFloat32Array()
var _map_sand := PackedFloat32Array()
var _map_humid := PackedFloat32Array()
var _next := [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
## The condenser's yield, as a share, clear and under a storm, read once a pass.
var _yields := Vector2.ZERO
var _map_n := 0
var _map_row := 0
var _map_reach := 0.0
var _map_at := -INF
var _map_passes := 0
## What it last knew of its own instruments and its link, to say when they change.
var _instruments := {}
var _linked := 1
## The last forecast a radio in it gave, and whether the radar has swept round once.
var _forecast := {}
var _swept := false
var _awake := false
var _shields_down := {}
var _viewport: SubViewport
var _view: ConsoleScreen
var _display: MeshInstance3D
var _screened := false
var _shown := ""
var _aim := -1
## The keys on the screen as last drawn, for what you aim at.
var _keys: Array = []
## The first load the power page shows, as it pages through them.
var _first_load := 0


func _ready() -> void:
	super()
	_instruments = _fitted()
	_awake = true
	_show_display()


## Use on the screen presses the key you aim at; at the frame, it works its tray.
func interact(by: Player) -> bool:
	var screen := _screen()
	if by != null and screen != null and by.hands.look_device == self and by.hands.look_socket == screen:
		if not running():
			return by.hands.refuse("no power")
		press(_on_screen(by.hands.look_point))
		return true
	return super(by)


## Whether it computes: powered and whole, in the world.
func running() -> bool:
	return powered and not wrecked() and world != null


## A press on the screen at a spot, 0 to 1 across and down: the key there,
## if any, a tab or a switch.
func press(at: Vector2) -> void:
	var on := keys()
	var key := _key_at(at, on)
	if key >= 0:
		(on[key].act as Callable).call()
	_screen_at = -INF


## The keys a page of its screen shows (its own, by default), as
## {text, lit, box, device, to}: its tabs, then its switches.
func keys(on := -1) -> Array:
	return _model(page if on < 0 else on as Page, pooled_readings()).keys


## Every Console in its system, the first one first: those standing on the
## same deck, or itself alone.
func linked() -> Array[Console]:
	var found: Array[Console] = []
	for device in _system():
		if device is Console:
			found.append(device)
	return found


## The shields its system makes smart: on its deck, or seated on it.
func smart_shields() -> Array[ShieldGenerator]:
	var found: Array[ShieldGenerator] = []
	for device in _system():
		if device is ShieldGenerator:
			found.append(device)
	return found


## Every reading its system has, each from the first Console that reads it.
func pooled_readings() -> Dictionary:
	var all := {}
	for each in linked():
		if each.running():
			for key: String in each.readings:
				if not all.has(key):
					all[key] = each.readings[key]
	return all


## How many of each instrument its running system holds, by the stat each
## adds, radios as "radio".
func gear() -> Dictionary:
	var count := {}
	for each in linked():
		if not each.running():
			continue
		for key: String in each._fitted():
			count[key] = count.get(key, 0) + 1
	for radio in radios():
		count["radio"] = count.get("radio", 0) + 1
	return count


## The running radios in its system: its deck gives a Console a voice.
func radios() -> Array[Radio]:
	var found: Array[Radio] = []
	for device in _system():
		var radio := device as Radio
		if radio != null and not radio is SurveyReceiver and radio.powered and not radio.wrecked():
			found.append(radio)
	return found


## Cells across its storm map, by the gear in its system: a radar alone
## draws it coarse, each other kind of instrument finer, a second radar
## finer again. With no radar its other instruments only estimate a map,
## coarser still; with nothing to read, there's none.
func map_cells() -> int:
	var count := gear()
	# Under the sand, not the weather.
	count.erase("ground_radar")
	if count.is_empty():
		return 0
	if not count.has("radar"):
		return _tuning.storm_map_estimate_cells + _tuning.storm_map_estimate_per_instrument * (count.size() - 1)
	var n := _tuning.storm_map_radar_cells + _tuning.storm_map_cells_per_instrument * (count.size() - 1)
	return roundi(n * (_tuning.storm_map_second_radar if count.radar > 1 else 1.0))


## What its screen shows on a page (its own, by default), as text: what you'd
## read there.
func screen_text(on := -1) -> String:
	var shown := _model(page if on < 0 else on as Page, pooled_readings())
	var lines := PackedStringArray()
	for key: String in ["front", "here", "forecast", "wind", "angle", "pressure", "humidity", "sand", "cells"]:
		if shown.get(key, "") != "":
			lines.append(_plain(shown[key]))
	for row: String in shown.get("rows", []):
		lines.append(_plain(row))
	return "\n".join(lines)


## A row as words, its cells a space apart.
static func _plain(row: String) -> String:
	return " ".join(Array(row.trim_prefix("!").split("\t")).filter(func(cell: String) -> bool: return cell != ""))


func _recompute() -> void:
	super()
	if not _awake:
		return
	var now := _fitted()
	for key: String in INSTRUMENTS:
		if now.has(key) != _instruments.has(key):
			_say("%s %s" % [INSTRUMENTS[key], "ONLINE" if now.has(key) else "REMOVED"])
	if now.has("ground_radar") and not _instruments.has("ground_radar") and _root() is Chassis:
		(_root() as Chassis).deeds()
	_instruments = now
	if not now.has("radar"):
		_sweep.resize(0)
		_map.resize(0)
		_map_n = 0
		_swept = false
	_show_display()


func _physics_process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	if not running():
		if not readings.is_empty():
			readings.clear()
		return
	var now := stats()
	var steps := clampi(ceili(world.time_warp), 1, maxi(_tuning.radar_bearings, 1))
	if now.get("radar", 0) > 0:
		for i in steps:
			_sweep_one(now.radar_m)
		if _sampler() == self:
			_map_step(now.radar_m, steps)
	var t := world.time
	if t >= _read_at + _tuning.console_read_every or t < _read_at:
		_read_at = t
		_read(now, t)
		if _lead() == self:
			_watch()


func _process(_delta: float) -> void:
	if not _screened or world == null:
		return
	var aim := -1
	var hands := world.player.hands
	if hands.look_device == self and hands.look_socket == _screen():
		aim = _key_at(_on_screen(hands.look_point), _keys)
	var t := world.time
	if aim == _aim and t < _screen_at + _tuning.console_screen_every and t >= _screen_at:
		return
	_aim = aim
	_screen_at = t
	_draw_screen()


## Its own instruments, by the stat each adds: built into its frame, or fitted.
func _fitted() -> Dictionary:
	var found := {}
	for key: String in INSTRUMENTS:
		if frame_stats.get(key, 0) > 0:
			found[key] = self
	for part in parts():
		for key: String in INSTRUMENTS:
			if part.stats.get(key, 0) > 0:
				found[key] = part
	return found


## Everything in its system, its first Console first: what stands on its
## deck and is seated there, or itself and what's seated on it.
func _system() -> Array[Device]:
	var found: Array[Device] = []
	_gather(_root(), found)
	return found


## What its system stands on: its deck, or itself.
func _root() -> Device:
	var root: Device = self
	while root.host() != null:
		root = root.host()
	return root


## The way its deck points, or off a deck its own front, its screen's: a
## compass bearing.
func _heading() -> float:
	var ahead := _root().global_basis * Vector3.FORWARD
	return Radio.bearing(Vector2(ahead.x, ahead.z))


static func _gather(device: Device, found: Array[Device]) -> void:
	found.append(device)
	for each in device.mounted():
		# Freed under its host, it's gone from its seat by the next tick.
		if is_instance_valid(each):
			_gather(each, found)


## The Console that speaks for its system: the first one running.
func _lead() -> Console:
	for each in linked():
		if each.running():
			return each
	return self


## The Console that samples its system's storm map: the first running one
## with a radar.
func _sampler() -> Console:
	for each in linked():
		if each.running() and each._fitted().has("radar"):
			return each
	return null


## What its own instruments read now, from the field where it stands.
func _read(now: Dictionary, t: float) -> void:
	var field := world.weather.field
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	readings.clear()
	if now.get("anemometer", 0) > 0:
		# It reads the wind as the deck feels it: the field's, less the deck's own way over the sand.
		var wind := field.wind_at(x, z, t)
		var moving := _root().linear_velocity
		var felt := wind - Vector2(moving.x, moving.z)
		readings["wind"] = {"speed": felt.length(), "from": Radio.bearing(-felt), "true_speed": wind.length(),
			"true_from": Radio.bearing(-wind), "moving": Vector2(moving.x, moving.z).length(),
			"steady": field.steady_wind_at(x, z, t).length()}
	if now.get("barometer", 0) > 0:
		var back := _tuning.barometer_trend_seconds
		var raw := field.raw_storm_at(x, z, t)
		var was := field.raw_storm_at(x, z, t - back)
		var rise := (raw - was) / back
		# A rough warning: the trend carried on until the field crosses its threshold.
		var eta := -raw / rise if raw <= 0.0 and rise > 0.0 else INF
		var history := PackedFloat32Array()
		for k in HISTORY:
			history.append(pressure(field.raw_storm_at(x, z, t - (HISTORY - 1 - k) * HISTORY_EVERY)))
		readings["pressure"] = {"hpa": pressure(raw), "per_min": (pressure(raw) - pressure(was)) / back * 60.0,
			"eta": eta if eta <= _tuning.barometer_warn_minutes * 60.0 else INF, "stormy": raw > 0.0, "history": history}
	if now.get("hygrometer", 0) > 0:
		var celsius := world.weather.field_temperature(global_position, t)
		readings["humidity"] = {"share": humidity(celsius, field.raw_storm_at(x, z, t)),
			"condenser_lph": Condenser.yield_lph(_tuning, celsius)}
	if now.get("particle_sensor", 0) > 0:
		readings["sand"] = {"g_m3": sand_of(field, field.raw_storm_at(x, z, t)),
			"was": sand_of(field, field.raw_storm_at(x, z, t - SAND_TREND)), "stormy": field.raw_storm_at(x, z, t) > 0.0}
	if now.get("radar", 0) > 0 and _swept:
		readings["front"] = _front(field, x, z, t, now.radar_m)
	if now.get("ground_radar", 0) > 0:
		readings["ground"] = _survey(x, z, now.ground_radar_m)
	var voices := radios()
	if not voices.is_empty():
		var radio := voices[0]
		if t >= _forecast_at + _tuning.radio_forecast_every or t < _forecast_at or not readings.has("forecast"):
			_forecast_at = t
			var rx := world.world_x(radio.global_position.x)
			var rz := world.world_z(radio.global_position.z)
			var said := Radio.forecast(field, rx, rz, t, _tuning.radio_forecast_minutes * 60.0, Weather.FORECAST_STEP)
			said["t"] = t
			_forecast = said
		readings["forecast"] = _forecast
	Chart.witness(self, t)


## Plugged into the Walker's port: what it holds goes up to it (Chart).
func upload() -> void:
	Chart.upload(self)


## The air's pressure where the storm field stands at `raw`, hPa: it falls as
## a storm comes.
func pressure(raw: float) -> float:
	return _tuning.air_pressure_hpa - _tuning.air_pressure_fall * raw


## Humidity, 0 to 1, in air this warm where the field before its threshold
## stands at `raw`: as much as the condenser's yield gives it in the cold,
## less as the air warms, as the yield falls, and more as a storm nears, most
## in one. The hygrometer's reading and the map's every cell both.
func humidity(celsius: float, raw: float) -> float:
	var near := clampf((raw + _tuning.humidity_reach) / _tuning.humidity_reach, 0.0, 1.0)
	return clampf(_tuning.humidity_cold * Condenser.yield_lph(_tuning, celsius) / _tuning.condenser_litres_per_hour
		+ _tuning.humidity_storm * near, 0.0, 1.0)


## Sand in the air where the field stands at `raw`, g/m³: a storm's,
## thickening from its wall to its heart, as deep in the field as salvage
## counts a storm's heart, or what a front's outflow carries ahead of the wall.
func sand_of(field: WeatherField, raw: float) -> float:
	var deep := clampf(raw / _tuning.exposure_storm_full, 0.0, 1.0)
	return _tuning.sand_full_g_m3 * maxf(field.storm_of(raw) * lerpf(_tuning.sand_wall_share, 1.0, deep),
		_tuning.sand_outflow_share * field.outflow_of(raw))


## The radar's next bearing: out from here until the storm state changes.
func _sweep_one(reach: float) -> void:
	var count := _tuning.radar_bearings
	if _sweep.size() != count:
		_sweep.resize(count)
		_sweep.fill(INF)
		_bearing = 0
	var field := world.weather.field
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var along := _along(TAU * _bearing / count)
	_sweep[_bearing] = edge(field, x, z, world.time, along, reach, _tuning.radar_step_m)
	_bearing = (_bearing + 1) % count
	if _bearing == 0 and not _swept:
		# Round once, it reads at once.
		_swept = true
		_read_at = -INF


## Metres along a way from a place to where the storm state first differs
## from there, to a couple of metres, within reach; INF if it holds.
static func edge(field: WeatherField, x: float, z: float, t: float, along: Vector2, reach: float, step: float) -> float:
	var here := field.raw_storm_at(x, z, t) > 0.0
	var d := step
	while d <= reach:
		if (field.raw_storm_at(x + along.x * d, z + along.y * d, t) > 0.0) != here:
			var lo := d - step
			var hi := d
			while hi - lo > 2.0:
				var mid := (lo + hi) * 0.5
				if (field.raw_storm_at(x + along.x * mid, z + along.y * mid, t) > 0.0) != here:
					hi = mid
				else:
					lo = mid
			return hi
		d += step
	return INF


## The nearest edge the last sweep saw, how far and which way; the way storms
## ride the wind; how soon the storm upwind reaches here at that speed, or
## clears from here; and the sand it brings.
func _front(field: WeatherField, x: float, z: float, t: float, reach: float) -> Dictionary:
	var best := 0
	for i in _sweep.size():
		if _sweep[i] < _sweep[best]:
			best = i
	var inside := field.raw_storm_at(x, z, t) > 0.0
	var d: float = _sweep[best]
	var bearing := 360.0 * best / _sweep.size()
	var moving := field.prevailing_at(t)
	var out := {"inside": inside, "d": d, "bearing": bearing, "reach": reach, "moving": Radio.bearing(moving),
		"speed": moving.length(), "eta": INF, "hits": 0.0}
	if moving.length() > CLOSING:
		var up := -moving.normalized()
		var upwind := edge(field, x, z, t, up, reach, _tuning.radar_step_m)
		out.eta = upwind / moving.length() if upwind < INF else INF
		if not inside and upwind < INF:
			for k in HIT_STEPS:
				var deeper := upwind + HIT_DEPTH * (k + 1) / HIT_STEPS
				out.hits = maxf(out.hits, sand_of(field, field.raw_storm_at(x + up.x * deeper, z + up.y * deeper, t)))
	return out


## Samples its system's storm map a few rows a tick, a whole pass again each
## storm_map_every, at as many cells across as the system's gear allows, each
## cell's storm, sand and humidity from the field's one sample there, as
## sand_of() and humidity() would; the screen draws the last whole pass.
func _map_step(reach: float, rows: int) -> void:
	var n := map_cells()
	var t := world.time
	if n != _map_n or reach != _map_reach:
		_map_n = n
		_map_reach = reach
		_map_row = 0
		_map.resize(0)
		_map_at = -INF
	if _map_row == 0:
		if not _map.is_empty() and t < _map_at + _tuning.storm_map_every and t >= _map_at:
			return
		_map_at = t
		for each: PackedFloat32Array in _next:
			each.resize(n * n)
		# The temperature is straight in the storm's blanket, so the condenser's
		# yield is read clear and under a storm and taken between.
		var full := _tuning.condenser_litres_per_hour
		_yields = Vector2(Condenser.yield_lph(_tuning, world.weather.temperature_under(0.0, t)) / full,
			Condenser.yield_lph(_tuning, world.weather.temperature_under(1.0, t)) / full)
	var field := world.weather.field
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var cell := 2.0 * reach / n
	var tune := _tuning
	var storm: PackedFloat32Array = _next[0]
	var sand: PackedFloat32Array = _next[1]
	var humid: PackedFloat32Array = _next[2]
	for k in rows:
		var dz := (_map_row + 0.5) * 2.0 / n - 1.0
		for i in n:
			var c := _map_row * n + i
			var dx := (i + 0.5) * 2.0 / n - 1.0
			if dx * dx + dz * dz > 1.0:
				storm[c] = -1.0
				continue
			var r := field.raw_storm_at(x - reach + (i + 0.5) * cell, z - reach + (_map_row + 0.5) * cell, t)
			var s := field.storm_of(r)
			storm[c] = s
			sand[c] = maxf(s * lerpf(tune.sand_wall_share, 1.0, clampf(r / tune.exposure_storm_full, 0.0, 1.0)),
				tune.sand_outflow_share * field.outflow_of(r))
			humid[c] = clampf(tune.humidity_cold * lerpf(_yields.x, _yields.y, s)
				+ tune.humidity_storm * clampf((r + tune.humidity_reach) / tune.humidity_reach, 0.0, 1.0), 0.0, 1.0)
		_map_row += 1
		if _map_row == n:
			_map = storm.duplicate()
			_map_sand = sand.duplicate()
			_map_humid = humid.duplicate()
			_map_row = 0
			_map_passes += 1
			return


## A compass bearing's way along the ground, world x and z: north is -z.
static func _along(radians: float) -> Vector2:
	return Vector2(sin(radians), -cos(radians))


## The lead watches the storm for its system: alerts once each as it comes,
## and the smart shields' auto-on.
func _watch() -> void:
	var all := pooled_readings()
	var link := linked().size()
	if link != _linked:
		if link > _linked:
			_say("LINKED · %d CONSOLES" % link)
		_linked = link
	var pressure_now: Dictionary = all.get("pressure", {})
	if pressure_now.get("eta", INF) < INF:
		_once("pressure", "!PRESSURE ▼ · STORM ~%s" % _span(pressure_now.eta))
	elif pressure_now.has("eta"):
		_alerts.erase("pressure")
	var front: Dictionary = all.get("front", {})
	if not front.is_empty():
		if front.inside and not _alerts.has("inside"):
			_alerts["inside"] = true
			var fields := [["CLEARS", _span(front.eta) if front.eta < INF else "past %s" % _distance(front.reach)]]
			if all.has("sand"):
				fields.push_front(["SAND", "%.1f g/m³" % all.sand.g_m3])
			_say("!IN STORM", fields)
		if front.inside:
			_alerts.erase("front")
			_alerts.erase("near")
		elif _alerts.has("inside"):
			_alerts.erase("inside")
			_say("STORM PASSED")
		var near: bool = front.inside or front.d <= _tuning.smart_shield_auto_m
		var where := "FRONT %s %s · %s" % [_distance(front.d), _point(front.bearing), _span(front.eta)]
		if near and not front.inside:
			# Seen first this near, it's said once, as the near one.
			_alerts["front"] = true
			_once("near", "!" + where)
		elif not front.inside:
			_alerts.erase("near")
			if front.d < INF:
				_once("front", where)
			else:
				_alerts.erase("front")
		if near and not _front_near:
			var switched := false
			for shield in smart_shields():
				if shield.smart:
					switched = shield.switch(true) or switched
			if switched:
				_say("!SHIELD AUTO-ON")
		_front_near = near
	for shield in smart_shields():
		var down := shield.on and not shield.running()
		if down and not _shields_down.has(shield):
			_say("!SHIELD DOWN · NO POWER")
		if down:
			_shields_down[shield] = true
		else:
			_shields_down.erase(shield)
	_battery()


## Its pool's charge running out, said aloud: low, then critical, each once as
## what's left to run it on falls past its line (straight past both, only
## critical), and again once it's back over. What's left is the charge above
## where it gives way: Power's reserve while something outranks it, a shield.
func _battery() -> void:
	var share := world.power.pool_share(self)
	if is_nan(share):
		return
	var dark_at := world.power.gives_way_at(self)
	var left := (share - dark_at) / (1.0 - dark_at)
	if left >= _tuning.console_battery_critical + REARM:
		_alerts.erase("battery_critical")
	if left >= _tuning.console_battery_low + REARM:
		_alerts.erase("battery_low")
	if left < _tuning.console_battery_critical:
		if not _alerts.has("battery_critical"):
			_alerts["battery_critical"] = true
			_alerts["battery_low"] = true
			_say("!BATTERY CRITICAL · %d%%" % roundi(share * 100.0), [], "Battery critical.")
	elif left < _tuning.console_battery_low and not _alerts.has("battery_low"):
		_alerts["battery_low"] = true
		_say("!BATTERY LOW · %d%%" % roundi(share * 100.0), [], "Battery low.")


func _once(key: String, text: String) -> void:
	if not _alerts.has(key):
		_alerts[key] = true
		_say(text)


## A line of its own to its terminal, or a form with these fields, and a
## radio seated in its system gives it a voice: its tones, then `aloud` said
## in the radio's.
func _say(text: String, fields := [], aloud := "") -> void:
	var lead := _lead()
	var t := world.time if world != null else 0.0
	if fields.is_empty():
		lead.terminal.log_line(SENDER, text, t, _clock(t))
	else:
		lead.terminal.form(SENDER, text, fields, t, _clock(t))
	for device in _system():
		var radio := device as Radio
		if radio != null and not radio is SurveyReceiver and radio.powered and not radio.wrecked() and radio.is_inside_tree():
			Sounds.play_at(radio, Sounds.RADIO_TONES, -8.0, Radio.HEARD)
			if aloud != "":
				radio.announce(PackedStringArray([aloud]))
			break


## Which key a spot on the screen is on, 0 to 1 across and down, or -1.
static func _key_at(at: Vector2, on: Array) -> int:
	var spot := at * Vector2(PIXELS)
	for k in on.size():
		if (on[k].box as Rect2).has_point(spot):
			return k
	return -1


## Where a point in the world lies on the screen's picture, 0 to 1 across and down.
func _on_screen(point: Vector3) -> Vector2:
	var screen := _screen()
	if screen == null:
		return Vector2(-1.0, -1.0)
	var local := (global_transform * screen.transform).affine_inverse() * point
	return Vector2(local.x / PICTURE.x + 0.5, 0.5 - local.y / PICTURE.y)


## Its screen port, with its screen in it, or null.
func _screen() -> Socket:
	for socket in sockets():
		if socket.kind == &"screen" and socket.part != null and socket.part.stats.get("screen", 0) > 0:
			return socket
	return null


## A screen fitted gets its picture; taken out, the picture is hidden and
## kept, never freed and made again.
func _show_display() -> void:
	var screen := _screen()
	var was := _screened
	_screened = screen != null
	if not _screened:
		if _display != null:
			_display.visible = false
			_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if _display == null:
		_viewport = SubViewport.new()
		_viewport.size = PIXELS
		_viewport.disable_3d = true
		_viewport.transparent_bg = false
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(_viewport)
		_view = ConsoleScreen.new()
		_view.size = PIXELS
		_viewport.add_child(_view)
		_display = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = PICTURE
		_display.mesh = quad
		var glass := StandardMaterial3D.new()
		glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass.albedo_texture = _viewport.get_texture()
		_display.material_override = glass
		_display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_display)
	var face: float = Catalog.PARTS[screen.part.get_meta(&"catalog")].size.z
	_display.transform = screen.transform * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, face + 0.002))
	if not was:
		_shown = ""
	_screen_at = -INF


## Draws the screen if what it shows has changed, and only for someone near
## enough to read it.
func _draw_screen() -> void:
	var lit := running()
	_display.visible = lit
	if not lit:
		return
	var eye := world.player.camera.global_position
	if eye.distance_to(global_position) > _tuning.console_screen_seen_m and _shown != "":
		return
	var shown := _model(page, pooled_readings())
	var cells: Dictionary = shown.get("map", {}).get("cells", {})
	if not cells.is_empty():
		# A radar's map is told apart by its pass; the arrays stay out of the comparison.
		shown.map.erase("cells")
	var said := str(shown)
	if said == _shown:
		return
	_shown = said
	if not cells.is_empty():
		shown.map["cells"] = cells
	_keys = shown.keys
	_view.show_model(shown)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## What a page shows, its tabs and its keys laid out on it. The Map's: what
## each filter on draws and each reading's text as it reads there. The
## power page's: the deck's electrics. The others': rows as its terminal
## prints them, a table's cells apart by tabs.
func _model(on: Page, all: Dictionary) -> Dictionary:
	var shown := {"page": PAGE_NAMES[on], "clock": _clock(world.time, true), "aim": _aim,
		"flip": world.moon.north().z > 0.0, "tabs": TABS.map(func(p: Page) -> Dictionary:
			return {"text": PAGE_NAMES[p], "lit": p == on, "act": _go.bind(p), "device": null, "to": p})}
	match on:
		Page.MAP:
			_map_page(shown, all)
		Page.STATS:
			terminal.readout(SENDER, _readout(all))
			var rows := PackedStringArray()
			for from: String in terminal.readouts:
				rows.append_array(terminal.readouts[from])
			shown["rows"] = rows
			if all.has("wind"):
				shown["gyro"] = _gyro(all.wind)
			if all.has("pressure"):
				shown["history"] = [all.pressure.history, _tuning.air_pressure_hpa]
		Page.POWER:
			_panel(shown, all)
		Page.LOG:
			var rows := PackedStringArray()
			for line: Dictionary in Terminal.merged(linked().map(func(c: Console) -> Terminal: return c.terminal), 18):
				rows.append(_logged(line))
			shown["rows"] = rows if not rows.is_empty() else PackedStringArray([" nothing logged"])
	ConsoleScreen.lay_out(shown)
	return shown


func _go(to: Page) -> void:
	page = to


## The Map's filters its system can feed: the weather from any instrument
## that reads it, the survey from a ground radar, and navigation once there's
## something to steer by, a noted bearing or a Home fix.
func filters(all: Dictionary) -> Array:
	var can := []
	if map_cells() > 0:
		can.append("weather")
	if all.has("ground"):
		can.append("survey")
	if not bearings.is_empty() or (world.home != null and not is_nan(world.home.nav().metres)):
		can.append("nav")
	return can


func _filter(name: String) -> void:
	if name in filters_off:
		filters_off.erase(name)
	else:
		filters_off.append(name)


## The Map: a switch for each filter its system can feed, and each one on laid
## over it, the map reaching as far as the nearest of them so each stays
## readable; what lies past its edge is pinned there.
func _map_page(shown: Dictionary, all: Dictionary) -> void:
	var can := filters(all)
	shown["filters"] = can.map(func(f: String) -> Dictionary:
		return {"text": FILTERS[f], "lit": not f in filters_off, "act": _filter.bind(f), "device": null, "to": f})
	if can.is_empty():
		shown["here"] = "NO INSTRUMENTS"
		return
	var on := can.filter(func(f: String) -> bool: return not f in filters_off)
	var reach := INF
	var rows := PackedStringArray()
	if "weather" in on:
		_radar(shown, all)
		reach = minf(reach, shown.get("map", {}).get("reach", INF))
	if "survey" in on:
		shown["survey"] = all.ground
		rows.append_array(_survey_rows(all.ground))
		reach = minf(reach, all.ground.reach)
	if "nav" in on:
		var chart := Chart.layer(self)
		shown["chart"] = chart
		rows.append_array(chart.rows)
		reach = minf(reach, chart.reach)
	shown["rows"] = rows
	if reach < INF:
		shown["reach"] = reach
		shown["span"] = "%s across" % _distance(reach * 2.0)


## The gyro as a compass: the wind as the deck feels it, which way and how
## strong, the way the deck points, and the wind's angle off its bow, as a
## sailor trims to it: plus to starboard, minus to port. And Tu-ward, unless
## Tu stands overhead or right underfoot, where every way is.
func _gyro(wind: Dictionary) -> Dictionary:
	var heading := _heading()
	var off := wrapf(wind.from - heading, -180.0, 180.0)
	var shown := {"from": wind.from, "speed": wind.speed, "steady": wind.steady, "heading": heading, "off": off,
		"angle": ("%d° %s" % [roundi(absf(off)), _side(off)]).strip_edges()}
	var tu := tu_ward()
	if not is_nan(tu):
		shown["tu"] = tu
	return shown


## Tu-ward: the great-circle bearing from where it stands toward the point
## under Tu, whole degrees as its other bearings are kept (north -z), which it
## knows from where it is on the moon, so on the far side too. NAN within a
## degree of the point under Tu or the one opposite.
func tu_ward() -> float:
	var moon := world.moon
	var here := Sphere.point(moon.latitude, moon.longitude)
	var under := world.weather.day.sub_tu(world.time)
	if absf(here.dot(under)) > cos(deg_to_rad(1.0)):
		return NAN
	var bearing := rad_to_deg(Sphere.bearing(here, under))
	# Past a pole the ground's north is +z.
	return float(roundi(fposmod(bearing if moon.north().z < 0.0 else bearing + 180.0, 360.0)) % 360)


## Which side of the bow a wind this far off it comes from, or none dead ahead or astern.
static func _side(off: float) -> String:
	return "" if roundi(absf(off)) in [0, 180] else ("STBD" if off > 0.0 else "PORT")


## The Map's weather: its storm map at the system's resolution, humidity laid
## over its clear air, the front's numbers where the front is, the anomalies
## once the Walker's taught, and round it the wind's gyro, the pressure's bar
## and the forecast along its foot.
func _radar(shown: Dictionary, all: Dictionary) -> void:
	var n := map_cells()
	shown["cells"] = "" if n == 0 else "%d × %d" % [n, n]
	if n == 0:
		shown["here"] = "NO INSTRUMENTS"
		return
	var map := {"n": n, "estimate": not gear().has("radar")}
	var front: Dictionary = all.get("front", {})
	if map.estimate:
		_estimate(map, all)
		var eta: float = all.get("pressure", {}).get("eta", INF)
		if map.has("front"):
			shown["front"] = "~%s · ~%s" % [_distance((map.front as Vector2).length()), _span(eta)]
		elif eta < INF:
			shown["front"] = "STORM ~%s" % _span(eta)
		if map.cells.storm[map.cells.storm.size() / 2] > 0.0:
			shown["here"] = "IN STORM"
	else:
		var sampler := _sampler()
		if sampler == null or sampler._map.size() != n * n:
			shown["here"] = "SWEEPING"
			return
		map["reach"] = sampler._map_reach
		map["pass"] = sampler._map_passes
		map["cells"] = {"storm": sampler._map, "sand": sampler._map_sand,
			"humid": sampler._map_humid if all.has("humidity") else PackedFloat32Array()}
		if not front.is_empty():
			if front.inside:
				shown["here"] = "IN STORM · CLEARS %s" % _span(front.eta)
			elif front.d < INF:
				map["front"] = _along(deg_to_rad(front.bearing)) * front.d
				shown["front"] = "%s · %s" % [_distance(front.d), _span(front.eta)]
	shown["map"] = map
	map["anomalies"] = Chart.anomalies(self, map.get("reach", 0.0))
	if all.has("wind"):
		shown["wind"] = "%d m/s %s" % [roundi(all.wind.speed), _point(all.wind.from)]
		map["gyro"] = _gyro(all.wind)
		shown["angle"] = map.gyro.angle
	if all.has("pressure"):
		var p: Dictionary = all.pressure
		shown["pressure"] = _row("PRESS", "%d" % roundi(p.hpa), "hPa", _trend(p.per_min, 0.05))
		map["pressure"] = [p.hpa, _tuning.air_pressure_hpa, _tuning.air_pressure_fall, p.eta < INF or p.stormy]
	if all.has("humidity"):
		shown["humidity"] = _row("HUMID", "%d" % roundi(all.humidity.share * 100.0), "%")
	if all.has("sand"):
		shown["sand"] = _row("SAND", "%.2f" % all.sand.g_m3, "g/m³")
		map["sand"] = true
	if all.has("forecast"):
		var r: Dictionary = all.forecast
		var now: float = world.time
		if r.stormy:
			shown["forecast"] = "IN STORM · CLEARS %s" % (_span(r.change - now) if r.change < INF else "PAST %d MIN" % roundi(_tuning.radio_forecast_minutes))
		elif r.change == INF:
			shown["forecast"] = "CLEAR %d MIN AND MORE" % roundi(_tuning.radio_forecast_minutes)
		else:
			shown["forecast"] = "STORM IN %s FROM %s" % [_span(r.change - now), _point(r.from)]


## The ground radar's sweep, a reading: the old lines under the sand within
## its reach, and every structure standing on the ground or under it there
## and each big dune's ruin it finds, built or still only a seed, nearest
## first, as {at, m east and south of it; name; m of sand over it, 0 once
## dug out; bared, a storm laying it bare now; dune, a dune's ruin}. Its
## place is watched while it runs, so the dunes' ruins round it are looked
## at whatever your pace.
func _survey(x: float, z: float, reach: float) -> Dictionary:
	var sites := world.shape.sites
	sites.dunes.watch(get_instance_id(), x, z, reach, world.time)
	var lines := []
	for piece in sites.paths_in(Rect2(x - reach, z - reach, reach * 2.0, reach * 2.0)):
		var points := PackedVector2Array()
		for p in piece.points:
			points.append(p - Vector2(x, z))
		lines.append(points)
	var bare := {}
	for each: Array in sites.newly_exposed(x, z, reach):
		bare[each[0]] = true
	var found := []
	for site in sites.query(Rect2(x - reach, z - reach, reach * 2.0, reach * 2.0), false):
		var each := site as Structure
		if each == null or not each.stands() or each.yields == 1 or each.distance_to(x, z) > reach \
				or each.era == Eras.GEOLOGY:
			continue
		found.append({"at": Vector2(each.x - x, each.z - z), "name": _site_name(each), "under": maxf(each.depth - each.taken(), 0.0),
			"bared": bare.has(each), "dune": each.source == &"dune"})
	for seed in sites.dunes.near(x, z, reach):
		if not seed.built:
			found.append({"at": Vector2(seed.site.x - x, seed.site.z - z), "name": _site_name(seed.site),
				"under": maxf(seed.site.depth - seed.taken, 0.0), "bared": seed.level > 0.0, "dune": true})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at.length() < b.at.length())
	return {"reach": reach, "sites": found, "lines": lines}


static func _site_name(site: Structure) -> String:
	return "DUNE RUIN" if site.source == &"dune" else String(site.kind).replace("_", " ").to_upper()


## The ground radar's nearest under the Map: each one's name, how far and
## which way, and under it the sand over it, "bared" or "dug out".
func _survey_rows(ground: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for each: Dictionary in ground.sites.slice(0, SURVEY_ROWS):
		var at: Vector2 = each.at
		rows.append(("!" if each.bared else "") + _row(each.name, _distance_parts(at.length())[0],
			_distance_parts(at.length())[1], _point(Radio.bearing(at))))
		if each.bared:
			rows.append("!" + _row(" bared now"))
		elif each.under <= 0.0:
			rows.append(_row(" dug out"))
		else:
			rows.append(_row(" sand over", "%.1f" % each.under, "m"))
	if rows.is_empty():
		rows.append("nothing within %s" % _distance(ground.reach))
	return rows


## With no radar, the map as its other instruments estimate it: here as it
## is, and a storm the barometer expects coming on the wind, as far upwind as
## the wind carries it before it arrives, across the whole way it comes.
func _estimate(map: Dictionary, all: Dictionary) -> void:
	var n: int = map.n
	map["reach"] = ESTIMATE_REACH
	var storm := PackedFloat32Array()
	var sand := PackedFloat32Array()
	var humid := PackedFloat32Array()
	storm.resize(n * n)
	storm.fill(-1.0)
	sand.resize(n * n)
	humid.resize(n * n)
	humid.fill(-1.0)
	var here := -1.0
	if all.has("pressure"):
		here = 1.0 if all.pressure.stormy else 0.0
	elif all.has("sand"):
		here = 1.0 if all.sand.stormy else 0.0
	var middle := (n / 2) * n + n / 2
	storm[middle] = here
	if all.has("sand"):
		sand[middle] = all.sand.g_m3 / _tuning.sand_full_g_m3
	var coming := INF
	var from := Vector2.ZERO
	if all.has("wind") and all.has("pressure"):
		# Storms ride the wind over the sand, not as the deck feels it.
		from = _along(deg_to_rad(all.wind.true_from))
		coming = all.pressure.eta * all.wind.true_speed
		for j in n:
			for i in n:
				var k := j * n + i
				if k == middle:
					continue
				var at := Vector2(i + 0.5 - n * 0.5, j + 0.5 - n * 0.5) * (2.0 * ESTIMATE_REACH / n)
				storm[k] = 1.0 if at.dot(from) >= coming else 0.0
		if coming < INF:
			map["front"] = from * coming
	if all.has("humidity"):
		var clear := world.weather.temperature_under(0.0)
		var under := world.weather.temperature_under(1.0)
		for k in n * n:
			if storm[k] >= 0.0:
				# Estimated, a cell is the field's threshold or far below it.
				humid[k] = humidity(lerpf(clear, under, storm[k]), 0.0 if storm[k] > 0.0 else -INF)
	map["cells"] = {"storm": storm, "sand": sand, "humid": humid}


## Its stats: every reading in detail, as a table: a label, then a number,
## its unit and a note, a row or two each, rows under a reading indented, a
## "!" before what's urgent; and each smart shield's line and its load.
func _readout(all: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	if all.is_empty():
		rows.append_array(["NO INSTRUMENTS", " fit a computer mod", " to a side port"])
	if all.has("wind"):
		var w: Dictionary = all.wind
		# Its angle off the bow is written by the gyro under the table.
		rows.append(_row("WIND", "%.1f" % w.speed, "m/s", _point(w.from)))
		if w.moving >= STILL:
			rows.append(_row(" true", "%.1f" % w.true_speed, "m/s", _point(w.true_from)))
		rows.append(_row(" steady", "%.1f" % w.steady, "m/s"))
	if all.has("pressure"):
		var p: Dictionary = all.pressure
		rows.append(_row("PRESS", "%.1f" % p.hpa, "hPa", _trend(p.per_min, 0.05)))
		rows.append(_row(" trend", "%.1f" % absf(p.per_min), "hPa/min"))
		if p.eta < INF:
			rows.append("!" + _row(" storm", "~" + _span_parts(p.eta)[0], _span_parts(p.eta)[1]))
	if all.has("humidity"):
		rows.append(_row("HUMID", "%d" % roundi(all.humidity.share * 100.0), "%"))
		rows.append(_row(" condenser", "%.1f" % all.humidity.condenser_lph, "L/h"))
	if all.has("sand"):
		var g: float = all.sand.g_m3
		rows.append(("!" if g >= _tuning.sand_full_g_m3 * 0.5 else "") + _row("SAND", "%.2f" % g, "g/m³",
			_trend(g - all.sand.was, 0.01)))
	if all.has("ground"):
		var sites: Array = all.ground.sites
		rows.append(_row("GROUND", "%d" % sites.size(), "found", "%d bared" % sites.filter(
			func(each: Dictionary) -> bool: return each.bared).size()))
	if all.has("front"):
		var f: Dictionary = all.front
		var moving := _row(" moving", "%d" % roundi(f.speed), "m/s", _point(f.moving))
		if f.inside:
			rows.append("!" + _row("STORM", "", "", "here"))
			rows.append(_row(" clears", _span_parts(f.eta)[0], _span_parts(f.eta)[1]) if f.eta < INF
				else _row(" upwind", ">" + _distance_parts(f.reach)[0], _distance_parts(f.reach)[1]))
			if f.d < INF:
				rows.append(_row(" clear air", _distance_parts(f.d)[0], _distance_parts(f.d)[1], _point(f.bearing)))
			rows.append(moving)
		elif f.d < INF:
			rows.append(("!" if f.d <= _tuning.smart_shield_auto_m else "")
				+ _row("FRONT", _distance_parts(f.d)[0], _distance_parts(f.d)[1], _point(f.bearing)))
			rows.append(_row(" eta", _span_parts(f.eta)[0], _span_parts(f.eta)[1]))
			rows.append(moving)
			if all.has("sand") and f.eta < INF:
				rows.append(_row(" hits", "%.1f" % f.hits, "g/m³"))
		else:
			rows.append(_row("FRONT", "none"))
			rows.append(_row(" reach", _distance_parts(f.reach)[0], _distance_parts(f.reach)[1]))
	if all.has("forecast"):
		var r: Dictionary = all.forecast
		var past := PackedStringArray([">%d" % roundi(_tuning.radio_forecast_minutes), "min"])
		var now: float = world.time
		if r.stormy:
			var clears := _span_parts(r.change - now) if r.change < INF else past
			rows.append(_row("FCST", clears[0], clears[1], "clears" if r.change < INF else "storm"))
		elif r.change == INF:
			rows.append(_row("FCST", past[0], past[1], "clear"))
		else:
			var lasts := _span_parts(r.back - r.change) if r.back < INF else past
			rows.append(_row("FCST", _span_parts(r.change - now)[0], _span_parts(r.change - now)[1], "storm"))
			rows.append(_row(" from", "", "", _point(r.from)))
			rows.append(_row(" winds", "%d" % roundi(r.wind), "m/s"))
			rows.append(_row(" lasts", lasts[0], lasts[1]))
	for shield in smart_shields():
		var dark := shield.on and not shield.running()
		rows.append(("!" if dark else "") + _row(_name(shield), "%d" % roundi(shield.demand_w() if shield.running() else 0.0),
			"W", "NO PWR" if dark else _mode(shield, all.has("front"))))
		if shield.running():
			# What it holds back, read off the shield, not the field: past a full
			# storm's, while the wind and sand read ordinary, is an anomaly.
			var bears := shield.particle_load()
			rows.append(("!" if bears > 1.0 else "") + _row(" load", "%d" % roundi(bears * 100.0), "%"))
			if bears > 1.0 and world.player.camera.global_position.distance_to(global_position) \
					<= _tuning.console_screen_seen_m:
				Deeds.done(world, &"tells", &"load")
	return rows


## A table's row as a terminal prints it: its label, number, unit and note,
## apart by tabs.
static func _row(label: String, number := "", unit := "", note := "") -> String:
	return "\t".join([label, number, unit, note])


## A trend as a small arrow: up, down, or steady within `still`.
static func _trend(by: float, still: float) -> String:
	return "▲" if by > still else ("▼" if by < -still else "–")


## The deck's electrics, its power pool: what makes power, each power box
## with its bays as they stand, the batteries and their charge, and what
## draws it, each with its watts, and a row of switches for each way a device
## can be worked: a shield's off, on or smart, a radio's dial, a tray floating
## or resting, a lamp on or off. Each switch works the device as its own use
## would. A box that lets it ranks each draw and switches it off here, and a
## colonial cabinet's bays are set here too, held to charge or supplying.
func _panel(shown: Dictionary, all: Dictionary) -> void:
	var pool := world.power.pool_of(self)
	var can := world.power.control(pool)
	var places := _places(pool, can)
	var order: Array[Device] = []
	for device in _system():
		if device in pool:
			order.append(device)
	for device: Device in pool:
		if not device in order:
			order.append(device)
	var sources := []
	var boxes := []
	var loads := []
	var makes := 0.0
	var draws := 0.0
	var held := 0.0
	var room := 0.0
	for device in order:
		var called := _name(device)
		var now := device.stats()
		for cell in device.supplies():
			held += cell.charge_wh
			room += cell.capacity()
		if now.solar_w > 0.0 or now.turbine_w > 0.0:
			var made := device.production_w()
			makes += made
			sources.append({"row": _row(" " + called, "%d" % roundi(made), "W")})
		if device is PowerBox:
			boxes.append(_box(device as PowerBox, called))
		var groups := _switches(device, called, all.has("front"), can)
		var drawn := device.demand_w() if device.powered else 0.0
		if drawn > 0.0 or not groups.is_empty():
			draws += drawn
			# A smart shield says whether it's up now: its switch says only that it's smart.
			var shield := device as ShieldGenerator
			var off: bool = can.switches and device.switched_off
			var note := "OFF" if off else ("DARK" if not device.powered else ("ON" if shield != null and shield.on
				and _mode(shield, all.has("front")) == "SMART" else ""))
			var named := ("%d %s" % [places[device], called]) if can.ranks else called
			loads.append({"row": _row(" " + named, "%d" % roundi(drawn), "W", note),
				"dark": not device.powered, "groups": groups})
	var net := makes - draws
	var left := INF
	if net < 0.0:
		left = held / -net * 3600.0
	elif net > 0.0:
		left = (room - held) / net * 3600.0
	var bank := {"share": held / room if room > 0.0 else 0.0,
		"row": _row("BANK", "%d" % roundi(100.0 * held / room), "%", "%d Wh" % floori(held)) if room > 0.0
			else _row("BANK", "none"),
		"net": _row(" net", "%+d" % roundi(net), "W"),
		"left": _row(" full" if net > 0.0 else " left", _span_parts(left)[0], _span_parts(left)[1])}
	if _first_load >= loads.size():
		_first_load = 0
	shown["panel"] = {"makes": _row("OUTPUT", "%d" % roundi(makes), "W"), "sources": sources, "boxes": boxes,
		"bank": bank, "draws": _row("DRAWS", "%d" % roundi(draws), "W"), "loads": loads, "first": _first_load,
		"more": {"text": "", "lit": false, "act": _page_loads, "device": null, "to": &"more"}}
	var rows := PackedStringArray([shown.panel.makes])
	for source: Dictionary in sources:
		rows.append(source.row)
	for box: Dictionary in boxes:
		rows.append(box.row)
		for bay: Dictionary in box.bays:
			rows.append(bay.line)
	rows.append_array(PackedStringArray([bank.row, bank.net, bank.left, shown.panel.draws]))
	for load: Dictionary in loads:
		var lit := PackedStringArray()
		for group: Array in load.groups:
			for key: Dictionary in group:
				if key.lit:
					lit.append(key.text)
		rows.append(load.row + (" " + " ".join(lit) if not lit.is_empty() else ""))
	shown["rows"] = rows


## A power box on the page: its row, its charge as its own, and each bay as
## it stands, exactly: how full, which way and how hard it flows, or held,
## dead or empty. A cabinet's bays are keys that hold them or let them supply.
func _box(box: PowerBox, called: String) -> Dictionary:
	var bays := []
	var held := 0.0
	var room := 0.0
	var all := box.bays()
	for i in all.size():
		var cell := all[i].part as Battery
		var bay := {"state": 2 if all[i].kind == PowerBox.DEAD else (3 if cell == null else (1 if box.is_held(i) else 0)),
			"share": 0.0, "flow": 0.0, "pct": "DEAD" if all[i].kind == PowerBox.DEAD else "—", "w": ""}
		if cell != null:
			held += cell.charge_wh
			room += cell.capacity()
			bay.share = cell.charge_wh / maxf(cell.capacity(), 1e-9)
			bay.flow = cell.flow_w
			bay.pct = "%d%%" % roundi(bay.share * 100.0)
			bay.w = "%+dW" % roundi(cell.flow_w)
		bay["line"] = _row("  BAY %d" % (i + 1), bay.pct.trim_suffix("%"), "%" if cell != null else "",
			("HOLD " if bay.state == 1 else "") + bay.w)
		if box.model().get("screen_bays", false) and bay.state < 2:
			bay["key"] = {"text": "", "lit": bay.state == 1, "act": _hold_bay.bind(box, i, called), "device": box, "to": i}
		bays.append(bay)
	return {"row": _row(" " + called, "%d" % roundi(100.0 * held / room), "%", "%d Wh" % floori(held)) if room > 0.0
		else _row(" " + called, "none"), "bays": bays}


## Where each device in a pool stands in who's served first, 1 the first.
func _places(pool: Array, can: Dictionary) -> Dictionary:
	var levels: Array[int] = []
	for device: Device in pool:
		var rank := Power.rank_in(device, can)
		if not levels.has(rank):
			levels.append(rank)
	levels.sort()
	levels.reverse()
	var places := {}
	for device: Device in pool:
		places[device] = levels.find(Power.rank_in(device, can)) + 1
	return places


## A device's switches on the power page, a row of keys for each way it can
## be worked, the one lit that says how it stands; and as its pool's boxes
## allow, its rank up and down and its own switch, joining a row with room.
func _switches(device: Device, called: String, radar: bool, can := {}) -> Array:
	var groups := []
	if device.wrecked():
		return groups
	var keys := func(tos: Array, lit: Variant, texts: Array, act: Callable) -> Array:
		var row := []
		for i in tos.size():
			row.append({"text": texts[i], "lit": tos[i] == lit, "act": act.bind(device, tos[i], called, texts[i]),
				"device": device, "to": tos[i]})
		return row
	var shield := device as ShieldGenerator
	if shield != null:
		var modes := [&"off", &"on"]
		if radar and shield in smart_shields():
			modes.append(&"smart")
		groups.append(keys.call(modes, StringName(_mode(shield, radar).to_lower()), modes.map(func(m: StringName) -> String:
			return String(m).to_upper()), _set_shield))
	var radio := device as Radio
	if radio != null:
		# The dial's own controls: its switch, use's sweep and its volume knob.
		groups.append(keys.call([&"off", &"on"], &"on" if radio.on else &"off", ["OFF", "ON"], _switch_radio)
			+ keys.call([&"sweep", &"quieter", &"louder"], &"", ["SWEEP", "VOL -", "VOL +"], _work_dial))
	if device.has_tray() and device.host() == null:
		groups.append(keys.call([&"float", &"rest"], &"rest" if device.resting else &"float", ["FLOAT", "REST"], _rest))
	if device.lamp_w() > 0.0:
		groups.append(keys.call([true, false], device.lamps, ["LAMP ON", "LAMP OFF"], _lamps))
	if not (device.demand_w() > 0.0 or not groups.is_empty() or device.switched_off):
		return groups
	var circuit := []
	if can.get("ranks", false):
		circuit += keys.call([&"rank_up", &"rank_down"], &"", ["PRI +", "PRI -"], _rank)
	# What has a switch of its own is switched there; a Console never blinds itself.
	if can.get("switches", false) and groups.is_empty() and not device is Console:
		circuit += keys.call([&"switch_on", &"switch_off"], &"switch_off" if device.switched_off else &"switch_on",
			["ON", "OFF"], _switch)
	if circuit.is_empty():
		return groups
	for group: Array in groups:
		if group.size() + circuit.size() <= 5 and group.all(func(k: Dictionary) -> bool: return k.text.length() <= 5):
			group.append_array(circuit)
			return groups
	groups.append(circuit)
	return groups


## How a shield stands on the screen: smart, with a radar to be smart by, or on or off.
func _mode(shield: ShieldGenerator, radar: bool) -> String:
	return "SMART" if radar and shield.smart and shield in smart_shields() else ("ON" if shield.on else "OFF")


## A shield's switch: off and on as use at it would, smart to switch itself
## on as a front nears, and on at once if one is near now.
func _set_shield(shield: ShieldGenerator, to: StringName, called: String, text: String) -> void:
	shield.smart = to == &"smart"
	var up := shield.on or _lead()._front_near if shield.smart else to == &"on"
	if up != shield.on and not shield.switch(up):
		_say("!%s · NO POWER" % called)
		return
	_say("%s %s" % [called, text])


func _switch_radio(radio: Radio, to: StringName, called: String, text: String) -> void:
	if radio.switch(to == &"on"):
		_say("%s %s" % [called, text])


func _work_dial(radio: Radio, to: StringName, called: String, _text: String) -> void:
	if to == &"sweep":
		radio.sweep()
	elif not radio.turn_volume(1 if to == &"louder" else -1):
		return
	_say("%s %s" % [called, (radio.dial_reading().to_upper() if radio.on else "OFF") if to == &"sweep"
		else "VOL %d%%" % roundi(radio.volume * 100.0)])


func _rest(device: Device, to: StringName, called: String, text: String) -> void:
	if device.rest(to == &"rest"):
		_say("%s %s" % [called, text])


func _lamps(device: Device, on: bool, called: String, text: String) -> void:
	if device.switch_lamps(on):
		_say("%s %s" % [called, text])


## Ranks a device one up or down in who its pool serves first.
func _rank(device: Device, to: StringName, called: String, _text: String) -> void:
	var pool := world.power.pool_of(self)
	var can := world.power.control(pool)
	var now := Power.rank_in(device, can)
	device.priority = clampi(now + (1 if to == &"rank_up" else -1), 0, MOST_RANK)
	if device.priority != now:
		_say("%s PRI %d" % [called, _places(pool, can)[device]])


## Switches a device off at the box, a draw its pool skips, or on again.
func _switch(device: Device, to: StringName, called: String, text: String) -> void:
	var off := to == &"switch_off"
	if off != device.switched_off:
		device.switched_off = off
		_say("%s %s" % [called, text])


## A cabinet's bay held to charge only, or let supply.
func _hold_bay(box: PowerBox, i: int, called: String) -> void:
	if box.hold(i, not box.is_held(i)):
		_say("%s BAY %d %s" % [called, i + 1, "CHARGE" if box.is_held(i) else "SUPPLY"])


## The power page shows its next loads, from the first again after the last.
func _page_loads(to: int) -> void:
	_first_load = to


## What the screen calls a device: its catalog's short name, or its label.
static func _name(device: Device) -> String:
	return Catalog.DEVICES.get(device.get_meta(&"catalog", &""), {}).get("short", device.label).to_upper()


## A logged line as a row: its time, and its sender if that's not a
## Console, as its lead, then what it said, urgent if it was; a form's fields
## run on under its title. A Console's own lines fit the screen's row.
static func _logged(line: Dictionary) -> String:
	var text: String = line.text
	if text.begins_with("  "):
		return "\t" + text.substr(2)
	var stamp: String = line.at if line.from == SENDER else "%s %s" % [line.at, line.from]
	return ("!" if text.begins_with("!") else "") + stamp + "\t" + text.trim_prefix("!")


## A bearing as a Console prints it, by the moon's north where it stands, as a
## compass reads it.
func _point(degrees: float) -> String:
	var turned := degrees if world == null or world.moon.north().z < 0.0 else degrees + 180.0
	return POINTS[roundi(fposmod(turned, 360.0) / 22.5) % POINTS.size()]


static func _distance(m: float) -> String:
	return " ".join(_distance_parts(m))


## A distance as a number and its unit, as a table sets them apart.
static func _distance_parts(m: float) -> PackedStringArray:
	return PackedStringArray(["%d" % (roundi(m / 10.0) * 10), "m"] if m < 1000.0 else ["%.1f" % (m / 1000.0), "km"])


static func _span(seconds: float) -> String:
	return "—" if seconds == INF else " ".join(_span_parts(seconds))


## A span of time as a number and its unit: seconds, minutes, then hours.
static func _span_parts(seconds: float) -> PackedStringArray:
	if seconds == INF:
		return PackedStringArray(["—", ""])
	if seconds < 90.0:
		return PackedStringArray(["%d" % maxi(0, roundi(seconds)), "s"])
	if seconds < 5400.0:
		return PackedStringArray(["%d" % roundi(seconds / 60.0), "min"])
	return PackedStringArray(["%.1f" % (seconds / 3600.0), "h"])


## The local time of day, as the screen shows it, its day too if asked.
func _clock(t: float, with_day := false) -> String:
	if world == null:
		return "--:--"
	var day := world.weather.day
	var hours := day.time_of_day(t, world.moon.longitude) * 24.0
	var at := "%02d:%02d" % [floori(hours), floori(fmod(hours, 1.0) * 60.0)]
	return "D%d %s" % [day.day(t, world.moon.longitude, world.began), at] if with_day else at
