extends HandsProbe
## Full-radio bookmarks must not change a receiver's Use action or narrow band.

func run() -> void:
	await load_hands()
	DialMarks.add(world, 1020.0, "music", Color.RED, 1.0)
	var receiver := Catalog.device(&"survey_receiver") as SurveyReceiver
	world.content.add_child(receiver)
	receiver.global_position = world.player.global_position + Vector3.UP
	fit_part(receiver, &"battery")
	hands.hold(receiver)
	await physics_frames(30)
	check(hands.interact() and receiver.on and receiver.frequency == Dial.BEACON_KHZ,
		"Use powers the receiver on without jumping to a full-radio bookmark")
	var before := DialMarks.all(world)
	press(&"mark_frequency")
	await physics_frames(2)
	check(DialMarks.all(world) == before, "the receiver does not add unsupported dial marks")
	check(hands.interact() and not receiver.on, "Use still switches the receiver off")
	check(world.player.suit.put_in(), "the receiver goes into the suit")
	await physics_frames(3)
	world.player.camera.rotate_object_local(Vector3.UP, 1.2)
	await get_tree().process_frame
	var eyes := world.player.camera.global_transform
	var ahead := (receiver.hiss.global_position - eyes.origin).normalized().dot(-eyes.basis.z.normalized())
	check(receiver.hiss.panning_strength == 0.0 and receiver._signal.panning_strength == 0.0 and ahead > 0.999,
		"carried receiver sound stays ahead without panning when the camera turns")
	check(world.player.suit.take_out(stack_of(receiver)), "the receiver comes back out")
	await physics_frames(3)
	check(receiver.hiss.panning_strength == 1.0 and receiver.hiss.position == Hands.middle_of(receiver),
		"taken out, receiver sound returns to its physical speaker")
