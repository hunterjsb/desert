extends ShieldProbe
## Radio probe 4: static follows the storm. A radio playing music hisses the
## louder the stronger the storm over it: not at all in clear skies, then
## more at each step up to the worst. A running bubble round it changes
## nothing: the static is the sand charging up, not the storm's sound.

const STEPS := [0.0, 0.25, 0.5, 0.75, 1.0]


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	while radio.channel != Radio.MUSIC:
		radio.interact(world.player)
	var heard := PackedFloat32Array()
	for storm: float in STEPS:
		weather_everywhere(storm)
		await physics_frames(3)
		heard.append(radio.hiss.volume_db)
	print("static at storms of %s: %s dB" % [STEPS, heard])
	check(radio.track() != null, "the radio plays music")
	check(heard[0] <= -60.0, "silent under clear skies (%.0f dB)" % heard[0])
	for i in range(1, heard.size()):
		check(heard[i] > heard[i - 1] + 1.0, "louder in a %d%% storm than a %d%% one" % [STEPS[i] * 100, STEPS[i - 1] * 100])

	var shield := shield_at(radio.global_position + Vector3(1.0, 0.0, 0.0))
	await physics_frames(3)
	check(shield.running() and world.weather.shelter_at(radio.global_position, &"storm") == 1.0, "a bubble stands round it")
	check(absf(radio.hiss.volume_db - heard[-1]) < 0.1,
		"inside it the static is as loud (%.1f dB, %.1f outside)" % [radio.hiss.volume_db, heard[-1]])
