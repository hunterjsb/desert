extends MovementProbe
## Structure kits probe 2: you can walk through every kind's doors and
## openings. Each kind with a way in, dug out, stood by hand both ways round
## where the dunes take it, a wreck leaning as far as its era leans: you walk
## its tour on held keys, in at its openings, through its rooms, down a
## cistern's or a dugout's drift and back up, into a wreck's torn tail and
## out; at a walk, and the house ruin at a sprint too. You never snag, never
## get stuck, and never go through a floor or the sand.
## Time limit: 900 s

## How near a point counts as reached, m.
const REACHED := 0.4
## Slower than this share of your pace, away from a turn, is a snag.
const SNAG := 0.6
## A leg may take this many times as long as its length at your pace, plus this, s.
const SLACK := 1.5
const SPARE := 1.0


func run() -> void:
	# Dug out, as the wind leaves them after a hard storm.
	Tuning.current().site_return_m = -1.0
	await load_moving(1234, true)
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var stats := {"stuck": 0, "snags": 0, "under": 0.0, "legs": 0}
	var walked := []
	var k := 0
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		if piece.tour.is_empty():
			continue
		for turned in 2:
			var site := await _stand(kind, from + Vector2(80.0 * (k % 6) - 200.0, 90.0 * (k / 6) + 60.0), turned)
			k += 1
			if site == null:
				check(false, "%s stands somewhere to walk" % kind)
				continue
			walked.append("%s %d" % [kind, site.turn])
			for sprint in ([false, true] if kind == &"house_ruin" else [false]):
				await _tour(site, sprint, stats)
	print("walked %d: %s; %d legs, %d stuck, %d snags, deepest under a floor %.3f m"
		% [walked.size(), ", ".join(walked), stats.legs, stats.stuck, stats.snags, stats.under])
	check(stats.stuck == 0, "you never got stuck (%d legs not reached)" % stats.stuck)
	check(stats.snags == 0, "you never snagged in an opening (%d snags)" % stats.snags)
	check(stats.under > -0.05, "you never went through a floor (%.3f m)" % stats.under)


## A kind stood by hand near a place, turned a quarter turn if `turned`,
## where the dunes take it and its ground is its own.
func _stand(kind: StringName, near: Vector2, turned: int) -> Structure:
	var sites := world.shape.sites
	var lean := deg_to_rad(Eras.TILT.get(StructureKit.piece(kind).era, Vector2.ZERO).y)
	for j in 30:
		var at := near + Vector2((j % 6) * 9.0, (j / 6) * 9.0)
		var site := sites.by_hand(kind, at.x, at.y, 0.3 + turned * PI * 0.5, 0.0, lean)
		if not site.stands():
			continue
		sites.add(site)
		if sites.covering(site.x, site.z) == site:
			await settle(true)
			return site
	return null


func _tour(site: Structure, sprint: bool, stats: Dictionary) -> void:
	var tour := site.piece.tour
	var start := site.to_world(tour[0])
	await place(start.x, start.y, site.to_world(tour[1]) - start)
	var pace := world.tuning.sprint_speed if sprint else world.tuning.walk_speed
	for k in range(1, tour.size()):
		var to := site.to_world(tour[k])
		var from := Vector2(where().x, where().z)
		# Up a drift out of a pit you climb as slowly as up any slope.
		var grade := maxf(world.height_at(to.x, to.y) - world.height_at(from.x, from.y), 0.0) / maxf(from.distance_to(to), 0.1)
		var limit := from.distance_to(to) / (pace * _uphill(grade)) * SLACK + SPARE
		var slow := 0.0
		var spent := 0.0
		var reached := false
		stats.legs += 1
		hold(["move_forward", "sprint"] if sprint else ["move_forward"])
		while spent < limit:
			var here := Vector2(where().x, where().z)
			var left := here.distance_to(to)
			if left < REACHED:
				reached = true
				break
			face(to - here)
			await simulate(1.0 / ticks_per_second())
			spent += 1.0 / ticks_per_second()
			stats.under = minf(stats.under, _under_floor(site))
			# Away from the start and end of a leg, you keep your pace, as the
			# slope under you allows.
			var off_turn := spent > 0.3 and left > 1.0
			var ahead := (to - here).normalized()
			var climb := maxf(world.height_at(here.x + ahead.x, here.y + ahead.y) - world.height_at(here.x, here.y), 0.0)
			slow = slow + 1.0 / ticks_per_second() if off_turn and flat_speed() < pace * _uphill(climb) * SNAG else 0.0
			if slow > 0.2:
				stats.snags += 1
				printerr("%s: snagged near %s on the way to tour point %d (%s)" % [site.kind, here, k,
					"sprint" if sprint else "walk"])
				slow = -INF
		if not reached:
			stats.stuck += 1
			printerr("%s at %.0f,%.0f: never reached tour point %d (%s)" % [site.kind, site.x, site.z, k,
				"sprint" if sprint else "walk"])
			hold([])
			return
	hold([])


## The share of your pace a climb of this rise per metre leaves you, as the
## player has it.
func _uphill(climb: float) -> float:
	return maxf(0.4, 1.0 - climb * world.tuning.uphill_slowdown)


## How far your feet are below a room's floor while you're on it, m.
func _under_floor(site: Structure) -> float:
	var at := where()
	var p := site.plan(at.x - site.x, at.z - site.z)
	for room in site.piece.rooms:
		if room.holds(p) and room.sand(p) <= room.floor + 0.01:
			return at.y - (site.floor_y + room.floor)
	return 0.0
