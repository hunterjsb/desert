extends HandsProbe
## Salvage probe 9: the deliveryship's care package. A signal flare lights with
## use and burns flare_burn_seconds, then it's spent and won't light again.
## Lit while the deliveryship is low over the horizon, nothing comes. Lit as it
## passes high over, its cannon fires once: its muzzle flashes in the sky, its
## boom comes no sooner than sound takes to come from it, and a cargo
## container leaves the muzzle where the craft is and comes down a smooth
## path, falling all the way, onto the sand near the flare, on the craft's
## side of it. It tumbles end over end in the plane it falls through and
## rolls on away from where the craft was. It hits in a cloud of sand and a
## ring of it, and stays in the world, a container.
## Time limit: 240 s


func run() -> void:
	await load_hands()
	var player := world.player
	var tuning := world.tuning
	tuning.flare_burn_seconds = 4.0
	speed_up(4)

	# A run begins with the deliveryship passing over: away from it first, the craft below the horizon.
	var start := player.global_position
	world.time = _first(func(u: float) -> bool: return _away(start, u))

	# A flare burns, then it's spent.
	var flare := Catalog.part(&"flare") as Flare
	world.content.add_child(flare)
	flare.global_position = player.global_position + Vector3.UP
	hands.hold(flare)
	await simulate(0.5)
	check(flare.use(player, Vector3.ZERO) and flare.lit, "use lights a flare")
	await simulate(tuning.flare_burn_seconds + 0.5)
	check(not flare.lit and flare.spent(), "it burns out")
	flare.use(player, Vector3.ZERO)
	check(not flare.lit, "and won't light again: use refuses")

	# Lit while the deliveryship is low: nothing comes.
	var at := player.global_position
	var high := deg_to_rad(tuning.airdrop_elevation_degrees)
	# After a pass, sinking: it won't rise past the cannon's height while we wait.
	var low_t := _first(func(u: float) -> bool:
		var e: float = Airdrop.deliveryship(world, at, u).up
		return e > 0.0 and e < high * 0.5 and Airdrop.deliveryship(world, at, u + 10.0).up < e)
	world.time = low_t
	var second := _new_flare(player)
	second.use(player, Vector3.ZERO)
	await simulate(2.0)
	check(_drops().is_empty() and not second.called, "lit with the deliveryship low, nothing comes")
	second.burnt = 9999.0
	await simulate(0.2)

	# Lit as it passes high over.
	tuning.flare_burn_seconds = 60.0
	var pass_t := _first(func(u: float) -> bool: return Airdrop.deliveryship(world, at, u).up > high)
	world.time = pass_t - 1.0
	var third := _new_flare(player)
	third.use(player, Vector3.ZERO)
	var drops: Array[Airdrop] = []
	for i in 300:
		await get_tree().physics_frame
		drops = _drops()
		if not drops.is_empty():
			break
	check(drops.size() == 1 and third.called, "lit as the deliveryship passes high over, its cannon fires")
	if drops.is_empty():
		return
	var drop := drops[0]
	var fired := drop.fired_at
	var craft := Airdrop.deliveryship(world, third.global_position, fired)
	var sky := Radio.constellation_of(world)
	print("fired from %.0f m, %.0f° up; down in %.1f s" % [craft.metres, rad_to_deg(craft.up), drop.lands_at - fired])
	check(sky.flash(&"deliveryship", fired + 0.1) > 2.0 and sky.flash(&"deliveryship", fired + 2.0) == 1.0,
		"its muzzle flashes in the sky, and fades")
	check(drop.to_global(drop.along(0.0)).distance_to(craft.at) < 1.0, "the container leaves the muzzle, where the craft is")

	# A smooth path down, falling all the way.
	var last := drop.to_global(drop.along(0.0))
	var rising := false
	var biggest := 0.0
	for k in range(1, 201):
		var now := drop.to_global(drop.along(drop.progress(fired + (drop.lands_at - fired) * k / 200.0)))
		biggest = maxf(biggest, now.distance_to(last))
		last = now
	var heights := []
	for k in 11:
		heights.append(drop.to_global(drop.along(drop.progress(fired + (drop.lands_at - fired) * k / 10.0))).y)
	for k in 10:
		rising = rising or heights[k + 1] > heights[k] + 0.01
	var span := drop.to_global(drop.along(0.0)).distance_to(drop.global_position)
	print("heights down its path: %s; its biggest step a 200th of the way, %.0f m of %.0f" % [heights.map(
		func(h: float) -> int: return roundi(h)), biggest, span])
	check(not rising, "it falls all the way")
	check(biggest < span * 0.03, "smoothly, no jump in its path")
	var landing := drop.global_position
	var off := Vector2(landing.x - third.global_position.x, landing.z - third.global_position.z)
	var side := Vector2(craft.at.x - third.global_position.x, craft.at.z - third.global_position.z)
	print("lands %.0f m off the flare, %.0f° off the craft's side" % [off.length(), rad_to_deg(absf(off.angle_to(side)))])
	check(off.length() >= tuning.airdrop_land_m.x - 0.5 and off.length() <= tuning.airdrop_land_m.y + 0.5,
		"it comes down near the flare")
	check(absf(off.angle_to(side)) < deg_to_rad(45.0), "on the craft's side of it")

	# The boom, no sooner than sound comes.
	var sound := world.weather.rumbles.speed()
	var heard_at := INF
	var spin_seen := Vector3.ZERO
	while is_instance_valid(drop) and not drop.landed:
		await get_tree().physics_frame
		if drop._boomed and heard_at == INF:
			heard_at = world.time
		if not drop.landed and spin_seen == Vector3.ZERO and world.time > fired + 2.0:
			spin_seen = drop.cargo.global_basis.z
	await simulate(0.2)
	if heard_at == INF and drop._boomed:
		heard_at = world.time
	print("the boom came %.1f s after the shot; sound takes %.1f s from %.0f m" % [heard_at - fired, craft.metres / sound,
		craft.metres])
	check(heard_at - fired >= craft.metres / sound - 0.1, "its boom comes no sooner than sound takes from the craft")

	# Down: the hit, the roll, the sand.
	var cargo := drop.cargo
	var roll := drop.hit_spin
	var coming := Vector3(drop.hit_velocity.x, 0.0, drop.hit_velocity.z)
	var from_craft: Vector3 = drop.global_position - craft.at
	from_craft.y = 0.0
	check(coming.normalized().dot(from_craft.normalized()) > 0.9, "it comes in from the craft's side")
	var away := coming
	print("on the ground: rolling %.2f rad/s about %s, moving %.1f m/s away; the craft's way %s" % [roll.length(), roll.normalized(),
		away.length(), coming.normalized()])
	check(drop.landed and roll.length() > 0.5 and absf(roll.normalized().y) < 0.05
		and absf(roll.normalized().dot(coming.normalized())) < 0.1, "it tumbles end over end, about an axis across its way")
	check(away.dot(from_craft) > 0.0, "rolling on away from where the craft was")
	check(roll.dot(Vector3.UP.cross(coming.normalized())) > 0.0, "turning the way it rolls")
	var bursts := drop.find_children("*", "CPUParticles3D", false, false).filter(func(p: CPUParticles3D) -> bool:
		return p.one_shot and p.emitting)
	check(bursts.size() == 2, "it hits in a cloud of sand and a ring of it")
	await simulate(tuning.airdrop_settle_seconds + 1.0)
	check(is_instance_valid(cargo) and cargo.get_parent() == world.content and cargo.get_meta(&"catalog") == &"cargo"
		and not is_instance_valid(drop), "it stays in the world, a container, settled on the sand")
	check(is_instance_valid(cargo) and cargo.global_position.y < world.height_under(cargo.global_position) + 1.5,
		"on the sand")
	await simulate(3.0)
	check(_drops().is_empty(), "the cannon fired once")
	speed_up(1)


## Whether the deliveryship is well below the horizon from a place at world time t, and stays so a while.
func _away(at: Vector3, t: float) -> bool:
	return Airdrop.deliveryship(world, at, t).up < -0.2 and Airdrop.deliveryship(world, at, t + 30.0).up < -0.1


func _new_flare(player: Player) -> Flare:
	var old := player.hands.held
	if old != null:
		player.hands.stow()
	var flare := Catalog.part(&"flare") as Flare
	world.content.add_child(flare)
	flare.global_position = player.global_position + Vector3.UP
	player.hands.hold(flare)
	return flare


func _drops() -> Array[Airdrop]:
	var out: Array[Airdrop] = []
	for each in world.content.get_children():
		if each is Airdrop:
			out.append(each)
	return out


func _first(wanted: Callable) -> float:
	var t := world.time
	while t < world.time + 400.0 * world.tuning.day_minutes * 60.0:
		if wanted.call(t):
			return t
		t += 1.0
	check(false, "found a moment")
	return world.time
