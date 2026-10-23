extends ShieldProbe
## Radio probe 63: the wire logger. In the radio's misc bay it writes out what
## comes in over the air (gonkhub, 2026-10-22): each phrase of a god's words,
## as it's read, floats over the set as a subtitle, and stays a moment after
## the last; a set without one shows nothing.


func run() -> void:
	await load_storm(0.0)
	await beside_god(&"quartermaster")
	var carrier := Radio.gods_of(world).carrier(&"quartermaster", world.time)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"wire_logger"], [0.0, 2.0]) as Radio
	var plain := Scenarios.standing(world, &"radio", [&"battery"], [0.6, 2.0]) as Radio
	for each: Radio in [radio, plain]:
		each.freeze = true
		each.on = true
		each.frequency = carrier
	var shown := ""
	for i in 60 * 60:
		await get_tree().physics_frame
		if radio.transcript != "":
			shown = radio.transcript
			break
	print("over the set: \"%s\"; it said %s" % [shown, radio.spoken])
	check(shown != "" and radio.spoken.has(shown), "a phrase of the god's words is written out as it's read")
	var label := radio._subtitle
	check(label != null and label.visible and label.text == shown and label.global_position.y > radio.global_position.y,
		"floating over the set")
	check(plain.transcript == "" and plain._subtitle == null, "a set without a logger shows nothing")
	for i in 60 * 60:
		await get_tree().physics_frame
		if radio._lines.is_empty():
			break
	check(radio.transcript != "", "its last phrase stays once the words are done")
	for i in int((Tuning.current().logger_hold_s + 1.0) * 60.0):
		await get_tree().physics_frame
	check(radio.transcript == "" and not label.visible, "and goes a moment after")
