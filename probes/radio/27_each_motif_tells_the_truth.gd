extends WeatherProbe
## Radio probe 27: each of the living city's motifs tells the truth. Over a
## day and a half round one of its legs, every slot's motif is so at the
## city as the world lays it: storm coming, a storm reaching it within
## city_warn_s out of clear air; city moving, under way; tether in, a storm
## on it moored; all clear, clear air and none due, moored; its position,
## the pole star's height its latitude and the stars' turn, against yours,
## its longitude. Each plays. In clear air a radio near it on its carrier
## plays each motif and its line shows it.
## Time limit: 300 s.

## Slots the radio listens through: one whole round of them.
const POSITION_SLOTS := LivingCity.POSITION_EVERY


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var city := Radio.gods_of(world).city
	var day := world.tuning.day_minutes * 60.0
	var leg := city.leg(world.time + day)
	var from: float = leg[1] - 0.5 * day
	# Off the middle of its leg, in range of it at either end.
	var middle := (leg[0] as Vector3).slerp(leg[3], 0.5)
	var near := Sphere.toward(middle, Sphere.bearing(middle, leg[3]) + PI * 0.5, 1000.0 / world.shape.history.radius)
	world.travel(rad_to_deg(Sphere.latitude(near)), rad_to_deg(Sphere.longitude(near)), 0.0)
	world.time = from
	world.time_warp = 0.0
	await settle(true)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	# A day and a half of storms would wear it out.
	world.wear.set_physics_process(false)
	radio.on = true
	radio.frequency = city.carrier()
	var counts := {}
	var heard := {}
	var every := world.tuning.city_chatter_every
	var t: float = city.slot_start(from) + every
	var warn := world.tuning.city_warn_s
	while t < leg[2] + 0.5 * day:
		var at := Walker.ground(world, city.at(t))
		var motif := city.motif(field, at, t)
		var stormy := field.raw_storm_at(at.x, at.y, t) > 0.0
		var comes := false
		for s in range(5, roundi(warn) + 1, 5):
			comes = comes or field.raw_storm_at(at.x, at.y, t + s) > 0.0
		var truth := false
		match motif:
			LivingCity.STORM: truth = not stormy and comes
			LivingCity.MOVING: truth = city.moving(t)
			LivingCity.TETHER: truth = stormy and not city.moving(t)
			LivingCity.CLEAR: truth = not stormy and not comes and not city.moving(t)
			LivingCity.POSITION: truth = _decodes(city, t)
		check(truth, "day %.2f: %s is so at the city" % [t / day, motif])
		counts[motif] = counts.get(motif, 0) + 1
		t += every
	print("round a leg of %.1f km: %s" % [Sphere.angle(leg[0], leg[3]) * world.shape.history.radius / 1000.0, counts])
	for motif in LivingCity.MOTIFS:
		check(counts.has(motif), "%s plays" % motif)

	# In clear air, a radio near it on its carrier plays each motif it hears and shows it.
	var tuning := Tuning.current()
	tuning.storm_threshold = 2.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	t = city.slot_start(from) + every
	for k in POSITION_SLOTS:
		world.time = t + 1.0
		await physics_frames(3)
		var motif := city.motif(world.weather.field, Walker.ground(world, city.at(t)), t)
		heard[motif] = true
		check(radio.reception.motif == motif and radio.said.contains(LivingCity.SHAPES[motif])
			and radio._signal.stream == Sounds.CITY_MOTIFS[motif], "the radio plays %s: \"%s\"" % [motif, radio.said])
		t += every
	check(heard.has(LivingCity.CLEAR) and heard.has(LivingCity.POSITION), "all clear and its position heard")


## Its position as written, read back: the star's height its latitude, and
## the stars' turn over it against yours where you stand, its longitude.
func _decodes(city: LivingCity, t: float) -> bool:
	var written := city.stars(t, world.weather.day).split(" ")
	var p := city.at(t)
	var lat := float(written[1].trim_suffix("°")) * (1.0 if written[0] == "pole" else -1.0)
	var mine := world.weather.day.time_of_day(t, world.moon.longitude) * 360.0
	var lon := world.moon.longitude + deg_to_rad(float(written[4].trim_suffix("°")) - mine)
	return absf(lat - rad_to_deg(Sphere.latitude(p))) <= 0.51 \
		and absf(angle_difference(lon, Sphere.longitude(p))) <= deg_to_rad(1.01)
