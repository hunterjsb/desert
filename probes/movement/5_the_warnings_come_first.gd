extends MovementProbe
## Movement probe 5: the warnings always come first. Leave a small camp, a
## shield generator and a crate, in a straight line at every speed from a
## walk to a board flat out with a tailwind behind it, along the chunk grid
## and across it: the first warning comes at least 15 s before you reach the
## edge where the camp is lost, the last at least 5 s before, and past the
## edge the camp really is lost, and you're told. Then flat out on a board,
## turning back at the last warning: the camp is never lost.

const SPEEDS := [0.5, 1.8, 3.9, 10.0, 20.0, 26.0]
const WAYS := [Vector2(1.0, 0.0), Vector2(0.6, -0.8)]
## Enough time to react, s, before the edge.
const FIRST_LEAST := 15.0
const LAST_LEAST := 5.0
## Where the camp stands, from spawn, m: the shield and the crate.
const CAMP := [Vector2(2.0, 3.0), Vector2(-2.0, 3.5)]


func run() -> void:
	await load_moving()
	set_rate(60, 16)
	var watch := player.camp_range
	var heard := {"levels": [], "lost": 0}
	watch.warned.connect(func(level: int) -> void: heard.levels.append([level, _ticks]))
	watch.lost.connect(func(_labels: PackedStringArray) -> void: heard.lost += 1)
	var home := Vector2(world.player_world_x(), world.player_world_z())
	for way: Vector2 in WAYS:
		for speed: float in SPEEDS:
			var camp := await _camp(home)
			var edge := _edge(home, way, camp)
			# Started far enough out to reach the edge soon, near enough to be warned on the way.
			var start := maxf(0.0, edge - maxf(speed * (world.tuning.range_first_seconds + 10.0),
				world.tuning.range_first_m + 20.0))
			heard.levels.clear()
			heard.lost = 0
			player.set_physics_process(false)
			teleport(home.x + way.x * start, home.y + way.y * start)
			await settle(true)
			_ticks = 0
			var past := {"edge": INF}
			var at := home + way * start
			var limit := ceili(((edge - start) / speed + 10.0) * 60.0)
			while _ticks < limit and (heard.lost == 0 or _ticks < past.edge + 60):
				at += way * speed / 60.0
				player.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.05, world.engine_z(at.y))
				player.velocity = Vector3(way.x, 0.0, way.y) * speed
				await get_tree().physics_frame
				keep_pace()
				_ticks += 1
				if past.edge == INF and at.distance_to(home) >= edge:
					past.edge = _ticks
			player.velocity = Vector3.ZERO
			player.set_physics_process(true)
			var first := _when(heard.levels, CampRange.FIRST)
			var last := _when(heard.levels, CampRange.LAST)
			var gone := camp.all(func(d: Variant) -> bool: return not is_instance_valid(d))
			print("%s at %4.1f m/s: warned %5.1f s and last %4.1f s before the edge %.0f m out"
				% [way, speed, (past.edge - first) / 60.0, (past.edge - last) / 60.0, edge])
			check(past.edge - first >= FIRST_LEAST * 60, "%s at %.1f m/s: warned at least %d s ahead (%.1f)"
				% [way, speed, FIRST_LEAST, (past.edge - first) / 60.0])
			check(past.edge - last >= LAST_LEAST * 60 and last > first, "%s at %.1f m/s: the last warning %d s ahead (%.1f)"
				% [way, speed, LAST_LEAST, (past.edge - last) / 60.0])
			check(gone and heard.lost == 1, "%s at %.1f m/s: past the edge the camp is lost, and you're told" % [way, speed])
			teleport(home.x, home.y)
			await settle(true)
	await _turn_back(home)
	set_rate(60)


var _ticks := 0


## Flat out on a board from the camp, turning back at the last warning.
func _turn_back(home: Vector2) -> void:
	var camp := await _camp(home)
	var watch := player.camp_range
	face(WAYS[0])
	var board := await ride_here()
	hold(["move_forward"])
	var seen := {"nearest": INF, "soonest": INF, "turned": false, "lost": false}
	watch.lost.connect(func(_labels: PackedStringArray) -> void: seen.lost = true)
	await ride_for(90.0, func() -> void:
		seen.nearest = minf(seen.nearest, watch.near)
		seen.soonest = minf(seen.soonest, watch.seconds)
		if watch.told == CampRange.LAST and not seen.turned:
			seen.turned = true
			face(-WAYS[0]))
	hold([])
	var kept := camp.all(func(d: Variant) -> bool: return is_instance_valid(d))
	print("flat out, turned back at the last warning: %.0f m and %.1f s from the edge at the nearest; camp kept: %s"
		% [seen.nearest, seen.soonest, kept])
	check(seen.turned and kept and not seen.lost and seen.nearest > 0.0,
		"turned back at the last warning flat out, the camp is never lost")
	player.step_off()
	board.free()


## A fresh camp beside where the run began, standing on the sand.
func _camp(home: Vector2) -> Array[Device]:
	for node in world.content.get_children():
		if node is Device:
			node.free()
	teleport(home.x, home.y)
	await settle(true)
	var made: Array[Device] = []
	for k in CAMP.size():
		var device := Catalog.device(&"shield" if k == 0 else &"crate_frame")
		world.content.add_child(device)
		var at: Vector2 = home + CAMP[k]
		device.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.3, world.engine_z(at.y))
		made.append(device)
	await simulate(0.5)
	return made


## How far along `way` from `home` the first of the camp is lost, m: where
## your chunk is too many from its.
func _edge(home: Vector2, way: Vector2, camp: Array[Device]) -> float:
	var size := float(world.tuning.chunk_size)
	var keep := world.tuning.view_radius + 1
	var nearest := INF
	for device in camp:
		var coord := world.terrain.chunk_at(world.world_x(device.global_position.x), world.world_z(device.global_position.z))
		var low := Vector2(coord - Vector2i.ONE * keep) * size
		var high := Vector2(coord + Vector2i.ONE * (keep + 1)) * size
		nearest = minf(nearest, CampRange._out(home, way, low, high))
	return nearest


## The tick a warning of this level came, or INF.
func _when(levels: Array, level: int) -> float:
	for each: Array in levels:
		if each[0] == level:
			return each[1]
	return INF
