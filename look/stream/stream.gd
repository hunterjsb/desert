extends Node
## Hitch check in a real window, which headless probe 7 can't be: the shader
## compile and the GPU's side of an upload only happen here. On seed 1234 it
## flies 6 km at full dev speed (F4 + Shift), then walks over a chunk edge, and
## fails if any frame from the first chunk on spent longer than
## stream_frame_max_ms streaming. Whole-frame times are printed beside it. CI has
## no GPU, so run it by hand after touching terrain streaming; exit code 0 passes:
##   godot --path . res://look/stream/stream.tscn
## Renders 1920x1080 in a small window that never takes focus; nothing but this
## script moves the player, and it's silent.

const WORLD_SCENE := preload("res://game/world/world.tscn")
const FLY_SECONDS := 20.0
const WALK_SECONDS := 15.0
const PIPELINES := [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH,
	Performance.PIPELINE_COMPILATIONS_SURFACE, Performance.PIPELINE_COMPILATIONS_DRAW,
	Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]

var _world: World


func _ready() -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	var player := _world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	var vsync := DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	var refresh := DisplayServer.screen_get_refresh_rate(window.current_screen)
	print("stream: %s, vsync %s at %.0f Hz%s" % [get_viewport().get_visible_rect().size,
		"on" if vsync else "off", refresh, _shared_gpu()])
	# Missing a refresh shows as a frame half again as long as one.
	var missed := 1500.0 / refresh if vsync and refresh > 0.0 else INF

	await _measure("load", missed, func() -> bool: return _world.terrain.is_idle())

	player.flying = true
	player.global_position.y += 30.0
	player.rotation_degrees.y = -90.0
	player.camera.rotation_degrees.x = 0.0
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _measure("fly", missed, _for(FLY_SECONDS))
	Input.action_release("sprint")
	Input.action_release("move_forward")

	# Onto the sand a few metres short of a chunk edge, once there's ground there.
	player.flying = false
	var x := _world.player_world_x()
	var z := floorf(_world.player_world_z() / Tuning.current().chunk_size) * Tuning.current().chunk_size + 4.0
	player.rotation_degrees.y = 0.0
	player.global_position = Vector3(_world.engine_x(x), _world.height_at(x, z) + 0.1, _world.engine_z(z))
	while not _world.terrain.is_settled_around(x, z):
		await get_tree().process_frame
	Input.action_press("move_forward")
	await _measure("walk", missed, _for(WALK_SECONDS))
	Input.action_release("move_forward")

	var limit := Tuning.current().stream_frame_max_ms
	var slowest := _world.terrain.slowest_frame_ms
	var passed := slowest < limit
	print("stream: %s, slowest streaming frame %.2f ms against %.1f%s" % ["PASS" if passed else "FAIL",
		slowest, limit, _shared_gpu()])
	get_tree().quit(0 if passed else 1)


## Frames until done() says so, then one line of what they cost.
func _measure(phase: String, missed_ms: float, done: Callable) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var pipelines := _pipelines()
	var frames: Array[float] = []
	var streaming: Array[float] = []
	var gpu := 0.0
	# Workers falling behind leave you over ground with no collision yet.
	var behind := 0
	var last := Time.get_ticks_usec()
	while not done.call():
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		streaming.append(_world.terrain.frame_ms)
		gpu = maxf(gpu, RenderingServer.viewport_get_measured_render_time_gpu(rid))
		if not _world.terrain.is_settled_around(_world.player_world_x(), _world.player_world_z()):
			behind += 1
	var misses := frames.filter(func(ms: float) -> bool: return ms > missed_ms).size()
	print("  %-4s %5d frames  p99 %5.2f  worst %5.2f ms  missed %3d  gpu worst %5.2f  streaming p99 %4.2f worst %4.2f ms  pipelines %d  ground behind %d frames"
		% [phase, frames.size(), _p99(frames), frames.max(), misses, gpu, _p99(streaming), streaming.max(),
			_pipelines() - pipelines, behind])


func _for(seconds: float) -> Callable:
	var until := Time.get_ticks_usec() + int(seconds * 1e6)
	return func() -> bool: return Time.get_ticks_usec() >= until


func _p99(values: Array[float]) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[int(sorted.size() * 0.99)]


func _pipelines() -> int:
	var count := 0
	for monitor: Performance.Monitor in PIPELINES:
		count += int(Performance.get_monitor(monitor))
	return count


## Another Godot on the same machine skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""
