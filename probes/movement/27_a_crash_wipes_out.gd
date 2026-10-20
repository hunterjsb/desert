extends MovementProbe
## Movement probe 27: crashes. Ridden into a wall head on at speed, the
## board throws you off, knocked and winded, and bounces back off it. At a
## crawl the same wall only stops you, and flat out at a glance you slide
## along it and ride on.

## The wall stands this far past the flat place, m, across your way.
const WALL := 20.0
const GLANCE := deg_to_rad(75.0)
## Your speed this long after you met the wall, s, says whether you rode on.
const AFTER := 0.3


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var tuning := world.tuning
	var head_on := await _into(flat, 0.0, 60.0, 6.0)
	var crawl := await _into(flat, 0.0, 8.0, 0.4)
	var glance := await _into(flat, GLANCE, 60.0, 6.0)
	for each: Array in [["head on", head_on], ["at a crawl", crawl], ["at a glance", glance]]:
		var seen: Dictionary = each[1]
		print("%s at %.1f m/s, %.1f m/s into the wall: %s" % [each[0], seen.speed, seen.into,
			"thrown (%s), %.1f health and %.0f stamina lost, the board back off it at %.1f m/s"
			% [seen.how, seen.hurt, seen.winded, seen.back] if seen.thrown else "rode on at %.1f m/s" % seen.after])
	check(head_on.thrown and head_on.how == &"crash" and head_on.into > tuning.board_crash,
		"head on at speed it throws you (%.1f m/s into it)" % head_on.into)
	check(head_on.hurt > 0.0 and head_on.hurt < tuning.board_wipeout_hurt + 0.5 and head_on.winded > 0.0,
		"knocked and winded, gently (%.1f health, %.0f stamina)" % [head_on.hurt, head_on.winded])
	check(head_on.back > 0.5, "and the board bounces back off it (%.1f m/s)" % head_on.back)
	check(not crawl.thrown and crawl.into > 0.5, "at a crawl it only stops you (%.1f m/s into it)" % crawl.into)
	check(not glance.thrown and glance.after > 8.0, "at a glance you slide along it and ride on (%.1f m/s)" % glance.after)
	set_rate(60)


## Up to speed along +x from `run` m before a wall turned `turn` off square
## across your way, pushing for `push` s, then coasting: {speed, into,
## thrown, how, hurt, winded, back, after}. `into` is your way into the wall
## as you met it; `back`, the board's away from it once thrown; `after`, your
## speed AFTER s on.
func _into(flat: Dictionary, turn: float, run: float, push: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var at := Vector2(flat.x + WALL, flat.z)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 3.0, 12.0)
	shape.shape = box
	wall.add_child(shape)
	world.content.add_child(wall)
	wall.global_transform = Transform3D(Basis(Vector3.UP, turn),
		Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 1.2, world.engine_z(at.y)))
	await place(at.x - run, at.y, Vector2(1.0, 0.0))
	var board := await ride_here()
	var ride := player.ride
	var normal := -wall.global_basis.x
	var seen := {"speed": 0.0, "into": 0.0, "into_was": 0.0, "thrown": false, "how": &"", "hurt": 0.0, "winded": 0.0, "back": 0.0,
		"after": 0.0, "t": 0.0}
	hold(["move_forward"])
	var dt := 1.0 / ticks_per_second()
	await ride_for(push + 6.0, func() -> void:
		seen.t += dt
		if seen.t > push:
			hold([])
		if player.ride == ride:
			seen.health = player.vitals.health
			seen.stamina = player.stamina
			var way := Vector3(ride.velocity.x, 0.0, ride.velocity.y)
			# Your way into the wall, the last tick before it stopped you.
			if player.get_slide_collision_count() == 0 and seen.into == 0.0:
				seen.speed = way.length()
				seen.into_was = maxf(0.0, -way.dot(normal))
			elif seen.into == 0.0:
				seen.into = seen.into_was
				seen.met = seen.t
			if seen.has("met") and seen.after == 0.0 and seen.t >= seen.met + AFTER:
				seen.after = way.length())
	seen.thrown = player.ride == null
	if seen.thrown:
		seen.how = ride.thrown
		seen.into = maxf(seen.into, ride.thrown_at)
		seen.hurt = seen.health - player.vitals.health
		seen.winded = seen.stamina - player.stamina
		await simulate(0.1)
		seen.back = board.linear_velocity.dot(normal)
	hold([])
	player.step_off()
	wall.free()
	return seen
