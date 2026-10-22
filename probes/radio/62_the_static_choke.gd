extends KiteProbe
## Radio probe 62: the static choke. In the radio's misc bay it takes the edge
## out every storm's interference (gonkhub, 2026-10-22): a god through a thin
## storm comes through as if there were none, at choke_signal of its strength;
## other static, a charged kite's, at choke_static of itself.


func run() -> void:
	await load_storm(0.0, 9.0)
	var tuning := Tuning.current()
	var rig := await kite_rig(false)
	var radio: Radio = rig.radio
	var kite: AntennaKite = rig.kite
	radio.on = true
	await fly_up(kite)
	kite.charge = 0.2
	await physics_frames(3)
	var noise := radio.noise
	radio.fit(Catalog.part(&"static_choke"), _socket(radio, &"radio_bay"))
	await physics_frames(3)
	print("a charged kite's static: %.3f bare, %.3f choked" % [noise, radio.noise])
	check(noise > 0.05 and absf(radio.noise - noise * tuning.choke_static) < 0.01, "it halves the static")
	var choke := radio.take(_socket_with(radio, &"radio_bay"))
	var gods := Radio.gods_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var id := &"ledger"
	radio.frequency = gods.carrier(id, world.time) + 2.0
	await physics_frames(3)
	var clear: Dictionary = radio.receive(id, x, z, world.time)
	radio.fit(choke, _socket(radio, &"radio_bay"))
	var clear_choked: Dictionary = radio.receive(id, x, z, world.time)
	check(absf(clear_choked.strength - clear.strength * tuning.choke_signal) < 1e-4, "at a little of the signal")
	choke = radio.take(_socket_with(radio, &"radio_bay"))
	weather_everywhere(0.25, 9.0)
	await physics_frames(3)
	var bare: Dictionary = radio.receive(id, x, z, world.time)
	radio.fit(choke, _socket(radio, &"radio_bay"))
	var choked: Dictionary = radio.receive(id, x, z, world.time)
	print("a god through a thin storm: storm %.2f to %.2f, dirt %.2f to %.2f" % [bare.storm, choked.storm, bare.dirt,
		choked.dirt])
	check(bare.storm > 0.0 and choked.storm == 0.0 and not choked.cut and choked.warp == 0.0,
		"no storm comes between: no garbling, cuts or sliding from it")
	check(bare.dirt > 0.05 and choked.dirt < bare.dirt * 0.5, "it comes through far cleaner")

## A device's socket of a kind with something in it, or null.
func _socket_with(device: Device, kind: StringName) -> Socket:
	for socket in device.sockets():
		if socket.kind == kind and socket.part != null:
			return socket
	return null
