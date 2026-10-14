extends RopeProbe
## Rope & tethering probe 5: too much load breaks something, and never
## explodes. A gust spike far past a line's breaking strength, too brief to
## sustain, leaves it holding. Then the wind rises until the line's sustained
## load passes its strength: it snaps near its rating, the floater drifts off
## downwind no faster than the wind, and nothing spikes. A strong line on a
## weak stake pulls the stake out instead, and the stake goes with the floater.

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
	set_rate(60, 2)
	wind.override = func(_x: float, _z: float, _t: float) -> Vector2: return Vector2(_blowing, 0.0)
	ropes.snapped.connect(func(_rope: Rope) -> void: _snapped_in = _blowing)
	await _line_snaps()
	ropes.clear()
	for body: Node3D in world.content.get_children():
		if body is RigidBody3D:
			body.free()
	_blowing = 12.0
	await _stake_pulls_out()


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
		seen.fastest = maxf(seen.fastest, v.length() - _blowing)
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


func _stake_pulls_out() -> void:
	var floater := Props.floater(world, spot(6.0, 0.0))
	var rope := stake_line(spot(0.0, 0.0), floater, 0.3, INF, WEAK)
	var stake: RigidBody3D = rope.a.holder
	await simulate(4.0)
	var seen := {"fastest": -INF}
	var watch := func() -> void:
		for body: RigidBody3D in [floater, stake]:
			seen.fastest = maxf(seen.fastest, body.linear_velocity.length() - _blowing)
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


func _strands_sane() -> void:
	var bad := 0
	for strand in ropes.strands:
		for p in strand.points:
			if not finite(p) or p.y < world.height_under(p) - 0.001:
				bad += 1
	check(bad == 0, "every drawn strand is finite and on or above the sand (%d points off)" % bad)
