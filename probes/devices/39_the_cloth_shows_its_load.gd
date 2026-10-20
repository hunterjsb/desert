extends DeckProbe
## Devices & mods probe 39: fabric is drawn by the force on it. On a frame's
## face, its cloth's load goes as its push across it, the same share of it in
## a breeze as in a fresh wind; slack in the breeze, taut in a gale, bellied
## the other way when the wind comes round, and edge-on it bears nothing while
## the air going past stirs it.


func run() -> void:
	await load_lines()
	var deck := Rig.build(world.content, [[&"frame", Vector2i.ZERO, 0], [&"face", Vector2i.ZERO, &"back", &"fabric"]]).deck
	deck.global_position = flat_spot(0.0, 5.0, 3.0) + Vector3.UP * 0.1
	await simulate(1.0)
	var face := Rig.face_of(deck, Vector2i.ZERO, &"back")
	var cloth: MeshInstance3D = null
	for node in face.fitted:
		if node.has_meta(&"cloth"):
			cloth = node
	check(cloth != null, "the fabric has its cloth")
	if cloth == null:
		return
	var out := deck.global_basis * face.transform.basis.z.normalized()
	var breeze := await shown(deck, cloth, -out * 4.0)
	var fresh := await shown(deck, cloth, -out * 9.0)
	var gale := await shown(deck, cloth, -out * 20.0)
	var round := await shown(deck, cloth, out * 20.0)
	var edge := await shown(deck, cloth, out.cross(Vector3.UP) * 20.0)
	check(absf(breeze.x / breeze.y - fresh.x / fresh.y) < absf(fresh.x / fresh.y) * 0.01,
		"its load goes as its push (%.4f and %.4f a newton)" % [breeze.x / breeze.y, fresh.x / fresh.y])
	check(absf(breeze.x) < 0.3 and absf(gale.x) >= 1.0, "slack in a breeze (%.2f), taut in a gale (%.2f)" % [breeze.x, gale.x])
	check(signf(round.x) == -signf(gale.x), "bellied the other way with the wind round (%.2f)" % round.x)
	check(absf(edge.x) < 0.02 and edge.z > 15.0, "edge-on it bears nothing (%.3f) while the air stirs it (%.0f m/s)" % [edge.x, edge.z])


## What the cloth is drawn with a few ticks into a steady wind, from still:
## its load, its push across its face, N, and the air past it.
func shown(deck: Chassis, cloth: MeshInstance3D, wind: Vector3) -> Vector3:
	blow(Vector2.ZERO)
	await simulate(0.5)
	blow(Vector2(wind.x, wind.z))
	await simulate(3.0 / 60.0)
	var normal := (deck.global_basis * (deck.plates()[0][1] as Vector3)).normalized()
	return Vector3(cloth.get_instance_shader_parameter(&"load"), deck.faces.pushes[0].dot(normal),
		cloth.get_instance_shader_parameter(&"air"))
