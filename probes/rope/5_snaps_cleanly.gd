extends RopeProbe
## Rope & tethering probe 5: too much load breaks something, and never
## explodes. A gust spike far past a line's breaking strength, too brief to
## sustain, leaves it holding. Then the wind rises until the line's sustained
## load passes its strength: it snaps near its rating, the floater drifts off
## downwind no faster than the wind, and nothing spikes. A strong line on a
## weak stake pulls the stake out instead, and the stake goes with the floater.
## And a line laid ring to ring, from a floating planter's hook to a stake,
## parts into two lines when it snaps, each with a loose end where it broke:
## the stake keeps one, the planter drags the other off downwind. And a line a
## snag lets go of, stretched past its stop while the other end drove on,
## drags its end free and never slings it.

const WEAK := 400.0
## The wind rises this much a second, m/s.
const RISE := 0.5
## Speed past the wind that would mean something flung it, m/s.
const FLUNG := 0.5

## Wind speed along +x, m/s, and the wind it was when the line snapped.
var _blowing := 12.0
var _snapped_in := -1.0


func run() -> void:
	await load_ropes()
	set_rate(60, 4)
	wind.override = func(_x: float, _z: float, _t: float) -> Vector2: return Vector2(_blowing, 0.0)
	ropes.snapped.connect(func(_rope: Rope) -> void: _snapped_in = _blowing)
	_blowing = 0.0
	await _snag_lets_go()
	ropes.clear()
	for body: Node3D in world.content.get_children():
		if body is RigidBody3D:
			body.free()
	_blowing = 12.0
	_snapped_in = -1.0
	await _line_snaps()
	ropes.clear()
	for body: Node3D in world.content.get_children():
		if body is RigidBody3D:
			body.free()
	_blowing = 12.0
	await _stake_pulls_out()
	ropes.clear()
	for body: Node3D in world.content.get_children():
		if body is RigidBody3D or body is Line:
			body.free()
	# Rising from nearer where it will go.
	_blowing = 20.0
	_snapped_in = -1.0
	await _line_parts()


## The wind rises steadily until `done` says stop, or it reaches 40 m/s;
## `each` is called after every tick.
func _rise_until(done: Callable, each: Callable) -> void:
	var h := 1.0 / ticks_per_second()
	while not done.call() and _blowing < 40.0:
		await get_tree().physics_frame
		each.call()
		_blowing += RISE * h


func _line_snaps() -> void:
	var floater := Props.floater(world, spot(6.0, 0.0))
	var rope := stake_line(spot(0.0, 0.0), floater, 0.3, WEAK, INF)
	await simulate(6.0)
	# A gust worth two and a half times the line's strength, for a tenth of a second.
	var peak := {"pull": 0.0}
	_blowing = 45.0
	await simulate(0.1, func() -> void: peak.pull = maxf(peak.pull, rope.tension))
	_blowing = 12.0
	await simulate(3.0, func() -> void: peak.pull = maxf(peak.pull, rope.tension))
	print("a 0.1 s spike pulled %.0f N on a %.0f N line" % [peak.pull, WEAK])
	check(peak.pull > WEAK, "the spike really pulled past the breaking strength")
	check(ropes.ropes.has(rope), "and the line held, since it wasn't sustained")

	# Watched from before the snap, so the tick it lets go is seen too.
	var h := 1.0 / ticks_per_second()
	var seen := {"fastest": -INF, "kick": 0.0, "last": floater.linear_velocity}
	var watch := func() -> void:
		var v := floater.linear_velocity
		seen.fastest = maxf(seen.fastest, _past_wind(v))
		seen.kick = maxf(seen.kick, (v - seen.last).length() / h)
		seen.last = v
	await _rise_until(func() -> bool: return _snapped_in > 0.0, watch)
	var from := floater.global_position
	await simulate(4.0, watch)
	var drift := floater.global_position - from
	var load_at_snap: float = floater.get_meta(&"wind_catch") * _snapped_in * _snapped_in
	print("snapped in a %.1f m/s wind (%.0f N on a %.0f N line); drifted %.1f m, %.0f° off downwind;"
		% [_snapped_in, load_at_snap, WEAK, drift.length(), rad_to_deg(flat(drift).angle_to(Vector3.RIGHT))]
		+ " hardest kick %.1f m/s², fastest %.2f m/s past the wind" % [seen.kick, seen.fastest])
	check(_snapped_in > 0.0, "the line snapped as the wind rose")
	check(load_at_snap > WEAK * 0.95 and load_at_snap < WEAK * 1.15, "near its breaking strength")
	check(flat(drift).angle_to(Vector3.RIGHT) < deg_to_rad(10.0) and drift.length() > 5.0,
		"the floater drifts off downwind")
	check(seen.fastest < FLUNG, "no faster than the wind")
	check(seen.kick < 1.5 * load_at_snap / floater.mass, "nothing kicks it: the line just stops pulling")
	_strands_sane()


## Something solid holds a loose end while the other end drives on, then lets
## go: stood in by the floater set that far past its line's stop in still air,
## half the line again. Smooth sand never holds one: up a slip face or down it,
## the end comes along at the pace of what drags it.
func _snag_lets_go() -> void:
	var floater := Props.floater(world, spot(6.0, 0.0))
	var rope := stake_line(spot(0.0, 0.0), floater, 0.0, INF, INF)
	await simulate(2.0)
	var out := flat(floater.global_position - rope.a.global_position).normalized()
	floater.global_position += out * rope.length * 0.5
	var seen := {"closing": 0.0}
	await simulate(2.0, func() -> void: seen.closing = maxf(seen.closing, -floater.linear_velocity.dot(out)))
	print("let go %.1f m past its stop, the floater came back at %.2f m/s at most" % [rope.length * (0.5 - rope.max_stretch),
		seen.closing])
	check(seen.closing < Rope.CLOSING_SPEED + FLUNG, "a line a snag lets go of drags its end free, never flung")
	_strands_sane()


func _stake_pulls_out() -> void:
	var floater := Props.floater(world, spot(6.0, 0.0))
	var rope := stake_line(spot(0.0, 0.0), floater, 0.3, INF, WEAK)
	var stake: RigidBody3D = rope.a.holder
	await simulate(4.0)
	var seen := {"fastest": -INF}
	var watch := func() -> void:
		for body: RigidBody3D in [floater, stake]:
			seen.fastest = maxf(seen.fastest, _past_wind(body.linear_velocity))
	await _rise_until(func() -> bool: return stake.pulled, watch)
	var gave := _blowing
	var from := stake.global_position
	await simulate(4.0, watch)
	var dragged := stake.global_position - from
	print("the stake pulled out in a %.1f m/s wind and was dragged %.1f m; fastest %.2f m/s past the wind"
		% [gave, dragged.length(), seen.fastest])
	check(stake.pulled and ropes.ropes.has(rope), "the stake gave way, not the line")
	check(dragged.length() > 3.0 and flat(dragged).angle_to(Vector3.RIGHT) < deg_to_rad(30.0),
		"and went downwind with the floater")
	check(seen.fastest < FLUNG, "with nothing flung")
	_strands_sane()


## How much faster than the wind something goes, m/s. The wind is level, so
## only level speed counts: what it carries over a dune rises and falls too.
func _past_wind(v: Vector3) -> float:
	return Vector2(v.x, v.z).length() - _blowing


func _strands_sane() -> void:
	var bad: Array[String] = []
	for strand in ropes.strands:
		var last := strand.points.size() - 1
		for i in strand.points.size():
			var p := strand.points[i]
			# The ends ride rings on bodies, which may rest SAND_SLOP into it.
			var under := world.height_under(p) - p.y
			var allowed := World.SAND_SLOP if i == 0 or i == last else 0.001
			if not finite(p) or under > allowed:
				bad.append("point %d of %d, %.3f m under" % [i, last, under])
	check(bad.is_empty(), "every drawn strand is finite and on or above the sand %s" % [bad])


func _line_parts() -> void:
	var planter := Catalog.device(&"planter")
	world.content.add_child(planter)
	planter.global_position = spot(6.0, 0.0) + Vector3.UP * world.tuning.hover_height
	# Its front ring toward the stake upwind.
	planter.global_basis = Basis(Vector3.UP, PI / 2.0)
	for id: StringName in [&"hover_tray", &"battery", &"hook", &"hook"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		for socket in planter.sockets():
			if socket.kind == part.kind and socket.part == null:
				planter.fit(part, socket)
				break
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.drive(spot(0.0, 0.0), world.height_under(spot(0.0, 0.0)))
	var line := Line.between(world, planter.free_tie(stake.global_position), stake.free_tie(planter.global_position), 0.3)
	line.rope.breaking = WEAK
	await simulate(4.0)
	var fastest := {"v": -INF}
	await _rise_until(func() -> bool: return _snapped_in > 0.0, func() -> void: pass)
	await simulate(4.0, func() -> void:
		for node in world.content.get_children():
			if node is Part:
				fastest.v = maxf(fastest.v, _past_wind(node.linear_velocity)))
	var lines := world.content.get_children().filter(func(n: Node) -> bool: return n is Line)
	var loose := world.content.get_children().filter(func(n: Node) -> bool:
		return n is Part and n.has_meta(&"line") and n.socket == null)
	var on_stake: Line = lines.filter(func(l: Line) -> bool: return l.ends.any(func(e: Part) -> bool:
		return e.socket != null and e.socket.get_parent() == stake))[0] if lines.size() == 2 else null
	var with_planter: Line = lines.filter(func(l: Line) -> bool: return l != on_stake)[0] if on_stake != null else null
	print("snapped in a %.1f m/s wind: %d lines, %d loose ends; the planter dragged its half %.1f m off; a loose end at most %.2f m/s past the wind"
		% [_snapped_in, lines.size(), loose.size(), planter.global_position.distance_to(stake.global_position), fastest.v])
	check(lines.size() == 2 and loose.size() == 2 and lines.all(func(l: Line) -> bool: return ropes.ropes.has(l.rope)),
		"a laid line parts into two, each a line with a loose end where it broke")
	check(on_stake != null and with_planter != null and with_planter.ends.any(func(e: Part) -> bool:
		return e.socket != null and e.socket.get_parent() == planter), "the stake keeps one half, the planter the other")
	check(planter.global_position.distance_to(stake.global_position) > 10.0, "and drags it off downwind")
	check(fastest.v < FLUNG, "with nothing flung")
	_strands_sane()
