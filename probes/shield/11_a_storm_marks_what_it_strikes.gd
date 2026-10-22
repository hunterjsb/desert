extends ShieldProbe
## Bubble shield probe 11: a storm's wear shows where it struck. Ten minutes
## of the worst storm in a gale wear a turbine out on the sand, and its paint
## carries all that wear on the faces turned to the wind; one in a bubble
## beside it takes none.

const MINUTES := 10.0
const WIND := 25.0


func run() -> void:
	await load_storm(1.0, WIND)
	var middle := ahead(-4.0)
	shield_at(middle)
	var inside := turbine_at(middle + Vector3(0.0, 0.0, 2.0))
	var outside := turbine_at(ahead(16.0))
	await physics_frames(30)
	await live(MINUTES * 60.0)
	var upwind := -world.weather.felt_wind(outside.global_position).normalized()
	var lost := 1.0 - outside.durability
	var shown: Vector4 = outside.frame_view.get_instance_shader_parameter(&"blasted")
	var faces := outside.frame_view.global_basis * Vector3(shown.x, shown.y, shown.z)
	print("outside: %.4f worn, marked %s, its paint facing %s, upwind %s; inside: %.3f worn, marked %s"
		% [lost, outside.weathered, faces, upwind, 1.0 - inside.durability, inside.weathered])
	check(lost > 0.1 and absf(outside.weathered.w - lost) < 1e-4, "the storm wore the turbine outside, all of it marked")
	check(faces.dot(upwind) > 0.98 and absf(shown.w - lost) < 1e-4, "its paint shows it on the faces turned to the wind")
	check(inside.weathered == Vector4.ZERO and inside.durability == 1.0, "the one in the bubble took none")
