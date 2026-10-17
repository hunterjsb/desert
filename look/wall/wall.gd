extends Node
## Look-test: the game's own storm walls on seed 1234, with keys that jump to
## the dev scenarios at set distances from a front, the clock under your
## thumb, and a capture mode for frame times. Nothing here is faked; it drives
## the World and reads what the weather reports.
##   godot --path . res://look/wall/wall.tscn
##   godot --path . --disable-vsync res://look/wall/wall.tscn -- --capture <dir> [--only 5km,deep]

const SEED := 1234
const DAYTIME := [0.35, 0.55]
const WARPS := {KEY_1: 1.0, KEY_2: 5.0, KEY_3: 20.0, KEY_4: 60.0}
## Keys to scenarios: a front at a distance (contact is 0), deep inside, or
## inside with clear air 100 m upwind.
const JUMPS := {
	KEY_5: ["front", 3000.0], KEY_6: ["front", 1000.0], KEY_7: ["front", 300.0],
	KEY_8: ["front", 50.0], KEY_9: ["front", 0.0], KEY_0: ["deep", 0.0], KEY_MINUS: ["back", 100.0],
}
const KEYS := [
	["1-4", "time x1, x5, x20, x60"], ["Space", "pause"],
	["5-9", "a front at 3 km, 1 km, 300 m, 50 m, contact"], ["0", "deep in the storm"],
	["-", "a storm about to clear"], ["R", "back to spawn"], ["H", "hide the readout"],
]
## Capture mode's shots: scenario kind, distance, yaw from facing it, pitch, name.
const SHOTS := [
	["front", 5000.0, 0.0, 3.0, "5km"],
	["front", 3000.0, 0.0, 4.0, "3km"],
	["front", 1800.0, 0.0, 6.0, "1800m"],
	["front", 1000.0, 0.0, 9.0, "1km"],
	["front", 500.0, 0.0, 14.0, "500m"],
	["front", 300.0, 0.0, 18.0, "300m"],
	["front", 300.0, 75.0, 8.0, "300m_along_the_front"],
	["front", 300.0, 180.0, 5.0, "300m_looking_away"],
	# Along fronts and past storms' ends, where a wall's side shows.
	["front", 3000.0, -50.0, 4.0, "3km_left"],
	["front", 3000.0, 50.0, 4.0, "3km_right"],
	["front", 1000.0, -70.0, 6.0, "1km_along_left"],
	["front", 1000.0, 70.0, 6.0, "1km_along_right"],
	["front", 300.0, -75.0, 8.0, "300m_along_left"],
	["front", 300.0, 120.0, 5.0, "300m_past_the_end"],
	["front", 100.0, 0.0, 20.0, "100m"],
	["front", 50.0, 0.0, 15.0, "50m"],
	["front", 20.0, 0.0, 8.0, "20m"],
	["front", 0.0, 0.0, 5.0, "contact"],
	["deep", 0.0, 0.0, 0.0, "deep"],
	["deep", 0.0, 0.0, 70.0, "deep_looking_up"],
	["back", 100.0, 0.0, 3.0, "clearing_100m"],
]

var _paused_warp := 1.0
var _jump := ""

@onready var world: World = $World
@onready var readout: Label = $Hud/Readout


func _ready() -> void:
	Dev.set_scene_keys(KEYS)
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at != -1:
		var only := args.find("--only")
		_capture(args[at + 1] if args.size() > at + 1 else "user://wall",
			args[only + 1].split(",") if only != -1 and args.size() > only + 1 else PackedStringArray())


func _enter_tree() -> void:
	# Before the World's _ready builds the weather from it.
	Tuning.current().run_seed = SEED
	# The fixed exposure, not the eye's, so shots and readings compare across builds.
	Tuning.current().eye_adapts = false


func _process(_delta: float) -> void:
	readout.text = _readout()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode
	if WARPS.has(code):
		world.time_warp = WARPS[code]
	elif JUMPS.has(code):
		jump(JUMPS[code][0], JUMPS[code][1])
	elif code == KEY_SPACE and not world.player.flying:
		if world.time_warp > 0.0:
			_paused_warp = world.time_warp
			world.time_warp = 0.0
		else:
			world.time_warp = _paused_warp
	elif code == KEY_R:
		Scenarios.apply(world, Scenarios.by_key("spawn"))
		_jump = "spawn"
	elif code == KEY_H:
		$Hud.visible = not $Hud.visible


## Drops you at a scenario found in this run's own weather: kind "front" (a
## front `distance` m upwind, coming at you), "deep" or "back".
func jump(kind: String, distance: float) -> Dictionary:
	var scenario := {"key": "%s_%d" % [kind, distance], "kind": kind, "distance": distance, "day": DAYTIME}
	var place := Scenarios.find(world, scenario)
	_jump = scenario.key if not place.is_empty() else "%s: none in 3 days" % scenario.key
	if not place.is_empty():
		world.respawn(place.x, place.z, place.yaw, place.time)
	return place


## The stage is whichever part of an arrival is furthest along.
func stage() -> String:
	var weather := world.weather
	if weather.seen_storm > 0.95:
		return "inside"
	if weather.seen_storm > 0.02:
		return "contact"
	if weather.seen_front > -150.0:
		return "the face"
	if weather.wind.length() > 14.0:
		return "the wind rises"
	if weather.seen_sun < 0.9:
		return "the light dims"
	return "clear" if weather.seen_front < -6000.0 else "on the horizon"


func _readout() -> String:
	var weather := world.weather
	var front := weather.seen_front
	var shown := "-" if front == -INF else ("%.2f km" % (-front / 1000.0) if absf(front) >= 1000.0
		else "%d m" % roundi(-front))
	# A front closes at the drift's speed along its normal.
	var normal := weather.face.front_at(world.player.camera.global_position)
	var closing := -weather.field.prevailing_at(world.time).dot(Vector2(normal.y, normal.z))
	var when := "-"
	if front < 0.0 and front != -INF and closing > 0.1:
		var eta := -front / closing
		when = "%d:%02d" % [int(eta) / 60, int(eta) % 60]
	elif front >= 0.0:
		when = "now"
	var state := "paused" if world.time_warp == 0.0 else "×%d" % roundi(world.time_warp)
	return "front %s   impact %s   %s\n%s   seen %d%%   wind %d m/s   %s" % [shown, when, state,
		stage(), roundi(weather.seen_storm * 100.0), roundi(weather.wind.length()), _jump]


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
		if not only.is_empty() and not only.has(shot[4]):
			continue
		var place := jump(shot[0], shot[1])
		if place.is_empty():
			print("  %-24s none in this run's weather" % shot[4])
			continue
		# Hold the clock while the ground streams in, then run up to the moment.
		world.time_warp = 0.0
		var waited := Time.get_ticks_msec()
		while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 20000:
			await get_tree().process_frame
		world.player.rotation.y = place.yaw + deg_to_rad(shot[2])
		world.player.camera.rotation_degrees.x = shot[3]
		world.time = place.time - 1.6
		world.time_warp = 1.0
		await get_tree().create_timer(0.6).timeout
		var frames := 0
		var longest := 0.0
		var gpu := 0.0
		var started := Time.get_ticks_usec()
		var last := started
		while Time.get_ticks_usec() - started < 1000000:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			longest = maxf(longest, (now - last) / 1000.0)
			last = now
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			frames += 1
		var average := (Time.get_ticks_usec() - started) / 1000.0 / frames
		gpu /= frames
		worst_ms = maxf(worst_ms, average)
		worst_gpu = maxf(worst_gpu, gpu)
		var path := out_dir.path_join("%02d_%s.png" % [n + 1, shot[4]])
		get_viewport().get_texture().get_image().save_png(path)
		print("  %-24s front %8.1f m  seen %3d%%  %-15s frame %5.2f ms (worst %5.2f)  gpu %5.2f ms" % [shot[4],
			-world.weather.seen_front, roundi(world.weather.seen_storm * 100.0), stage(), average, longest, gpu])
	print("capture: worst average frame %.2f ms, worst gpu %.2f ms; storm map upload worst %.2f ms, %d jump rebuilds%s"
		% [worst_ms, worst_gpu, world.weather.map.max_upload_ms, world.weather.map.rebuilds, _shared_gpu()])
	get_tree().quit()


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
