extends ShieldProbe
## Radio probe 61: the direction loop. In the radio's misc bay it takes the
## ferrite rod's place: its null deep and narrower, so a bearing comes sharper,
## and as deep by night's sky wave, where the rod's goes shallow.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.global_basis = Basis.IDENTITY
	await physics_frames(2)
	# The rod lies along the set's width, x: a station due east is end-on.
	var end_on := 90.0
	var near := 90.0 - rad_to_deg(asin(tuning.loop_width * 1.5))
	var rod := [radio.rod(end_on, false), radio.rod(end_on, true), radio.rod(near, false)]
	radio.fit(Catalog.part(&"direction_loop"), Scenarios._free(radio, &"radio_bay"))
	var loop := [radio.rod(end_on, false), radio.rod(end_on, true), radio.rod(near, false)]
	print("end-on by day, by night, a little off: rod %.2f %.2f %.2f, loop %.2f %.2f %.2f" % (rod + loop))
	check(loop[0] <= rod[0] and loop[0] <= tuning.loop_null + 0.01, "its null is deep")
	check(loop[1] < rod[1] * 0.5, "as deep by night, where the rod's goes shallow")
	check(loop[2] > rod[2], "and narrower: a little off end-on it's heard again")
