extends MovementProbe
## Movement probe 29: boards by make. A skimmer racer and a Knights' patrol
## board ride the one ride, measurably apart: flat out over the flat the
## racer is faster and floats higher; in the same hard carve it breaks loose
## and slides out further where the patrol board holds closer to its way;
## and each weighs, looks and hums as its make.

## Turning your view this fast, rad/s, move forward held, for this long, s.
const CARVE := 1.4
const TURNING := 1.5


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var racer := await _ride(flat, BoardMakes.RACER)
	var patrol := await _ride(flat, BoardMakes.PATROL)
	for seen: Dictionary in [racer, patrol]:
		print("%s, %.1f kg: %.1f m/s flat out, %.2f m over the sand; carving, loose in %.2f s, %.0f° off its way at most"
			% [seen.label, seen.kg, seen.top, seen.over, seen.broke, rad_to_deg(seen.slid)])
	check(racer.top > patrol.top + 3.0, "the racer is faster flat out (%.1f against %.1f m/s)" % [racer.top, patrol.top])
	check(racer.over > patrol.over + 0.08, "and floats higher (%.2f against %.2f m)" % [racer.over, patrol.over])
	check(racer.slid > patrol.slid + deg_to_rad(10.0) and racer.broke < patrol.broke,
		"it breaks loose sooner and slides out further (%.0f° against %.0f°)" % [rad_to_deg(racer.slid), rad_to_deg(patrol.slid)])
	check(racer.kg < patrol.kg and racer.look != patrol.look and racer.hum != patrol.hum,
		"and each weighs, looks and hums as its make")
	set_rate(60)


## A fresh board of this make flat out along +x, then a hard carve:
## {label, kg, top, over, broke, slid, look, hum}.
func _ride(flat: Dictionary, make: StringName) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	var board := await ride_here(&"battery", make)
	var ride := player.ride
	hold(["move_forward"])
	await ride_for(7.0)
	var at := where()
	var seen := {"label": board.label, "kg": board.mass, "top": flat_speed(),
		"over": ride.y - world.height_at(at.x, at.z), "broke": INF, "slid": 0.0, "t": 0.0,
		"look": board.frame_view.mesh, "hum": Sounds.BOARD_HUMS[make]}
	var dt := 1.0 / ticks_per_second()
	await ride_for(TURNING, func() -> void:
		player.rotation.y -= CARVE * dt
		seen.t += dt
		var a := absf(ride.velocity.angle_to(ride.ahead))
		seen.slid = maxf(seen.slid, minf(a, PI - a))
		if ride.skidding:
			seen.broke = minf(seen.broke, seen.t))
	hold([])
	return seen
