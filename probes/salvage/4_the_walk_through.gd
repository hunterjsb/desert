extends MovementProbe
## Salvage & ruins probe 4: the walk-through. You walk the ruin type's tour,
## in at the front door, through every room and every doorway, out the back,
## and back in and out the front, on held keys, at a walk and at a sprint, in
## ruins standing every way round. You never snag, never get stuck, and never
## go through the floor or the sand.

## Ruins to walk, each stood a different way round, and how near a point
## counts as reached, m.
const RUINS := 2
const REACHED := 0.4
## Slower than this share of your pace, away from a turn, is a snag.
const SNAG := 0.6
## A leg may take this many times as long as its length at your pace, plus this, s.
const SLACK := 1.5
const SPARE := 1.0


func run() -> void:
	await load_moving(1234, true)
	var walked := 0
	var turns := {}
	var stats := {"stuck": 0, "snags": 0, "under": 0.0, "legs": 0}
	for ruin in world.shape.ruins.around(world.spawn.x, world.spawn.y, 3000.0):
		if turns.has(ruin.turn % 2) or walked >= RUINS:
			continue
		turns[ruin.turn % 2] = true
		walked += 1
		for sprint in [false, true]:
			await _tour(ruin, sprint, stats)
	print("%d ruins walked at a walk and a sprint: %d legs, %d stuck, %d snags, deepest under the floor %.3f m"
		% [walked, stats.legs, stats.stuck, stats.snags, stats.under])
	check(walked == RUINS, "ruins stood both ways round were walked (%d)" % walked)
	check(stats.stuck == 0, "you never got stuck (%d legs not reached)" % stats.stuck)
	check(stats.snags == 0, "you never snagged on a doorway or a wall (%d snags)" % stats.snags)
	check(stats.under > -0.05, "you never went through a floor (%.3f m)" % stats.under)


func _tour(ruin: Ruin, sprint: bool, stats: Dictionary) -> void:
	var start := ruin.to_world(Ruin.TOUR[0])
	await place(start.x, start.y, ruin.to_world(Ruin.TOUR[1]) - start)
	var pace := world.tuning.sprint_speed if sprint else world.tuning.walk_speed
	for k in range(1, Ruin.TOUR.size()):
		var to := ruin.to_world(Ruin.TOUR[k])
		var from := Vector2(where().x, where().z)
		var limit := from.distance_to(to) / pace * SLACK + SPARE
		var held := ["move_forward", "sprint"] if sprint else ["move_forward"]
		var slow := 0.0
		var spent := 0.0
		var reached := false
		stats.legs += 1
		hold(held)
		while spent < limit:
			var here := Vector2(where().x, where().z)
			var left := here.distance_to(to)
			if left < REACHED:
				reached = true
				break
			face(to - here)
			await simulate(1.0 / ticks_per_second())
			spent += 1.0 / ticks_per_second()
			stats.under = minf(stats.under, _under_floor(ruin))
			# Away from the start and end of a leg, you keep your pace.
			var off_turn := spent > 0.3 and left > 1.0
			slow = slow + 1.0 / ticks_per_second() if off_turn and flat_speed() < pace * SNAG else 0.0
			if slow > 0.2:
				stats.snags += 1
				printerr("snagged near %s on the way to tour point %d (%s)" % [here, k, "sprint" if sprint else "walk"])
				slow = -INF
		if not reached:
			stats.stuck += 1
			printerr("never reached tour point %d of the ruin at %s (%s)" % [k, ruin.center, "sprint" if sprint else "walk"])
			return
	hold([])


## How far your feet are below the floor while you're inside its walls, m.
func _under_floor(ruin: Ruin) -> float:
	var at := where()
	var p := ruin.plan(at.x - ruin.center.x, at.z - ruin.center.y)
	if absf(p.x) > Ruin.HALF.x - Ruin.WALL or absf(p.y) > Ruin.HALF.y - Ruin.WALL:
		return 0.0
	return at.y - ruin.floor_y
