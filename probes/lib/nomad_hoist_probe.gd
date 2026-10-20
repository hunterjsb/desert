class_name NomadHoistProbe
extends LineProbe
## Real salvage layout and ownership for kept nomad rigs.

func load_nomads() -> void:
	await load_lines(1234, true)
	for i in 1500:
		await get_tree().process_frame
		if world.salvage.is_idle():
			return
	check(false, "nearby salvage settles")


func lay_nomad(kind: StringName, index := 90000) -> Chassis:
	var x := world.player_world_x() + 4.0
	var z := world.player_world_z() + 4.0
	var coord := world.terrain.chunk_at(x, z)
	var spec := {"id": &"chassis", "device": true, "layer": Finds.SURFACE, "charge": 1.0,
		"fill": [], "sound": 1.0, "rig": NomadKit.RIGS[kind], "index": index,
		"x": x, "z": z, "yaw": 0.0, "bury": 0.0, "lean": 0.0, "lean_by": 0.0, "frozen": true}
	return world.salvage.lay(coord, spec) as Chassis


func mast_on(deck: Chassis) -> Mast:
	for each in deck.mounted():
		if each is Mast:
			return each
	return null


func winch_on(deck: Chassis) -> ManualWinch:
	for each in deck.mounted():
		if each is ManualWinch:
			return each
	return null
