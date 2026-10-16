extends LineProbe
## Rope & tethering probe 4: lines share load. A floating crate on two
## identical parallel lines, from the hooks on its two sides to stakes straight
## upwind of them: each line carries about half its wind load. Then the wind
## rises until the load is half again what one line can bear, and holds there:
## the same crate on one line snaps it, the crate on two holds.

## Every line here snaps past this sustained load, N.
const WEAK := 300.0
const BREEZE := 15.0
## The two lines' shares of their total may differ from a half by this much.
const HALF := 0.05


func run() -> void:
	Tuning.current().rope_breaking = WEAK
	await load_lines()
	speed_up(4)
	# Downwind is +z; each crate's stakes sit 5 m straight upwind of its hooks.
	var two := floating(&"crate_frame", spot(-4.0, 0.0))
	var one := floating(&"crate_frame", spot(4.0, 0.0))
	var pair: Array[Rope] = []
	for crate: Device in [two, one]:
		for socket in crate.sockets():
			# The hooks on its two sides, not those on its front and back.
			var side := crate.to_local(socket.global_position).x
			if socket.kind != &"tie" or absf(side) < 0.3 or (crate == one and side < 0.0):
				continue
			var stake := driven_stake(socket.global_position + Vector3(0.0, 0.0, -5.0))
			var line := Line.between(world, socket, stake.free_tie(socket.global_position), 0.2)
			if crate == two:
				pair.append(line.rope)
	var single: Rope = ropes.ropes.filter(func(r: Rope) -> bool: return not pair.has(r))[0]
	blow(Vector2(0.0, BREEZE))
	await simulate(15.0)

	var pulls := pair.map(func(r: Rope) -> float: return _along_ground(r))
	var total: float = pulls[0] + pulls[1]
	var load := wind_load(two).length()
	print("crate on two lines in %d m/s: wind load %.1f N; the lines pull %.1f and %.1f N (%.1f%% and %.1f%%)"
		% [BREEZE, load, pulls[0], pulls[1], 100.0 * pulls[0] / total, 100.0 * pulls[1] / total])
	check(absf(pulls[0] / total - 0.5) < HALF and absf(pulls[1] / total - 0.5) < HALF,
		"each of two parallel lines carries about half")
	check(absf(total - load) < 0.05 * load, "and together they carry the whole wind load (%.1f of %.1f N)" % [total, load])

	# Half again one line's strength, on the crate's own catch.
	var strong := sqrt(1.5 * WEAK / world.weather.catch_of(two))
	var held_at := two.global_position
	var rise := 5.0
	var t := {"s": 0.0, "worst": 0.0}
	await simulate(rise + 12.0, func() -> void:
		t.s += 1.0 / 60.0
		blow(Vector2(0.0, lerpf(BREEZE, strong, minf(t.s / rise, 1.0))))
		for rope in pair:
			t.worst = maxf(t.worst, rope.share()))
	print("in %.1f m/s (%.0f N on each crate): one line %s; two lines %s, each at most %d%% of its strength; moved %.2f m"
		% [strong, 1.5 * WEAK, "snapped" if not ropes.ropes.has(single) else "held",
			"held" if pair.all(func(r: Rope) -> bool: return ropes.ropes.has(r)) else "snapped",
			roundi(t.worst * 100.0), two.global_position.distance_to(held_at)])
	check(not ropes.ropes.has(single), "a load past one line's strength snaps it")
	check(pair.all(func(r: Rope) -> bool: return ropes.ropes.has(r)), "and holds on two")
	check(two.global_position.distance_to(held_at) < 1.0, "the crate on two lines stays where it was held")


## A line's pull along the ground, N.
func _along_ground(rope: Rope) -> float:
	return rope.tension * flat(rope.normal).length()
