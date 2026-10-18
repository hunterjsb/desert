class_name Console
extends Device
## The camp's computer: a rack standing tall, its whole front a screen. Its
## computer mods each read the weather field itself, never the felt weather,
## so a bubble doesn't blind them: the field has no pressure, humidity or
## sand, so those are derived from it (Tuning, Console). Every Console
## standing on one deck is one system, its instruments pooled. Its screen
## leads with the storm map, which takes in all the system reads: the more
## gear, the finer it is, and with less it coarsens, never going. Then every
## reading in detail, a smart shield's form, and its log. A shield in the
## system is smart: the screen reports it and switches it, and with a radar
## it switches itself on as a front nears. Its messages go out through its
## Terminal, and its screen draws only when what it shows has changed. Use on
## the screen presses the key you aim at, and anywhere else on it steps the
## page; use at the frame works its tray.

## Its pages, numbered as older saves knew them, and the order use steps
## through them.
enum Page { RADAR, SHIELD, LOG, STATS }
const ORDER: Array[Page] = [Page.RADAR, Page.STATS, Page.SHIELD, Page.LOG]
const PAGE_NAMES := ["RADAR", "SHIELD", "LOG", "STATS"]
## The sender its own lines go out under.
const SENDER := "CON"
## What each computer mod is called in its own lines, by the stat it adds.
const INSTRUMENTS := {"anemometer": "ANEMOMETER", "barometer": "BAROMETER", "hygrometer": "HYGROMETER",
	"particle_sensor": "PARTICLE SENSOR", "radar": "RADAR"}
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
## With no radar, the map estimates this far round it, m: what a storm the
## barometer feels, carried by the wind, covers in its warning's reach.
const ESTIMATE_REACH := 6000.0
## The screen's pixels, the share of its height its keys take at its foot,
## and the picture on its glass, m.
const PIXELS := Vector2i(580, 1080)
const KEY_SHARE := 0.09
const PICTURE := Vector2(0.58, 1.08)

var page := Page.RADAR
## Whether a smart shield switches itself on as the radar sees a front near.
var auto_shield := true
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
var _shown := ""
var _aim := -1


func _ready() -> void:
	super()
	_instruments = _fitted()
	_awake = true
	_show_display()


## Use on the screen presses the key you aim at, or steps the page; at the
## frame, it works its tray.
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


## A press on the screen at a spot, 0 to 1 across and down: one of its keys,
## or the next page.
func press(at: Vector2) -> void:
	var key := _key_at(at)
	var keys := _keys()
	match keys[key][0] if key >= 0 and key < keys.size() else "PAGE":
		"SHIELD":
			_switch_shields()
		"AUTO":
			var lead := _lead()
			lead.auto_shield = not lead.auto_shield
			_say("AUTO %s" % ("ON · at %s" % _distance(_tuning.smart_shield_auto_m) if lead.auto_shield else "OFF"))
		_:
			page = _next_page()
	_screen_at = -INF


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
		for seated in each.mounted():
			if seated is Radio and seated.powered and not seated.wrecked():
				count["radio"] = count.get("radio", 0) + 1
	return count


## Cells across its storm map, by the gear in its system: a radar alone
## draws it coarse, each other kind of instrument finer, a second radar
## finer again. With no radar its other instruments only estimate a map,
## coarser still; with nothing to read, there's none.
func map_cells() -> int:
	var count := gear()
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
	for key: String in ["front", "here", "forecast", "wind", "pressure", "humidity", "sand", "cells"]:
		if shown.get(key, "") != "":
			lines.append(shown[key])
	for row: String in shown.get("rows", []):
		lines.append(row.trim_prefix("!"))
	return "\n".join(lines)


func stats() -> Dictionary:
	var now := super()
	now["instruments"] = _fitted().size()
	return now


func _recompute() -> void:
	super()
	if not _awake:
		return
	var now := _fitted()
	for key: String in INSTRUMENTS:
		if now.has(key) != _instruments.has(key):
			_say("%s %s" % [INSTRUMENTS[key], "ONLINE" if now.has(key) else "REMOVED"])
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
	if _display == null or world == null:
		return
	var aim := -1
	var hands := world.player.hands
	if hands.look_device == self and hands.look_socket == _screen():
		aim = _key_at(_on_screen(hands.look_point))
	var t := world.time
	if aim == _aim and t < _screen_at + _tuning.console_screen_every and t >= _screen_at:
		return
	_aim = aim
	_screen_at = t
	_draw_screen()


## Its own instruments, by the stat each adds.
func _fitted() -> Dictionary:
	var found := {}
	for part in parts():
		for key: String in INSTRUMENTS:
			if part.stats.get(key, 0) > 0:
				found[key] = part
	return found


## Everything in its system, its first Console first: what stands on its
## deck and is seated there, or itself and what's seated on it.
func _system() -> Array[Device]:
	var root: Device = self
	while root.host() != null:
		root = root.host()
	var found: Array[Device] = []
	_gather(root, found)
	return found


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
		var wind := field.wind_at(x, z, t)
		readings["wind"] = {"speed": wind.length(), "from": Radio.bearing(-wind),
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
	for each in mounted():
		var radio := each as Radio
		if radio != null and radio.powered and not radio.wrecked():
			if t >= _forecast_at + _tuning.radio_forecast_every or t < _forecast_at or not readings.has("forecast"):
				_forecast_at = t
				var rx := world.world_x(radio.global_position.x)
				var rz := world.world_z(radio.global_position.z)
				var said := Radio.forecast(field, rx, rz, t, _tuning.radio_forecast_minutes * 60.0, Weather.FORECAST_STEP)
				said["t"] = t
				_forecast = said
			readings["forecast"] = _forecast
			break


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
		_once("pressure", "!PRESSURE FALLING · STORM ~%s" % _span(pressure_now.eta))
	elif pressure_now.has("eta"):
		_alerts.erase("pressure")
	var front: Dictionary = all.get("front", {})
	if not front.is_empty():
		if front.inside and not _alerts.has("inside"):
			_alerts["inside"] = true
			var fields := [["CLEARS", _clears(front).trim_prefix("clears ")]]
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
		var where := "FRONT %s %s · ETA %s" % [_distance(front.d), _point(front.bearing), _span(front.eta)]
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
		if near and not _front_near and auto_shield:
			var switched := false
			for shield in smart_shields():
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


func _once(key: String, text: String) -> void:
	if not _alerts.has(key):
		_alerts[key] = true
		_say(text)


## The screen's shield key: every smart shield off if any runs, else all on.
func _switch_shields() -> void:
	var shields := smart_shields()
	var up := not shields.any(func(s: ShieldGenerator) -> bool: return s.on)
	var switched := false
	for shield in shields:
		switched = shield.switch(up) or switched
	_say("SHIELD %s" % ("ON" if up else "OFF") if switched else "!SHIELD WON'T START · NO POWER")


## A line of its own to its terminal, or a form with these fields, and a
## radio seated in its system gives it a voice.
func _say(text: String, fields := []) -> void:
	var lead := _lead()
	var t := world.time if world != null else 0.0
	if fields.is_empty():
		lead.terminal.log_line(SENDER, text, t, _clock(t))
	else:
		lead.terminal.form(SENDER, text, fields, t, _clock(t))
	for device in _system():
		var radio := device as Radio
		if radio != null and radio.powered and not radio.wrecked() and radio.is_inside_tree():
			Sounds.play_at(radio, Sounds.RADIO_TONES, -8.0, Radio.HEARD)
			break


## The page after this one in use's order, passing over the shield's with no
## smart shield.
func _next_page(from := page) -> Page:
	var at := ORDER.find(from)
	for i in ORDER.size():
		at = (at + 1) % ORDER.size()
		if ORDER[at] != Page.SHIELD or not smart_shields().is_empty():
			return ORDER[at]
	return Page.RADAR


## The screen's keys, as [name, what it says]: the page key names the page
## it goes to; the others say how they stand, and a press switches them.
func _keys() -> Array:
	var keys: Array = [["PAGE", "%s ›" % PAGE_NAMES[_next_page()]]]
	var shields := smart_shields()
	if not shields.is_empty():
		var any_on := shields.any(func(s: ShieldGenerator) -> bool: return s.on)
		keys.append(["SHIELD", "SHIELD: %s" % ("ON" if any_on else "OFF")])
		if pooled_readings().has("front"):
			keys.append(["AUTO", "AUTO: %s" % ("ON" if _lead().auto_shield else "OFF")])
	return keys


## Which key a spot on the screen is on, or -1: the keys share its foot in thirds.
func _key_at(at: Vector2) -> int:
	if at.y < 1.0 - KEY_SHARE or at.y > 1.0 or at.x < 0.0 or at.x > 1.0:
		return -1
	var key := mini(floori(at.x * 3.0), 2)
	return key if key < _keys().size() else -1


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


## A screen fitted gets its picture; taken out, it goes.
func _show_display() -> void:
	var screen := _screen()
	if screen == null:
		if _display != null:
			_display.queue_free()
			_viewport.queue_free()
			_display = null
			_viewport = null
			_view = null
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
		_shown = ""
	var face: float = Catalog.PARTS[screen.part.get_meta(&"catalog")].size.z
	_display.transform = screen.transform * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, face + 0.002))
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
	_view.show_model(shown)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## What a page shows. The radar's: its map and what's drawn on it, each
## reading's text as it reads there. The others': rows as its terminal
## prints them.
func _model(on: Page, all: Dictionary) -> Dictionary:
	var shown := {"page": PAGE_NAMES[on], "clock": _clock(world.time, true), "aim": _aim,
		"keys": _keys().map(func(k: Array) -> String: return k[1]), "flip": world.moon.north().z > 0.0}
	match on:
		Page.RADAR:
			_radar(shown, all)
		Page.STATS:
			terminal.readout(SENDER, _readout(all))
			var rows := PackedStringArray()
			for from: String in terminal.readouts:
				rows.append_array(terminal.readouts[from])
			shown["rows"] = rows
			if all.has("wind"):
				shown["gyro"] = [all.wind.from, all.wind.speed, all.wind.steady]
			if all.has("pressure"):
				shown["history"] = [all.pressure.history, _tuning.air_pressure_hpa]
		Page.SHIELD:
			var rows := PackedStringArray()
			for shield in smart_shields():
				rows.append_array(["SHIELD  %s" % shield.label.to_upper(), "STATE   %s" % _shield_state(shield),
					"DRAW    %d W" % roundi(shield.demand_w()), "POOL    %d Wh" % floori(world.power.pool_wh(shield)),
					"LEFT    %s" % _span(shield.seconds_left()), "BUBBLE  %d m" % roundi(shield.size), ""])
			var auto := "needs a radar"
			if all.has("front"):
				auto = "ON · at %s" % _distance(_tuning.smart_shield_auto_m) if _lead().auto_shield else "OFF"
			rows.append("AUTO    %s" % auto)
			shown["rows"] = rows
		Page.LOG:
			var rows := PackedStringArray()
			for line: Dictionary in Terminal.merged(linked().map(func(c: Console) -> Terminal: return c.terminal), 18):
				rows.append(_logged(line))
			shown["rows"] = rows if not rows.is_empty() else PackedStringArray(["  nothing logged"])
	return shown


## The radar page: its storm map at the system's resolution, humidity laid
## over its clear air, the front's numbers where the front is, and round it
## the wind's gyro, the pressure's bar, and the forecast along its foot.
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
				shown["here"] = "IN STORM · %s" % _clears(front)
			elif front.d < INF:
				map["front"] = _along(deg_to_rad(front.bearing)) * front.d
				shown["front"] = "%s · %s" % [_distance(front.d), _span(front.eta)]
	shown["map"] = map
	if all.has("wind"):
		shown["wind"] = "%d m/s %s" % [roundi(all.wind.speed), _point(all.wind.from)]
		map["gyro"] = [all.wind.from, all.wind.speed]
	if all.has("pressure"):
		var p: Dictionary = all.pressure
		shown["pressure"] = "%d hPa %s" % [roundi(p.hpa), "▼" if p.per_min < -0.05 else ("▲" if p.per_min > 0.05 else "–")]
		map["pressure"] = [p.hpa, _tuning.air_pressure_hpa, _tuning.air_pressure_fall, p.eta < INF or p.stormy]
	if all.has("humidity"):
		shown["humidity"] = "HUMID %d%%" % roundi(all.humidity.share * 100.0)
	if all.has("sand"):
		shown["sand"] = "SAND %.1f g/m³" % all.sand.g_m3
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
		from = _along(deg_to_rad(all.wind.from))
		coming = all.pressure.eta * all.wind.speed
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


## Its stats: every reading in detail, a row or two each, the label first, a
## "!" before what's urgent, and a smart shield's line.
func _readout(all: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	if all.is_empty():
		rows.append_array(["NO INSTRUMENTS", "  fit a computer mod to a side port"])
	if all.has("wind"):
		rows.append("WIND   %.1f m/s from %s" % [all.wind.speed, _point(all.wind.from)])
		rows.append("       steady %.1f m/s" % all.wind.steady)
	if all.has("pressure"):
		var p: Dictionary = all.pressure
		var way := "falling" if p.per_min < -0.05 else ("rising" if p.per_min > 0.05 else "steady")
		rows.append("PRESS  %.1f hPa %s" % [p.hpa, way])
		rows.append(("!" if p.eta < INF else "") + "       %.1f hPa/min%s" % [absf(p.per_min),
			" · storm ~%s" % _span(p.eta) if p.eta < INF else ""])
	if all.has("humidity"):
		rows.append("HUMID  %d%% · condenser %.1f L/h" % [roundi(all.humidity.share * 100.0), all.humidity.condenser_lph])
	if all.has("sand"):
		var g: float = all.sand.g_m3
		var way := "rising" if g > all.sand.was + 0.01 else ("falling" if g < all.sand.was - 0.01 else "steady")
		rows.append(("!" if g >= _tuning.sand_full_g_m3 * 0.5 else "") + "SAND   %.2f g/m³ %s" % [g, way])
	if all.has("front"):
		var f: Dictionary = all.front
		var heading := "heading %s %d m/s" % [_point(f.moving), roundi(f.speed)]
		if f.inside:
			rows.append("!STORM  here · %s" % _clears(f))
			if f.d < INF:
				rows.append("       clear air %s %s" % [_distance(f.d), _point(f.bearing)])
			rows.append("       " + heading)
		elif f.d < INF:
			rows.append(("!" if f.d <= _tuning.smart_shield_auto_m else "")
				+ "FRONT  %s %s · %s" % [_distance(f.d), _point(f.bearing), _span(f.eta)])
			rows.append("       " + heading)
			if all.has("sand") and f.eta < INF:
				rows.append("       hits %.1f g/m³" % f.hits)
		else:
			rows.append("FRONT  none in %s" % _distance(f.reach))
	if all.has("forecast"):
		var r: Dictionary = all.forecast
		var horizon := roundi(_tuning.radio_forecast_minutes)
		var now: float = world.time
		if r.stormy:
			rows.append("FCST   in storm · %s" % ("clears in %s" % _span(r.change - now) if r.change < INF
				else "no clearing in %d min" % horizon))
		elif r.change == INF:
			rows.append("FCST   clear %d min and more" % horizon)
		else:
			rows.append("FCST   storm in %s from %s" % [_span(r.change - now), _point(r.from)])
			rows.append("       winds to %d m/s · %s" % [roundi(r.wind), "lasts %s" % _span(r.back - r.change)
				if r.back < INF else "%d min+" % horizon])
	var shields := smart_shields()
	if not shields.is_empty():
		rows.append(("!" if shields[0].on and not shields[0].running() else "") + "SHIELD %s" % _shield_state(shields[0]))
	return rows


## When a storm here clears, as the radar sees the storm upwind.
func _clears(front: Dictionary) -> String:
	return "clears in %s" % _span(front.eta) if front.eta < INF else "upwind past %s" % _distance(front.reach)


func _shield_state(shield: ShieldGenerator) -> String:
	if shield.wrecked():
		return "WRECKED"
	if not shield.on:
		return "OFF" + (" · auto at %s" % _distance(_tuning.smart_shield_auto_m)
			if _lead().auto_shield and pooled_readings().has("front") else "")
	if not shield.running():
		return "ON · NO POWER"
	return "ON · %d W · %s left" % [roundi(shield.demand_w()), _span(shield.seconds_left())]


## A logged line as a row: its time, its sender, what it said, urgent if it
## was; a form's fields run on under its title.
static func _logged(line: Dictionary) -> String:
	var text: String = line.text
	var stamp := "%s %s " % [line.at, line.from]
	if text.begins_with("  "):
		return " ".repeat(stamp.length()) + text.substr(2)
	return ("!" if text.begins_with("!") else "") + stamp + text.trim_prefix("!")


## A bearing as a Console prints it, by the moon's north where it stands, as a
## compass reads it.
func _point(degrees: float) -> String:
	var turned := degrees if world == null or world.moon.north().z < 0.0 else degrees + 180.0
	return POINTS[roundi(fposmod(turned, 360.0) / 22.5) % POINTS.size()]


static func _distance(m: float) -> String:
	return "%d m" % (roundi(m / 10.0) * 10) if m < 1000.0 else "%.1f km" % (m / 1000.0)


static func _span(seconds: float) -> String:
	if seconds == INF:
		return "—"
	if seconds < 90.0:
		return "%d s" % maxi(0, roundi(seconds))
	if seconds < 5400.0:
		return "%d min" % roundi(seconds / 60.0)
	return "%d h %d min" % [floori(seconds / 3600.0), roundi(fmod(seconds, 3600.0) / 60.0) % 60]


## The local time of day, as the screen shows it, its day too if asked.
func _clock(t: float, with_day := false) -> String:
	if world == null:
		return "--:--"
	var day := world.weather.day
	var hours := day.time_of_day(t, world.moon.longitude) * 24.0
	var at := "%02d:%02d" % [floori(hours), floori(fmod(hours, 1.0) * 60.0)]
	return "D%d %s" % [day.day(t, world.moon.longitude), at] if with_day else at
