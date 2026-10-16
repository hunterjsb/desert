extends Node
## Look-test: the art direction. A camp beside the corner of the ruin nearest
## the run's start, on seed 1234 in the game's own light and weather: a
## floating crate frame with a hover tray, a battery and a hook, a planter, a
## shield generator with its bubble up, a stake with a line to the crate, and
## a charger under a solar panel. Each candidate look draws over the same real
## devices, so sizes, sockets and the rope are the game's; nothing in game/
## changes. --storm stands the camp in a storm instead of clear skies.
##   godot --path . res://look/style/style.tscn -- --look b [--storm]
##   godot --path . --disable-vsync res://look/style/style.tscn -- --look b [--storm] --capture <dir> [--only crate]
## look/style/shoot.sh shoots every candidate and builds the contact sheets.

const SEED := 1234
const LOOKS := {
	"grey": preload("res://look/style/look.gd"),
	"a": preload("res://look/style/look_a.gd"),
	"b": preload("res://look/style/look_b.gd"),
	"c": preload("res://look/style/look_c.gd"),
	"d": preload("res://look/style/look_d.gd"),
}
const MOMENTS := {"morning": 0.285, "midmorning": 0.4, "noon": 0.5, "dusk": 0.715}
## The camp's middle, where the generator stands, in the ruin's plan: off its
## end wall, by the corner. The camp faces its camera turned this far from
## straight away from that corner, so the corner stands off to one side.
const CAMP_AT := Vector2(13.5, 3.0)
const CAMP_TURN := 12.0
## The camp in its own frame, x right and z toward the 8 m camera, m: catalog
## id, x, z, yaw degrees, parts. The crate floats; the rest stand on the sand.
const CAMP := [
	[&"crate_frame", -1.9, 0.6, 25.0, [&"battery", &"hover_tray"]],
	[&"planter", 2.0, 0.7, -18.0, [&"battery", &"seedling", &"seedling", &"seedling", &"sapling"]],
	[&"charger", 1.1, -1.6, 35.0, [&"battery", &"solar_panel"]],
	[&"shield", 0.0, 0.0, 10.0, [&"battery"]],
]
const STAKE_AT := Vector2(-3.9, -0.9)
## Where the two finds lie half-buried, x and z, with their lean, degrees.
const FINDS := [[Vector2(-0.55, 2.6), 14.0], [Vector2(0.75, 2.75), -9.0]]
## Shots: name, moment ("storm" for the storm), camera in the camp's frame
## (x, metres over the sand, z), and what it looks at, camp frame.
const SHOTS := [
	["camp8_morning", "morning", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
	["camp8_midmorning", "midmorning", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
	["camp8_noon", "noon", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
	["camp8_dusk", "dusk", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
	["camp50", "midmorning", Vector3(14.0, 4.0, 48.0), Vector3(0.0, 1.0, 0.0)],
	["crate", "midmorning", Vector3(-2.5, 1.12, 2.05), Vector3(-1.9, 1.08, 0.6)],
	["crate5", "midmorning", Vector3(-3.65, 1.7, 5.3), Vector3(-1.9, 1.1, 0.6)],
	["finds", "midmorning", Vector3(0.1, 0.62, 3.45), Vector3(0.1, 0.04, 2.68)],
	["storm", "storm", Vector3(0.9, 1.7, 5.2), Vector3(0.0, 0.5, 0.0)],
]
## Daytime to look for a storm in, and how long it must have stood full
## where the camp is, s.
const STORM_DAY := [0.38, 0.55]
const STORM_HELD := 300.0

var look: RefCounted
var generator: ShieldGenerator
var camp: Array[Device] = []
var ruin: Ruin
var storm := false
## The camp's middle in world metres, and its yaw.
var _middle := Vector2.ZERO
var _yaw := 0.0
var _eye := Vector3(0.0, 1.6, 0.0)

@onready var world: World = $World


func _enter_tree() -> void:
	var args := OS.get_cmdline_user_args()
	storm = args.has("--storm")
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	# Clear skies unless it's the storm's turn; the equator is stormy.
	if not storm:
		tuning.storm_threshold = 0.9


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var which := args[args.find("--look") + 1] if args.has("--look") else "b"
	look = LOOKS[which].new()
	var capturing := args.has("--capture")
	if capturing:
		_quiet()
	# Ruins were planned with salvage on; no finds from here, only the camp.
	world.tuning.salvage = false
	ruin = world.shape.ruins.around(world.spawn.x, world.spawn.y, 4000.0)[0]
	var corner := Vector2(Ruin.HALF)
	var away := (ruin.to_world(CAMP_AT) - ruin.to_world(corner)).normalized().rotated(deg_to_rad(-CAMP_TURN))
	_middle = ruin.to_world(CAMP_AT)
	_yaw = atan2(away.x, away.y)
	var wind := world.weather.field.prevailing_at(0.0)
	look.wind = Vector3(wind.x, 0.0, wind.y).normalized()
	var start := _storm_time() if storm else _run_time(MOMENTS.midmorning)
	if storm and is_nan(start):
		print("style: no storm over the camp in three days")
		get_tree().quit()
		return
	var stand := _to_world(Vector3(1.6, 0.0, 8.0))
	world.respawn(stand.x, stand.y, _yaw, start)
	world.time_warp = 0.0
	await _ground()
	_eye = world.player.camera.global_position - world.player.global_position
	_build_camp()
	_dress()
	print("style: %s, %s, ruin at %d,%d turned %d, camp at %.0f,%.0f" % [look.title(), "storm" if storm else "clear",
		ruin.center.x, ruin.center.y, ruin.turn, _middle.x, _middle.y])
	if capturing:
		var only := args.find("--only")
		_capture(args[args.find("--capture") + 1],
			args[only + 1].split(",") if only != -1 and args.size() > only + 1 else PackedStringArray())
	else:
		world.time_warp = 1.0


## A run time on the first day at a time of day.
func _run_time(of_day: float) -> float:
	return fposmod(of_day - world.tuning.start_time_of_day, 1.0) * world.tuning.day_minutes * 60.0


## The first daytime moment in three days the camp has stood deep in a storm
## for a while, or NAN.
func _storm_time() -> float:
	var field := world.weather.field
	var day := world.weather.day
	var t := STORM_HELD
	while t < 3.0 * 24.0 * 3600.0:
		var hour := day.time_of_day(t)
		if hour >= STORM_DAY[0] and hour <= STORM_DAY[1] and field.storm_at(_middle.x, _middle.y, t) >= 1.0:
			var held := true
			for back in range(30, int(STORM_HELD), 30):
				held = held and field.storm_at(_middle.x, _middle.y, t - back) >= 1.0
			if held:
				return t
		t += 10.0
	return NAN


## A camp-frame point as world metres (x, z).
func _to_world(p: Vector3) -> Vector2:
	return _middle + Vector2(p.x, p.z).rotated(-_yaw)


## A camp-frame point in the engine, `p.y` metres over the sand there.
func _engine(p: Vector3) -> Vector3:
	var w := _to_world(p)
	return Vector3(world.engine_x(w.x), world.height_at(w.x, w.y) + p.y, world.engine_z(w.y))


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


## The camp, each piece set down and held still: the bubble keeps the wind
## off, but shots must match from candidate to candidate.
func _build_camp() -> void:
	var turn := Basis(Vector3.UP, _yaw)
	for entry: Array in CAMP:
		var device := Catalog.device(entry[0])
		device.set_meta(&"id", entry[0])
		world.content.add_child(device)
		for part_id: StringName in entry[4]:
			var part := Catalog.part(part_id)
			world.content.add_child(part)
			for socket in device.sockets():
				if socket.kind == part.kind and socket.part == null:
					device.fit(part, socket)
					break
		var size: Vector3 = Catalog.DEVICES[entry[0]].size
		var floats: bool = entry[4].has(&"hover_tray")
		var at := _engine(Vector3(entry[1], world.tuning.hover_height if floats else size.y * 0.5 + 0.02, entry[2]))
		device.global_transform = Transform3D(turn * Basis(Vector3.UP, deg_to_rad(entry[3])), at)
		device.freeze = true
		camp.append(device)
		if device is ShieldGenerator:
			generator = device
	var crate := camp[0]
	var stake := Catalog.stake()
	stake.set_meta(&"id", &"stake")
	world.content.add_child(stake)
	var spot := _engine(Vector3(STAKE_AT.x, 0.0, STAKE_AT.y))
	stake.drive(spot, spot.y)
	# The hook goes on the ring mount facing the stake.
	var ring: Socket = null
	for socket in crate.sockets():
		if socket.kind == &"ring" and (ring == null or socket.global_position.distance_to(spot) < ring.global_position.distance_to(spot)):
			ring = socket
	var hook := Catalog.part(&"hook")
	world.content.add_child(hook)
	crate.fit(hook, ring)
	Line.between(world, crate.free_tie(spot), stake.free_tie(crate.global_position), 0.6)
	camp.append(stake)
	generator.stand(true)


## Every camp piece in the candidate's look, the ruin, and its two finds.
func _dress() -> void:
	for device in camp:
		_dress_device(device)
	for line in world.content.get_children():
		if line is Line:
			(line as Line).rope.strand.material_override.set_shader_parameter("color", look.rope_color())
	var view := _ruin_view()
	if view != null:
		look.ruin(view, view.global_transform)
	var found: Array[Node3D] = look.finds()
	for i in found.size():
		var entry: Array = FINDS[i]
		var at := _engine(Vector3(entry[0].x, -0.06, entry[0].y))
		world.content.add_child(found[i])
		found[i].global_transform = Transform3D(Basis(Vector3.UP, _yaw + 0.6 * i - 0.2)
			* Basis(Vector3.BACK, deg_to_rad(entry[1])), at)


func _dress_device(device: Device) -> void:
	var id: StringName = device.get_meta(&"id")
	var skin: Node3D = look.stake() if id == &"stake" else look.frame(id, Catalog.DEVICES[id].size)
	if skin == null:
		return
	var fitted := {}
	for socket in device.sockets():
		for node in socket.fitted:
			fitted[node] = socket
	for socket in device.sockets():
		if socket.marker != null:
			socket.marker.visible = false
		var mount: Node3D = look.mount(socket.kind)
		if mount != null:
			socket.add_child(mount)
		if socket.part == null:
			continue
		var part_id := _part_id(socket.part)
		var shown: Node3D = look.part(part_id, Catalog.PARTS[part_id].size)
		if shown != null:
			socket.add_child(shown)
		if shown != null or part_id == &"rope_end":
			for node in socket.fitted:
				if node is GeometryInstance3D:
					node.visible = false
	for child in device.get_children():
		if child is MeshInstance3D and not fitted.has(child):
			child.visible = false
	device.add_child(skin)


static func _part_id(part: Part) -> StringName:
	for id: StringName in Catalog.PARTS:
		if Catalog.PARTS[id].label == part.label:
			return id
	return &""


func _ruin_view() -> MeshInstance3D:
	for chunk: TerrainChunk in world.terrain.chunks():
		if chunk.ruin() != null and chunk.ruin().center == ruin.center:
			return chunk._ruin_view
	return null


## A small window that can't take focus, nothing but this script moving the
## camera, and silence.
func _quiet() -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	world.player.set_process_unhandled_input(false)
	world.player.hands.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	world.player.flying = true
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false


## Every shot of this weather, rendered at 1920x1080, with what it cost to draw.
func _capture(out_dir: String, only: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var storm_at := world.time
	for shot: Array in SHOTS:
		if (shot[1] == "storm") != storm or (not only.is_empty() and not only.has(shot[0])):
			continue
		generator.battery().charge_wh = generator.battery().capacity()
		var eye := _engine(shot[2])
		world.player.global_position = eye - _eye
		await _ground()
		eye = _engine(shot[2])
		world.player.global_position = eye - _eye
		var target := _engine(shot[3])
		var to := target - eye
		world.player.rotation.y = atan2(-to.x, -to.z)
		world.player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
		if storm:
			# Run the storm a moment so its dust is moving.
			world.time = storm_at - 1.6
			world.time_warp = 1.0
			await get_tree().create_timer(0.8).timeout
		else:
			world.time = _run_time(MOMENTS[shot[1]])
			world.time_warp = 0.0
			# Physics ticks, not frames: the light follows the clock on the tick.
			for i in 20:
				await get_tree().physics_frame
		var gpu := 0.0
		for i in 12:
			await get_tree().process_frame
			gpu = maxf(gpu, RenderingServer.viewport_get_measured_render_time_gpu(rid))
		var calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(shot[0] + ".png"))
		print("  %-18s gpu %5.2f ms  draws %5d  triangles %8d" % [shot[0], gpu, calls, prims])
	print("style: done%s" % _shared_gpu())
	get_tree().quit()


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
