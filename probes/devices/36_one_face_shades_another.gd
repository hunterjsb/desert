extends DeckProbe
## Devices & mods probe 36: a face behind another catches a fraction. Two
## frames side by side across a steady wind, each walled front and back: the
## walls upwind each take what a lone wall would, side by side not shading
## each other; each one behind takes only a fraction of that.

const WIND := 12.0


func run() -> void:
	await load_lines()
	var deck := Rig.build(world.content, [[&"piece", Vector2i(1, 0)], [&"frame", Vector2i(0, 0), 0], [&"frame", Vector2i(1, 0), 0],
		[&"wall", Vector2i(0, 0), &"front"], [&"wall", Vector2i(0, 0), &"back"],
		[&"wall", Vector2i(1, 0), &"front"], [&"wall", Vector2i(1, 0), &"back"]]).deck
	deck.global_position = flat_spot(0.0, 5.0, 4.0) + Vector3.UP * 0.1
	await simulate(1.0)
	var plates := deck.plates()
	var out := deck.global_basis * (plates[0][1] as Vector3)
	blow(Vector2(-out.x, -out.z) * WIND)
	await simulate(3.0 / 60.0)
	var lone := world.tuning.wind_catch_per_m2 * WIND * WIND
	for i in plates.size():
		var push := deck.faces.pushes[i].length()
		var upwind := (deck.global_basis * (plates[i][1] as Vector3)).dot(out) > 0.0
		if upwind:
			check(absf(push - lone) < lone * 0.03, "a wall upwind takes what a lone one would (%.0f of %.0f N)" % [push, lone])
		else:
			check(push > 0.0 and push < lone * 0.25, "a wall behind another takes a fraction (%.0f of %.0f N)" % [push, lone])
