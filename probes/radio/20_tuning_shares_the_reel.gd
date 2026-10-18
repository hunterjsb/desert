extends LineProbe
## Radio probe 20: tuning shares reel in with the reel, by one rule. A line to
## a stake at your waist and a radio on the sand: looking at the radio, reel
## in tunes it a notch and leaves the line be; looking away, it reels the line
## and leaves the dial. A line's end in your hand reels even as you look at
## the radio. Holding the radio, reel in reels the line at your waist while
## there is one, then tunes the radio; bring near never turns its dial.


func run() -> void:
	await load_lines()
	var player := world.player
	var radio := device(&"radio", spot(0.0, -1.2), 0.0, true) as Radio
	var stake := driven_stake(spot(3.0, 0.0))
	await simulate(0.5)
	radio.freeze = true
	radio.on = true
	radio.frequency = Dial.MUSIC_KHZ
	var moored := Scenarios.to_waist(world, stake.free_tie(player.global_position))
	await simulate(0.5)

	look(eye(), radio.global_position)
	var got := await _reel_in(moored.rope, radio)
	check(absf(got.khz - world.tuning.dial_notch_khz) < 0.01 and absf(got.line) < 0.01,
		"looking at the radio, reel in tunes it a notch and leaves the line at your waist (%.0f kHz, %.2f m)" % [got.khz, got.line])
	look(eye(), stake.global_position + Vector3.UP * 0.3)
	got = await _reel_in(moored.rope, radio)
	check(got.khz == 0.0 and absf(got.line - Reel.NOTCH) < 0.01,
		"looking away, it reels the line and leaves the dial (%.0f kHz, %.2f m)" % [got.khz, got.line])

	var led := await lead(floating(&"crate_frame", spot(-3.0, 0.0)))
	look(eye(), radio.global_position)
	got = await _reel_in(led.rope, radio)
	check(got.khz == 0.0 and got.line > 0.1, "a line's end in your hand reels, even looking at the radio (%.0f kHz, %.2f m)"
		% [got.khz, got.line])
	hands.drop()
	await simulate(0.5)

	radio.freeze = false
	hands.hold(radio)
	await simulate(0.5)
	look(eye(), stake.global_position + Vector3.UP * 0.3)
	got = await _reel_in(moored.rope, radio)
	check(got.khz == 0.0 and absf(got.line - Reel.NOTCH) < 0.01, "holding it, the line at your waist reels first")
	player.waist.untie(player.waist.tied.back())
	got = await _reel_in(moored.rope, radio)
	check(absf(got.khz - world.tuning.dial_notch_khz) < 0.01, "with no line there, it tunes the radio you hold")
	var khz := radio.frequency
	press(&"bring_near")
	await simulate(0.5)
	check(radio.frequency == khz and hands.held == radio, "bring near never turns its dial")


## A notch of reel in where you look: how far the dial moved, kHz, and the line came in, m.
func _reel_in(rope: Rope, radio: Radio) -> Dictionary:
	await physics_frames(2)
	var khz := radio.frequency
	var length := rope.length
	press(&"reel_in")
	await simulate(1.0)
	return {"khz": radio.frequency - khz, "line": length - rope.length}
