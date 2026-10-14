extends Node
## The rope look-test: the test floater, a crate, stakes and you, tied up round
## spawn in the real world and its weather, to judge whether rope can feel
## right. Keys are on screen; probes/rope/ judge whether it's reliable.
##   godot --path . res://look/rope/rope.tscn
##   godot --path . res://look/rope/rope.tscn -- --capture <dir>
##   godot --headless --path . res://look/rope/rope.tscn -- --bench

const Props := preload("res://look/rope/props.gd")
const Stake := preload("res://look/rope/stake.gd")
const WORLD_SCENE := preload("res://game/world/world.tscn")
const SEED := 1234
## A waist tie takes this long to undo, s. The PRD leaves it open; feel it here.
const UNTIE := 1.0
## How near a stake you have to be to take up its line, m.
const REACH := 3.0
## A worst gust's rise, hold and fall, s.
const GUST := Vector3(1.5, 3.0, 2.0)
## The snap rig's line: holds a storm's mean, not its gusts.
const WEAK := 450.0
const KEYS_HELP := "wind: 1 calm  2 breeze  3 storm  4 worst gust  5 real · storms: 6 deep in one  " \
	+ "7 one 100 m off  8 spawn · H hand/waist · Q let go · E take up a staked line · " \
	+ "F stake your lines here · R reset · click to look, WASD, F3 numbers"

var world: World
var ropes: Ropes
var wind: RopeWind
var wind_mode := "real"

var _base := Callable()
var _gust_from := -INF
var _gust := Vector2.ZERO
var _untie := -1.0
var _setups: Array[Dictionary] = []
## Why a rope stopped holding.
var _gone := {}
var _props: Array[Node3D] = []
var _note := ""
var _origin := Vector3.ZERO
var _down := Vector3.FORWARD
var _across := Vector3.RIGHT

@onready var readout: Label = $Hud/Readout
@onready var keys: Label = $Hud/Keys


func _ready() -> void:
	Tuning.current().run_seed = SEED
	world = WORLD_SCENE.instantiate()
	add_child(world)
	move_child(world, 0)
	wind = RopeWind.new(world.run_seed, world.tuning)
	world.weather.field = wind
	wind.override = _blow
	ropes = Ropes.new()
	var creak: AudioStreamOggVorbis = preload("res://look/rope/creak.ogg")
	creak.loop = true
	ropes.creak = creak
	add_child(ropes)
	ropes.setup(world)
	ropes.snapped.connect(func(rope: Rope) -> void: _gone[rope] = "SNAPPED")
	keys.text = KEYS_HELP
	var args := OS.get_cmdline_user_args()
	if args.has("--bench"):
		_bench()
		return
	await _ground()
	build()
	var at := args.find("--capture")
	if at != -1:
		_capture(args[at + 1] if args.size() > at + 1 else "user://rope")


## Ties up every setup round where you stand, laid out along the wind, and
## turns you to face across it so the lines run left to right.
func build() -> void:
	ropes.clear()
	for prop in _props:
		if is_instance_valid(prop):
			prop.queue_free()
	_props.clear()
	_setups.clear()
	_gone.clear()
	_untie = -1.0
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
	var yours := _floater(5.0, 0.8)
	var ring := Props.ring_toward(yours, ropes.hand.global_position)
	_setup("your line", yours, [ropes.tie(ropes.hand, ring,
		ring.global_position.distance_to(ropes.hand.global_position) + 0.5)])
	var tow := _floater(2.5, -7.0)
	_setup("tow", tow, [_line(_stake(-4.0, -7.0), tow, 0.5)])


func _floater(f: float, s: float) -> RigidBody3D:
	var body := Props.floater(world, _spot(f, s))
	_props.append(body)
	return body


func _stake(f: float, s: float) -> RopeEnd:
	var stake: RigidBody3D = Props.stake(world, _spot(f, s))
	_props.append(stake)
	return stake.ring


## A line from a ring to the body's ring that faces it, with this much slack.
func _line(from: RopeEnd, body: Node3D, slack: float, breaking := Ropes.BREAKING) -> Rope:
	var ring := Props.ring_toward(body, from.global_position)
	return ropes.tie(from, ring, ring.global_position.distance_to(from.global_position) + slack, breaking)


func _setup(label: String, body: Node3D, lines: Array) -> void:
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.top_level = true
	tag.font_size = 40
	tag.outline_size = 10
	tag.pixel_size = 0.006
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
			_storm("deep")
		KEY_7:
			_storm("storm_100")
		KEY_8:
			_storm("spawn")
		KEY_H:
			_hand_or_waist()
		KEY_Q:
			_let_go()
		KEY_E:
			_take_up()
		KEY_F:
			_stake_here()
		KEY_R:
			build()


func _hand_or_waist() -> void:
	var held := ropes.lines_on(ropes.hand)
	if not held.is_empty():
		for rope in held:
			ropes.move_end(rope, ropes.hand, ropes.waist)
	else:
		for rope in ropes.lines_on(ropes.waist):
			ropes.move_end(rope, ropes.waist, ropes.hand)
	_untie = -1.0


## A line in your hand drops at once; one round your waist takes a moment.
func _let_go() -> void:
	for rope in ropes.lines_on(ropes.hand):
		_gone[rope] = "let go"
		ropes.let_go(rope, ropes.hand)
	if not ropes.lines_on(ropes.waist).is_empty() and _untie < 0.0:
		_untie = UNTIE


func _take_up() -> void:
	var me := world.player.global_position
	var carry := ropes.hand if ropes.lines_on(ropes.waist).is_empty() else ropes.waist
	for prop in _props:
		var stake := prop as Stake
		if stake == null or stake.pulled or stake.global_position.distance_to(me) > REACH:
			continue
		for rope in ropes.lines_on(stake.ring):
			ropes.move_end(rope, stake.ring, carry)


func _stake_here() -> void:
	var player := world.player
	var stake: RigidBody3D = Props.stake(world, player.global_position - player.global_basis.z * 0.8)
	_props.append(stake)
	for end in [ropes.hand, ropes.waist]:
		for rope in ropes.lines_on(end):
			ropes.move_end(rope, end, stake.ring)
	_untie = -1.0


## Drops you into one of the run's own storms and ties everything up again there.
func _storm(key: String) -> void:
	var place := Scenarios.find(world, Scenarios.by_key(key))
	if place.is_empty():
		_note = "no %s in this run's first three days" % key
		return
	ropes.clear()
	world.respawn(place.x, place.z, place.yaw, place.time)
	_set_wind("real")
	_note = Scenarios.by_key(key).label
	await _ground()
	build()


func _ground() -> void:
	while not world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
		await get_tree().process_frame


func _physics_process(delta: float) -> void:
	if _untie < 0.0:
		return
	_untie -= delta
	if _untie < 0.0:
		for rope in ropes.lines_on(ropes.waist):
			_gone[rope] = "untied"
			ropes.let_go(rope, ropes.waist)


func _process(_delta: float) -> void:
	readout.text = _readout()
	for setup in _setups:
		var body: Node3D = setup.body
		if not is_instance_valid(body):
			continue
		var tag: Label3D = setup.tag
		tag.global_position = body.global_position + Vector3.UP * 1.3
		tag.text = "%s\n%s" % [setup.label, _states(setup.lines)]


func _readout() -> String:
	var lines := PackedStringArray()
	var blowing := world.weather.felt_wind(world.player.global_position)
	lines.append("wind %s %d m/s%s" % [wind_mode, roundi(blowing.length()), "  GUST" if _gusting() else ""])
	for setup in _setups:
		lines.append("%s   %s" % [setup.label, _states(setup.lines)])
	var you := "free"
	if not ropes.lines_on(ropes.waist).is_empty():
		you = "untying %.1f s" % _untie if _untie >= 0.0 else "waist-tied"
	elif not ropes.lines_on(ropes.hand).is_empty():
		you = "holding"
	var drag: Vector3 = world.player.get_meta(&"rope_drag", Vector3.ZERO)
	lines.append("you: %s, dragged %.1f m/s" % [you, Vector2(drag.x, drag.z).length()])
	var pulled := _props.filter(func(prop: Node3D) -> bool:
		return is_instance_valid(prop) and prop is Stake and prop.pulled).size()
	if pulled > 0:
		lines.append("%d stake%s pulled out" % [pulled, "" if pulled == 1 else "s"])
	lines.append("ropes %.2f ms a tick" % ropes.cost_ms)
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
			var stake: RigidBody3D = Props.stake(world, center + Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 3.0) * 6.0)
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
	keys.visible = false
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
	await _shot(out_dir, "06_storm_pinned_and_crate", camera, [Vector3(0.0, 9.0, 3.5), Vector3(0.0, 20.0, 0.5)])
	_gust_now()
	await _wait(1.6)
	await _shot(out_dir, "07_gust_rising", camera, overview)
	await _wait(2.2)
	await _shot(out_dir, "08_gust_peak", camera, overview)
	await _wait(4.0)
	await _shot(out_dir, "09_after_gust_snap_rig", camera, [Vector3(4.0, 4.0, 2.2), Vector3(7.0, 10.0, 0.4)])
	var eye: Transform3D = world.player.camera.global_transform
	camera.global_transform = eye
	camera.look_at(ropes.lines_on(ropes.hand)[0].strand.points[0].lerp(
		ropes.lines_on(ropes.hand)[0].strand.points[-1], 0.6))
	await _shot(out_dir, "10_your_line_in_storm", camera, [])
	_hand_or_waist()
	await _wait(3.0)
	camera.global_transform = eye
	camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(-35.0))
	camera.rotate_y(deg_to_rad(-40.0))
	await _shot(out_dir, "11_waist_tied", camera, [])
	_set_wind("breeze")
	_hand_or_waist()
	_let_go()
	await _walk_tow(camera)
	await _shot(out_dir, "12_towing", camera, [])
	_storm("deep")
	await _wait(1.0)
	await _ground()
	await _wait(8.0)
	await _shot(out_dir, "13_deep_storm", camera, overview)
	await _shot(out_dir, "14_deep_storm_one_line", camera, one_line)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


## Takes up the tow line and walks you upwind with it, by script.
func _walk_tow(camera: Camera3D) -> void:
	var player := world.player
	player.global_position = _spot(-4.0, -5.5)
	_take_up()
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
