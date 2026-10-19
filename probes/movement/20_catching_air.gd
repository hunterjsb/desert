extends MovementProbe
## Movement probe 20: catching air. On the flat a hop flies over a metre for
## more than a second, and from a crouch it pops higher. Flat out with the
## wind over the biggest ridge for 12 km, the board leaves its crest and flies,
## and getting low into each crest and popping off its top flies further.
## Every landing is a firm press, never a slam, and never bounces you back up.

## Over its ride height by more than this, m, it's flying.
const FLYING := 0.25
const HOP_HIGH := 1.0
const HOP_AIR := 1.2
## A pop from a full crouch goes this much higher than a hop.
const POP := 1.5
const CREST_HIGH := 3.0
const CREST_AIR := 1.5
## The hardest flying or landing may move you, m/s²: a slam is several times it.
const LANDING := 40.0
## Pressed or unloaded by this much beyond your weight, m/s², the rider pumps.
const FELT := 1.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.view_radius = tuning.near_radius
	tuning.far_radius = (tuning.view_radius + 1) * tuning.chunk_size
	await load_moving()
	set_rate(60, 8)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var flat := flat_place(x, z, 150.0, 30.0)
	var hop := await _hop(flat, down, false)
	var pop := await _hop(flat, down, true)
	print("on the flat: a hop %.2f m over its ride height for %.2f s; from a crouch %.2f m for %.2f s"
		% [hop.high, hop.air, pop.high, pop.air])
	check(hop.high >= HOP_HIGH and hop.air >= HOP_AIR, "a hop flies %.1f m or more for %.1f s (%.2f m, %.2f s)"
		% [HOP_HIGH, HOP_AIR, hop.high, hop.air])
	check(pop.high >= hop.high * POP, "from a crouch it pops higher (%.2f m)" % pop.high)

	var big := _biggest_crest(x, z, down)
	var start := Vector2(big.x, big.y) - down * 300.0
	for popping: bool in [false, true]:
		var seen := await _crests(start, down, popping)
		print("%s flat out over the biggest crest, %.1f m over the trough: the longest flight %.2f s, %.2f m over its ride height, %.0f m long, from %.1f m/s; the hardest %.1f m/s², %d bounces, bottomed %d, landing at %.1f m/s at most"
			% ["popping" if popping else "pushing", big.z, seen.air, seen.high, seen.long, seen.speed, seen.hardest,
			seen.bounces, seen.bottomed, seen.landing])
		if not popping:
			check(seen.air >= CREST_AIR and seen.high >= CREST_HIGH, "off a big crest it flies %.1f s or more, %.0f m or more up (%.2f s, %.2f m)"
				% [CREST_AIR, CREST_HIGH, seen.air, seen.high])
		check(seen.hardest < LANDING and seen.bottomed == 0 and seen.bounces == 0,
			"%s, it never slams, bottoms out or bounces landing (%.1f m/s²)" % ["popping" if popping else "pushing", seen.hardest])
	set_rate(60)


## A hop from rest on the flat, standing or from a crouch: how high over its
## ride height and how long it flies.
func _hop(flat: Dictionary, along: Vector2, low: bool) -> Dictionary:
	await _board_at(Vector2(flat.x, flat.z), along)
	hold(["crouch"] if low else [])
	await ride_for(0.6)
	hold(["jump", "crouch"] if low else ["jump"])
	await ride_for(1.0 / 60.0)
	hold([])
	var seen := {"high": 0.0, "ticks": 0, "up": true}
	await ride_for(5.0, func() -> void:
		seen.high = maxf(seen.high, player.ride.gap)
		if seen.up and player.ride.gap > 0.05:
			seen.ticks += 1
		elif seen.ticks > 0:
			seen.up = false)
	return {"high": seen.high, "air": seen.ticks / 60.0}


## Flat out with the wind for 25 s, popping off each crest or not: the
## longest flight, and the hardest you were moved flying or landing.
func _crests(from: Vector2, down: Vector2, popping: bool) -> Dictionary:
	await _board_at(from, down)
	hold(["move_forward"])
	var seen := {"air": 0.0, "high": 0.0, "long": 0.0, "speed": 0.0, "hardest": 0.0, "bounces": 0, "ys": [],
		"tick": 0, "landed": -1000, "flight": {}, "low": false}
	await ride_for(25.0, func() -> void:
		var ride := player.ride
		var at := where()
		seen.tick += 1
		seen.ys.append(at.y)
		if seen.ys.size() > 3:
			seen.ys.pop_front()
		var flight: Dictionary = seen.flight
		if seen.ys.size() == 3 and (not flight.is_empty() or seen.tick - seen.landed < 60):
			seen.hardest = maxf(seen.hardest, absf((seen.ys[2] - 2.0 * seen.ys[1] + seen.ys[0]) * 3600.0))
		if ride.gap > FLYING:
			if flight.is_empty():
				seen.bounces += 1 if seen.tick - seen.landed < 30 else 0
				seen.flight = {"from": at, "ticks": 0, "high": 0.0, "speed": flat_speed()}
				flight = seen.flight
			flight.ticks += 1
			flight.high = maxf(flight.high, ride.gap)
		elif not flight.is_empty():
			seen.landed = seen.tick
			if flight.ticks / 60.0 > seen.air:
				seen.air = flight.ticks / 60.0
				seen.high = flight.high
				seen.long = Vector2(at.x - flight.from.x, at.z - flight.from.z).length()
				seen.speed = flight.speed
			seen.flight = {}
		if not popping:
			return
		# Low as it unloads over the crest, and up off its top as it leaves the sand.
		var keys := ["move_forward"]
		if seen.low and ride.gap > 0.1:
			keys.append("jump")
			seen.low = false
		elif ride.pressing < -FELT and ride.gap < 0.1:
			seen.low = true
		elif ride.pressing > FELT:
			seen.low = false
		if seen.low:
			keys.append("crouch")
		hold(keys))
	hold([])
	seen.bottomed = player.ride.bottomed if player.ride != null else -1
	seen.landing = player.ride.landed_hardest if player.ride != null else INF
	return seen


## On a fresh board at a world place, nose along `along`.
func _board_at(at: Vector2, along: Vector2) -> void:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(at.x, at.y, along)
	await ride_here(&"big_battery")


## Along `down` from a place, within 12 km, the crest with the biggest drop
## after it: x, y the place and z the drop, m.
func _biggest_crest(x: float, z: float, down: Vector2) -> Vector3:
	var best := Vector3(x, z, 0.0)
	var s := 0.0
	while s < 12000.0:
		var at := Vector2(x, z) + down * s
		var top := world.height_at(at.x, at.y)
		var low := top
		for k in 60:
			var on := at + down * k * 2.0
			low = minf(low, world.height_at(on.x, on.y))
		if top - low > best.z and top >= world.height_at(at.x - down.x * 2.0, at.y - down.y * 2.0):
			best = Vector3(at.x, at.y, top - low)
		s += 4.0
	return best
