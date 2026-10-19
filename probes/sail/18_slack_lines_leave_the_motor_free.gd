extends BoardTowProbe
## Sailing probe 18: slack lines allow full powered catch-up to a rig. A
## turn keeps the rider's momentum instead of clipping it to the rig's speed.


func run() -> void:
	await load_towing(false, 100.0)
	var lines: Array[Line] = [line]
	for i in 2:
		fit_part(cargo, &"hook")
		lines.append(Line.to_waist(world, cargo.free_tie(world.player.global_position), 100.0))
	cargo.freeze = true
	var from := world.player.global_position
	await simulate(4.0)
	var player := world.player
	var speed := player.ride.velocity.length()
	var before := player.ride.velocity
	Input.action_release("move_forward")
	player.ride.step(1.0 / 60.0, Vector2.LEFT, false)
	var after := player.ride.velocity
	Input.action_release("move_left")
	print("slack catch-up: %.2f m/s after %.1f m; one-frame turn %.2f to %.2f m/s, old-direction momentum %.2f" % [
		speed, flat(player.global_position - from).length(), before.length(), after.length(), after.dot(before.normalized())])
	check(speed > 10.0 and world.player.waist.tied.size() == 3
		and lines.all(func(l: Line) -> bool: return l.rope.tension == 0.0),
		"three slack waist lines leave the board fast under its own power")
	check(after.dot(before.normalized()) > before.length() * 0.9,
		"turning retains its momentum along the old course")
