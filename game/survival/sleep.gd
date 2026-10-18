class_name Sleep
extends Node
## Sleeping out a storm or a night (docs/prd/survival.md), on a bedroll or a
## ruin's bed, once the camp is still. The physics never fast-forwards: the
## camp is held where it stands and the clock stepped to when you wake, each
## system living each step by its own sums against the weather's curve, read
## ahead as a forecast reads it. What follows from those numbers happens: a
## shield run dry lets the storm in and wakes you, a line loaded past its
## strength gives and the wind takes what it held, your water runs out. Then
## the world goes on as it now is.

## The ways to sleep: so many hours, until a time of day, through the storm,
## until the weather station calls one.
const HOURS := &"hours"
const UNTIL := &"until"
const STORM := &"storm"
const STATION := &"station"
## What "until" offers, as local time of day and its word.
const MOMENTS := [[0.25, "morning"], [0.5, "noon"], [0.75, "dusk"], [0.0, "night"]]
## What woke you, said on waking.
const WOKE := {&"storm": "The storm woke you", &"wind": "The wind woke you", &"heat": "The heat woke you",
	&"cold": "The cold woke you", &"thirst": "Woke thirsty", &"hunger": "Woke hungry",
	&"station": "Woke to the station"}
## The summary stays this long, s.
const SUMMARY_SECONDS := 7.0
## A thing the wind took this far, m, moved in the night.
const MOVED := 2.0

## Falling asleep or asleep: the screen going dark, or dark.
var sleeping := false
## What the last night came to, and its summary's lines.
var last := {}
var said := PackedStringArray()

var _world: World
var _tuning: Tuning
## The fastest anything of the camp moved, m/s, and turned, rad/s, as the
## physics ran on while you fell asleep.
var _watched := Vector2.ZERO
var _watching := false
var _line: Label
var _fading: Tween
## The bed the words were brought up on: a bedroll may be in your hands.
var _bed: Node


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning


func _ready() -> void:
	# Under the fade, so it shows as the screen comes back.
	var layer := CanvasLayer.new()
	layer.layer = 99
	add_child(layer)
	_line = Label.new()
	_line.theme_type_variation = &"Caption"
	_line.uppercase = true
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_line.offset_left = -400.0
	_line.offset_right = 400.0
	_line.offset_top = 96.0
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.modulate.a = 0.0
	layer.add_child(_line)


func _physics_process(_delta: float) -> void:
	if not _watching:
		return
	var player := _world.player
	_watched.x = maxf(_watched.x, Vector2(player.velocity.x, player.velocity.z).length())
	for body in _camp():
		_watched = _watched.max(Vector2(body.linear_velocity.length(), body.angular_velocity.length()))


## Use on a bed: the words to choose how long, if you can sleep now, else why
## not. Says it answered.
func offer(by: Player, bed: Node = null) -> bool:
	if sleeping:
		return true
	var why := refusal(bed)
	if why != "":
		return by.hands.refuse(why)
	var ui := Controls.ui
	if ui == null:
		return false
	_bed = bed
	by.suit.close()
	ui.open(menu())
	return true


## Why you can't sleep now, in a few words, or "": on your feet and still,
## hands (but for the bed in them) and waist free, nothing of the camp moving
## as the physics runs or under sail, and no harm reaching you where you lie:
## under a running shield in a storm, or on sand calm enough.
func refusal(bed: Node = null) -> String:
	var player := _world.player
	if player.vitals.dead:
		return "dead"
	if player.flying or player.ride != null:
		return "not on your feet"
	if player.hands.held != null and player.hands.held != bed or player.hands.grasp.body != null:
		return "hands full"
	if not player.waist.tied.is_empty():
		return "a line at your waist"
	if Vector2(player.velocity.x, player.velocity.z).length() > _tuning.sleep_still_speed:
		return "you're moving"
	for body in _camp():
		if body.linear_velocity.length() > _tuning.sleep_still_speed \
				or body.angular_velocity.length() > _tuning.sleep_still_spin:
			return "%s moving" % _name(body).to_lower()
	# The night reckons the wind on what's held, not a sail's pull: furl it first.
	for device in _world.devices():
		if device is Mast and (device as Mast).raised \
				and device.global_position.distance_to(player.global_position) <= _tuning.sleep_camp_m:
			return "sail up"
	var harm := player.vitals.harms_at(player.global_position)
	if harm.storm > 0.0:
		return "no shield"
	if harm.wind > 0.0:
		return "too windy"
	if harm.temperature > 0.0:
		return "too hot" if _world.weather.felt_temperature(player.global_position) > 0.0 else "too cold"
	return ""


## The words use on a bed brings up over the running game: through the storm
## while one's on or due, so many hours, until a time of day, and with a
## radio in earshot until its station calls a storm. Each sleeps as it says.
func menu() -> Words:
	var words := Words.new("")
	var hours := [_tuning.sleep_hours]
	var moment := [0]
	if storm_due():
		words.add("Through the storm", _choose.bind(STORM))
	words.add(func() -> String: return "Sleep %d h" % hours[0], func() -> void: _choose(HOURS, hours[0]),
		func(by: int) -> void: hours[0] = clampi(hours[0] + by, 1, 24))
	words.add(func() -> String: return "Until %s" % MOMENTS[moment[0]][1], func() -> void: _choose(UNTIL, moment[0]),
		func(by: int) -> void: moment[0] = posmod(moment[0] + by, MOMENTS.size()))
	var station := radio()
	if station != null and _station_clear(station):
		words.add("Until a storm's called", _choose.bind(STATION))
	return words


## A storm on you, or due within the weather's own forecast.
func storm_due() -> bool:
	return _world.weather.in_storm or _world.weather.next_change_time < INF


## A radio in earshot to wake you as the weather station calls a storm:
## carried or near you, whole, with power to run.
func radio() -> Radio:
	var at := _world.player.camera.global_position
	for each: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		if each.world != _world or each.wrecked() or each.global_position.distance_to(at) > Broadcast.EARSHOT:
			continue
		if each.powered and (_world.power.pool_wh(each) > 0.0 or each.production_w() > 0.0):
			return each
	return null


## When a way of sleeping wakes you, world time, from now: never past
## sleep_most_days, and the station's call wakes you sooner.
func wake_for(how: StringName, arg := 0) -> float:
	var t := _world.time
	var most := t + _tuning.sleep_most_days * _day()
	match how:
		HOURS:
			return minf(t + arg * _day() / 24.0, most)
		UNTIL:
			var ahead := fposmod(MOMENTS[arg][0] - _world.weather.day.time_of_day(t, _world.moon.longitude), 1.0)
			return t + (ahead if ahead > 1e-4 else 1.0) * _day()
		STORM:
			return minf(_storm_over(t, most), most)
	return most


## Sleeps the way chosen: the screen goes dark while the physics runs on and
## the camp is watched, then, if it held still, the night is lived and you
## wake to what it left.
func fall_asleep(how: StringName, arg := 0) -> void:
	if sleeping:
		return
	sleeping = true
	_watched = Vector2.ZERO
	_watching = true
	await _fade(true)
	_watching = false
	var why := refusal(_bed if is_instance_valid(_bed) else null)
	if why == "" and (_watched.x > _tuning.sleep_still_speed or _watched.y > _tuning.sleep_still_spin):
		why = "camp moving"
	if why == "":
		var station := radio() if how == STATION else null
		if station != null:
			station.channel = Radio.WEATHER
		show_summary(summary(overnight(wake_for(how, arg), station)))
	await _fade(false)
	sleeping = false
	if why != "":
		_world.player.hands.refuse(why)


## The night, lived with the physics still: the clock stepped toward `until`
## a sleep tick at a time, each system living each step by its own sums in
## the order a frame runs them, until then or until something wakes you; a
## radio given wakes you as its station calls a storm. Then everything goes
## on from where the night left it. Returns what happened.
func overnight(until: float, station: Radio = null) -> Dictionary:
	var started := Time.get_ticks_usec()
	var world := _world
	var player := world.player
	var from := world.time
	var t := from
	var call := _call_time(station, t, until) if station != null else INF
	var shields: Array[ShieldGenerator] = []
	var sound := {}
	for device in world.devices() + player.suit.devices():
		sound[device] = device.durability
		if device is ShieldGenerator:
			shields.append(device)
	var running := shields.filter(func(s: ShieldGenerator) -> bool: return s.running())
	var bearings := {}
	for rope in world.ropes.ropes:
		bearings[rope] = world.ropes.bearing(rope)
	var were := {}
	for node in world.content.get_children():
		if node is RigidBody3D and not node.freeze:
			were[node] = node.global_position
	var groups := _groups()
	var gave := {}
	var woke := &""
	while t < until - 1e-6:
		woke = _woken(t, call, station)
		if woke != &"":
			break
		var h := minf(_tuning.sleep_tick, until - t)
		if _bear(t, h, bearings, gave):
			groups = _groups()
		world.power.live(h, t)
		for shield in shields:
			shield.settle()
		world.wear.live(h, t)
		world.farm.live(h, t)
		player.vitals.live(h, t)
		world.terrain.tracks.live(h, t)
		_drift(groups, t, h)
		t += h
	world.time = t
	var night := {"from": from, "to": t, "woke": woke, "shields": [], "loose": [], "wrecked": []}
	for shield: ShieldGenerator in running:
		night.shields.append({"name": _name(shield), "held": shield.running(), "wh": world.power.pool_wh(shield)})
	_wake(groups, were, gave, night)
	for device: Device in sound:
		if is_instance_valid(device) and not device.is_queued_for_deletion() and sound[device] > 0.0 \
				and device.wrecked():
			night.wrecked.append(_name(device))
	world.weather.forecast_now()
	# The storm pass's map is drawn again for the hour you woke to while it's dark.
	world.weather.map.update(t, 1.0)
	last = night
	Dev.put("sleep/last", "%.1f h in %d ms" % [(t - from) / (_day() / 24.0), (Time.get_ticks_usec() - started) / 1000])
	return night


## The night in a few short lines: how long, what woke you early, each
## shield that was up, and what the wind took or wrecked.
func summary(night: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var hours: float = (night.to - night.from) / (_day() / 24.0)
	lines.append("Slept %d h" % roundi(hours) if hours >= 0.5 else "Barely slept")
	if WOKE.has(night.woke):
		lines.append(WOKE[night.woke])
	for shield: Dictionary in night.shields:
		lines.append("%s %s" % [shield.name, "held" if shield.held else "gave out"])
	for each: Dictionary in night.loose:
		lines.append("%s %s" % [each.name, "blew away" if each.lost else ("broke loose" if each.gave
			else "drifted %d m" % roundi(each.m))])
	for wrecked: String in night.wrecked:
		lines.append("%s wrecked" % wrecked)
	return lines


## The summary as you wake, fading after a while.
func show_summary(lines: PackedStringArray) -> void:
	said = lines
	_line.text = "\n".join(lines)
	_line.modulate.a = 1.0
	if _fading != null:
		_fading.kill()
	_fading = _line.create_tween()
	_fading.tween_interval(SUMMARY_SECONDS)
	_fading.tween_property(_line, "modulate:a", 0.0, UIRoot.FADE_SECONDS)


func _choose(how: StringName, arg := 0) -> void:
	if Controls.ui != null:
		Controls.ui.close_top()
	if how == STORM and _world.weather.shelter_at(_world.player.global_position, &"storm") <= 0.0:
		_world.player.hands.refuse("no shield")
		return
	fall_asleep(how, arg)


## What wakes you at world time t, or none: harm reaching you, a need run
## low with nothing left to take, or the station calling a storm.
func _woken(t: float, call: float, station: Radio) -> StringName:
	var player := _world.player
	if player.vitals.dead:
		return &"dead"
	var at := player.global_position
	var harm := player.vitals.harms_at(at, t)
	if harm.storm > 0.0:
		return &"storm"
	if harm.wind > 0.0:
		return &"wind"
	if harm.temperature > 0.0:
		return &"heat" if _world.weather.felt_temperature(at, t) > 0.0 else &"cold"
	var low := _tuning.sleep_wake_need * Vitals.FULL
	if player.vitals.thirst <= low and player.suit.supply(&"water") == null:
		return &"thirst"
	if player.vitals.hunger <= low and player.suit.supply(&"food") == null:
		return &"hunger"
	if t >= call and is_instance_valid(station) and _hears(station, t):
		return &"station"
	return &""


## Whether a radio hears the weather station at world time t, its dial kept
## on the Walker's carrier as it moves from day to day.
func _hears(station: Radio, t: float) -> bool:
	if not station.playing():
		return false
	station.frequency = Radio.gods_of(_world).carrier(&"walker", t)
	var heard := station.receive(&"walker", _world.world_x(station.global_position.x),
		_world.world_z(station.global_position.z), t)
	return not heard.cut and heard.clean > 0.0


## Every line meets the wind's load over a step, as Ropes reckons it with the
## camp held still: one past its strength gives way as it would live, and a
## stake its lines pull past its holding comes out. Says whether anything gave.
func _bear(t: float, h: float, bearings: Dictionary, gave: Dictionary) -> bool:
	var ropes := _world.ropes
	var changed := false
	var pulls := {}
	var shares := {}
	for rope: Rope in ropes.ropes.duplicate():
		if not bearings.has(rope):
			continue
		var load := ropes.load_at(rope, t, h, bearings[rope], shares)
		if load > rope.breaking:
			for end: RopeEnd in [rope.a, rope.b]:
				gave[end.holder] = true
			bearings.erase(rope)
			ropes.give_way(rope)
			changed = true
			continue
		for end: RopeEnd in [rope.a, rope.b]:
			var stake := end.holder as Stake
			if stake != null and stake.driven:
				pulls[stake] = pulls.get(stake, 0.0) + load
	for stake: Stake in pulls:
		if pulls[stake] > stake.holding:
			stake.pull_out(_world.height_under(stake.global_position))
			gave[stake] = true
			for rope in ropes.ropes:
				if rope.a.holder == stake or rope.b.holder == stake:
					bearings.erase(rope)
			changed = true
	return changed


## Everything loose in the world in groups joined by lines, each held if any
## of it is held fast: frozen where it lies, as a driven stake or a find is,
## or tied to something that isn't loose, as you are.
func _groups() -> Array[Dictionary]:
	var root := {}
	for node in _world.content.get_children():
		if node is RigidBody3D:
			root[node] = node
	var fixed := {}
	for rope in _world.ropes.ropes:
		var a := rope.a.holder
		var b := rope.b.holder
		if root.has(a) and root.has(b):
			root[_top(root, a)] = _top(root, b)
		elif root.has(a) or root.has(b):
			fixed[a if root.has(a) else b] = true
	var by := {}
	for body: RigidBody3D in root:
		var top: Node = _top(root, body)
		if not by.has(top):
			by[top] = {"bodies": [], "held": false, "lost": false}
		var group: Dictionary = by[top]
		if body.freeze or fixed.has(body):
			group.held = true
		else:
			group.bodies.append(body)
	var out: Array[Dictionary] = []
	for group: Dictionary in by.values():
		if not group.held and not group.bodies.is_empty():
			out.append(group)
	return out


static func _top(root: Dictionary, body: Node) -> Node:
	while root[body] != body:
		body = root[body]
	return body


## The wind carries off what nothing holds, each group as one: at the wind's
## speed less what the sand's friction holds back, none of it while it
## floats, as a body slides once the wind beats its friction live. Carried off
## the ground the world keeps, it's gone.
func _drift(groups: Array[Dictionary], t: float, h: float) -> void:
	var weather := _world.weather
	for group: Dictionary in groups:
		if group.lost:
			continue
		var grip := 0.0
		var catch := 0.0
		var lead: RigidBody3D = null
		for body: RigidBody3D in group.bodies:
			grip += _world.grip(body)
			catch += weather.catch_of(body)
			if lead == null or body.mass > lead.mass:
				lead = body
		var wind := weather.felt_wind(lead.global_position, t)
		var stick := sqrt(grip / catch) if catch > 0.0 else INF
		var speed := wind.length() - stick
		if speed <= 0.0:
			continue
		var by := wind.normalized() * speed * h
		for body: RigidBody3D in group.bodies:
			var at := body.global_position
			var clear := at.y - _world.height_under(at)
			var to := at + by
			if not _world.has_ground_under(to):
				group.lost = true
				break
			body.global_position = Vector3(to.x, _world.height_under(to) + clear, to.z)


## Waking, the camp goes on from where the night left it: what the wind
## carried off the ground is gone, what it moved lies still where it went,
## lines drawn again where their ends are. Each device so moved, or gone, is
## told in the night.
func _wake(groups: Array[Dictionary], were: Dictionary, gave: Dictionary, night: Dictionary) -> void:
	var moved := {}
	for group: Dictionary in groups:
		for body: RigidBody3D in group.bodies:
			if not is_instance_valid(body) or not were.has(body):
				continue
			var m := Vector2(body.global_position.x - were[body].x, body.global_position.z - were[body].z).length()
			if group.lost or m > MOVED:
				moved[body] = true
				if body is Device and not body is Stake:
					night.loose.append({"name": _name(body), "lost": group.lost, "m": m, "gave": _gave(body, gave)})
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
		if group.lost:
			for body: RigidBody3D in group.bodies:
				if is_instance_valid(body):
					body.queue_free()
	for rope in _world.ropes.ropes:
		if moved.has(rope.a.holder) or moved.has(rope.b.holder):
			rope.strand.hang(_world, rope.length, rope.a, rope.b)


## Whether a line on a body, or on what it's joined to, gave in the night.
func _gave(body: Node, gave: Dictionary) -> bool:
	if gave.has(body):
		return true
	for rope in _world.ropes.ropes:
		if rope.a.holder == body and gave.has(rope.b.holder) or rope.b.holder == body and gave.has(rope.a.holder):
			return true
	return false


## The camp: your devices and stakes loose near you.
func _camp() -> Array[RigidBody3D]:
	var found: Array[RigidBody3D] = []
	var at := _world.player.global_position
	for node in _world.content.get_children():
		var device := node as Device
		if device != null and not device.freeze and device.global_position.distance_to(at) <= _tuning.sleep_camp_m:
			found.append(device)
	return found


## When the storm on you, or the next one due, has passed where you lie;
## INF if none is on or due within the forecast's reach.
func _storm_over(t: float, most: float) -> float:
	var field := _world.weather.field
	var x := _world.player_world_x()
	var z := _world.player_world_z()
	var starts := t
	if field.raw_storm_at(x, z, t) <= 0.0:
		starts = t + field.next_change(x, z, t, Weather.FORECAST_HORIZON, Weather.FORECAST_STEP)
		if starts == INF:
			return INF
	return starts + field.next_change(x, z, starts, maxf(most - starts, 0.0), Weather.FORECAST_STEP)


## Whether the weather station holds calm where the radio is, nothing to
## report: no storm on it, and none due soon.
func _station_clear(station: Radio) -> bool:
	var x := _world.world_x(station.global_position.x)
	var z := _world.world_z(station.global_position.z)
	return Transmissions.calm(Radio.forecast(_world.weather.field, x, z, _world.time,
		_tuning.radio_forecast_minutes * 60.0, Weather.FORECAST_STEP), _world.time)


## When the station breaks its calm to report a storm, where the radio is:
## the storm's arrival there, less how soon it counts as due.
func _call_time(station: Radio, t: float, until: float) -> float:
	var x := _world.world_x(station.global_position.x)
	var z := _world.world_z(station.global_position.z)
	var due := _tuning.radio_calm_minutes * 60.0
	var arrives := t + _world.weather.field.next_change(x, z, t, until - t + due, Weather.FORECAST_STEP)
	return maxf(arrives - due, t)


## To black or back, as the UI fades; with no UI, as long as it would take.
func _fade(to_black: bool) -> void:
	var ui := Controls.ui
	if ui != null and ui.main != null and ui.main.world() == _world:
		await ui.fade(to_black)
		return
	for i in roundi(UIRoot.FADE_SECONDS * Engine.physics_ticks_per_second):
		await get_tree().physics_frame


func _day() -> float:
	return _tuning.day_minutes * 60.0


## A thing as the summary names it: its short name if it has one.
static func _name(body: Node) -> String:
	var id: StringName = body.get_meta(&"catalog", &"")
	return Catalog.DEVICES.get(id, {}).get("short", body.get(&"label") if &"label" in body else "something")
