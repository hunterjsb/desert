extends HandsProbe
## Radio probe 27: marked frequencies. With no marks, use on a radio in your
## hands sweeps to the next carrier as ever. With a radio in your hands,
## mark_frequency marks where its dial stands, in a bright colour picked at
## random, kept in the profile and shown as a tick on the band in that colour;
## pressed again there, it takes the mark off. No menu, nothing to type. With
## marks, use on a radio in your hands goes to the next mark above, and round
## to the lowest past the highest.


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
	radio.frequency = 300.0
	hands.interact()
	print("no marks, use: %d kHz" % roundi(radio.frequency))
	check(radio.frequency > 300.0, "with none, use sweeps to the next carrier")

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
	for khz: float in [1200.0, 1500.0, 1800.0]:
		radio.frequency = khz
		press(&"mark_frequency")
		await physics_frames(1)
		colours[Color.html(Profile.mark_at(khz, 1.0).color).to_html()] = true
	await physics_frames(2)
	print("marks: %s" % [Profile.marks()])
	check(Profile.marks().size() == 4 and radio._ticks.size() == 4, "four marks, four ticks")
	check(colours.size() == 4, "each its own colour, picked at random")

	radio.frequency = 700.0
	var went: Array[float] = []
	for k in 5:
		hands.interact()
		went.append(radio.frequency)
	print("use with marks, from 700 kHz: %s" % [went])
	var expected: Array[float] = [1200.0, 1500.0, 1800.0, 650.0, 1200.0]
	check(went == expected, "use goes to the next mark, round to the lowest")

	radio.frequency = 1502.0
	press(&"mark_frequency")
	await physics_frames(2)
	check(Profile.marks().size() == 3 and Profile.mark_at(1500.0, 1.0).is_empty() and radio._ticks.size() == 3,
		"pressed again on a mark, within a carrier's width, it takes it off, and its tick")
	press(&"mark_frequency")
	await physics_frames(1)
	check(Profile.marks().size() == 4 and not Profile.mark_at(1502.0, 1.0).is_empty(), "and again marks it anew")
