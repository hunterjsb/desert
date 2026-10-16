extends ShieldProbe
## Bubble shield probe 2: in the worst storm, with a gale behind it, a camp
## inside a running base shield takes no wear and no wind for ten minutes of
## world time. Nothing inside feels the wind, nothing drifts, the turbine
## inside makes nothing, and the shield holds the whole time.

const MINUTES := 10.0
const WIND := 35.0


func run() -> void:
	await load_storm(1.0, WIND)
	var middle := ahead(4.0)
	var generator := shield_at(middle)
	var camp := camp_at(middle)
	var turbine: Device = camp[3]
	await physics_frames(120)
	var start := {}
	for device in camp + [generator]:
		start[device] = device.global_position
	var felt := 0.0
	var made := 0.0
	var dropped := 0
	# The first moment anything felt the weather, to tell a flake's cause.
	var first := ""
	# Each second of physics is ten of world time: weather, wear and power.
	world.time_warp = 10.0
	for second in roundi(MINUTES * 60.0 / world.time_warp):
		await fast_forward(1.0)
		for device in camp + [generator]:
			var here := world.weather.felt_wind(device.global_position).length() \
				+ world.weather.felt_storm(device.global_position)
			if here > 0.0 and first.is_empty():
				first = "%s at %d s: %.2f m from the shield, moving %.2f m/s; shield %s, radius %.2f, moved %.2f m" % [
					device.label, second * roundi(world.time_warp), device.global_position.distance_to(generator.global_position),
					device.linear_velocity.length(), "up" if generator.running() else "down", generator.shelter.radius,
					generator.global_position.distance_to(start[generator])]
			felt = maxf(felt, here)
		made = maxf(made, turbine.production_w())
		dropped += int(not generator.running())
	world.time_warp = 0.0
	var worn := PackedStringArray()
	var drift := 0.0
	for device in camp + [generator]:
		if device.durability < 1.0:
			worn.append("%s %.4f" % [device.label, device.durability])
		var moved: Vector3 = device.global_position - start[device]
		drift = maxf(drift, Vector2(moved.x, moved.z).length())
	print("after %.0f min: felt %.3f, drift %.3f m, turbine %.2f W, shield %.1f Wh left"
		% [world.time / 60.0, felt, drift, made, generator.battery().charge_wh])
	if not first.is_empty():
		print("first felt: ", first)
	check(world.weather.field_storm(middle) == 1.0 and world.weather.field_wind(middle).length() >= WIND - 0.01,
		"outside is the worst storm, in a gale")
	check(dropped == 0, "the shield held the whole time")
	check(worn.is_empty(), "nothing inside wore (%s)" % ", ".join(worn))
	check(felt == 0.0, "nothing inside felt wind or storm (%.3f)" % felt)
	check(drift < 0.05, "nothing inside drifted (%.3f m)" % drift)
	check(made == 0.0, "the turbine inside made nothing (%.2f W)" % made)
