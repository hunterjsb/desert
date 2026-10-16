extends MovementProbe
## Movement probe 17: pumping. Over the same ridges, pushing flat out the same
## way, a rider who crouches as the board unloads over a crest and stands as
## it presses into a dip goes further than one who stands still, but only a
## little: flat out, drag takes each pump's surge back within a couple of
## seconds. One who does it the wrong way round loses. The tuck's lower drag
## is switched off for these, so it's only the pump; with it on, the tuck
## and pumping with it are measured too.

const SECONDS := 30.0
## Pressed or unloaded by this much beyond your weight, m/s², the rider changes.
const FELT := 1.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.view_radius = tuning.near_radius
	tuning.far_radius = (tuning.view_radius + 1) * tuning.chunk_size
	await load_moving()
	set_rate(60, 8)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var heading := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var catch := tuning.crouch_catch
	tuning.crouch_catch = 1.0
	var still := await _ride(x, z, heading, 0)
	var pumped := await _ride(x, z, heading, 1)
	var wrong := await _ride(x, z, heading, -1)
	tuning.crouch_catch = catch
	var tucked := await _ride(x, z, heading, 0, true)
	var both := await _ride(x, z, heading, 1)
	var gain := pumped / still - 1.0
	print("%.0f s over the dunes: %.1f m standing, %.1f m pumping (%+.1f%%), %.1f m pumping the wrong way round"
		% [SECONDS, still, pumped, 100.0 * gain, wrong])
	print("with the tuck: %.1f m tucked all the way, %.1f m pumping (%+.1f%% on standing)"
		% [tucked, both, 100.0 * (both / still - 1.0)])
	check(gain > 0.004, "pumping goes further than standing still (%+.1f%%)" % (100.0 * gain))
	check(gain < 0.05, "but only a little (%+.1f%%)" % (100.0 * gain))
	check(wrong < still, "the wrong way round loses (%.1f m against %.1f)" % [wrong, still])
	set_rate(60)


## How far you go pushing along `heading` for SECONDS, m: standing (0),
## pumping (1), the wrong way round (-1), or tucked all the way.
func _ride(x: float, z: float, heading: Vector2, pump: int, tuck := false) -> float:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(x, z, heading)
	await ride_here()
	var from := where()
	var low := {"on": tuck}
	hold(["move_forward", "crouch"] if tuck else ["move_forward"])
	await ride_for(SECONDS, func() -> void:
		if pump == 0:
			return
		var pressed := player.ride.pressing * pump
		if pressed < -FELT and not low.on:
			low.on = true
			hold(["move_forward", "crouch"])
		elif pressed > FELT and low.on:
			low.on = false
			hold(["move_forward"]))
	hold([])
	return Vector2(where().x - from.x, where().z - from.z).length()
