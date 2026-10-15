extends LineProbe
## Rope & tethering probe 11: dragged, not launched. You stand on the sand
## holding a floating planter's line, and the worst gust the field can blow
## rises behind it. It drags you, moving as you really move, at no more than the
## line at its breaking strength and the wind's own shove could; you never
## leave the sand, and the drag never judders back and forth. Held in your hand
## and tied at your waist, on the flattest sand near spawn and down the
## steepest slope, its slip face. Holding it in your hand, you turn round and
## back again and again, and the line is never yanked: turning swings your
## hand, never the line past its reach.

const RISE := 1.5
const HOLD := 6.0
## Lifted off the sand at most this far, m; changing speed by at most this
## much a tick, m/s, and turning back against the drag at most this often.
const LIFT := 0.1
const JOLT := 0.5
const REVERSALS := 2
## Turning round on the spot this often, taking this long, for this long, s;
## the line's pull stays under this many times what it pulls while you stand
## still.
const TURN_EVERY := 1.0
const TURN_TAKES := 0.3
const TURNING := 4.0
const YANK := 1.5


func run() -> void:
	await load_lines()
	speed_up(4)
	var flat_at := _site(false)
	var slope_at := _site(true)
	for site: Array in [["flat sand", flat_at], ["the steepest slope", slope_at]]:
		for waist in [false, true]:
			await _dragged(site[0], site[1], waist)
	speed_up(1)


## Flattest or steepest within 120 m of spawn, with the way downhill:
## [where, downhill, grade].
func _site(steep: bool) -> Array:
	var best := spot(0.0, 0.0)
	var best_slope := INF if not steep else -INF
	var downhill := Vector3.RIGHT
	for i in 61:
		for j in 61:
			var at := spot(i * 4.0 - 120.0, j * 4.0 - 120.0)
			var grade := Vector3(world.height_under(at + Vector3.RIGHT) - world.height_under(at - Vector3.RIGHT),
				0.0, world.height_under(at + Vector3.BACK) - world.height_under(at - Vector3.BACK)) * 0.5
			if (steep and grade.length() > best_slope) or (not steep and grade.length() < best_slope):
				best_slope = grade.length()
				best = at
				downhill = -grade.normalized() if grade.length() > 1e-4 else Vector3.RIGHT
	return [best, downhill, best_slope]


func _dragged(where: String, site: Array, waist: bool) -> void:
	var player := world.player
	var at: Vector3 = site[0]
	var downhill: Vector3 = site[1]
	blow(Vector2.ZERO)
	teleport(world.world_x(at.x), world.world_z(at.z))
	player.rotation.y = atan2(-downhill.x, -downhill.z)
	await settle(true)
	var planter := floating(&"planter", at + downhill * 4.0)
	await simulate(0.5)
	var line := await lead(planter)
	if waist:
		# F with nothing to work ties the line in your hand on.
		check(hands.interact(), "you tie it at your waist")
	# Set up where the probe put you; dragged, you move as you really move.
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	await simulate(0.5)
	var start := player.global_position
	var top := (world.tuning.rope_breaking / (world.tuning.player_mass * world.tuning.grip_per_speed)
		- world.tuning.grip / world.tuning.grip_per_speed) \
		+ (wind.worst_gust() - world.tuning.wind_resist_speed) * world.tuning.wind_push
	var seen := {"speed": 0.0, "lift": 0.0, "jolt": 0.0, "reversals": 0, "last": Vector3.ZERO, "t": 0.0}
	await simulate(RISE + HOLD, func() -> void:
		seen.t += 1.0 / 60.0
		blow(Vector2(downhill.x, downhill.z) * wind.worst_gust() * minf(seen.t / RISE, 1.0))
		var v := flat(player.velocity)
		seen.speed = maxf(seen.speed, v.length())
		seen.lift = maxf(seen.lift, clearance(player))
		seen.jolt = maxf(seen.jolt, (v - seen.last).length())
		var along := v.dot(downhill)
		if seen.t > RISE and along * seen.last.dot(downhill) < 0.0:
			seen.reversals += 1
		seen.last = v)
	var dragged := flat(player.global_position - start).dot(downhill)
	var how := "at your waist" if waist else "in your hand"
	print("%s, %s (grade %.2f): dragged %.1f m, at most %.2f m/s (the line at its strength and the wind allow %.2f),"
		% [where, how, site[2], dragged, seen.speed, top]
		+ " lifted %.3f m, speed changed %.3f m/s a tick at most, %d reversals; line %s"
		% [seen.lift, seen.jolt, seen.reversals, "held" if line.rope != null and ropes.ropes.has(line.rope) else "SNAPPED"])
	check(dragged > 2.0, "%s, %s: the gust drags you" % [where, how])
	check(seen.speed <= top, "%s, %s: no faster than the line and the wind can drag you" % [where, how])
	check(seen.lift < LIFT, "%s, %s: never launched off the sand (%.3f m)" % [where, how, seen.lift])
	check(seen.jolt < JOLT and seen.reversals <= REVERSALS, "%s, %s: no judder" % [where, how])
	if not waist and line.rope != null and ropes.ropes.has(line.rope):
		var pulled := {"still": 0.0, "turning": 0.0, "t": 0.0}
		await simulate(TURNING, func() -> void:
			pulled.still = maxf(pulled.still, line.rope.tension))
		await simulate(TURNING, func() -> void:
			pulled.t += 1.0 / 60.0
			if fmod(pulled.t, TURN_EVERY) < TURN_TAKES:
				player.rotation.y += PI / (TURN_TAKES * 60.0)
			pulled.turning = maxf(pulled.turning, line.rope.tension))
		print("  in the gust the line pulls at most %.0f N standing, %.0f N turning round every %.0f s"
			% [pulled.still, pulled.turning, TURN_EVERY])
		check(ropes.ropes.has(line.rope) and pulled.turning < YANK * pulled.still,
			"%s: turning round doesn't yank the line in your hand" % where)
	# Let go and clear up for the next.
	blow(Vector2.ZERO)
	player.waist.let_go()
	if hands.held != null:
		hands.drop()
	await simulate(1.5)
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0
	for piece in [planter] + line.ends:
		if is_instance_valid(piece) and piece.is_inside_tree():
			piece.queue_free()
	await simulate(0.2)
