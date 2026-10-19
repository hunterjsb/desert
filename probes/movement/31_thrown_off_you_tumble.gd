extends MovementProbe
## Movement probe 31: thrown off, you tumble. Each way of falling off, an
## edge caught in a hockey stop flat out, a landing past the throw and a
## crash head on into a wall, throws you into a tumble that keeps your way:
## you hit the sand again and again, rolling, and move forward held moves you
## not at all until you've come to rest, lain a moment and got up; then you
## walk. Tumbling far enough off a flat-out wipeout is Yard Sale.

## The wall stands this far past the flat place, m, across your way.
const WALL := 20.0
## Crossed this far just before it lands from this high, radians and m.
const CROSSED := deg_to_rad(25.0)
const HIGH := 12.0


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var tuning := world.tuning
	var profile := get_node(^"/root/Profile")
	var goal := tuning.deed_tumble_m
	tuning.deed_tumble_m = 5.0
	world.counts_deeds = true
	var edge := await _thrown(flat, &"edge")
	world.counts_deeds = false
	tuning.deed_tumble_m = goal
	var throw := tuning.board_land_throw
	tuning.board_land_throw = 10.0
	var landing := await _thrown(flat, &"landing")
	tuning.board_land_throw = throw
	var crash := await _thrown(flat, &"crash")
	for seen: Dictionary in [edge, landing, crash]:
		print("%s at %.1f m/s: tumbling on at %.1f m/s%s, %d hits (hardest %.1f m/s), rolled %.0f°, %.1f m in %.2f s to rest, up %.2f s later"
			% [seen.how, seen.ride, seen.way, ", %.1f back off the wall" % seen.back if seen.how == &"crash" else "",
				seen.hits, seen.hardest, rad_to_deg(seen.rolled), seen.came, seen.rest, seen.up - seen.rest])
	for seen: Dictionary in [edge, landing, crash]:
		check(seen.thrown == seen.how and seen.hits >= 1 and seen.rolled > deg_to_rad(80.0),
			"%s: thrown off, you tumble (%d hits, rolled %.0f°)" % [seen.how, seen.hits, rad_to_deg(seen.rolled)])
		check(seen.moved_held < 0.3 and seen.up >= seen.rest + Tumble.LIE + Tumble.GET_UP - 0.05 and seen.walk,
			"%s: no key moves you till you've come to rest and got up (%.2f m/s at rest; up %.2f s after), then you walk"
			% [seen.how, seen.moved_held, seen.up - seen.rest])
	check(edge.way > edge.ride * 0.95 and landing.way > landing.ride * 0.95 and crash.back > 1.0,
		"it keeps your way (%.1f of %.1f m/s, %.1f of %.1f), off a wall bouncing you back (%.1f m/s)"
		% [edge.way, edge.ride, landing.way, landing.ride, crash.back])
	check(profile.did("yard_sale"), "tumbling far enough is Yard Sale (%.1f m)" % edge.came)
	set_rate(60)


## Up to speed along +x on a fresh board and thrown off as `how` says, move
## forward held throughout: {how, thrown, ride, way, back, hits, hardest,
## rolled, came, rest, up, moved_held, walk}. `ride` is your way as it threw
## you, before anything solid stopped it; `way`, the tumble's as it began;
## `back`, your way back off the wall; `rest` and `up`, s from the throw;
## `moved_held`, your fastest once at rest; `walk`, walking at the end.
func _thrown(flat: Dictionary, how: StringName) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var wall: StaticBody3D = null
	if how == &"crash":
		var at := Vector2(flat.x + WALL, flat.z)
		wall = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, 3.0, 12.0)
		shape.shape = box
		wall.add_child(shape)
		world.content.add_child(wall)
		wall.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 1.2, world.engine_z(at.y))
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	var ride := player.ride
	var seen := {"how": how, "thrown": &"", "ride": 0.0, "way": 0.0, "back": 0.0, "rolled": 0.0, "rest": INF,
		"up": INF, "moved_held": 0.0, "walk": false, "t": 0.0, "lifted": false, "turned": false}
	var dt := 1.0 / ticks_per_second()
	hold(["move_forward"])
	await ride_for(12.0, func() -> void:
		seen.t += dt
		if player.get_slide_collision_count() == 0:
			seen.ride = ride.velocity.length()
		if how == &"edge" and seen.t >= 6.0:
			hold(["move_back"])
		elif how == &"landing" and seen.t >= 4.0 and not seen.lifted:
			ride.y += HIGH
			ride.vy = 0.0
			seen.lifted = true
		elif seen.lifted and not seen.turned and ride.vy < 0.0 and ride.gap < 0.6:
			ride.ahead = ride.ahead.rotated(CROSSED)
			seen.turned = true)
	seen.t = 0.0
	seen.thrown = ride.thrown
	var tumble := player.tumble
	if tumble == null:
		return seen
	hold(["move_forward"])
	await simulate(6.0, func() -> void:
		seen.t += dt
		if player.tumble == tumble:
			if seen.way == 0.0:
				seen.way = tumble.velocity.length()
			if wall != null:
				seen.back = maxf(seen.back, -tumble.velocity.x)
			seen.rolled = maxf(seen.rolled, absf(tumble.rolled))
			if tumble.lain > 0.0:
				seen.rest = minf(seen.rest, seen.t)
				seen.moved_held = maxf(seen.moved_held, flat_speed())
		elif seen.up == INF:
			seen.up = seen.t)
	seen.hits = tumble.hits
	seen.hardest = tumble.hardest
	seen.came = tumble.came
	seen.walk = player.tumble == null and player.mode == "walk"
	hold([])
	if wall != null:
		wall.free()
	return seen
