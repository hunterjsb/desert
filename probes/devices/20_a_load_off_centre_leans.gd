extends LineProbe
## Devices & mods probe 20: a load off centre leans a crate. A crate frame on
## its one tray, a solar panel on each top mount, floats level, its load
## right over its tray. Another with a big battery in its back slot, running
## both on a cable, leans toward the battery and floats on, still and
## nowhere near tipping.

## Level within this, degrees; leaning, at least this and never past the most.
const LEVEL := 1.0
const LEANS := 3.0
const MOST := 20.0


func run() -> void:
	await load_lines()
	var flat := flat_spot(0.0, 4.0, 5.0)
	var even := _crate(flat + Vector3(-1.5, 0.0, 0.0), [&"solar_panel", &"solar_panel"])
	var heavy := _crate(flat + Vector3(1.5, 0.0, 0.0), [&"big_battery"])
	# The battery runs both, on a cable, so nothing in the level one leans it.
	var cable := Catalog.cable(world, flat)
	for i in 2:
		var port: Socket = [even, heavy][i].sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0]
		[even, heavy][i].fit(cable.plugs[i], port)
	await simulate(5.0)
	print("load over its tray: %.2f° from level; a big battery at its back: %.2f°, %.3f m up, turning %.4f rad/s"
		% [_tilt(even), _tilt(heavy), clearance(heavy), heavy.angular_velocity.length()])
	check(even.stats().hovering and _tilt(even) < LEVEL, "its load right over its tray, a crate floats level")
	# Level, the way out of its back; leaning toward it, its top tips that way.
	var toward := heavy.global_basis.z * Vector3(1.0, 0.0, 1.0)
	check(heavy.stats().hovering and _tilt(heavy) > LEANS and _tilt(heavy) < MOST
		and heavy.global_basis.y.dot(toward) > 0.0 and heavy.angular_velocity.length() < 0.01,
		"a big battery at its back leans it toward the battery, and it floats on, still")


## A crate frame on a tray with parts in it, floating where it rests over a place.
func _crate(at: Vector3, parts: Array) -> Device:
	var made := device(&"crate_frame", at, 0.0)
	for id: StringName in [&"hover_tray"] + parts:
		fit_part(made, id)
	made.global_position.y += made.rest_height()
	return made


func _tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.normalized().angle_to(Vector3.UP))
