extends "res://probes/movement/43_board_the_powered_chassis.gd"
## Actual input-driven powered-deck boarding, seen from beside the craft.

var camera: Camera3D
var output: String
var shots := {}
var shooting := false

func run() -> void:
	output = OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(output)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	await super.run()


func load_moving(run_seed := 1234, salvage := false) -> void:
	await super.load_moving(run_seed, salvage)
	var length := world.tuning.day_minutes * 60.0
	var first := fposmod(0.4 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * length
	for day in 300:
		var t := first + day * length
		var at := Vector2(world.player_world_x(), world.player_world_z())
		if world.weather.day.sunlight(t, world.moon.latitude, world.moon.longitude) > 0.3 \
				and world.weather.field.raw_storm_at(at.x, at.y, t) < 0.0 \
				and world.weather.field.raw_storm_at(at.x, at.y, t + 60.0) < 0.0:
			world.time = t
			return


func _process(_delta: float) -> void:
	if not is_instance_valid(deck):
		return
	camera.global_position = deck.global_transform * Vector3(5, 2.8, 4)
	camera.look_at(deck.global_transform * Vector3(0.8, 0.7, 0))
	if not shooting and player != null and player.vault.active:
		var phase := mini(2, floori(player.vault.progress * 3.0))
		var name := "%d-climb-%d.png" % [render_rate, phase]
		if not shots.has(name):
			shots[name] = true
			_shot(name)


func captured(rate: int) -> void:
	await _shot("%d-boarded.png" % rate)


func _shot(name: String) -> void:
	shooting = true
	Dev.hide_overlays()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name))
	shooting = false
