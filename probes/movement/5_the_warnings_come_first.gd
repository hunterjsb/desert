extends MovementProbe
## Movement probe 5: the warnings always come first. Leave a small camp, a
## shield generator and a crate, in a straight line at every speed from a
## walk to a board flat out with a tailwind behind it, along the chunk grid
## and across it: the first warning comes at least 15 s before you reach the
## edge where the camp is lost, the last at least 5 s before, and past the
## edge the camp really is lost, and you're told, as the countdown said. Then
## flat out on a board, turning back at the last warning and riding home: the
## camp is never lost. And flat out carving from side to side, on past the
## edge: each warning comes once and stays up, the loss is told once, and
## then nothing for 30 s.
## Time limit: 600 s (about 150 s on Linux or macOS CI; Windows CI takes twice that)

const SPEEDS := [1.0, 1.8, 3.9, 10.0, 20.0, 26.0]
const WAYS := [Vector2(1.0, 0.0), Vector2(0.6, -0.8)]
## Enough time to react, s, before the edge.
const FIRST_LEAST := 15.0
const LAST_LEAST := 5.0
## Where the camp stands, from spawn, m: the shield and the crate.
const CAMP := [Vector2(2.0, 3.0), Vector2(-2.0, 3.5)]
## The countdown at the last warning is out by no more than this, s.
const HONEST := 2.0
## Quiet this long after the camp is lost, s.
const QUIET := 30.0


func run() -> void:
	await load_moving()
	set_rate(60, 16)
	var watch := player.camp_range
	var heard := {"levels": [], "lost": 0, "lost_at": INF}
	watch.warned.connect(func(level: int) -> void: heard.levels.append([level, _ticks, watch.seconds]))
	watch.lost.connect(func(_labels: PackedStringArray) -> void:
		heard.lost += 1
		heard.lost_at = _ticks)
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
			heard.lost_at = INF
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
			if heard.lost == 0:
				# Past the edge the camp's chunk goes as streaming gets to it, on its
				# own budget: a slow machine gets there later, never not at all.
				await settle()
				await physics_frames(5)
			player.set_physics_process(true)
			var first := _when(heard.levels, CampRange.FIRST)
			var last := _when(heard.levels, CampRange.LAST)
			var said := _counted(heard.levels, CampRange.LAST)
			var took: float = (heard.lost_at - last) / 60.0
			var gone := camp.all(func(d: Variant) -> bool: return not is_instance_valid(d))
			print("%s at %4.1f m/s: warned %5.1f s and last %4.1f s before the edge %.0f m out; lost %4.1f s after the last, which said %.0f s"
				% [way, speed, (past.edge - first) / 60.0, (past.edge - last) / 60.0, edge, took, said])
			check(past.edge - first >= FIRST_LEAST * 60, "%s at %.1f m/s: warned at least %d s ahead (%.1f)"
				% [way, speed, FIRST_LEAST, (past.edge - first) / 60.0])
			check(past.edge - last >= LAST_LEAST * 60 and last > first, "%s at %.1f m/s: the last warning %d s ahead (%.1f)"
				% [way, speed, LAST_LEAST, (past.edge - last) / 60.0])
			check(gone and heard.lost == 1, "%s at %.1f m/s: past the edge the camp is lost, and you're told" % [way, speed])
			if said < INF:
				check(absf(took - said) <= HONEST, "%s at %.1f m/s: lost when the countdown said (%.1f s, said %.0f)"
					% [way, speed, took, said])
			teleport(home.x, home.y)
			await settle(true)
	await _turn_back(home)
	await _carving(home)
	set_rate(60)


var _ticks := 0


## Flat out on a board from the camp, turning back at the last warning and
## riding home.
func _turn_back(home: Vector2) -> void:
	var camp := await _camp(home)
	var watch := player.camp_range
	face(WAYS[0])
	var board := await ride_here()
	hold(["move_forward"])
	var seen := {"nearest": INF, "soonest": INF, "turned": false, "lost": false}
	watch.lost.connect(func(_labels: PackedStringArray) -> void: seen.lost = true)
	var back_home := func() -> bool:
		return seen.turned and Vector2(where().x - home.x, where().z - home.y).length() < 30.0
	while not back_home.call() and player.ride != null and player.ride.ticks < 60 * 120:
		await ride_for(0.5, func() -> void:
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


## Flat out from the camp carving from side to side, on past the edge and
## then for QUIET s more: what was told, and how often the line dropped or
## changed its form before the camp was lost.
func _carving(home: Vector2) -> void:
	var camp := await _camp(home)
	var watch := player.camp_range
	face(WAYS[0])
	var board := await ride_here()
	var seen := {"t": 0, "levels": [], "lost": [], "drops": 0, "forms": 0, "was": "", "after": 0}
	watch.warned.connect(func(level: int) -> void: seen.levels.append(level))
	watch.lost.connect(func(_labels: PackedStringArray) -> void: seen.lost.append(seen.t))
	while player.ride != null and (seen.lost.is_empty() or seen.t < seen.lost[0] + QUIET * 60) \
			and seen.t < 60 * 150:
		await ride_for(1.5, func() -> void:
			seen.t += 1
			var form := _form(watch.said)
			if seen.lost.is_empty():
				if seen.was != "" and form == "":
					seen.drops += 1
				elif seen.was != "" and form != seen.was:
					seen.forms += 1
			elif seen.t > seen.lost[0] + CampRange.LOST_SECONDS * 60 and (form != "" or watch.told > 0):
				seen.after += 1
			seen.was = form)
		hold(["move_forward", "move_left" if (seen.t / 90) % 2 == 0 else "move_right"])
	hold([])
	var kept := camp.filter(func(d: Variant) -> bool: return is_instance_valid(d))
	print("carving flat out past the edge: warned %s, lost %d times; the line dropped %d times and changed form %d times before; %d ticks up after"
		% [seen.levels, seen.lost.size(), seen.drops, seen.forms, seen.after])
	check(seen.levels == [CampRange.FIRST, CampRange.LAST] and seen.lost.size() == 1 and kept.is_empty(),
		"carving, each warning came once and the camp was lost once (%s, %d)" % [seen.levels, seen.lost.size()])
	check(seen.drops == 0 and seen.forms == 0, "the line stayed up and steady (dropped %d, changed %d)"
		% [seen.drops, seen.forms])
	check(seen.after == 0, "and %d s after the loss, nothing's up" % QUIET)
	player.step_off()
	board.free()


## The line's form: a countdown, a distance, a loss, or "" when it's down.
func _form(said: String) -> String:
	return "" if said == "" else ("s" if said.contains(" s ") or said.ends_with(" s") else ("m" if said.contains(" m ") else said))


## What the warning of this level counted down from, s, or INF if it gave the distance.
func _counted(levels: Array, level: int) -> float:
	for each: Array in levels:
		if each[0] == level:
			return ceilf(each[2]) if each[2] <= Tuning.current().range_first_seconds else INF
	return INF


## The tick a warning of this level came, or INF.
func _when(levels: Array, level: int) -> float:
	for each: Array in levels:
		if each[0] == level:
			return each[1]
	return INF
