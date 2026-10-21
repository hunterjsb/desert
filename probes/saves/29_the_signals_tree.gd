extends HandsProbe
## Profile & saves probe 29: the gods heard. A radio on beside you, tuned to
## each god's carrier inside its window in turn, the air clear and carrying
## every god's ground wave this far: the first heard is First Light, and
## Pantheon waits for the seventh. Off its window, a god's idle talk counts
## for nothing.


func run() -> void:
	var tuning := Tuning.current()
	tuning.storm_threshold = 2.0
	tuning.ground_wave_m = 1e9
	await load_hands(1234)
	world.counts_deeds = true
	world.time_warp = 0.0
	var profile := get_node(^"/root/Profile")
	var radio := spawn_device(&"radio", 2.0) as Radio
	radio.on = true
	var gods := Radio.gods_of(world)
	await physics_frames(5)
	# Off its window at midnight, the Ledger talks only noise.
	world.time = _when(radio, &"ledger", false)
	broadside(radio, &"ledger")
	radio.frequency = gods.carrier(&"ledger", world.time)
	await physics_frames(3)
	check(radio.reception.get("id") == &"ledger" and radio.reception.clean > 0.0 and not profile.did("god_heard"),
		"the Ledger off its window, heard: no First Light")
	var heard := 0
	for id in Gods.ids():
		world.time = _when(radio, id, true)
		broadside(radio, id)
		radio.frequency = gods.carrier(id, world.time)
		await physics_frames(3)
		heard += 1
		check(profile.did("god_heard"), "%s heard in its window: First Light" % Gods.title(id))
		check(profile.did("gods") == (heard == Gods.ROSTER.size()), "%d of seven gods heard" % heard)


## The first moment from now that a god's useful, or not, where the radio is.
func _when(radio: Radio, id: StringName, useful: bool) -> float:
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var gods := Radio.gods_of(world)
	var t := world.time + 1.0
	while t < world.time + 2.0 * world.tuning.day_minutes * 60.0:
		if Transmissions.say(id, radio, gods, p, x, z, t).useful == useful:
			return t
		t += 2.0
	check(false, "a moment %s is %s" % [Gods.title(id), "useful" if useful else "idle"])
	return t
