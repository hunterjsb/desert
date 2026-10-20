extends WeatherProbe
## Radio probe 25: a contact's bearing points at the living city. Beside the
## Walker, a radio on its carrier reads its log a slot at a time: its survey,
## then each contact it keeps. Every contact as the line writes it, where the
## Walker stood and the bearing from there, lies on a line that passes the
## city where it was then, ahead along the bearing. Far off, the log
## comes through as noise.
## Time limit: 300 s.

## As written, a fix to a tenth of a degree and a bearing to a degree: this
## near the line, m.
const NEAR := 500.0
var _read := RegEx.create_from_string("from (\\d+\\.\\d)([ns]) (\\d+\\.\\d)([ew]) · brg (\\d+)")


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	world.time_warp = 0.0
	await settle(true)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	Scenarios._on_station(world, radio)
	var gods := Radio.gods_of(world)
	var city := gods.city
	var radius := world.shape.history.radius
	var every := world.tuning.walker_log_every
	var heard := {}
	var slot := ceilf(world.time / every) * every
	for k in 2 * (world.tuning.walker_contacts_kept + 1):
		world.time = slot + k * every + 1.0
		await physics_frames(2)
		var contact: Dictionary = radio.reception.get("contact", {})
		var found := _read.search(radio.logged)
		if contact.is_empty() or found == null:
			continue
		var from := Sphere.point(deg_to_rad(found.get_string(1).to_float() * (1.0 if found.get_string(2) == "n" else -1.0)),
			deg_to_rad(found.get_string(3).to_float() * (1.0 if found.get_string(4) == "e" else -1.0)))
		var bearing := deg_to_rad(found.get_string(5).to_float())
		var there := city.at(contact.t)
		var off := absf(Sphere.off_line(from, Sphere.toward(from, bearing, 0.01), there)) * radius
		var ahead := Sphere.toward(from, bearing, 0.01).dot(there) > from.dot(there)
		heard[contact.t] = true
		print("\"%s\": the city %.1f km off, %.0f m off the line" % [radio.logged, Sphere.angle(from, there) * radius / 1000.0, off])
		check(off < NEAR and ahead, "a contact's bearing passes the city, ahead (%.0f m off)" % off)
	check(heard.size() == world.tuning.walker_contacts_kept, "every contact it keeps read in turn (%d)" % heard.size())

	# Across the moon from it, past its log's reach, only noise of it.
	var away := -gods.home(&"walker", world.time)
	world.travel(rad_to_deg(Sphere.latitude(away)), rad_to_deg(Sphere.longitude(away)), 0.0)
	await settle(true)
	radio = Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	Scenarios._on_station(world, radio)
	await physics_frames(3)
	print("%.0f km from it: \"%s\"" % [radio.reception.metres / 1000.0, radio.logged])
	check(radio.reception.metres > world.tuning.walker_log_m.y and _read.search(radio.logged) == null,
		"far off, its log is noise")
