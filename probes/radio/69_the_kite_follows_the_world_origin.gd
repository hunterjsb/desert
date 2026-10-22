extends KiteProbe
## Recentering must move the aerial and reel together without changing their geography.
func run() -> void:
	await load_storm(0.0, 9.0)
	var rig := await kite_rig(true)
	var kite: AntennaKite = rig.kite
	await fly_up(kite)
	var relative := kite.kite_at - kite.anchor()
	var height := kite.height()
	var charge := kite.charge
	var visuals := {}
	for visual in [kite._kite, kite._line, kite._flash]:
		visuals[visual] = visual.global_position - kite.anchor()
	world.shift_origin(Vector2i(8, -5))
	check((kite.kite_at - kite.anchor()).distance_to(relative) < 0.001,
		"the same instant keeps the actual aerial offset rather than flying it across the origin shift")
	check(absf(kite.height() - height) < 0.001 and kite.charge == charge,
		"recentering preserves the actual ground-relative height and stored charge")
	for visual: Node3D in visuals:
		check((visual.global_position - kite.anchor()).distance_to(visuals[visual]) < 0.001,
			"existing top-level aerial visuals share the exact origin displacement")
