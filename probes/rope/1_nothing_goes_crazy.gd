extends RopeProbe
## Rope & tethering probe 1: nothing goes crazy. Every combination of wind
## (calm up to the worst storm gust), weight (a 2 kg lantern to a 150 kg crate)
## and number of lines (1 to 4) runs for two simulated minutes, all at once,
## each wind in its own row. No number turns invalid, nothing moves faster
## than its wind could carry it, a kicked rig in calm only ever loses energy,
## and under steady wind everything settles. Drawn strands stay finite, on or
## above the sand, and within reach of their ends. Lines and stakes are
## unbreakable here, so only the constraint itself is on trial.

const MINUTES := 2.0
const SPACING := 16.0
## Each row's wind along +x: speed, gusts as a share of it, and whether it
## should settle. Calm starts every rig moving instead.
const KICK := 4.0
const SETTLED := 0.05

var _rows: Array[Dictionary] = []
## Per floater: where its tray last held it, and the work the tray has done
## since, following the sand up and down under it.
var _rest := {}
var _tray_work := {}


func run() -> void:
	await load_ropes()
	set_rate(60, 6)
	_rows = [
		# In still air only drag slows a rig swinging round its stake, so calm
		# proves energy only ever goes, not that it's all gone.
		{"name": "calm", "speed": 0.0, "gusts": 0.0, "settles": false},
		{"name": "breeze", "speed": wind.breeze_speed(), "gusts": 0.0, "settles": true},
		{"name": "gusting storm", "speed": wind.storm_speed(), "gusts": world.tuning.gust_storm_strength,
			"settles": false},
		{"name": "worst gust", "speed": wind.worst_gust(), "gusts": 0.0, "settles": true},
	]
	var home_z := world.player_world_z()
	var blows: Array[Callable] = []
	for row in _rows:
		blows.append(wind.steady(Vector2.RIGHT, row.speed, row.gusts) if row.speed > 0.0
			else func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO)
	wind.override = func(x: float, z: float, t: float) -> Vector2:
		return blows[_row_at(z - home_z)].call(x, z, t)

	var rigs: Array[Dictionary] = []
	for r in _rows.size():
		for weight in 3:
			for lines in range(1, 5):
				rigs.append(_rig(r, weight, lines))
	print("%d rigs, %d ropes, %.0f simulated minutes" % [rigs.size(), ropes.ropes.size(), MINUTES])
	await get_tree().physics_frame
	for rig in rigs:
		if _rows[rig.row].name == "calm":
			rig.body.linear_velocity = Vector3(0.0, 0.5, KICK)
			rig.body.angular_velocity = Vector3(0.3, 1.0, 0.0)

	var seconds := MINUTES * 60.0
	var ticks := roundi(seconds * ticks_per_second())
	var window := 5 * ticks_per_second()
	var energy: Array[float] = []
	var bad := {"invalid": 0, "fast": 0, "strands": 0, "unsettled": 0}
	var worst := {"speed": 0.0, "fast_what": "", "unsettled": {}}
	for tick in ticks:
		await get_tree().physics_frame
		var calm := 0.0
		for rig in rigs:
			var body: RigidBody3D = rig.body
			var v := body.linear_velocity
			if not (finite(body.global_position) and finite(v) and finite(body.angular_velocity)):
				bad.invalid += 1
				continue
			var limit: float = rig.limit
			if v.length() > limit:
				bad.fast += 1
				if v.length() - limit > worst.speed:
					worst.speed = v.length() - limit
					worst.fast_what = rig.what
			if _rows[rig.row].name == "calm":
				calm += _energy(body)
			if tick > ticks - 20 * ticks_per_second() and _rows[rig.row].settles and v.length() > SETTLED:
				bad.unsettled += 1
				worst.unsettled[rig.what] = maxf(worst.unsettled.get(rig.what, 0.0), v.length())
		if tick % window == 0:
			energy.append(-INF)
		energy[-1] = maxf(energy[-1], calm)
		for rope in ropes.ropes:
			if not is_finite(rope.tension):
				bad.invalid += 1
		if tick % 30 == 0:
			bad.strands += _strands_off()
	print("calm rigs' most energy per 5 s, J: ", energy.map(func(e: float) -> String: return "%.1f" % e))
	print("invalid %d, too fast %d (worst %.2f m/s over, %s), strands off %d, unsettled %s"
		% [bad.invalid, bad.fast, worst.speed, worst.fast_what, bad.strands, worst.unsettled])
	check(bad.invalid == 0, "no invalid numbers")
	check(bad.fast == 0, "nothing faster than its wind could carry it")
	var grew := 0
	for i in range(1, energy.size()):
		if energy[i] > energy[i - 1] + absf(energy[i - 1]) * 0.02:
			grew += 1
	check(grew == 0, "a kicked rig in calm only loses energy (%d windows gained)" % grew)
	check(energy[-1] < energy[0] * 0.25, "and keeps losing it")
	check(bad.unsettled == 0, "everything settles under steady wind")
	check(bad.strands == 0, "every drawn strand stays finite, above the sand and within reach of its ends")


func _row_at(z: float) -> int:
	return clampi(floori(z / SPACING + _rows.size() * 0.5), 0, _rows.size() - 1)


## One object on `lines` lines from stakes 6 m round it, starting upwind.
func _rig(row: int, weight: int, lines: int) -> Dictionary:
	var column := weight * 4 + lines - 1
	var at := spot((column - 5.5) * SPACING, (row - _rows.size() * 0.5 + 0.5) * SPACING)
	var body: RigidBody3D
	var what: String
	match weight:
		0:
			body = Props.floater(world, at, 2.0, 0.05, Vector3.ONE * 0.4)
			what = "lantern"
		1:
			body = Props.floater(world, at)
			what = "floater"
		_:
			body = Props.crate(world, at, 150.0)
			what = "crate"
	var spread: Array = [[0.0], [-60.0, 60.0], [0.0, 120.0, 240.0], [0.0, 90.0, 180.0, 270.0]][lines - 1]
	for angle: float in spread:
		stake_line(at + Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(angle)) * 6.0, body, 0.3, INF, INF)
	var top: float = _rows[row].speed * (1.0 + _rows[row].gusts)
	return {"row": row, "body": body, "what": "%s, %d line%s, %s" % [what, lines, "" if lines == 1 else "s",
		_rows[row].name], "limit": KICK + 0.5 if top == 0.0 else top * 1.1 + 1.0}


## Moving energy, plus what the hover tray holds as a spring, less what the
## tray has put in: its spring rests a set height over the sand, so over a
## slope it lifts and lowers what it holds. Called once a tick.
func _energy(body: RigidBody3D) -> float:
	var spin := body.angular_velocity
	var total := 0.5 * body.mass * body.linear_velocity.length_squared() \
		+ 0.5 * spin.dot(Vector3(body.inertia.x * spin.x, body.inertia.y * spin.y, body.inertia.z * spin.z))
	if body is Props.Floater:
		var omega := TAU * Props.Floater.HOVER_HERTZ
		var rest := world.height_under(body.global_position) + Props.Floater.HOVER
		var off := body.global_position.y - rest
		_tray_work[body] = _tray_work.get(body, 0.0) - body.mass * omega * omega * off * (rest - _rest.get(body, rest))
		_rest[body] = rest
		total += 0.5 * body.mass * omega * omega * off * off - _tray_work[body]
	return total


func _strands_off() -> int:
	var off := 0
	for strand in ropes.strands:
		var reach := strand.length * 1.1 + 0.05
		for p in strand.points:
			if not finite(p) or p.y < world.height_under(p) - 0.001 \
					or (strand.a != null and p.distance_to(strand.a.global_position) > reach) \
					or (strand.b != null and p.distance_to(strand.b.global_position) > reach):
				off += 1
	return off
