extends ShieldProbe
## Radio probe 47: the Surveyor's schedule. Tuned to Frontier Ag's crop
## survey while it's up, the radio reads out when it's next high enough over
## you to fire at a flare, where to look and how high; the time it gives is
## when it comes, and while it's up there it says to light one. Hearing it is
## Flight Plan. Under clear skies.


func run() -> void:
	await load_storm(0.0)
	world.counts_deeds = true
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var sky := Radio.constellation_of(world)
	var p := radio.point_at(world.world_x(radio.global_position.x), world.world_z(radio.global_position.z))
	var orbit: Satellite = sky.orbits[Airdrop.SURVEYOR]
	var high := world.tuning.airdrop_elevation_degrees
	var up := _first(world.time, func(u: float) -> bool:
		var e := rad_to_deg(orbit.seen_from(p, u).elevation)
		return sky.on_air(Airdrop.SURVEYOR, u) and e > 15.0 and e < high - 10.0)
	world.time = up
	radio.on = true
	radio.frequency = sky.carrier(Airdrop.SURVEYOR, up)
	await physics_frames(5)
	var plan := Airdrop.next_pass(world, radio.global_position, world.time)
	print("tuned to it %.0f° up: \"%s\"" % [rad_to_deg(orbit.seen_from(p, world.time).elevation), radio.said])
	check(radio.channel == Radio.SURVEY and radio.said.contains("Due in"), "on its carrier, it reads out when it's due")
	check(get_node(^"/root/Profile").did(&"flight_plan"), "hearing it is Flight Plan")

	# The time it gives is when it comes.
	check(not plan.is_empty(), "a pass due within %d hours" % roundi(Airdrop.LOOK_AHEAD / 3600.0))
	if plan.is_empty():
		return
	var due_at: float = world.time + plan.due
	var then: float = Airdrop.surveyor(world, radio.global_position, due_at).up
	var before: float = Airdrop.surveyor(world, radio.global_position, due_at - 2.0).up
	print("due in %.0f s, from %.0f° bearing, %.0f° at its highest" % [plan.due, plan.bearing, plan.peak])
	check(rad_to_deg(then) >= high and rad_to_deg(before) < high, "it gets high enough to fire just when it said")
	world.time = due_at + 1.0
	radio.frequency = sky.carrier(Airdrop.SURVEYOR, world.time)
	await physics_frames(5)
	print("overhead: \"%s\"" % radio.said)
	check(radio.said.contains("Light signal flare"), "while it's up there, it says to light one")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
