extends ShieldProbe
## Radio probe 18: static only when nothing plays (gonkhub, 2026-10-19). Tuned
## to a god coming in clean, there's no static under it; between stations,
## with nothing to hear, static is all there is. A god through a thin storm
## still plays, as loud as the dial has it, with still no static: the storm
## is in its sound instead, chewed up by the interference chain (crushed,
## gritty, warbling, smeared) as dirty as it comes through. A god whose way
## a storm blocks outright is nothing to hear, and its static is back.


func run() -> void:
	await load_storm(0.0)
	# Beside Mother Cistern, so a god comes in clean whatever the dial's plan.
	await beside_god(&"cistern")
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var best := &""
	var cleanest := 0.0
	for id in Gods.ids():
		radio.frequency = gods.carrier(id, world.time)
		var got: float = radio.receive(id, x, z, world.time).clean
		if got > cleanest and id != &"stoker" and id != &"eye" and id != &"walker":
			cleanest = got
			best = id
	radio.frequency = gods.carrier(best, world.time)
	await physics_frames(5)
	var under := radio.hiss.volume_db
	var clean_dirt := radio.dirt
	var carriers := Dial.carriers(gods, world.time)
	radio.frequency = (carriers[2][0] + carriers[3][0]) * 0.5
	await physics_frames(5)
	var between := radio.hiss.volume_db
	print("static under %s (clean %.2f, dirt %.2f): %.1f dB; between stations: %.1f dB" % [Gods.title(best), cleanest,
		clean_dirt, under, between])
	check(under < -60.0, "under a clean signal, no static")
	check(radio.channel == Radio.STATIC and between > under + 40.0, "between stations, static is all there is")
	check(clean_dirt < 0.1, "and a clean signal plays clean")

	# A thin storm: still playing, no static, its sound chewed up instead.
	weather_everywhere(0.25)
	radio.frequency = gods.carrier(best, world.time)
	await physics_frames(5)
	var bus := AudioServer.get_bus_index(radio.signal_bus())
	var crushed := AudioServer.is_bus_effect_enabled(bus, Garble.Stage.CRUSH)
	var warbling := AudioServer.is_bus_effect_enabled(bus, Garble.Stage.WARBLE)
	var level := Radio.audible(radio.reception)
	print("through a thin storm: clean %.2f, dirt %.2f, playing at %.2f, static %.1f dB, crushed %s, warbling %s" % [
		radio.reception.clean, radio.dirt, level, radio.hiss.volume_db, crushed, warbling])
	check(radio.dirt > 0.3 and level > 0.5, "a thin storm's god still plays loud, dirty")
	check(radio.hiss.volume_db < -40.0, "with no static under it")
	check(crushed and warbling, "the storm in its sound: crushed and warbling")

	weather_everywhere(1.0)
	await physics_frames(5)
	print("its way blocked by a storm: %.1f dB, clean %.2f" % [radio.hiss.volume_db, radio.reception.clean])
	check(radio.reception.clean == 0.0 and radio.hiss.volume_db > under + 40.0, "with its way blocked, the static is back")
