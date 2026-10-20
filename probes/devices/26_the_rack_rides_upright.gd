extends DeckProbe
## Devices & mods probe 26: the rack rides upright. A Console as heavy as one
## is ever found, a tall rack, stuck on a deck of two pieces on their trays
## beside a shield and its batteries, floats leaning only a little, then
## rides two minutes of a gusting storm, the deck moored by one line from a
## ring of its own: upright, never rocking over, swinging only round onto
## its line.

## Leaning at rest at most, and tilting in the storm at most, degrees;
## rocking over no faster than this, rad/s: swinging round on its line is
## how anything moored settles.
const LEAN := 8.0
const TILT := 15.0
const SPIN := 0.3
## Everything a found Console's ports can hold, the heaviest of each.
const HEAVIEST := [&"screen", &"anemometer", &"anemometer", &"anemometer", &"particle_sensor", &"particle_sensor",
	&"particle_sensor", &"radar"]


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, -4.0, 3.0))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)), 0)
	for i in 2:
		fit_part(deck, &"hover_tray")
	var on_deck := Rig.make([&"console", HEAVIEST]) as Console
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, -0.15), 0.0, on_deck)
	var other := Rig.piece(deck, Vector2i(1, 0))
	Stick.put(deck, other, Chassis.TOP, Vector2(-0.2, 0.2), 0.0, Catalog.device(&"shield"))
	for at: Vector2 in [Vector2(0.3, 0.3), Vector2(0.3, -0.1), Vector2(-0.2, -0.3)]:
		Stick.put(deck, other, Chassis.TOP, at, 0.0, Catalog.part(&"big_battery"))
	deck.global_position.y = world.height_under(deck.global_position) + deck.rest_height()
	await simulate(10.0)
	print("a Console of %.1f kg on a deck of two pieces: leaning %.2f°" % [on_deck.mass, _tilt(on_deck)])
	check(deck.stats().hovering and _tilt(on_deck) < LEAN, "on a deck it floats, leaning a little (%.1f°)" % _tilt(on_deck))
	deck.fit(Catalog.part(&"hook"), ring(deck, Vector2i.ZERO, Vector2i(-1, 0)))
	await _storm(on_deck, "on a deck")


## Two minutes of a gusting storm, moored by one line to a stake upwind from
## its deck's ring: it rides upright.
func _storm(made: Console, where: String) -> void:
	var holder: Device = made.host()
	var tie := holder.free_tie(holder.global_position - Vector3(3.0, 0.0, 0.0))
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
