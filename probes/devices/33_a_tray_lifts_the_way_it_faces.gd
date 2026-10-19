extends DeckProbe
## Devices & mods probe 33: a tray lifts toward the sand it faces. On a
## piece's underside it holds up all it carries and floats it; tipped, it
## pushes as much less as it faces away from the sand; stuck on a wall it
## lifts nothing, and the deck carrying it counts none of its lift. A piece
## flipped over, its tray facing the sky, lies on the sand drawing nothing
## until it's righted.


func run() -> void:
	await load_lines()
	var under := piece(flat_spot(0.0, 4.0, 2.0))
	Stick.put(under, under, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	Stick.put(under, under, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"big_battery"))
	await simulate(4.0)
	check(under.hovering() and absf(under.carried_kg - under.mass) < 0.5 and clearance(under) > 0.6,
		"facing the sand, a tray floats its piece, holding up all of it (%.1f of %.1f kg)" % [under.carried_kg, under.mass])
	var tipped := Device.facing_down(Vector3(0.0, -1.0, 1.0))
	check(absf(tipped - sqrt(0.5)) < 1e-3 and Device.facing_down(Vector3.UP) == 0.0,
		"tipped halfway to a wall it pushes 0.71 of that, facing the sky none")

	var walled := piece(flat_spot(4.0, 4.0, 2.0))
	Stick.put(walled, walled, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"frame"))
	var face: Socket = (frame_on(walled, walled) as Frame).faces()[&"right"]
	walled.join(Catalog.device(&"chassis") as Chassis, face)
	var wall := on_frame(walled, face)
	Stick.put(walled, wall, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	await simulate(3.0)
	check(walled.stats().lift_kg == 0.0 and not walled.hovering() and walled.carried_kg == 0.0,
		"on a wall it lifts nothing, and the deck counts none of it")

	var flipped := piece(flat_spot(-4.0, 4.0, 2.0))
	Stick.put(flipped, flipped, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	var at := flipped.global_position
	world.teleport(flipped, Transform3D(Basis(Vector3.RIGHT, PI), at + Vector3.UP * 0.4))
	await simulate(4.0)
	check(flipped.global_basis.y.y < -0.9 and clearance(flipped) < 0.5 and flipped.carried_kg == 0.0 and flipped.demand_w() == 0.0,
		"flipped, its tray facing the sky, it lies on the sand holding nothing up and drawing nothing")
