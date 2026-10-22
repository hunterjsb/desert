extends HandsProbe
## Radio probe 21: tuning brings the dial up close. Looking at a radio on the
## sand, a notch of reel in eases the view in to its face, near and through
## the close lens, its face square enough to read; the knob turns a notch's
## twentieth of a turn and the needle crosses its share of the band. A while
## after the last notch the view eases back out, and looking away it eases
## out at once. A radio in your hands turns its face to you as you tune it,
## and looking at a Console tunes, and closes in on, the radio on its top.
## Off (dial_close_up), a notch leaves the view your own, and only a fine
## step brings it in; on, any tuning does.


func run() -> void:
	await load_hands()
	var tuning := world.tuning
	var close := world.player.close_up
	var radio := device(&"radio", spot(0.0, -1.2), 0.0, true) as Radio
	await simulate(0.5)
	radio.freeze = true
	radio.on = true
	radio.frequency = 600.0
	look(eye(), radio.global_position)
	await simulate(1.0)
	check(close.close == 0.0 and world.player.camera.current and not close._controls.visible, "before tuning, the view is your own without tuning reminders")
	check(not tuning.dial_close_up, "the close-up is off")
	press(&"reel_in")
	await simulate(0.6)
	check(close.close == 0.0 and world.player.camera.current and is_equal_approx(radio.frequency,
		600.0 + tuning.dial_notch_khz), "off, a notch tunes it and leaves the view your own")
	press(&"tune_fine_up")
	await simulate(0.6)
	print("a fine step: closed in %.2f" % close.close)
	check(close.close == 1.0 and close.current and close._controls.visible, "a fine step brings the view and its controls in")
	var original := InputMap.action_get_events(&"mark_frequency")
	InputMap.action_erase_events(&"mark_frequency")
	var remapped := InputEventKey.new()
	remapped.physical_keycode = KEY_P
	InputMap.action_add_event(&"mark_frequency", remapped)
	await simulate(0.1)
	check(close._controls.text.contains(Controls.tint(Controls.key_for(&"mark_frequency"))),
		"the close-view reminder follows the live binding")
	InputMap.action_erase_events(&"mark_frequency")
	for binding in original:
		InputMap.action_add_event(&"mark_frequency", binding)
	await simulate(tuning.dial_close_hold + 0.5)
	check(close.close == 0.0 and world.player.camera.current and not close._controls.visible, "leaving tuning removes its controls")
	radio.frequency = 600.0
	tuning.dial_close_up = true
	await simulate(0.5)
	var turned := radio.knob.basis.get_euler().z
	var needle := radio.needle.position.x

	press(&"reel_in")
	await simulate(0.6)
	var face := radio.face()
	var off := close.global_position - face.origin
	var square := rad_to_deg(face.basis.z.angle_to(off))
	print("closed in: %.2f, %.2f m off its face, %.0f° off square, lens %.0f°" % [close.close, off.length(), square, close.fov])
	check(close.close == 1.0 and close.current, "a notch brings the view in")
	check(absf(off.length() - tuning.dial_close_m) < 0.02 and is_equal_approx(close.fov, tuning.dial_close_fov),
		"to dial_close_m off its face through the close lens")
	check(square <= rad_to_deg(CloseUp.SLANT) + 0.5 and (-close.global_basis.z).dot(-off.normalized()) > 0.999,
		"looking at its face, square enough to read")
	var knob := rad_to_deg(angle_difference(turned, radio.knob.basis.get_euler().z))
	var moved := radio.needle.position.x - needle
	print("the knob turned %.1f°, the needle %.2f mm" % [knob, moved * 1000.0])
	check(absf(knob + 360.0 * tuning.dial_notch_khz / Radio.KHZ_A_TURN) < 0.1, "the knob turns clockwise by the notch")
	check(absf(moved - (Radio.BAND.y - Radio.BAND.x) * tuning.dial_notch_khz / (Dial.HIGHEST - Dial.LOWEST)) < 1e-5,
		"the needle crosses the band by the notch")

	await simulate(tuning.dial_close_hold)
	check(close.close == 0.0 and world.player.camera.current, "a while after the last notch it eases back out")
	press(&"reel_in")
	await simulate(0.6)
	look(eye(), radio.global_position + Vector3(2.0, 0.0, 0.0))
	await simulate(0.5)
	check(close.close == 0.0 and world.player.camera.current, "looking away it eases out at once")

	radio.freeze = false
	hands.hold(radio)
	await simulate(0.5)
	press(&"reel_in")
	await simulate(1.0)
	var to_you := (eye() - radio.global_position).normalized()
	check(close.radio == radio and close.close == 1.0, "a radio in your hands closes in as you tune it")
	check(radio.global_basis.z.dot(to_you) > 0.9, "and turns its face to you (%.2f)" % radio.global_basis.z.dot(to_you))
	hands.drop()
	await simulate(tuning.dial_close_hold + 0.5)

	var dropped := Scenarios.console(world)
	var console: Console = dropped[1]
	await simulate(1.0)
	var screen := console.global_transform * Vector3(0.0, 0.01, -0.33)
	look(screen + console.global_basis * Vector3.FORWARD * 1.2 + Vector3.UP * 0.3, screen)
	await simulate(0.2)
	press(&"reel_in")
	await simulate(0.6)
	check(close.radio == dropped[2] and close.close == 1.0, "looking at a Console, tuning closes in on the radio on its top")
