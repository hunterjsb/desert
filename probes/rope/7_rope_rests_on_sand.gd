extends LineProbe
## Rope & tethering probe 7: rope rests on the sand, never in it. Heavy lines
## lie slack over the most sharply rounded crest near spawn, a floating planter
## hangs on a slack line whose middle lies on the sand, and you drag a line in
## your hand round its stake, in calm and then a gusting breeze. Every tick the
## drawn rope is sampled the way the screen draws it, along the curve between
## its points: its underside never sinks into the sand, and the slack lines
## really do lie on it.

## The underside may press this far into the sand, m: a rope lying on it.
const INTO := 0.005
## How far round the stake you drag your line, and how far out.
const DRAG_TURN := PI
const DRAG_OUT := 3.0

var _seen := {"samples": 0, "deepest": -INF, "lying": 0}


func run() -> void:
	await load_lines()
	speed_up(4)
	var crest := _crest()
	print("crest at %.0f, %.0f, rounded %.3f /m" % [crest.x, crest.z, _roundness(crest)])
	var across := Vector3(1.0, 0.0, 0.0)
	for k in 3:
		var side := Vector3(0.0, 0.0, (k - 1) * 1.5)
		var a := driven_stake(crest - across * 5.0 + side)
		var b := driven_stake(crest + across * 5.0 + side)
		Line.between(world, a.free_tie(b.global_position), b.free_tie(a.global_position), 1.0 + k)
	var planter := floating(&"planter", spot(4.0, -4.0))
	var anchor := driven_stake(spot(4.0, -9.0))
	lay(planter, anchor, 1.5)
	var drag_stake := driven_stake(spot(-4.0, 2.0))
	var spare := _spare(spot(-4.0, 2.0 + DRAG_OUT))
	Line.between(world, drag_stake.free_tie(spare.global_position), spare.free_tie(drag_stake.global_position), 2.0)
	await simulate(0.5)
	look(spot(-4.0, 2.0 + DRAG_OUT + 1.0) + Vector3.UP * 1.65, spare.global_position)
	check(hands.grab(), "you take up the stake on the line's other end")
	await simulate(0.5)

	var snaps := {"n": 0}
	ropes.snapped.connect(func(_r: Rope) -> void: snaps.n += 1)
	await simulate(6.0, _sample)
	blow(Vector2(wind.breeze_speed(), 0.0), world.tuning.gust_strength)
	await simulate(10.0, _sample)
	# Round the stake through half a turn, the line sweeping over the sand.
	for i in 40:
		var turn := DRAG_TURN * (i + 1) / 40.0
		await walk_to(drag_stake.global_position + Vector3(sin(turn), 0.0, cos(turn)) * DRAG_OUT, _sample)
	await simulate(3.0, _sample)
	print("%d samples along the drawn ropes: the deepest underside %.4f m into the sand; %d ticks with slack lines on it"
		% [_seen.samples, _seen.deepest, _seen.lying])
	check(_seen.deepest < INTO, "no drawn rope dips into the sand (%.4f m)" % _seen.deepest)
	check(_seen.lying > 0, "slack heavy lines lie on the sand")
	check(snaps.n == 0 and ropes.ropes.size() == 5, "and every line held")


## The most sharply rounded crest within 40 m of spawn.
func _crest() -> Vector3:
	var best := spot(0.0, 0.0)
	var most := -INF
	for i in 41:
		for j in 41:
			var at := spot(i * 2.0 - 40.0, j * 2.0 - 40.0)
			var r := _roundness(at)
			if r > most:
				most = r
				best = at
	return best


## How sharply the sand rounds over at a place, along x: minus its curvature.
func _roundness(at: Vector3) -> float:
	var h := func(dx: float) -> float: return world.height_under(at + Vector3(dx, 0.0, 0.0))
	return -(h.call(1.0) - 2.0 * h.call(0.0) + h.call(-1.0))


## A stake lying loose on the sand.
func _spare(at: Vector3) -> Stake:
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2.0), at + Vector3.UP * 0.04)
	return stake


## Samples each drawn rope as the screen draws it, at every ring of the tube.
func _sample() -> void:
	var lying := false
	for strand in ropes.strands:
		var points := strand.points
		for i in points.size() - 1:
			for r in RopeStrand.RINGS_PER_LINK:
				var p := strand.drawn(i, float(r) / RopeStrand.RINGS_PER_LINK)
				var into := world.height_under(p) - (p.y - RopeStrand.RADIUS)
				_seen.deepest = maxf(_seen.deepest, into)
				_seen.samples += 1
				lying = lying or into > -0.01
	if lying:
		_seen.lying += 1
