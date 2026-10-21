extends Node3D
## Shared orbital renderer, captured without starting a run or an arrival.
const RUN_SEED := 1234

func _ready() -> void:
	Dev.hide_overlays()
	var tuning := Tuning.current()
	var history := History.new(RUN_SEED, tuning)
	var day := DayCycle.new(tuning)
	var orbit := ArrivalOrbit.new()
	add_child(orbit)
	orbit.setup(history, day)
	orbit.update_light(tuning.day_minutes * 60.0 * 0.31)
	var direction := Sphere.point(deg_to_rad(-30.0), deg_to_rad(30.0))
	orbit.camera.position = direction * ArrivalOrbit.RADIUS * 1.65
	orbit.camera.look_at(Sphere.north(direction) * ArrivalOrbit.RADIUS * 0.65, Sphere.north(direction))
	if not OS.get_cmdline_user_args().is_empty():
		for i in 12:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
		print("Orbital view: seed=%d rift_points=%d; regional albedo illustrative" % [RUN_SEED, history.geology.rift.size()])
		get_tree().quit()
