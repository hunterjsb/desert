extends LineProbe
## Devices & mods probe 20: a load off centre leans a piece. A chassis piece
## on one tray under its middle, a battery in its middle and a solar panel
## either side, floats level, its load right over its tray. Another with a
## big battery stuck at its back edge leans toward the battery and floats on,
## still and nowhere near tipping.

## Level within this, degrees; leaning, at least this and never past the most.
const LEVEL := 1.0
const LEANS := 3.0
const MOST := 20.0


func run() -> void:
	await load_lines()
	var flat := flat_spot(0.0, 4.0, 5.0)
	var even := _piece(flat + Vector3(-1.5, 0.0, 0.0), [[Vector2(0.0, 0.3), &"solar_panel"], [Vector2(0.0, -0.3), &"solar_panel"]])
	# At its back edge, the way out of its +Z side.
	var heavy := _piece(flat + Vector3(1.5, 0.0, 0.0), [[Vector2(0.0, -0.4), &"big_battery"]])
	await simulate(5.0)
	print("load over its tray: %.2f° from level; a big battery at its back: %.2f°, %.3f m up, turning %.4f rad/s"
		% [_tilt(even), _tilt(heavy), clearance(heavy), heavy.angular_velocity.length()])
	check(even.stats().hovering and _tilt(even) < LEVEL, "its load right over its tray, a piece floats level")
	# Level, the way out of its back; leaning toward it, its top tips that way.
	var toward := heavy.global_basis.z * Vector3(1.0, 0.0, 1.0)
	check(heavy.stats().hovering and _tilt(heavy) > LEANS and _tilt(heavy) < MOST
		and heavy.global_basis.y.dot(toward) > 0.0 and heavy.angular_velocity.length() < 0.01,
		"a big battery at its back leans it toward the battery, and it floats on, still")


## A piece on a tray under its middle, a battery in its middle and these
## stuck on its top at their places, floating where it rests over a place.
func _piece(at: Vector3, parts: Array) -> Chassis:
	var made := device(&"chassis", at, 0.0) as Chassis
	Stick.put(made, made, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	Stick.put(made, made, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"battery"))
	for each: Array in parts:
		Stick.put(made, made, Chassis.TOP, each[0], 0.0, Catalog.part(each[1]))
	made.global_position.y += made.rest_height()
	return made


func _tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.normalized().angle_to(Vector3.UP))
