class_name KiteProbe
extends ShieldProbe
## A radio with a shortwave converter, an antenna kite set down off it, and a
## cable from the radio's aerial clip to the kite reel's lead terminal, through
## a driven stake between them or straight.


## The rig, made: {radio, kite, cable, stake (or null)}.
func kite_rig(staked: bool, strong := false, at := Vector2(0.0, 2.0)) -> Dictionary:
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [at.x, at.y]) as Radio
	radio.freeze = true
	var kite := Scenarios.standing(world, &"antenna_kite", [], [at.x + 4.0, at.y]) as AntennaKite
	kite.freeze = true
	var stake: Stake = null
	if staked:
		stake = Catalog.stake()
		world.content.add_child(stake)
		var mid := radio.global_position.lerp(kite.global_position, 0.5) + Vector3(0.0, 0.0, 0.6)
		stake.drive(mid, world.height_under(mid))
	var cable := Catalog.cable(world, radio.global_position + Vector3.UP, strong)
	radio.fit(cable.plugs[0], _socket(radio, &"lead"))
	kite.fit(cable.plugs[1], _socket(kite, &"lead"))
	if staked:
		check(cable.route(stake) == "", "the cable passes through the driven stake")
	await physics_frames(3)
	return {"radio": radio, "kite": kite, "cable": cable, "stake": stake}


## A device's first open socket of a kind, or null.
func _socket(device: Device, kind: StringName) -> Socket:
	for socket in device.sockets():
		if socket.kind == kind and socket.is_open():
			return socket
	return null


## Flies the kite on its full line (its paying out is radio probe 55's), and
## lets it settle where the wind puts it.
func fly_up(kite: AntennaKite) -> void:
	kite.fly()
	kite.line_out = Tuning.current().kite_line_m
	await physics_frames(200)
