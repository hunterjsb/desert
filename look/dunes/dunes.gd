extends Node
## Look-test: the dunes in the real world on seed 1234 under clear skies, from
## the same spots at the same moments, so a change can be judged against the
## last. Walk or fly it by hand, or capture every shot:
##   godot --path . res://look/dunes/dunes.tscn [-- --tune name=value ...]
##   godot --path . --disable-vsync res://look/dunes/dunes.tscn -- [--tune name=value ...] --capture <dir> [--only sea_eye_upwind_dusk]
## Each --tune overrides one tuning value, such as sand_shader=false or mid_step=4.
## look/dunes/shoot.sh shoots with the sand shader and without, and builds the
## contact sheets.

const SEED := 1234
## Times of day to shoot: low morning sun, noon, and dusk's low sun.
const MOMENTS := [["morning", 0.285], ["noon", 0.5], ["dusk", 0.715]]
## Spots, by how much sand lies there: deep in a dune sea, and at a sea's edge.
const SPOTS := [["sea", 1.0], ["edge", 0.45]]
## Shots at each spot: name, metres up, yaw from facing upwind, pitch.
const VIEWS := [
	["eye_upwind", 0.0, 0.0, 2.0],
	["eye_downwind", 0.0, 180.0, 2.0],
	["30m", 30.0, 35.0, -12.0],
	["200m", 200.0, 20.0, -9.0],
]
## The edge spot only needs to show the change from sea to flats.
const EDGE_VIEWS := ["eye_upwind", "200m"]
## Spots are looked for within this far of spawn, m, on this grid.
const SEARCH := 2500.0
const SEARCH_STEP := 50.0

@onready var world: World = $World


func _enter_tree() -> void:
	# Before the World's _ready builds the ground and weather from them.
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	# Clear skies: this judges the dunes, and the equator is stormy.
	tuning.storm_threshold = 0.9
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i] == "--tune":
			var pair := args[i + 1].split("=")
			tuning.set(pair[0], str_to_var(pair[1]))


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	var only := args.find("--only")
	_capture(args[at + 1] if args.size() > at + 1 else "user://dunes",
		args[only + 1].split(",") if only != -1 and args.size() > only + 1 else PackedStringArray())


## The spots, read from the sand field.
static func spots() -> Dictionary:
	var shape := TerrainShape.new(SEED, Tuning.current())
	var found := {}
	for spot: Array in SPOTS:
		var best := Vector2.ZERO
		var miss := INF
		var x := -SEARCH
		while x <= SEARCH:
			var z := -SEARCH
			while z <= SEARCH:
				var off := absf(shape.sand_at(x, z) - spot[1])
				if off < miss - 1e-4:
					miss = off
					best = Vector2(x, z)
				z += SEARCH_STEP
			x += SEARCH_STEP
		found[spot[0]] = best
	return found


## A run time on the first day at each time of day.
func moments() -> Dictionary:
	var found := {}
	for moment: Array in MOMENTS:
		found[moment[0]] = fposmod(moment[1] - world.tuning.start_time_of_day, 1.0) * world.tuning.day_minutes * 60.0
	return found


## A small window that can't take focus, nothing but this script moving the
## camera, and silence; then every shot, rendered at 1920x1080.
func _capture(out_dir: String, only: PackedStringArray) -> void:
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
	# Only the dunes: the survival bars and any other screen layer go.
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	DirAccess.make_dir_recursive_absolute(out_dir)
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	print("dunes: sand shader %s, mid step %d m, into %s at %s%s" % ["on" if world.tuning.sand_shader else "off",
		world.tuning.mid_step, out_dir, get_viewport().get_visible_rect().size, _shared_gpu()])
	var places := spots()
	var when := moments()
	var upwind := -Vector2.from_angle(WeatherField.mean_heading(SEED))
	var worst_gpu := 0.0
	for spot: String in places:
		var at: Vector2 = places[spot]
		var views := VIEWS.filter(func(view: Array) -> bool: return spot == "sea" or EDGE_VIEWS.has(view[0]))
		var wanted := views.filter(func(view: Array) -> bool:
			return only.is_empty() or MOMENTS.any(func(m: Array) -> bool: return only.has("%s_%s_%s" % [spot, view[0], m[0]])))
		if wanted.is_empty():
			continue
		world.respawn(at.x, at.y, atan2(-upwind.x, -upwind.y), when.values()[0])
		world.time_warp = 0.0
		# The terrain plans the new ground on its next frame; until then it
		# reports the old ground as finished.
		await get_tree().process_frame
		await get_tree().process_frame
		var waited := Time.get_ticks_msec()
		while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
			await get_tree().process_frame
		if not world.terrain.is_idle():
			print("  %s: ground still building after 60 s" % spot)
		var ground := world.height_at(at.x, at.y)
		for moment: Array in MOMENTS:
			for view: Array in wanted:
				var name := "%s_%s_%s" % [spot, view[0], moment[0]]
				if not only.is_empty() and not only.has(name):
					continue
				world.time = when[moment[0]]
				world.player.global_position.y = ground + 0.1 + view[1]
				world.player.rotation.y = atan2(-upwind.x, -upwind.y) + deg_to_rad(view[2])
				world.player.camera.rotation_degrees.x = view[3]
				# Physics ticks, not frames: the light follows the clock on the tick.
				for i in 20:
					await get_tree().physics_frame
				var gpu := 0.0
				for i in 10:
					await get_tree().process_frame
					gpu = maxf(gpu, RenderingServer.viewport_get_measured_render_time_gpu(rid))
				worst_gpu = maxf(worst_gpu, gpu)
				get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
				print("  %-28s ground %6.1f m  gpu %5.2f ms" % [name, ground, gpu])
	print("dunes: worst gpu %.2f ms, slowest streaming frame %.2f ms%s" % [worst_gpu,
		world.terrain.slowest_frame_ms, _shared_gpu()])
	get_tree().quit()


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
