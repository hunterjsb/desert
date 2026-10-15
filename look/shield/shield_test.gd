extends Node
## Look-test: a bubble shield in the game's own storms on seed 1234. Sit inside
## while a wall rolls over and engulfs it, walk out into the storm and look
## back, switch it off and on for the bloom. The storm pass, its CPU twin, the
## particles and the sound all carve the bubble out through Weather's shelters;
## nothing here draws dust of its own.
##   godot --path . res://look/shield/shield.tscn
##   godot --path . --disable-vsync res://look/shield/shield.tscn -- --capture <dir> [--only in_deep,bloom_0.25s]

const Generator := preload("res://look/shield/generator.gd")

const SEED := 1234
const DAYTIME := [0.35, 0.55]
const WARPS := {KEY_1: 1.0, KEY_2: 5.0, KEY_3: 20.0, KEY_4: 60.0}
## Keys to scenarios: a front at a distance (contact is 0), or deep inside.
const JUMPS := {KEY_5: ["front", 300.0], KEY_6: ["front", 50.0], KEY_7: ["front", 0.0], KEY_8: ["deep", 0.0]}
const KEYS := [
	["B", "shield on and off"], ["C", "the camp to you"], ["1-4", "time x1, x5, x20, x60"],
	["Space", "pause"], ["5-8", "a front at 300 m, 50 m, contact, deep"], ["H", "hide the readout"],
]
## The generator sits this far ahead of you after a jump, m.
const AHEAD := 2.0
## The camp round the generator, as [size, colour, metres right, metres ahead, yaw degrees].
const CAMP := [
	[Vector3(1.0, 0.7, 0.7), Color(0.45, 0.33, 0.22), -2.2, 1.0, 15.0],
	[Vector3(0.7, 0.5, 0.6), Color(0.4, 0.3, 0.2), -2.9, 1.9, -20.0],
	[Vector3(1.4, 0.45, 0.6), Color(0.35, 0.3, 0.26), 2.4, 0.6, -10.0],
	[Vector3(0.9, 0.05, 0.7), Color(0.12, 0.16, 0.32), 1.2, -1.4, 30.0],
	[Vector3(0.12, 1.1, 0.12), Color(0.5, 0.5, 0.52), 3.6, 2.6, 0.0],
]
## The planter's green, on the third box.
const GREEN := Color(0.25, 0.5, 0.18)
## Capture mode's shots: scenario kind, front distance, metres the camera
## stands back from the generator (2 is inside, by the camp), yaw from facing
## the front, pitch, the shield ("on", "off", "bloom:<s>" or "collapse:<s>"
## switched at the moment and shot that long after), name.
const SHOTS := [
	["front", 300.0, 2.0, 0.0, 7.0, "on", "in_300m"],
	["front", 50.0, 2.0, 0.0, 12.0, "on", "in_50m"],
	["front", 0.0, 2.0, 0.0, 6.0, "on", "in_contact"],
	["front", 0.0, 2.0, 80.0, 4.0, "on", "in_contact_along"],
	["deep", 0.0, 2.0, 0.0, 2.0, "on", "in_deep"],
	["deep", 0.0, 2.0, 0.0, -20.0, "on", "in_deep_camp"],
	["deep", 0.0, 2.0, 0.0, 70.0, "on", "in_deep_up"],
	["deep", 0.0, 2.0, 160.0, 2.0, "on", "in_deep_downwind"],
	["deep", 0.0, 12.0, 0.0, -6.0, "on", "out_deep_5m"],
	["deep", 0.0, 17.0, 0.0, -4.0, "on", "out_deep_10m"],
	["front", 300.0, 24.0, 0.0, 8.0, "on", "out_300m"],
	["front", 0.0, 24.0, 0.0, 6.0, "on", "out_contact"],
	["deep", 0.0, 2.0, 0.0, 2.0, "off", "deep_no_shield"],
	["deep", 0.0, 2.0, 0.0, 2.0, "bloom:0.08", "bloom_0.08s"],
	["deep", 0.0, 2.0, 0.0, 2.0, "bloom:0.25", "bloom_0.25s"],
	["deep", 0.0, 12.0, 0.0, -6.0, "bloom:0.2", "bloom_outside_0.2s"],
	["deep", 0.0, 2.0, 0.0, 2.0, "collapse:0.4", "collapse_0.4s"],
]

var generator: Generator
var camp := Node3D.new()

var _paused_warp := 1.0
var _jump := ""

@onready var world: World = $World
@onready var readout: Label = $Hud/Readout


func _enter_tree() -> void:
	# Before the World's _ready builds the weather from it.
	Tuning.current().run_seed = SEED


func _ready() -> void:
	Dev.set_scene_keys(KEYS)
	generator = Generator.new()
	world.content.add_child(generator)
	world.content.add_child(camp)
	for i in CAMP.size():
		var entry: Array = CAMP[i]
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = entry[0]
		var look := StandardMaterial3D.new()
		look.albedo_color = entry[1]
		look.roughness = 0.85
		mesh.material = look
		box.mesh = mesh
		box.position = Vector3(entry[2], 0.0, -entry[3])
		box.rotation.y = deg_to_rad(entry[4])
		camp.add_child(box)
		if i == 2:
			var leaves := MeshInstance3D.new()
			var blob := SphereMesh.new()
			blob.radius = 0.32
			blob.height = 0.4
			var green := StandardMaterial3D.new()
			green.albedo_color = GREEN
			blob.material = green
			leaves.mesh = blob
			leaves.position.y = 0.3
			box.add_child(leaves)
	camp_to_player()
	generator.set_now(true)
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at != -1:
		var only := args.find("--only")
		_capture(args[at + 1] if args.size() > at + 1 else "user://shield",
			args[only + 1].split(",") if only != -1 and args.size() > only + 1 else PackedStringArray())


func _process(_delta: float) -> void:
	readout.text = _readout()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or $Scenarios.visible:
		return
	var code := key.physical_keycode
	if code == KEY_B:
		generator.switch(not generator.on)
	elif code == KEY_C:
		camp_to_player()
	elif WARPS.has(code):
		world.time_warp = WARPS[code]
	elif JUMPS.has(code):
		jump(JUMPS[code][0], JUMPS[code][1])
		camp_to_player()
	elif code == KEY_SPACE and not world.player.flying:
		if world.time_warp > 0.0:
			_paused_warp = world.time_warp
			world.time_warp = 0.0
		else:
			world.time_warp = _paused_warp
	elif code == KEY_H:
		$Hud.visible = not $Hud.visible


## Drops you at a scenario found in this run's own weather: kind "front" (a
## front `distance` m upwind, coming at you) or "deep".
func jump(kind: String, distance: float) -> Dictionary:
	var scenario := {"key": "%s_%d" % [kind, distance], "kind": kind, "distance": distance, "day": DAYTIME}
	var place := Scenarios.find(world, scenario)
	_jump = scenario.key if not place.is_empty() else "%s: none in 3 days" % scenario.key
	if not place.is_empty():
		world.respawn(place.x, place.z, place.yaw, place.time)
	return place


## Sets the generator down AHEAD m in front of you, the camp round it.
func camp_to_player() -> void:
	var player := world.player
	var ahead := -player.global_basis.z
	ahead.y = 0.0
	place_camp(player.global_position + ahead.normalized() * AHEAD, player.global_rotation.y)


func place_camp(at: Vector3, yaw: float) -> void:
	generator.global_position = Vector3(at.x, world.height_under(at), at.z)
	camp.global_position = generator.global_position
	camp.global_rotation = Vector3(0.0, yaw, 0.0)
	for box: MeshInstance3D in camp.get_children():
		var size: Vector3 = (box.mesh as BoxMesh).size
		box.global_position.y = world.height_under(box.global_position) + size.y * 0.5 - 0.03


func _readout() -> String:
	var weather := world.weather
	var eye := world.player.camera.global_position
	var shell := eye.distance_to(generator.shelter.global_position) - generator.shelter.radius
	var shield := "shield %s" % ("on" if generator.on else "off")
	var where := "inside" if weather.shelter_at(eye) > 0.0 else "%d m out" % roundi(shell) \
		if generator.shelter.radius > 0.0 else "-"
	var front := weather.seen_front
	var shown := "-" if front == -INF else ("in %d m" % roundi(front) if front >= 0.0 else "%d m" % roundi(-front))
	var state := "paused" if world.time_warp == 0.0 else "×%d" % roundi(world.time_warp)
	return "%s   %s   %s\nfront %s   seen %d%%   wind %d m/s   %s" % [shield, where, state, shown,
		roundi(weather.seen_storm * 100.0), roundi(weather.wind.length()), _jump]


## Walks SHOTS, saving a PNG of each with its frame times. Renders 1920x1080 in
## a small window that can't take focus; nothing but this script moves the
## camera, and it's silent.
func _capture(out_dir: String, only: PackedStringArray) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	set_process_unhandled_input(false)
	$Scenarios.set_process_unhandled_input(false)
	world.player.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	$Hud.visible = false
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	print("capture: %s at %s%s" % [out_dir, get_viewport().get_visible_rect().size, _shared_gpu()])
	var worst_ms := 0.0
	var worst_gpu := 0.0
	for n in SHOTS.size():
		var shot: Array = SHOTS[n]
		if not only.is_empty() and not only.has(shot[6]):
			continue
		var place := jump(shot[0], shot[1])
		if place.is_empty():
			print("  %-22s none in this run's weather" % shot[6])
			continue
		var upwind := Vector3(-sin(place.yaw), 0.0, -cos(place.yaw))
		var at := world.player.global_position + upwind * AHEAD
		place_camp(at, place.yaw)
		var stand: Vector3 = generator.global_position - upwind * float(shot[2])
		world.player.global_position = Vector3(stand.x, world.height_under(stand) + 0.1, stand.z)
		var action: String = shot[5]
		generator.set_now(action == "on" or action.begins_with("collapse"))
		# Hold the clock while the ground streams in, then run up to the moment.
		world.time_warp = 0.0
		var waited := Time.get_ticks_msec()
		while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 20000:
			await get_tree().process_frame
		world.player.rotation.y = place.yaw + deg_to_rad(shot[3])
		world.player.camera.rotation_degrees.x = shot[4]
		world.time = place.time - 1.6
		world.time_warp = 1.0
		await get_tree().create_timer(0.6).timeout
		var timed := action == "on" or action == "off"
		var average := 0.0
		var longest := 0.0
		var gpu := 0.0
		if timed:
			var frames := 0
			var started := Time.get_ticks_usec()
			var last := started
			while Time.get_ticks_usec() - started < 1000000:
				await get_tree().process_frame
				var now := Time.get_ticks_usec()
				longest = maxf(longest, (now - last) / 1000.0)
				last = now
				gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
				frames += 1
			average = (Time.get_ticks_usec() - started) / 1000.0 / frames
			gpu /= frames
			worst_ms = maxf(worst_ms, average)
			worst_gpu = maxf(worst_gpu, gpu)
		else:
			generator.switch(action.begins_with("bloom"))
			for i in roundi(float(action.get_slice(":", 1)) * Engine.physics_ticks_per_second):
				await get_tree().physics_frame
			await get_tree().process_frame
			await get_tree().process_frame
		var path := out_dir.path_join("%02d_%s.png" % [n + 1, shot[6]])
		get_viewport().get_texture().get_image().save_png(path)
		var eye := world.player.camera.global_position
		var times := "frame %5.2f ms (worst %5.2f)  gpu %5.2f ms" % [average, longest, gpu] if timed else "-"
		print("  %-22s front %7.1f m  seen %3d%%  shell %+5.1f m  %s" % [shot[6], -world.weather.seen_front,
			roundi(world.weather.seen_storm * 100.0),
			eye.distance_to(generator.shelter.global_position) - generator.shelter.radius, times])
	print("capture: worst average frame %.2f ms, worst gpu %.2f ms; storm map upload worst %.2f ms, %d jump rebuilds%s"
		% [worst_ms, worst_gpu, world.weather.map.max_upload_ms, world.weather.map.rebuilds, _shared_gpu()])
	get_tree().quit()


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
