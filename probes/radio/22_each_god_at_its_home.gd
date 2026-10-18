extends WeatherProbe
## Radio probe 22: each god broadcasts from its home. At the run's start,
## beside Port Morgan and beside Frontier Ag's farm domes nearest Halfrise,
## a radio reads every god's bearing and distance as those of the place
## history put it, where the world lays that place on the ground: its laid
## landmark where it's laid, else the sheet's own map of it. Five stand at
## their landmarks, the Almanac among those domes, and the Walker on the Rim
## where it has walked to. Its signal comes in from that same distance.
## Time limit: 600 s.

## The spots beside a home stand this far from its middle, m.
const BESIDE := 1200.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var history := world.shape.history
	var gods := Radio.gods_of(world)
	for id in Gods.ids():
		var mark: StringName = Gods.row(id)[3]
		if mark != &"":
			check(Sphere.angle(gods.home(id, 0.0), history.landmark(mark).p) * history.radius < 0.01,
				"%s stands at %s" % [Gods.title(id), history.landmark(mark).name])
	var ag := gods.home(&"almanac", 0.0)
	check(history.settlements.any(func(each: Dictionary) -> bool:
		return each.kind == &"farm_dome" and Sphere.angle(each.p, ag) < 1e-9), "the Almanac stands in Frontier Ag's farm domes")
	var rim := rad_to_deg(history.from_tu(gods.home(&"walker", 0.0)))
	check(absf(rim - 90.0) < 0.01, "the Walker walks the Rim (%.3f° from under Tu)" % rim)

	(await _spot("the start")).free()
	await _beside(history.landmark(&"port_morgan").p)
	(await _spot("beside Port Morgan")).free()
	await _beside(ag)
	var radio := await _spot("beside the Almanac's farm domes")
	var dome := world.shape.sites.nearest(world.player_world_x(), world.player_world_z(), BESIDE + 400.0,
		func(site: Site) -> bool: return site.kind == &"farm_dome", true)
	check(dome != null, "farm domes laid beside the Almanac's home")
	if dome != null:
		var off := Vector2(dome.x, dome.z).distance_to(radio.ground_of(ag))
		print("a farm dome laid %.0f m from where the Almanac speaks" % off)
		check(off < 300.0, "the Almanac speaks from among the farm domes laid there (%.0f m)" % off)
	radio.free()


## Stands you BESIDE m from a home, on its Tu-ward side.
func _beside(home: Vector3) -> void:
	var history := world.shape.history
	var at := Sphere.toward(home, Sphere.bearing(home, history.sub_tu), BESIDE / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
	await settle()


## A radio here, every god on it reading as its home lies on the ground from it.
func _spot(called: String) -> Radio:
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var sites := world.shape.sites
	var gods := Radio.gods_of(world)
	print("%s:" % called)
	for id in Gods.ids():
		var ground := sites.anchor().place(gods.home(id, world.time))
		var how := "mapped"
		for each in sites.landmarks_in(Rect2(Vector2(x, z), Vector2.ZERO).grow(BESIDE * 4.0)):
			if each.landmark.id == Gods.row(id)[3]:
				ground = Vector2(each.x, each.z)
				how = "laid"
		var want := Vector2(ground.x - x, ground.y - z)
		var way := radio.god_way(id)
		print("  %s: %.1f km, %03d°, \"%s\" (its home, %s: %.1f km, %03d°)" % [Gods.title(id), way.metres / 1000.0,
			roundi(way.bearing), way.way, how, want.length() / 1000.0, roundi(Radio.bearing(want))])
		check(absf(angle_difference(deg_to_rad(way.bearing), deg_to_rad(Radio.bearing(want)))) < deg_to_rad(0.5),
			"%s, %s, lies the way its home does" % [Gods.title(id), called])
		var heard: float = radio.receive(id, x, z, world.time).metres
		check(absf(heard - want.length()) < 5.0 + want.length() * 0.002,
			"%s, %s, comes in from as far as its home (%.0f m, %.0f)" % [Gods.title(id), called, heard, want.length()])
	return radio
