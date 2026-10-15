extends ShieldProbe
## Bubble shield probe 5: power adds up. A running base shield drains its
## battery at shield_clear_w in the clear and shield_storm_w in the worst
## storm, between the two in a middling one, and nothing while it's off; a
## bubble half as wide again costs more by its shell's area. And when the
## battery runs flat the bubble collapses, and at a place inside every
## consumer, the game's and the senses', loses its shelter on the same frame.

## World seconds each rate is measured over.
const SPAN := 120.0
const WIND := 15.0


func run() -> void:
	await load_storm(1.0, WIND)
	var tuning := Tuning.current()
	var base := shield_at(ahead(-10.0))
	var big := shield_at(ahead(12.0))
	big.size = tuning.shield_radius * 1.5
	var idle := shield_at(ahead(34.0), false)
	await physics_frames(10)
	var rates := {}
	for intensity: float in [1.0, 0.5, 0.0]:
		weather_everywhere(intensity, WIND)
		var cells: Array = [base, big, idle].map(func(g: ShieldGenerator) -> Battery: return g.battery())
		var before: Array = cells.map(func(c: Battery) -> float: return c.charge_wh)
		var t0 := world.time
		await live(SPAN, 30.0)
		var hours := (world.time - t0) / 3600.0
		rates[intensity] = range(cells.size()).map(func(i: int) -> float:
			return (before[i] - cells[i].charge_wh) / hours)
		print("storm %.1f (%.3f at the shield): base %.2f W, big %.2f W, off %.2f W"
			% [intensity, world.weather.field_storm(base.global_position), rates[intensity][0],
				rates[intensity][1], rates[intensity][2]])
	check(absf(rates[0.0][0] / tuning.shield_clear_w - 1.0) < 0.01, "in the clear it sips shield_clear_w (%.2f W)" % rates[0.0][0])
	check(absf(rates[1.0][0] / tuning.shield_storm_w - 1.0) < 0.01, "in the worst storm it draws shield_storm_w (%.2f W)" % rates[1.0][0])
	check(rates[0.5][0] > rates[0.0][0] * 1.5 and rates[0.5][0] < rates[1.0][0] * 0.9,
		"a middling storm costs between the two (%.2f W)" % rates[0.5][0])
	for intensity: float in rates:
		check(absf(rates[intensity][1] / rates[intensity][0] - 2.25) < 0.02,
			"at %.1f a bubble 1.5 times as wide draws 2.25 times as much (%.3f)" % [intensity, rates[intensity][1] / rates[intensity][0]])
		check(rates[intensity][2] == 0.0, "at %.1f a shield switched off draws nothing" % intensity)
	check(base.running() and big.running(), "both stood throughout")

	# Flat: your eyes 3 m inside, and a battery that has a tick or two left.
	weather_everywhere(1.0, WIND)
	var eye := base.shelter.global_position + Vector3(0.0, 0.9, 3.0)
	world.player.global_position = eye - world.player.camera.position
	await physics_frames(5)
	base.battery().charge_wh = 0.02
	world.time_warp = 1.0
	var at := {"frame": 0}
	var flips := {}
	var disagree: Array[String] = []
	var watch := EndOfFrame.new()
	watch.each = func() -> void:
		at.frame += 1
		if not base.powered and not at.has("flat"):
			at["flat"] = at.frame
		var seen := _consumers(eye)
		for what: String in seen:
			if not seen[what] and not flips.has(what):
				flips[what] = at.frame
		if seen.values().any(func(v: bool) -> bool: return v) and not seen.values().all(func(v: bool) -> bool: return v):
			disagree.append("frame %d: %s" % [at.frame, seen])
	add_child(watch)
	await physics_frames(roundi(Engine.physics_ticks_per_second * (tuning.power_tick * 3.0 + tuning.shield_bloom_seconds + 0.5)))
	watch.queue_free()
	world.time_warp = 0.0
	print("ran flat at frame %d; consumers lost shelter at %s" % [at.get("flat", -1), flips])
	check(at.has("flat"), "the battery ran flat and the shield went dark")
	check(flips.size() == _consumers(eye).size(), "every consumer lost its shelter")
	check(disagree.is_empty(), "every consumer lost it on the same frame: %s" % "; ".join(disagree.slice(0, 3)))
	check(base.shelter.radius == 0.0 and not base.running(), "the bubble collapsed")


## Whether each consumer at p says it's sheltered. Your eyes are at p.
func _consumers(p: Vector3) -> Dictionary:
	var weather := world.weather
	var material := weather.face.material
	var told: PackedVector4Array = material.get_shader_parameter("shelters")
	var drawn := false
	for i: int in material.get_shader_parameter("shelter_count"):
		drawn = drawn or p.distance_to(Vector3(told[i].x, told[i].y, told[i].z)) < told[i].w
	return {
		"storm felt": weather.felt_storm(p) == 0.0,
		"wind felt": weather.felt_wind(p) == Vector3.ZERO,
		"wear": world.wear.rate_at(p) == 0.0,
		"dust seen": weather.seen_storm == 0.0,
		"roar muffled": weather.atmosphere.muffled() > 0.5,
		"storm pass": drawn,
	}
