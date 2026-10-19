extends MovementProbe
## Movement probe 26: hard landings. Flat out over the flat, the board
## dropped from higher meets the sand harder: a small drop presses, a big one
## jars you, and landing crossed hits harder than straight. Crossed, a big
## landing's knocked-loose grip slides it out sideways for longer before it
## bites than the same crossing on the sand. Past the throw it throws you
## off, as a caught edge does, knocked and winded, and the board tumbles on.

## Dropped from this high over the ride, m: a press, and a jar.
const SMALL := 1.0
const BIG := 12.0
## Crossed this far just before it lands, radians.
const CROSSED := deg_to_rad(25.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var tuning := world.tuning
	var sand := await _drop(flat, 0.0, CROSSED)
	var small := await _drop(flat, SMALL, CROSSED)
	var straight := await _drop(flat, BIG, 0.0)
	var big := await _drop(flat, BIG, CROSSED)
	for each: Array in [["on the sand, crossed", sand, 0.0], ["a small drop, crossed", small, SMALL],
			["a big drop, straight", straight, BIG], ["a big drop, crossed", big, BIG]]:
		var seen: Dictionary = each[1]
		print("%s, %.0f m at %.1f m/s: met the sand at %.1f m/s (jars at %.1f), %d%% of its grip knocked loose; slid %.2f m across in %.2f s before it bit"
			% [each[0], each[2], seen.from, seen.hard, tuning.board_land_jar, roundi(seen.loose * 100.0 * Ride.LOOSE_GRIP),
			seen.across, seen.bit])
	check(small.hard < tuning.board_land_jar and big.hard > tuning.board_land_jar and not big.thrown,
		"a small drop presses and a big one jars, not throwing you (%.1f, %.1f m/s)" % [small.hard, big.hard])
	check(big.hard > straight.hard * 1.2, "crossed, it lands harder (%.1f against %.1f m/s)" % [big.hard, straight.hard])
	check(big.bit > sand.bit * 1.5 and big.across > sand.across * 1.3,
		"crossed, a big landing slides out before it bites (%.2f m in %.2f s, against %.2f m in %.2f s on the sand)"
		% [big.across, big.bit, sand.across, sand.bit])

	# The throw, as the edge's catch is tested: just past the landing it holds, just short it throws.
	var throw := tuning.board_land_throw
	tuning.board_land_throw = big.hard * 1.03
	var held := await _drop(flat, BIG, CROSSED)
	tuning.board_land_throw = big.hard * 0.97
	var thrown := await _drop(flat, BIG, CROSSED)
	tuning.board_land_throw = throw
	check(not held.thrown and thrown.thrown and thrown.how == &"landing",
		"it throws you past the threshold and not below it (%s, %s)" % [held.thrown, thrown.thrown])
	check(thrown.hurt > 0.0 and thrown.hurt < tuning.board_wipeout_hurt + 0.5 and thrown.winded > 0.0 and thrown.body,
		"thrown, you're knocked and winded (%.1f health, %.0f stamina) and the board tumbles on" % [thrown.hurt, thrown.winded])
	set_rate(60)


## Up to speed along +x, then the ride lifted `high` m over the sand and let
## fall, its nose turned `crossed` off its way just before it lands, nothing
## held: {from, hard, loose, across, bit, thrown, how}, and thrown, {hurt,
## winded, body}. `across` is how far it slid sideways to its nose before
## it bit, in `bit` s after it landed.
func _drop(flat: Dictionary, high: float, crossed: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	var board := await ride_here()
	hold(["move_forward"])
	await ride_for(4.0)
	hold([])
	var ride := player.ride
	var seen := {"from": flat_speed(), "hard": 0.0, "loose": 0.0, "across": 0.0, "bit": INF, "thrown": false,
		"how": &"", "turned": false, "landed": -1.0, "t": 0.0}
	ride.y += high
	ride.vy = 0.0
	var dt := 1.0 / ticks_per_second()
	await ride_for(3.0, func() -> void:
		seen.t += dt
		# Each tick you ride on, so what a thrown landing cost is only its own.
		if player.ride == ride:
			seen.health = player.vitals.health
			seen.stamina = player.stamina
		if not seen.turned and (high == 0.0 or ride.vy < 0.0 and ride.gap < 0.6):
			ride.ahead = ride.ahead.rotated(crossed)
			seen.turned = true
			if high == 0.0:
				seen.landed = seen.t
		seen.hard = maxf(seen.hard, ride.touched)
		if ride.touched > 0.0:
			seen.landed = seen.t
			seen.loose = ride.loose
		if seen.landed >= 0.0 and seen.bit == INF:
			var right := Vector2(-ride.ahead.y, ride.ahead.x)
			seen.across += absf(ride.velocity.dot(right)) * dt
			if absf(ride.velocity.angle_to(ride.ahead)) < Ride.SKID_TO:
				seen.bit = seen.t - seen.landed)
	seen.thrown = player.ride == null
	if seen.thrown:
		seen.how = ride.thrown
		seen.hurt = seen.health - player.vitals.health
		seen.winded = seen.stamina - player.stamina
		await simulate(0.3)
		seen.body = not board.freeze and board.rider == null
	return seen
