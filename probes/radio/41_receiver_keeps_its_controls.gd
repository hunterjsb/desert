extends HandsProbe
## Full-radio bookmarks must not change a receiver's Use action or narrow band.

func run() -> void:
	await load_hands()
	Profile.mark(1020.0, "music", Color.RED, 1.0)
	var receiver := Catalog.device(&"survey_receiver") as SurveyReceiver
	world.content.add_child(receiver)
	receiver.global_position = world.player.global_position + Vector3.UP
	fit_part(receiver, &"battery")
	hands.hold(receiver)
	await physics_frames(30)
	check(hands.interact() and receiver.on and receiver.frequency == Dial.BEACON_KHZ,
		"Use powers the receiver on without jumping to a full-radio bookmark")
	var before := Profile.marks()
	press(&"mark_frequency")
	await physics_frames(2)
	check(Profile.marks() == before, "the receiver does not add unsupported dial marks")
	check(hands.interact() and not receiver.on, "Use still switches the receiver off")
