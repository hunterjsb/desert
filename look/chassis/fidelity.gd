extends "res://look/paint/paint.gd"
## The chassis kit beside real camp gear, in the same light before and after.
func _dress() -> void:
	super._dress()
	for i in 4:
		var id: StringName = [&"chassis", &"chassis", &"chassis", &"chassis"][i]
		var body := Catalog.device(id)
		var era: StringName = [Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER][i]
		var line := Eras.lineage(era, &"watchtower", 1234)
		body.set_meta(&"lineage", line)
		body.apply_frame_look(Dress.lineage(id, line))
		_set_down(body, Vector3(-2.1 + i * 1.4, 0.0, -2.2), 0.0)
	for entry: Array in [[&"helm_seat", -2.0, -0.7], [&"hand_winch", -0.9, -0.8], [&"mast", 2.0, -0.7]]:
		_set_down(Catalog.device(entry[0]), Vector3(entry[1], 0.0, entry[2]), 0.0)
	for entry: Array in [[&"frame", -0.6, -3.5], [&"hull_plate", 0.8, -3.5]]:
		_set_down(Catalog.part(entry[0]), Vector3(entry[1], 0.0, entry[2]), 0.0)

func _shots() -> Array:
	return [["kit5", "midmorning", Vector3(3.0, 2.0, 4.0), Vector3(0, 0.4, -1.0)],
		["kit20", "midmorning", Vector3(12.0, 4.0, 15.0), Vector3(0, 0.4, -1.0)],
		["dusk", "dusk", Vector3(3.0, 2.0, 4.0), Vector3(0, 0.4, -1.0)],
		["bubble", "storm", Vector3(0.9, 1.7, 2.0), Vector3(0, 0.4, -1.0)]]
