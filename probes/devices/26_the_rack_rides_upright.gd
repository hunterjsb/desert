extends DeckProbe
## Devices & mods probe 26: the rack rides upright. A Console as heavy as one
## is ever found, a tall rack, floats on its one tray leaning only a little
## toward the batteries at its back, then rides two minutes of a gusting storm
## moored by one line from its back ring, upright, never rocking over,
## swinging only round onto its line. Standing on a deck of two pieces on
## their trays beside a shield, the deck moored by a ring of its own, it rides
## as steady.

## Leaning at rest at most, and tilting in the storm at most, degrees;
## rocking over no faster than this, rad/s: swinging round on its line is
## how anything moored settles.
const LEAN := 8.0
const TILT := 15.0
const SPIN := 0.3
## Everything a found Console can hold, the heaviest of each.
const HEAVIEST := [&"big_battery", &"big_battery", &"screen", &"anemometer", &"anemometer", &"anemometer",
	&"particle_sensor", &"particle_sensor", &"particle_sensor", &"radar", &"solar_panel", &"hook", &"hook"]


func run() -> void:
	await load_lines()
	var alone := device(&"console", flat_spot(0.0, 4.0, 3.0), 0.0) as Console
	fit_part(alone, &"hover_tray")
	for id: StringName in HEAVIEST:
		fit_part(alone, id)
	alone.global_position.y = world.height_under(alone.global_position) + alone.rest_height()
	await simulate(5.0)
	var lean := _tilt(alone)
	var back := alone.global_basis.z * Vector3(1.0, 0.0, 1.0)
	print("a Console of %.1f kg on its tray: leaning %.2f° %s" % [alone.mass, lean,
		"back" if alone.global_basis.y.dot(back) > 0.0 else "forward"])
	check(alone.stats().hovering and lean < LEAN, "on its one tray it floats, leaning a little (%.1f°)" % lean)
	await _storm(alone, "alone on its tray")
	# The deck has the sand to itself: the flattest near the spawn can be where
	# the Console's storm left it, and the two would knock together.
	world.ropes.clear()
	for body: Node in world.content.get_children():
		if body is RigidBody3D or body is Line:
			body.free()

	var deck := piece(flat_spot(0.0, -4.0, 3.0))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)), 0)
	for i in 2:
		fit_part(deck, &"hover_tray")
	var on_deck := Catalog.device(&"console") as Console
	world.content.add_child(on_deck)
	for id: StringName in HEAVIEST:
		fit_part(on_deck, id)
	deck.mount(on_deck, socket_on(deck, Vector2i.ZERO, &"deck"))
	var shield := Catalog.device(&"shield")
	world.content.add_child(shield)
	fit_part(shield, &"battery")
	deck.mount(shield, socket_on(deck, Vector2i(1, 0), &"deck"))
	deck.global_position.y = world.height_under(deck.global_position) + deck.rest_height()
	await simulate(10.0)
	print("on a deck of two pieces: leaning %.2f°" % _tilt(on_deck))
	check(deck.stats().hovering and _tilt(on_deck) < LEAN, "on a deck it floats, leaning a little (%.1f°)" % _tilt(on_deck))
	deck.fit(Catalog.part(&"hook"), ring(deck, Vector2i.ZERO, Vector2i(-1, 0)))
	await _storm(on_deck, "on a deck")


## Two minutes of a gusting storm, moored by one line to a stake upwind, from
## its back ring or its deck's: it rides upright.
func _storm(made: Console, where: String) -> void:
	var holder: Device = made.host() if made.host() != null else made
	var tie := made.free_tie(made.global_position + made.global_basis.z) if holder == made \
		else holder.free_tie(holder.global_position - Vector3(3.0, 0.0, 0.0))
	var at := tie.global_position - Vector3(3.0, 0.0, 0.0)
	var line := Line.between(world, tie, driven_stake(Vector3(at.x, world.height_under(at), at.z)).free_tie(tie.global_position), 0.3)
	blow(Vector2(wind.storm_speed(), 0.0), world.tuning.gust_storm_strength)
	speed_up(6)
	# The storm's first gust swings it round onto its line, as it does anything moored.
	await simulate(10.0)
	var seen := {"tilt": 0.0, "spin": 0.0}
	await simulate(120.0, func() -> void:
		var w := holder.angular_velocity
		seen.tilt = maxf(seen.tilt, _tilt(made))
		seen.spin = maxf(seen.spin, Vector2(w.x, w.z).length()))
	speed_up(1)
	blow(Vector2.ZERO)
	print("%s, two minutes in a %.0f m/s storm on one line: tilted %.2f° at most, rocking %.3f rad/s"
		% [where, wind.storm_speed(), seen.tilt, seen.spin])
	check(seen.tilt < TILT and seen.spin < SPIN and holder.stats().hovering,
		"%s, it rides a gusting storm upright (%.1f°, %.2f rad/s)" % [where, seen.tilt, seen.spin])
	line.queue_free()


func _tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.normalized().angle_to(Vector3.UP))
