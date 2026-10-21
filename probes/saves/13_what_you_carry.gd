extends LineProbe
## Profile & saves probe 13: what you carry. A radio tuned to the weather
## station, a compass and two more canisters go in with what you carry, and
## the run is saved. Resumed into a fresh world on the same seed, the radio is
## carried on the same channel with the same charge, playing from you, its
## line of words showing; the compass is carried, and the three canisters
## stack as one, each with its water. And a save from before, when what you
## carried was five slots and a radio a channel, resumes with their contents
## carried, the radio on the weather station's carrier.


func run() -> void:
	var saves := get_node(^"/root/Saves")
	await load_lines()
	var suit := world.player.suit
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = world.player.global_position + Vector3.UP
	(fit_part(radio, &"battery") as Battery).charge_wh = 61.5
	hands.hold(radio)
	await simulate(0.5)
	while radio.channel != Radio.WEATHER:
		radio.interact(world.player)
	check(suit.put_in(), "a radio on the weather goes in")
	for id: StringName in [&"compass", &"canister", &"canister"]:
		var thing := Catalog.part(id)
		world.content.add_child(thing)
		thing.global_position = world.player.global_position + Vector3.UP
		if thing is Supply:
			(thing as Supply).drain(0.5)
		hands.hold(thing)
		await simulate(0.5)
		check(suit.put_in(), "and a %s" % thing.label.to_lower())
	await simulate(0.5)
	var charge := radio.battery().charge_wh
	var water := _water(suit)
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	suit = world.player.suit
	var back: Array = suit.carried.filter(func(p: RigidBody3D) -> bool: return p is Radio)
	check(back.size() == 1 and back[0].channel == Radio.WEATHER and back[0].battery() != null
		and back[0].battery().charge_wh == charge, "the radio is carried, on the weather, %.4f Wh in it" % charge)
	if back.is_empty():
		return
	await simulate(1.0)
	var said := (world.player.get_node(^"Broadcast") as Broadcast).said
	print("resumed: the radio %s, the line says \"%s\"; water %s" % ["plays" if back[0].playing() else "is silent",
		said, _water(suit)])
	check(back[0].playing() and back[0].get_parent() == world.player and said.begins_with("%d kHz · " % roundi(back[0].frequency)),
		"playing from you, its words showing")
	var cans := suit.stacks().filter(func(s: Array) -> bool: return s[0] is Supply and s[0].kind == &"water")
	check(suit.carried.any(func(p: RigidBody3D) -> bool: return p is Compass) and cans.size() == 1
		and cans[0].size() == 3 and _water(suit) == water, "the compass is carried, and the canisters stack as one")

	# The same run as a save made when what you carried was five slots.
	var file: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	var old: Array = []
	for id: StringName in [&"canister", &"ration", &"bedroll", &"radio", &"compass"]:
		old.append(file.carried.filter(func(rec: Dictionary) -> bool: return rec.id == id)[0])
	for rec: Variant in old:
		if rec != null and rec.id == &"radio":
			for key: String in ["on", "frequency", "volume"]:
				rec.state.erase(key)
			rec.state["channel"] = Radio.WEATHER
	file.slots = old
	file.erase("carried")
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, file)
	check(await resume(), "a save with five slots resumes")
	suit = world.player.suit
	print("from five slots: %s" % ", ".join(suit.carried.map(func(p: RigidBody3D) -> String: return p.label)))
	var radios := suit.carried.filter(func(p: RigidBody3D) -> bool: return p is Radio)
	check(suit.carried.size() == 5 and radios.size() == 1, "their contents carried")
	await simulate(0.5)
	check(not radios.is_empty() and radios[0].channel == Radio.WEATHER, "the radio's channel on the dial, the weather station's carrier")


## Each canister's water, L, in the order you carry them.
func _water(suit: Suit) -> Array:
	return suit.carried.filter(func(p: RigidBody3D) -> bool: return p is Supply and p.kind == &"water") \
		.map(func(p: Supply) -> float: return p.amount)
