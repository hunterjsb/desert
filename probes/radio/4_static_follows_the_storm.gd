extends ShieldProbe
## Radio probe 4: the storm gets into the music. A radio playing music under
## a storm over it, at night when the port's comes in clean from afar: in
## clear skies it plays clean, with no static; as the
## storm thickens the music comes through dirtier and dirtier, chewed up by
## its interference chain, still with no static under it while it plays;
## once the storm takes it altogether, static is all there is, louder the
## stronger the storm. A running bubble round it changes nothing: the static
## and the interference are the sand charging up, not the storm's sound.

const STEPS := [0.0, 0.1, 0.2, 0.3, 0.6, 0.8, 1.0]


func run() -> void:
	await load_storm(0.0)
	while world.weather.day.is_day(world.time, world.moon.longitude):
		world.time += 30.0
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	while radio.channel != Radio.MUSIC:
		radio.interact(world.player)
	var hiss := PackedFloat32Array()
	var dirt := PackedFloat32Array()
	var playing := []
	for storm: float in STEPS:
		weather_everywhere(storm)
		await physics_frames(3)
		hiss.append(radio.hiss.volume_db)
		dirt.append(radio.dirt)
		playing.append(Radio.audible(radio.reception) > 0.05)
	print("storms of %s: dirt %s; playing %s; static %s dB" % [STEPS, dirt, playing, hiss])
	check(radio.track() != null, "the radio plays music")
	check(dirt[0] < 0.1 and hiss[0] <= -60.0, "clean under clear skies, with no static (%.0f dB)" % hiss[0])
	var lost := playing.find(false)
	check(lost > 2, "it still plays through a thin storm")
	for i in range(1, lost):
		check(dirt[i] > dirt[i - 1] + 0.05, "dirtier in a %d%% storm than a %d%% one" % [STEPS[i] * 100, STEPS[i - 1] * 100])
		check(hiss[i] < -40.0, "with no static under it in a %d%% storm" % [STEPS[i] * 100])
	check(lost != -1, "a thick enough storm takes it")
	for i in range(maxi(lost, 1), STEPS.size()):
		check(hiss[i] > -40.0, "taken, static is all there is in a %d%% storm" % [STEPS[i] * 100])
		if i > lost:
			check(hiss[i] > hiss[i - 1] + 1.0, "louder in a %d%% storm than a %d%% one" % [STEPS[i] * 100,
				STEPS[i - 1] * 100])

	var shield := shield_at(radio.global_position + Vector3(1.0, 0.0, 0.0))
	await physics_frames(3)
	check(shield.running() and world.weather.shelter_at(radio.global_position, &"storm") == 1.0, "a bubble stands round it")
	check(absf(radio.hiss.volume_db - hiss[-1]) < 0.1,
		"inside it the static is as loud (%.1f dB, %.1f outside)" % [radio.hiss.volume_db, hiss[-1]])
