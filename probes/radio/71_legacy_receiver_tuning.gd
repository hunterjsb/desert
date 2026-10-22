extends LineProbe
## Legacy receiver saves keep their offset when the beacon carrier moves.


func run() -> void:
	await load_lines()
	var saves := get_node(^"/root/Saves")
	# The last current save deliberately holds an unusual frequency: its tag wins.
	var offsets := [-3.0, 0.0, 4.0, 7.0, 1400.0]
	for offset: float in offsets:
		var receiver := Catalog.device(&"survey_receiver") as SurveyReceiver
		world.content.add_child(receiver)
		receiver.global_position = world.player.global_position + Vector3.UP
		(fit_part(receiver, &"battery") as Battery).charge_wh = 61.5
		receiver.frequency = Dial.BEACON_KHZ + offset
		hands.hold(receiver)
		await simulate(0.5)
		check(world.player.suit.put_in(), "receiver stows")
	check(saves.save(world), "receiver run saves")
	var file: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	var receivers: Array = file.carried.filter(func(rec: Dictionary) -> bool: return rec.id == &"survey_receiver")
	for i in 3:
		receivers[i].state.erase("beacon_khz")
		receivers[i].state.frequency = 1930.0 + offsets[i]
	receivers[3].state.erase("beacon_khz")
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, file)
	check(await resume(), "legacy receiver run resumes from disk")
	_check_receivers(offsets)
	check(saves.save(world) and await resume(), "migrated receiver run saves and resumes again")
	_check_receivers(offsets)


func _check_receivers(offsets: Array) -> void:
	var receivers: Array = world.player.suit.carried.filter(func(body: RigidBody3D) -> bool: return body is SurveyReceiver)
	check(receivers.size() == offsets.size(), "every receiver survives")
	for i in mini(receivers.size(), offsets.size()):
		var receiver := receivers[i] as SurveyReceiver
		check(receiver.frequency == Dial.BEACON_KHZ + offsets[i], "receiver keeps its beacon offset")
		check(not receiver.on and receiver.target.is_empty() and is_equal_approx(receiver.battery().charge_wh, 61.5),
			"migration does not switch on, acquire a target or refill the battery")
