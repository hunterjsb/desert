extends MovementProbe
## Movement probe 3: the wind dial on foot. In a gale, sprint the same
## stretch of dunes near spawn with the wind and then into it: into the wind
## takes longer and costs more stamina. Across a ridge you can't: its slip
## face is too steep to climb on foot, which is the ground's own dial. So the
## stretch is one you can cross both ways, ending as near as can be found to
## as high as it starts, so neither way is the one that climbs.

## The stretch, m, its sand never steeper than this, degrees, so neither way
## slides you, and rising and falling at least this much, m, so it's dunes.
const LENGTH := 60.0
const STEEPEST := 22.0
const RELIEF := 1.5
## A gale, well past what you stand against unmoved, m/s.
const WIND := 20.0


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var tuning := world.tuning
	# Never tired out, so the stamina a crossing takes is all it cost.
	tuning.stamina_max = 1000.0
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var stretch := _stretch(Vector2(world.player_world_x(), world.player_world_z()), down)
	check(not stretch.is_empty(), "a stretch of dunes near spawn you can cross both ways")
	if stretch.is_empty():
		return
	blow(down * WIND)
	var with: Dictionary = await _cross(stretch.from, stretch.from + down * LENGTH)
	var against: Dictionary = await _cross(stretch.from + down * LENGTH, stretch.from)
	print("%.0f m of dunes rising and falling %.1f m, %.1f m higher downwind, in a %.0f m/s gale: with it %.1f s and %.0f stamina, into it %.1f s and %.0f"
		% [LENGTH, stretch.relief, stretch.rise, WIND, with.seconds, with.stamina, against.seconds, against.stamina])
	check(with.crossed and against.crossed, "you crossed it both ways")
	check(against.seconds > with.seconds * 1.15, "into the wind takes longer (%.1f s against %.1f)"
		% [against.seconds, with.seconds])
	check(against.stamina > with.stamina * 1.1, "and costs more stamina (%.0f against %.0f)"
		% [against.stamina, with.stamina])
	set_rate(60)


## The stretch near spawn along the wind whose sand stays under STEEPEST and
## rises and falls at least RELIEF, ending nearest as high as it starts:
## {from, relief, rise}, or {} if none.
func _stretch(near: Vector2, down: Vector2) -> Dictionary:
	var across := down.orthogonal()
	var best := {}
	for ring in range(-25, 26):
		for back in range(-12, 13):
			var from := near + across * ring * 12.0 + down * back * 20.0
			var rise := world.height_at(from.x + down.x * LENGTH, from.y + down.y * LENGTH) - world.height_at(from.x, from.y)
			if not best.is_empty() and absf(rise) >= absf(best.rise):
				continue
			var low := INF
			var high := -INF
			var walkable := true
			for m in int(LENGTH) + 1:
				var at := from + down * m
				walkable = walkable and degrees(gradient(at.x, at.y)) < STEEPEST
				var h := world.height_at(at.x, at.y)
				low = minf(low, h)
				high = maxf(high, h)
			if walkable and high - low >= RELIEF:
				best = {"from": from, "relief": high - low, "rise": rise}
	return best


## Sprints from one end to the other: {seconds, stamina, crossed}.
func _cross(from: Vector2, to: Vector2) -> Dictionary:
	await place(from.x, from.y, (to - from).normalized())
	player.stamina = world.tuning.stamina_max
	var way := (to - from).normalized()
	var made := {"ticks": 0, "done": false}
	hold(["move_forward", "sprint"])
	while not made.done and made.ticks < 60 * 60:
		await simulate(1.0 / 60.0)
		made.ticks += 1
		made.done = Vector2(where().x - from.x, where().z - from.y).dot(way) >= LENGTH
	hold([])
	return {"seconds": made.ticks / 60.0, "stamina": world.tuning.stamina_max - player.stamina, "crossed": made.done}
