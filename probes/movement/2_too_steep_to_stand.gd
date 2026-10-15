extends MovementProbe
## Movement probe 2: a slip face won't hold you. Today's dunes top out near
## 16°, so the dunes here are raised threefold, until slip faces appear.
## Stand on one and you slide down it on your own; try to walk up it and you
## still go down. A steep windward slope under the slip angle holds you still.


func run() -> void:
	Tuning.current().dune_amplitude = 18.0
	await load_moving()
	set_rate(60, 4)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var slip := world.tuning.slip_angle

	var face := slope_between(x, z, 250.0, slip + 2.0, 40.0, 4.0)
	check(not face.is_empty(), "a slip face steeper than %.0f° near spawn" % (slip + 2.0))
	if face.is_empty():
		return
	var down: Vector2 = face.downhill
	await place(face.x, face.z, -down)
	var from := where()
	var seen := {"slid": false}
	await simulate(1.5, func() -> void: seen.slid = seen.slid or player.mode == "slide")
	var went := Vector2(where().x - from.x, where().z - from.z).dot(down)
	print("slip face %.1f°: stood still and slid %.2f m down it" % [face.degrees, went])
	check(seen.slid and went > 1.0, "standing on a %.0f° slip face slides you down it (%.2f m)" % [face.degrees, went])

	await place(face.x, face.z, -down)
	from = where()
	hold(["move_forward", "sprint"])
	await simulate(1.5)
	went = Vector2(where().x - from.x, where().z - from.z).dot(down)
	print("sprinting up it: went %.2f m down" % went)
	check(went > 0.3, "sprinting up it, you still go down (%.2f m)" % went)

	var held := slope_between(x, z, 250.0, slip - 10.0, slip - 4.0, 2.0)
	check(not held.is_empty(), "a steep slope under the slip angle near spawn")
	if held.is_empty():
		return
	await place(held.x, held.z, held.downhill)
	from = where()
	await simulate(1.5)
	var drift := Vector2(where().x - from.x, where().z - from.z).length()
	print("%.1f° slope: drifted %.4f m standing" % [held.degrees, drift])
	check(drift < 0.01 and player.mode == "stand", "a %.0f° slope holds you still (%.4f m)" % [held.degrees, drift])
	set_rate(60)
