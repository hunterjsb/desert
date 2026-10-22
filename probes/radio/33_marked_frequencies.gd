extends HandsProbe
## Radio probe 33: marked frequencies. Use on a radio in your hands switches
## it off and on, marks or none, its dial where it stood. With a radio in your hands,
## mark_frequency marks where its dial stands, in a bright colour picked at
## random, kept in the profile and shown as a tick on the band in that colour;
## pressed again there, it takes the mark off. No menu, nothing to type.


func run() -> void:
	await load_hands()
	var player := world.player
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = player.global_position + Vector3.UP
	fit_part(radio, &"battery")
	hands.hold(radio)
	await physics_frames(30)
	check(Profile.marks().is_empty(), "no marks to begin with")

	radio.on = true
	radio.frequency = 600.0
	hands.interact()
	print("no marks, use: %s at %d kHz" % ["on" if radio.on else "off", roundi(radio.frequency)])
	check(not radio.on and radio.frequency == 600.0, "use switches it off, its dial where it stood")
	hands.interact()
	check(radio.on and radio.frequency == 600.0, "and on again")

	radio.frequency = 650.0
	press(&"mark_frequency")
	await physics_frames(2)
	var marks := Profile.marks()
	check(marks.size() == 1 and marks[0].khz == 650.0 and Controls.playing(),
		"mark_frequency marks 650 kHz, with no menu")
	var first := Color.html(marks[0].color)
	check(first.s > 0.5 and first.v > 0.8, "in a bright colour")
	check(radio._ticks.size() == 1 and (radio._ticks[0].mesh.material as StandardMaterial3D).albedo_color.is_equal_approx(
		first), "a tick on the band in its colour")

	var colours := {first.to_html(): true}
	for khz: float in [1200.0, 1500.0, 1650.0]:
		radio.frequency = khz
		press(&"mark_frequency")
		await physics_frames(1)
		colours[Color.html(Profile.mark_at(khz, 1.0).color).to_html()] = true
	await physics_frames(2)
	print("marks: %s" % [Profile.marks()])
	check(Profile.marks().size() == 4 and radio._ticks.size() == 4, "four marks, four ticks")
	check(colours.size() == 4, "each its own colour, picked at random")

	radio.frequency = 700.0
	var states: Array[bool] = []
	for k in 2:
		hands.interact()
		states.append(radio.on)
	check(states == [false, true] and radio.frequency == 700.0, "with marks too, use only switches it off and on")

	radio.frequency = 1502.0
	press(&"mark_frequency")
	await physics_frames(2)
	check(Profile.marks().size() == 3 and Profile.mark_at(1500.0, 1.0).is_empty() and radio._ticks.size() == 3,
		"pressed again on a mark, within a carrier's width, it takes it off, and its tick")
	press(&"mark_frequency")
	await physics_frames(1)
	check(Profile.marks().size() == 4 and not Profile.mark_at(1502.0, 1.0).is_empty(), "and again marks it anew")
