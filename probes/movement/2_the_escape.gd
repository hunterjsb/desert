extends MovementProbe
## Movement probe 2: the escape is real. In the run's own weather, a storm
## front 50 m upwind and coming at you, clear air downwind: on a board with a
## charged base battery, flat out downwind, the storm never reaches you and
## the front falls further behind for as long as you ride, with charge to
## spare. From the same place and moment on foot, sprinting the same way, it
## catches you.

const DISTANCE := 50.0
const RIDE := 180.0
const SPRINT := 60.0
## The way downwind must be clear for a rider at about this speed, m/s, for
## the whole ride, so it's this front you escape and not another you meet.
const AHEAD_SPEED := 18.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.view_radius = tuning.near_radius + 1
	await load_world(1234, false)
	player = world.player
	hold([])
	set_rate(60, 16)
	var start := _start()
	check(not start.is_empty(), "a front %d m upwind with clear air downwind" % DISTANCE)
	if start.is_empty():
		return
	await _arrive(start)
	var board := await ride_here()
	world.time_warp = 1.0
	var gaps: Array[float] = [_gap()]
	var seen := {"caught": false, "ticks": 0}
	hold(["move_forward"])
	await ride_for(RIDE, func() -> void:
		seen.ticks += 1
		seen.caught = seen.caught or _stormy(where())
		if seen.ticks % 600 == 0:
			gaps.append(_gap()))
	hold([])
	var ridden := Vector2(where().x - start.x, where().z - start.z).length()
	var left: float = board.battery().charge_wh
	print("on the board: %.0f m in %.0f s, the front %s m behind every 10 s; %.0f Wh left of %.0f"
		% [ridden, RIDE, ", ".join(gaps.map(func(g: float) -> String: return "%.0f" % g)), left,
			board.battery().capacity()])
	check(not seen.caught, "the storm never reached you on the board")
	check(gaps.slice(1).all(func(g: float) -> bool: return g > DISTANCE) and gaps[-1] > gaps[1],
		"the front fell further and further behind")
	check(left > 0.0 and player.ride != null and player.ride.waited == 0, "with charge to spare (%.0f Wh)" % left)

	await _arrive(start)
	world.time_warp = 1.0
	var caught := INF
	hold(["move_forward", "sprint"])
	for i in roundi(SPRINT * 60.0):
		await simulate(1.0 / 60.0)
		if _stormy(where()):
			caught = i / 60.0
			break
	hold([])
	print("on foot, sprinting the same way: caught after %.1f s" % caught)
	check(caught < SPRINT, "on foot the storm catches you")
	set_rate(60)


## A place and moment with the front DISTANCE m upwind, and clear air downwind
## for a rider all the way: {x, z, time, down}, or {} if none in two days.
func _start() -> Dictionary:
	var field := world.weather.field
	var front := {"kind": "front", "distance": DISTANCE}
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0:
		var down := field.prevailing_at(t).normalized()
		var place := Scenarios._place(field, front, world.spawn, -down, t)
		if not place.is_empty():
			var clear := true
			var s := 0.0
			while clear and s <= RIDE:
				var ahead := Vector2(place.x, place.z) + down * AHEAD_SPEED * s
				clear = field.raw_storm_at(ahead.x, ahead.y, t + s) <= 0.0
				s += 5.0
			if clear:
				place.time = t
				place.down = down
				return place
		t += 60.0
	return {}


## There at that moment, the clock held while the ground there comes in, as
## long as that takes.
func _arrive(start: Dictionary) -> void:
	var down: Vector2 = start.down
	world.respawn(start.x, start.z, atan2(-down.x, -down.y), start.time)
	world.time_warp = 0.0
	await settle(true)


func _stormy(at: Vector3) -> bool:
	return world.weather.field.raw_storm_at(at.x, at.z, world.time) > 0.0


## Metres upwind from you to the front, now.
func _gap() -> float:
	var at := where()
	var up := -world.weather.field.prevailing_at(world.time).normalized()
	var d := 0.0
	while d < 6000.0 and not _stormy(at + Vector3(up.x, 0.0, up.y) * d):
		d += 1.0
	return d
