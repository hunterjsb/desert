class_name Console
extends Device
## The camp's computer: a crate's frame given to computing. Its computer mods
## each read the weather field itself, never the felt weather, so a bubble
## doesn't blind them: the field has no pressure, humidity or sand, so those
## are derived from it (Tuning, Console). Every Console standing on one deck is
## one system, its instruments pooled, and its full-face screen shows all they
## read: numbers, and with the full set a small storm map. A shield in the
## system is smart: the screen reports it and switches it, and with a radar
## it switches itself on as a front nears. Its messages go out through its
## Terminal, and its screen draws only when what it shows has changed. Use on
## the screen presses the key you aim at, and anywhere else on it steps the
## page; use at the frame works its tray, as a crate's.

enum Page { WEATHER, SHIELD, LOG }
const PAGE_NAMES := ["WEATHER", "SHIELD", "LOG"]
## The sender its own lines go out under.
const SENDER := "CON"
## What a full set of instruments reads: then the screen draws a storm map.
const FULL_SET := ["wind", "pressure", "humidity", "sand", "front", "forecast"]
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
## Storms riding a wind slower than this have no time to them, m/s.
const CLOSING := 0.5
## The screen's pixels, and the share of its height its keys take at the foot.
const PIXELS := Vector2i(768, 448)
const KEY_SHARE := 0.11
## The picture on the screen's glass, m: just inside its bezel.
const PICTURE := Vector2(0.68, 0.38)

var page := Page.WEATHER
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
## The storm map round it, a row at a time, storm intensity per cell.
var _map := PackedFloat32Array()
var _map_row := 0
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
## frame, it works its tray as a crate's.
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


## What its screen shows on a page (its own, by default), as text: what you'd
## read there.
func screen_text(on := -1) -> String:
	var rows := _rows(page if on < 0 else on as Page, pooled_readings())
	return "\n".join(Array(rows).map(func(r: String) -> String: return r.trim_prefix("!")))


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
	if now.get("radar", 0) > 0 and _full_set():
		for i in mini(steps, _tuning.storm_map_screen_cells):
			_map_one(now.radar_m)
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
		_gather(each, found)


## The Console that speaks for its system: the first one running.
func _lead() -> Console:
	for each in linked():
		if each.running():
			return each
	return self


func _full_set() -> bool:
	var all := pooled_readings()
	return FULL_SET.all(func(key: String) -> bool: return all.has(key))


## What its own instruments read now, from the field where it stands.
func _read(now: Dictionary, t: float) -> void:
	var field := world.weather.field
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	readings.clear()
	if now.get("anemometer", 0) > 0:
		var wind := field.wind_at(x, z, t)
		readings["wind"] = {"speed": wind.length(), "from": Radio.bearing(-wind)}
	if now.get("barometer", 0) > 0:
		var back := _tuning.barometer_trend_seconds
		var raw := field.raw_storm_at(x, z, t)
		var was := field.raw_storm_at(x, z, t - back)
		var rise := (raw - was) / back
		# A rough warning: the trend carried on until the field crosses its threshold.
		var eta := -raw / rise if raw <= 0.0 and rise > 0.0 else INF
		readings["pressure"] = {"hpa": pressure(raw), "per_min": (pressure(raw) - pressure(was)) / back * 60.0,
			"eta": eta if eta <= _tuning.barometer_warn_minutes * 60.0 else INF}
	if now.get("hygrometer", 0) > 0:
		var celsius := world.weather.field_temperature(global_position, t)
		var yields := Condenser.yield_lph(_tuning, celsius)
		readings["humidity"] = {"share": clampf(_tuning.humidity_cold * yields / _tuning.condenser_litres_per_hour
			+ _tuning.humidity_storm * field.storm_at(x, z, t), 0.0, 1.0), "condenser_lph": yields}
	if now.get("particle_sensor", 0) > 0:
		readings["sand"] = {"g_m3": sand(field, x, z, t), "was": sand(field, x, z, t - SAND_TREND)}
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


## Sand in the air at a place, g/m³: a storm's, thickening from its wall to
## its heart, as deep in the field as salvage counts a storm's heart, or what
## a front's outflow carries ahead of the wall.
func sand(field: WeatherField, x: float, z: float, t: float) -> float:
	var deep := clampf(field.raw_storm_at(x, z, t) / _tuning.exposure_storm_full, 0.0, 1.0)
	return _tuning.sand_full_g_m3 * maxf(field.storm_at(x, z, t) * lerpf(_tuning.sand_wall_share, 1.0, deep),
		_tuning.sand_outflow_share * field.outflow_at(x, z, t))


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
	var t := world.time
	var along := _along(TAU * _bearing / count)
	_sweep[_bearing] = edge(field, x, z, t, along, reach, _tuning.radar_step_m)
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
				out.hits = maxf(out.hits, sand(field, x + up.x * deeper, z + up.y * deeper, t))
	return out


## One row of the storm map round it, north up as the radar reads it.
func _map_one(reach: float) -> void:
	var n := _tuning.storm_map_screen_cells
	if _map.size() != n * n:
		_map.resize(n * n)
		_map.fill(0.0)
		_map_row = 0
	var field := world.weather.field
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var cell := 2.0 * reach / n
	for i in n:
		var at := Vector2(-reach + (i + 0.5) * cell, -reach + (_map_row + 0.5) * cell)
		_map[_map_row * n + i] = field.storm_at(x + at.x, z + at.y, world.time)
	_map_row = (_map_row + 1) % n


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
		else:
			if _alerts.has("inside"):
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


func _next_page() -> Page:
	var at := page
	for i in PAGE_NAMES.size():
		at = ((at + 1) % PAGE_NAMES.size()) as Page
		if at != Page.SHIELD or not smart_shields().is_empty():
			return at
	return Page.WEATHER


## The screen's keys, as [name, what it says]: each says how it stands, and
## a press switches it.
func _keys() -> Array:
	var keys: Array = [["PAGE", "PAGE ›"]]
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
	var all := pooled_readings()
	var rows := _rows(page, all)
	var head: String = "CONSOLE" + (" · LINK %d" % linked().size() if linked().size() > 1 else "") + " · " + PAGE_NAMES[page]
	var map := {}
	if page == Page.WEATHER and _full_set():
		map = _map_view(all)
	var keys := _keys()
	var key_names: Array = keys.map(func(k: Array) -> String: return k[1])
	var model := {"head": head, "clock": _clock(world.time, true), "rows": rows, "keys": key_names, "aim": _aim,
		"map": map}
	var said := str(model)
	if said == _shown:
		return
	_shown = said
	_view.show_model(model)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## The storm map as its screen draws it: the cells of the first radar's map
## in its system, turned so the moon's north is up, and the nearest edge.
func _map_view(all: Dictionary) -> Dictionary:
	for each in linked():
		if each._map.size() == _tuning.storm_map_screen_cells * _tuning.storm_map_screen_cells:
			var front: Dictionary = all.get("front", {})
			return {"cells": each._map, "n": _tuning.storm_map_screen_cells, "flip": world.moon.north().z > 0.0,
				"reach": front.get("reach", 0.0), "front": [front.d, front.bearing] if front.get("d", INF) < INF else [],
				"moving": front.get("moving", 0.0)}
	return {}


## A page's rows as its terminal prints them: on the weather page its
## readout, then the last lines logged under a rule (an empty row).
func _rows(on: Page, all: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	var logs := linked().map(func(c: Console) -> Terminal: return c.terminal)
	match on:
		Page.WEATHER:
			terminal.readout(SENDER, _readout(all))
			for from: String in terminal.readouts:
				rows.append_array(terminal.readouts[from])
			var latest := Terminal.merged(logs, 3)
			if not latest.is_empty():
				rows.append("")
				for line: Dictionary in latest:
					rows.append(_logged(line))
		Page.SHIELD:
			for shield in smart_shields():
				rows.append_array(["SHIELD  %s" % shield.label.to_upper(), "STATE   %s" % _shield_state(shield),
					"DRAW    %d W" % roundi(shield.demand_w()), "POOL    %d Wh" % floori(world.power.pool_wh(shield)),
					"LEFT    %s" % _span(shield.seconds_left()), "BUBBLE  %d m" % roundi(shield.size)])
			var auto := "needs a radar"
			if all.has("front"):
				auto = "ON · at %s" % _distance(_tuning.smart_shield_auto_m) if _lead().auto_shield else "OFF"
			rows.append("AUTO    %s" % auto)
		Page.LOG:
			for line: Dictionary in Terminal.merged(logs, 14):
				rows.append(_logged(line))
			if rows.is_empty():
				rows.append("  nothing logged")
	return rows


## Its readout: a row or two for each reading, the label first, a "!" before
## what's urgent, and a smart shield's line.
func _readout(all: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	if all.is_empty():
		rows.append_array(["NO INSTRUMENTS", "  fit a computer mod to a side port"])
	if all.has("wind"):
		rows.append("WIND   %.1f m/s from %s" % [all.wind.speed, _point(all.wind.from)])
	if all.has("pressure"):
		var p: Dictionary = all.pressure
		var way := "falling" if p.per_min < -0.05 else ("rising" if p.per_min > 0.05 else "steady")
		rows.append("PRESS  %.1f hPa %s %.1f/min" % [p.hpa, way, absf(p.per_min)])
		if p.eta < INF:
			rows.append("!       STORM LIKELY ~%s" % _span(p.eta))
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
			rows.append("       %s%s" % ["clear air %s %s · " % [_distance(f.d), _point(f.bearing)] if f.d < INF else "",
				heading])
		elif f.d < INF:
			rows.append(("!" if f.d <= _tuning.smart_shield_auto_m else "")
				+ "FRONT  %s %s · ETA %s" % [_distance(f.d), _point(f.bearing), _span(f.eta)])
			rows.append("       %s%s" % [heading, " · hits %.1f g/m³" % f.hits if all.has("sand") and f.eta < INF else ""])
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
				if r.back < INF else "past %d min" % horizon])
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
