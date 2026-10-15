extends ShieldProbe
## Bubble shield probe 8: nesting takes the best of each. A base wind shield,
## and a test-only temperature shield (strong against temperature, weak to
## wind, no help against dust) standing half out of it. Inside both, each harm
## gets the stronger protection. Inside only the outer one, temperature
## reaches you. Inside only the inner one the wind is weakened, not stopped,
## and the dust comes in: the storm pass only carves bubbles that stop it.

const THERMAL := {&"wind": 0.4, &"storm": 0.0, &"temperature": 0.8}
const WIND := 15.0


func run() -> void:
	await load_storm(1.0, WIND)
	var outer := shield_at(ahead(-4.0))
	var inner := shield_at(ahead(2.0))
	inner.shelter.blocks = THERMAL.duplicate()
	inner.size = 3.0
	await physics_frames(5)
	var c := outer.shelter.global_position
	var places := {"both": c + Vector3(4.5, 0.0, 0.0), "outer only": c + Vector3(-2.0, 0.0, 0.0),
		"inner only": c + Vector3(8.0, 0.0, 0.0)}
	var expect := {
		"both": {&"wind": 1.0, &"storm": 1.0, &"temperature": 0.8},
		"outer only": {&"wind": 1.0, &"storm": 1.0, &"temperature": 0.0},
		"inner only": THERMAL,
	}
	var weather := world.weather
	for where: String in places:
		var got := {}
		for harm: StringName in expect[where]:
			got[harm] = weather.shelter_at(places[where], harm)
		check(got == expect[where], "%s: %s, expected %s" % [where, got, expect[where]])
	var p: Vector3 = places["inner only"]
	check(weather.felt_wind(p).is_equal_approx(weather.field_wind(p) * 0.6) and weather.felt_storm(p) == weather.field_storm(p),
		"inside only the inner one, 60% of the wind and all the storm are felt")

	for where: String in ["both", "inner only"]:
		world.player.global_position = places[where] - world.player.camera.position
		await physics_frames(2)
		check((weather.seen_storm == 0.0) == (where == "both"), "%s: the dust is %s (seen %.2f)"
			% [where, "kept out" if where == "both" else "seen", weather.seen_storm])
	var material := weather.face.material
	check(material.get_shader_parameter("shelter_count") == 1, "the storm pass carves only the bubble that stops the dust")
