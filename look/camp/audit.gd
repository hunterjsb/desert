extends "res://look/camp/context.gd"
## Ripe crops and an unpowered screen frame under the same morning, dusk and storm light.
func _dress() -> void:
	super._dress()
	for entry: Array in [[&"planter", &"saltbush", Vector3(-0.2, 0, 1.8)], [&"deep_planter", &"coalcane", Vector3(1.2, 0, 1.6)]]:
		var bed := Catalog.device(entry[0]) as Planter
		_set_down(bed, entry[2], 0.0)
		for socket in bed.sockets():
			var plant := Catalog.part(entry[1]) as Plant
			if socket.kind != plant.kind or socket.part != null:
				plant.free()
				continue
			world.content.add_child(plant)
			bed.fit(plant, socket)
			plant.set_growth(1.0)
			plant.fruit = 1.0
			plant.state = Plant.RIPE
			plant._show()
		bed.set_process(false)
	_set_down(Catalog.device(&"console"), Vector3(-2.2, 0, 2.4), 0.0)
func _shots() -> Array:
	var crop := Vector3(0.5, 0.55, 1.7)
	var console := Vector3(-2.2, 0.65, 2.4)
	return [["crops5_morning", "midmorning", crop + Vector3(2.0, 1.2, 4).normalized() * 5.0, crop],
		["crops5_dusk", "dusk", crop + Vector3(2.0, 1.2, 4).normalized() * 5.0, crop],
		["crops5_storm", "storm", crop + Vector3(2.0, 1.2, 4).normalized() * 5.0, crop],
		["console5_morning", "midmorning", console + Vector3(0.8, 0.2, 4).normalized() * 5.0, console],
		["console5_dusk", "dusk", console + Vector3(0.8, 0.2, 4).normalized() * 5.0, console],
		["console5_storm", "storm", console + Vector3(0.8, 0.2, 4).normalized() * 5.0, console]]
