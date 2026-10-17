extends Node
## The rope look-test: the test floater, a crate, stakes and you, tied up round
## spawn in the real world and its weather, to judge whether rope can feel
## right. Your line and the tow are the game's own, so take, use and throw work
## them as they do anywhere; the game lists the keys; probes/rope/ judge whether it's reliable.
##   godot --path . res://look/rope/rope.tscn
##   godot --path . res://look/rope/rope.tscn -- --capture <dir>
##   godot --headless --path . res://look/rope/rope.tscn -- --bench

const Props := preload("res://look/rope/props.gd")
const WORLD_SCENE := preload("res://game/world/world.tscn")
const SEED := 1234
## A worst gust's rise, hold and fall, s.
const GUST := Vector3(1.5, 3.0, 2.0)
## The snap rig's line: holds a storm's mean, not its big gusts.
const WEAK := 550.0
const KEYS := [
	["1-5", "wind: calm, breeze, storm, worst gust, real"], ["6", "go deep into a storm"],
	["7", "go to a storm 100 m off"], ["8", "go to a clear day"], ["R", "reset"],
]

var world: World
var ropes: Ropes
var wind: RopeWind
var wind_mode := "real"

var _base := Callable()
var _gust_from := -INF
var _gust := Vector2.ZERO
var _setups: Array[Dictionary] = []
## Why a rope stopped holding.
var _gone := {}
var _props: Array[Node3D] = []
var _note := ""
var _origin := Vector3.ZERO
var _down := Vector3.FORWARD
var _across := Vector3.RIGHT

@onready var readout: Label = $Hud/Readout


func _ready() -> void:
	Tuning.current().run_seed = SEED
	# Its own props only: nothing found lies among them.
	Tuning.current().salvage = false
	world = WORLD_SCENE.instantiate()
	add_child(world)
	move_child(world, 0)
	wind = RopeWind.new(world.run_seed, world.tuning)
	world.weather.field = wind
	wind.override = _blow
	ropes = world.ropes
	ropes.snapped.connect(func(rope: Rope) -> void: _gone[rope] = "SNAPPED")
	Dev.set_scene_keys(KEYS)
	var args := OS.get_cmdline_user_args()
	if args.has("--bench"):
		_bench()
		return
	# A clear day to start, so the wind keys are judged in good light.
	await _go("clear")
	var at := args.find("--capture")
	if at != -1:
		_capture(args[at + 1] if args.size() > at + 1 else "user://rope")


## Ties up every setup round where you stand, laid out along the wind, and
## turns you to face across it so the lines run left to right.
func build() -> void:
	_tear_down()
	var player := world.player
	_origin = player.global_position
	var toward := wind.prevailing_at(world.time).normalized()
	_down = Vector3(toward.x, 0.0, toward.y)
	_across = Vector3(-_down.z, 0.0, _down.x)
	player.rotation.y = atan2(-_across.x, -_across.z)
	player.camera.rotation.x = deg_to_rad(-12.0)

	var one := _floater(-2.5, 10.0)
	_setup("one line", one, [_line(_stake(-9.0, 10.0), one, 1.0)])
	var weak := _floater(9.5, 10.0)
	_setup("snap rig", weak, [_line(_stake(3.0, 10.0), weak, 1.0, WEAK)])
	var pinned := _floater(-6.0, 19.0)
	_setup("pinned", pinned, [_line(_stake(-8.5, 13.5), pinned, 0.0),
		_line(_stake(-8.5, 24.5), pinned, 0.0)])
	var crate := Props.crate(world, _spot(6.0, 19.0))
	_props.append(crate)
	_setup("crate", crate, [_line(_stake(2.5, 17.0), crate, 0.2), _line(_stake(2.5, 21.0), crate, 0.2)])
	var yours := _floating(5.0, 0.8)
	_setup("your line", yours, [_in_hand(yours)])
	var tow := _floating(2.5, -7.0)
	var tow_stake := Catalog.stake()
	world.content.add_child(tow_stake)
	tow_stake.drive(_spot(-4.0, -7.0), world.height_under(_spot(-4.0, -7.0)))
	_props.append(tow_stake)
	_setup("tow", tow, [Line.between(world, tow.free_tie(tow_stake.global_position),
		tow_stake.free_tie(tow.global_position), 0.5).rope])


func _tear_down() -> void:
	var player := world.player
	for body in [player.hands.stow()] + player.waist.tied.duplicate():
		if body != null:
			player.waist.untie(body)
			body.queue_free()
	ropes.clear()
	# Lines and their loose ends, with the props their other ends were on.
	for node in world.content.get_children():
		if node is Line or (node is Part and node.has_meta(&"line")):
			node.queue_free()
	for prop in _props:
		if is_instance_valid(prop):
			prop.queue_free()
	_props.clear()
	_setups.clear()
	_gone.clear()


## A floating planter, the game's own: tray, battery, a hook on each ring mount.
func _floating(f: float, s: float) -> Device:
	var planter := Catalog.device(&"planter")
	world.content.add_child(planter)
	planter.global_position = _spot(f, s, world.tuning.hover_height)
	for id: StringName in [&"hover_tray", &"battery", &"hook", &"hook"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		for socket in planter.sockets():
			if socket.kind == part.kind and socket.part == null:
				planter.fit(part, socket)
				break
	planter.global_position.y += planter.rest_height() - world.tuning.hover_height
	_props.append(planter)
	return planter


## A line from the device to your hand, a little slack: laid to a stake where
## your hand is, its end taken off it into your hand.
func _in_hand(device: Device) -> Rope:
	var hands := world.player.hands
	var spare := Catalog.stake()
	world.content.add_child(spare)
	spare.global_position = world.player.global_transform * Ropes.HAND_AT
	spare.freeze = true
	var line := Line.between(world, device.free_tie(spare.global_position), spare.free_tie(device.global_position), 0.5)
	hands.hold(spare.take(spare.sockets()[0]))
	spare.queue_free()
	return line.rope


func _floater(f: float, s: float) -> RigidBody3D:
	var body := Props.floater(world, _spot(f, s))
	_props.append(body)
	return body


func _stake(f: float, s: float) -> RopeEnd:
	var stake := Props.stake(world, _spot(f, s))
	_props.append(stake)
	return stake.ring


## A line from a ring to the body's ring that faces it, with this much slack.
func _line(from: RopeEnd, body: Node3D, slack: float, breaking := NAN) -> Rope:
	var ring := Props.ring_toward(body, from.global_position)
	return ropes.tie(from, ring, ring.global_position.distance_to(from.global_position) + slack, breaking)


func _setup(label: String, body: Node3D, lines: Array) -> void:
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.top_level = true
	tag.fixed_size = true
	tag.font_size = 24
	tag.outline_size = 8
	tag.pixel_size = 0.0012
	tag.no_depth_test = true
	body.add_child(tag)
	_setups.append({"label": label, "body": body, "lines": lines, "tag": tag})


## Downwind f and across s from where the setups were laid out, on the sand.
func _spot(f: float, s: float, up := 0.0) -> Vector3:
	var at := _origin + _down * f + _across * s
	at.y = world.height_under(at) + up
	return at


func _blow(x: float, z: float, t: float) -> Vector2:
	var blowing: Vector2 = _base.call(x, z, t) if _base.is_valid() else wind.real_wind_at(x, z, t)
	var age := t - _gust_from
	if age < 0.0 or age > GUST.x + GUST.y + GUST.z:
		return blowing
	return blowing.lerp(_gust, smoothstep(0.0, GUST.x, age) * (1.0 - smoothstep(GUST.x + GUST.y,
		GUST.x + GUST.y + GUST.z, age)))


func _set_wind(mode: String) -> void:
	var toward := wind.prevailing_at(world.time)
	match mode:
		"calm":
			_base = func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO
		"breeze":
			_base = wind.steady(toward, wind.breeze_speed(), world.tuning.gust_strength)
		"storm":
			_base = wind.steady(toward, wind.storm_speed(), world.tuning.gust_storm_strength)
		_:
			_base = Callable()
	wind_mode = mode


func _gust_now() -> void:
	_gust_from = world.time
	_gust = wind.prevailing_at(world.time).normalized() * wind.worst_gust()


func _gusting() -> bool:
	return world.time - _gust_from <= GUST.x + GUST.y + GUST.z


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1:
			_set_wind("calm")
		KEY_2:
			_set_wind("breeze")
		KEY_3:
			_set_wind("storm")
		KEY_4:
			_gust_now()
		KEY_5:
			_set_wind("real")
		KEY_6:
			_go("deep")
		KEY_7:
			_go("storm_100")
		KEY_8:
			_go("clear")
		KEY_R:
			build()


## Drops you into one of the run's own moments, found by its scenario, and
## ties everything up again there.
func _go(key: String) -> void:
	var place := Scenarios.find(world, Scenarios.by_key(key))
	if place.is_empty():
		_note = "no %s in this run's first three days" % key
		return
	_tear_down()
	world.respawn(place.x, place.z, place.yaw, place.time)
	_set_wind("real")
	_note = Scenarios.by_key(key).label
	await _ground()
	build()


func _ground() -> void:
	while not world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
		await get_tree().process_frame


func _process(_delta: float) -> void:
	readout.text = _readout()
	for setup in _setups:
		if not is_instance_valid(setup.body):
			continue
		var body: Node3D = setup.body
		var tag: Label3D = setup.tag
		tag.global_position = body.global_position + Vector3.UP * 1.3
		tag.text = "%s\n%s" % [setup.label, _states(setup.lines)]


func _readout() -> String:
	var lines := PackedStringArray()
	var blowing := world.weather.felt_wind(world.player.global_position)
	# Each setup's load floats over it; this is only what isn't on any object.
	lines.append("wind %s %d m/s%s" % [wind_mode, roundi(blowing.length()), "  GUST" if _gusting() else ""])
	var you := "free"
	var waist := world.player.waist
	var held := world.player.hands.held
	if not waist.tied.is_empty():
		you = "untying %.1f s" % waist.untying if waist.untying >= 0.0 else "waist-tied"
	elif held != null and waist.carries_line(held):
		you = "holding"
	var drag: Vector3 = world.player.get_meta(&"rope_drag", Vector3.ZERO)
	lines.append("you: %s, dragged %.1f m/s" % [you, Vector2(drag.x, drag.z).length()])
	var pulled := 0
	for prop in _props:
		if is_instance_valid(prop) and prop is Stake and prop.pulled:
			pulled += 1
	if pulled > 0:
		lines.append("%d stake%s pulled out" % [pulled, "" if pulled == 1 else "s"])
	if _note != "":
		lines.append(_note)
	return "\n".join(lines)


## Each line's sustained load as a share of its breaking strength.
func _states(lines: Array) -> String:
	var parts := PackedStringArray()
	for rope: Rope in lines:
		if _gone.has(rope):
			parts.append(_gone[rope])
		elif not ropes.ropes.has(rope):
			parts.append("loose")
		else:
			parts.append("%d%%%s" % [roundi(rope.share() * 100.0), "" if rope.is_taut() else " slack"])
	return "  ".join(parts)


## Thirty ropes in a gusting storm, timed tick by tick.
func _bench() -> void:
	await _ground()
	_origin = world.player.global_position
	_set_wind("storm")
	for i in 10:
		var center := _origin + Vector3((i % 5) * 10.0 - 20.0, 0.0, (i / 5) * 14.0 + 10.0)
		var body := Props.floater(world, center)
		_props.append(body)
		for k in 3:
			var stake := Props.stake(world, center + Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 3.0) * 6.0)
			_props.append(stake)
			_line(stake.ring, body, 0.3)
	for i in 120:
		await get_tree().physics_frame
	var samples := PackedFloat64Array()
	var physics := 0.0
	var ticks := 600
	for i in ticks:
		await get_tree().physics_frame
		samples.append(ropes.tick_ms)
		physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	samples.sort()
	var total := 0.0
	for s in samples:
		total += s
	print("bench: %d ropes, %d bodies, storm wind %d m/s with gusts" % [ropes.ropes.size(), 10,
		roundi(wind.storm_speed())])
	print("bench: ropes per tick: mean %.3f ms, p99 %.3f ms, worst %.3f ms; whole physics tick mean %.2f ms"
		% [total / ticks, samples[int(ticks * 0.99)], samples[ticks - 1], physics / ticks])
	get_tree().quit()


## Saves a PNG per shot, set up from scratch each time; frame times are printed.
## The window can't take focus and ignores input, so play can't leak in.
func _capture(out_dir: String) -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	set_process_unhandled_input(false)
	world.player.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var window := get_window()
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	Dev.hide_overlays()
	var camera := Camera3D.new()
	camera.far = 5000.0
	add_child(camera)
	camera.current = true
	var started := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - started < 20000:
		await get_tree().process_frame
	var overview := [Vector3(0.0, -4.0, 4.5), Vector3(0.0, 14.0, 0.0)]
	var one_line := [Vector3(-5.0, 4.0, 1.7), Vector3(-5.0, 10.0, 0.5)]
	_set_wind("calm")
	await _wait(6.0)
	await _shot(out_dir, "01_calm", camera, overview)
	await _shot(out_dir, "02_calm_sag_close", camera, one_line)
	_set_wind("breeze")
	await _wait(10.0)
	await _shot(out_dir, "03_breeze", camera, overview)
	_set_wind("storm")
	await _wait(10.0)
	await _shot(out_dir, "04_storm", camera, overview)
	await _shot(out_dir, "05_storm_taut_close", camera, one_line)
	await _shot(out_dir, "06_storm_pinned_and_crate", camera, [Vector3(0.0, 12.5, 3.0), Vector3(0.0, 19.0, 0.5)])
	_gust_now()
	await _wait(1.6)
	await _shot(out_dir, "07_gust_rising", camera, overview)
	await _wait(2.2)
	await _shot(out_dir, "08_gust_peak", camera, overview)
	await _wait(4.0)
	await _shot(out_dir, "09_after_gust_snap_rig", camera, [Vector3(4.0, 4.0, 2.2), Vector3(7.0, 10.0, 0.4)])
	var eye: Transform3D = world.player.camera.global_transform
	camera.global_transform = eye
	var yours: Rope = _setups.filter(func(s: Dictionary) -> bool: return s.label == "your line")[0].lines[0]
	camera.look_at(yours.strand.points[0].lerp(yours.strand.points[-1], 0.6))
	await _shot(out_dir, "10_your_line_in_storm", camera, [])
	world.player.waist.take_from_hands()
	await _wait(3.0)
	camera.global_transform = eye
	camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(-35.0))
	camera.rotate_y(deg_to_rad(-40.0))
	await _shot(out_dir, "11_waist_tied", camera, [])
	_set_wind("breeze")
	world.player.waist.let_go()
	await _walk_tow(camera)
	await _shot(out_dir, "12_towing", camera, [])
	await _go("deep")
	await _wait(8.0)
	await _shot(out_dir, "13_deep_storm", camera, overview)
	await _shot(out_dir, "14_deep_storm_one_line", camera, one_line)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


## Takes the tow line's end off its stake into your hand and walks you upwind
## with it, by script.
func _walk_tow(camera: Camera3D) -> void:
	var player := world.player
	player.global_position = _spot(-4.0, -5.5)
	var stake: Stake = _props.filter(func(p: Node3D) -> bool: return p is Stake and p.carryable)[0]
	player.hands.hold(stake.take(stake.sockets()[0]))
	var seconds := 7.0
	while seconds > 0.0:
		var delta := get_physics_process_delta_time()
		await get_tree().physics_frame
		seconds -= delta
		player.velocity = -_down * world.tuning.walk_speed
		var next := player.global_position + player.velocity * delta
		next.y = world.height_under(next)
		player.global_position = next
		player.rotation.y = atan2(_down.x, _down.z)
		camera.global_position = next + _down * 9.0 + _across * 5.0 + Vector3.UP * 3.0
		camera.look_at(next + _down * 3.0 + Vector3.UP * 1.0)
	player.velocity = Vector3.ZERO


func _shot(out_dir: String, name: String, camera: Camera3D, view: Array) -> void:
	if not view.is_empty():
		var from: Vector3 = view[0]
		var to: Vector3 = view[1]
		camera.global_position = _spot(from.x, from.y, from.z)
		camera.look_at(_spot(to.x, to.y, to.z))
	var frames := 0
	var longest := 0.0
	var begun := Time.get_ticks_usec()
	var last := begun
	while Time.get_ticks_usec() - begun < 1000000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		longest = maxf(longest, (now - last) / 1000.0)
		last = now
		frames += 1
	var path := out_dir.path_join(name + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("  %-28s frame %5.2f ms (worst %5.2f)  ropes %.2f ms/tick  %s" % [name,
		(Time.get_ticks_usec() - begun) / 1000.0 / frames, longest, ropes.cost_ms,
		readout.text.replace("\n", " | ")])
