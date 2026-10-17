extends Node
## Look-test: the suit's headlamp on seed 1234, deep in a storm at midnight
## with no wind. A walked path is shot from behind its start, the way you'd
## look along it, with no light but the storm's and then by the headlamp; then
## the run's kit crate, its shield up, and a charger's lamp beside it, without
## the headlamp and with it. It prints the sand's lightness (CIE L*) 5, 10 and
## 15 m ahead and how much darker the steps there are, and what the headlamp
## costs the GPU, with and without shadows:
##   godot --path . --disable-vsync res://look/headlamp/headlamp.tscn -- --capture <dir>
## look/headlamp/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## The walk's start, metres east and south of spawn, away from the kit's camp.
const WALK := Vector2(0.0, -30.0)
const WALK_SECONDS := 9.0
## You stand this far behind the walk's start, looking this far down.
const BACK := 2.0
const PITCH := -5.0
## The camp is set down this far south of spawn, and shot from this far west
## of its crate, m.
const CAMP := 40.0
const CAMP_BACK := 6.0
const AHEAD := [5.0, 10.0, 15.0]
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	# A full storm everywhere that never passes, in still air.
	tuning.storm_ramp = 0.04
	tuning.storm_threshold = -2.0
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://headlamp")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var midnight := (1.0 - world.tuning.start_time_of_day) * world.tuning.day_minutes * 60.0
	world.respawn(world.spawn.x, world.spawn.y, -PI * 0.5, midnight)
	await _ground()
	for i in 600:
		if world.weather.map.ready:
			break
		await get_tree().process_frame

	var tracks := world.terrain.tracks
	_put(world.spawn + WALK, -PI * 0.5)
	await _ticks(30)
	Input.action_press("move_forward")
	var walked := 0.0
	while walked < WALK_SECONDS:
		await get_tree().physics_frame
		walked += get_physics_process_delta_time()
	Input.action_release("move_forward")
	await _ticks(30)
	player.set_physics_process(false)
	player.flying = true
	tracks.set_physics_process(false)
	var made := tracks.clock
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false

	var lamp := player.headlamp
	var start: Vector2 = world.spawn + WALK
	_stand(Vector3(world.engine_x(start.x - BACK), 0.0, world.engine_z(start.y)), Vector3.RIGHT)
	for lit in [false, true]:
		await _lamp(lamp, lit)
		var shots := {}
		for state: Array in [["before", 10.0], ["fresh", 0.0]]:
			tracks.clock = made + state[1]
			await _ticks(24)
			shots[state[0]] = get_viewport().get_texture().get_image()
		var name := "path_%s" % ("headlamp" if lit else "dark")
		shots.fresh.save_png(out_dir.path_join(name + ".png"))
		var readings := PackedStringArray()
		for d: float in AHEAD:
			var r := _reading(shots.before, shots.fresh, start + Vector2(d - BACK, 0.0))
			readings.append("%dm sand %.1f, steps %.1f darker" % [d, r.x, r.y])
		print("headlamp: %-16s light %.3f  %s" % [name, world.weather.seen_light, " · ".join(readings)])
		if lit:
			await _gpu_cost(lamp)
	tracks.clock = made

	# The camp: the run's kit, its crate's shield up, and a charger's lamp beside it.
	_put(world.spawn + Vector2(0.0, CAMP), -PI * 0.5)
	var crate: Device = Runs.kit(world).filter(func(n: Node) -> bool:
		return n is Device and (n as Device).stats().lift_kg > 0.0)[0]
	await _ticks(120)
	for seated in crate.mounted():
		if seated is ShieldGenerator:
			seated.interact(player)
	var charger := Catalog.device(&"charger")
	world.content.add_child(charger)
	var by := crate.global_position + Vector3(-1.2, 0.0, -1.6)
	charger.global_position = Vector3(by.x, world.height_under(by) + 0.2, by.z)
	for id: StringName in [&"battery", &"lamp"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		charger.fit(part, charger.sockets().filter(func(s: Socket) -> bool: return s.kind == part.kind)[0])
	charger.battery().charge_wh = charger.battery().capacity()
	world.power.wake(charger)
	_stand(crate.global_position + Vector3(-CAMP_BACK, 0.0, 0.0), Vector3.RIGHT)
	for i in 240:
		await get_tree().process_frame
	for lit in [false, true]:
		await _lamp(lamp, lit)
		await _ticks(24)
		var name := "camp_%s" % ("headlamp" if lit else "dark")
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		print("headlamp: %-16s shield %s" % [name, "up" if world.devices().any(func(d: Device) -> bool:
			return d is ShieldGenerator and d.running()) else "down"])
	get_tree().quit()


## The headlamp held off, or left to come on by itself and given its fade.
func _lamp(lamp: Headlamp, lit: bool) -> void:
	lamp.set_physics_process(lit)
	if not lit:
		lamp.visible = false
	await _ticks(120)


## The sand's lightness over the walk's line `at` (world metres), with every
## mark filled, and how much darker the marks there are fresh: over the
## pixels a mark darkened, their mean before less their mean fresh.
func _reading(before: Image, fresh: Image, at: Vector2) -> Vector2:
	var camera := world.player.camera
	var ground := Vector3(world.engine_x(at.x), world.height_at(at.x, at.y), world.engine_z(at.y))
	var middle := camera.unproject_position(ground) * Vector2(before.get_size()) / get_viewport().get_visible_rect().size
	var reach := camera.unproject_position(ground + Vector3(0.0, 0.0, 0.5)) * Vector2(before.get_size()) \
		/ get_viewport().get_visible_rect().size
	var half := maxi(4, roundi(absf(reach.x - middle.x)))
	var sand := 0.0
	var count := 0
	var marks := Vector2.ZERO
	for y in range(roundi(middle.y) - half / 4, roundi(middle.y) + half / 4 + 1):
		for x in range(roundi(middle.x) - half, roundi(middle.x) + half + 1):
			if x < 0 or y < 0 or x >= before.get_width() or y >= before.get_height():
				continue
			var a := _lightness(before.get_pixel(x, y))
			var b := _lightness(fresh.get_pixel(x, y))
			sand += a
			count += 1
			if a - b > 0.3:
				marks += Vector2(a - b, 1.0)
	return Vector2(sand / maxi(count, 1), marks.x / maxf(marks.y, 1.0))


static func _lightness(c: Color) -> float:
	var y := c.srgb_to_linear().get_luminance()
	return 116.0 * pow(y, 1.0 / 3.0) - 16.0 if y > 0.008856 else 903.3 * y


## The GPU's time per frame with the headlamp on, off, and on with shadows,
## alternated so a busy machine weighs on each alike.
func _gpu_cost(lamp: Headlamp) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var sums := [0.0, 0.0, 0.0]
	for round in GPU_ROUNDS:
		for way in 3:
			lamp.visible = way != 0
			lamp.shadow_enabled = way == 2
			for i in 10:
				await get_tree().process_frame
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sums[way] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	lamp.shadow_enabled = false
	lamp.visible = true
	var n := float(GPU_ROUNDS * GPU_FRAMES)
	print("headlamp: gpu %.3f ms a frame without it, %.3f with it, %.3f with its shadows, at %s%s"
		% [sums[0] / n, sums[1] / n, sums[2] / n, get_viewport().get_visible_rect().size, _shared_gpu()])


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""


## Your eyes at a place on the sand, looking along `facing`, a little down.
func _stand(at: Vector3, facing: Vector3) -> void:
	var player := world.player
	var eye := Vector3(at.x, world.height_under(at) + 1.65, at.z)
	player.global_position = eye - player.camera.position
	player.rotation.y = atan2(-facing.x, -facing.z)
	player.camera.rotation_degrees.x = PITCH


func _put(at: Vector2, yaw: float) -> void:
	world.teleport(world.player, Transform3D(Basis(Vector3.UP, yaw),
		Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.1, world.engine_z(at.y))))
	world.player.velocity = Vector3.ZERO


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
