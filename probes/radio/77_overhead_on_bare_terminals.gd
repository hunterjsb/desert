extends ShieldProbe
## Radio probe 77: overhead on bare terminals. On a shortwave converter alone,
## with no wire or kite, a satellite near straight overhead comes through
## decently, while one low in the sky stays faint (gonkhub, 2026-10-22).

## How long to look for each pass, s, and how often.
const SPAN := 3.0 * 86400.0
const STEP := 20.0


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.switch_band()
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var sky := Radio.constellation_of(world)
	var high := _pass(sky, p, 82.0, 90.0)
	var low := _pass(sky, p, 15.0, 40.0)
	check(not high.is_empty() and not low.is_empty(), "a satellite passes overhead and another low")
	if high.is_empty() or low.is_empty():
		return
	var heard := []
	for seen: Array in [high, low]:
		radio.frequency = sky.carrier(seen[0], seen[1])
		heard.append(radio.receive_from(sky.orbits[seen[0]], radio.frequency, seen[0], x, z, seen[1]))
	print("on bare terminals: the %s overhead %.2f, the %s low %.2f" % [high[0], heard[0].strength, low[0],
		heard[1].strength])
	check(heard[0].strength >= Radio.WHOLE, "a satellite overhead comes through decently")
	check(heard[1].strength < Radio.WHOLE, "a satellite low in the sky stays faint")


## The first voiced satellite on the air between these elevations, degrees, as [id, t].
func _pass(sky: Constellation, p: Vector3, from: float, to: float) -> Array:
	var t := world.time
	while t < world.time + SPAN:
		for id: StringName in sky.voiced():
			var up := rad_to_deg(sky.orbits[id].seen_from(p, t).elevation)
			if sky.on_air(id, t) and up >= from and up <= to:
				return [id, t]
		t += STEP
	return []
