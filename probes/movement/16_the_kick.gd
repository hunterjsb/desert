extends MovementProbe
## Movement probe 16: on the board, sprint kicks off the sand. From rest a
## kick gets you going and costs stamina; with none left there's no kick. Up
## a slip face from its foot, kicking climbs faster than pushing alone.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var flat := flat_place(x, z, 150.0, 30.0)
	var across := Vector2(1.0, 0.0)

	await place(flat.x - 20.0, flat.z, across)
	await ride_here()
	var had := player.stamina
	hold(["sprint"])
	await ride_for(2.0)
	var kicked := flat_speed()
	var paid := had - player.stamina
	print("kicking from rest for 2 s: %.2f m/s, %.0f stamina" % [kicked, paid])
	check(kicked > 3.0, "from rest a kick gets you going (%.2f m/s)" % kicked)
	check(paid > 0.0, "and costs stamina (%.0f)" % paid)

	player.step_off()
	await place(flat.x - 20.0, flat.z, across)
	await ride_here()
	player.stamina = 0.0
	hold(["sprint"])
	await ride_for(2.0)
	print("with no stamina: %.2f m/s" % flat_speed())
	check(flat_speed() < 0.3, "with no stamina there's no kick (%.2f m/s)" % flat_speed())

	var face := slope_between(x, z, 250.0, 28.0, 40.0, 8.0)
	check(not face.is_empty(), "a slip face near spawn")
	if face.is_empty():
		return
	var down: Vector2 = face.downhill
	var foot := Vector2(face.x, face.z)
	while degrees(gradient(foot.x, foot.y)) > 6.0:
		foot += down
	foot += down * 4.0
	var climbed: Array[float] = []
	for keys: Array in [["move_forward"], ["move_forward", "sprint"]]:
		player.step_off()
		await place(foot.x, foot.y, -down)
		await ride_here()
		player.stamina = world.tuning.stamina_max
		var from := where().y
		hold(keys)
		await ride_for(3.0)
		climbed.append(where().y - from)
	print("up a %.1f° slip face from its foot in 3 s: %.1f m pushing, %.1f m kicking too"
		% [face.degrees, climbed[0], climbed[1]])
	check(climbed[1] > climbed[0] * 1.15, "kicking climbs it faster (%.1f m against %.1f)" % [climbed[1], climbed[0]])
	set_rate(60)
