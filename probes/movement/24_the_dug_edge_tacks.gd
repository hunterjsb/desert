extends MovementProbe
## Movement probe 24: the dug edge tacks. Towed by a steady pull downwind, a
## board steered 60° across it runs downwind all the same: its hover can't
## hold against a line. Steered so with its edge dug in, it holds that line
## across the pull and makes ground across it.

## The line's pull, m/s², and how far across it the board is steered.
const PULL := 3.0
const ACROSS := deg_to_rad(60.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var flat_run := await _towed(flat, ["move_left"])
	var dug := await _towed(flat, ["move_left", "move_back"])
	for each: Dictionary in [flat_run, dug]:
		print("%s, towed %.1f m/s² and steered %.0f° across: %.1f m at %.0f° off downwind, %.1f m/s"
			% ["dug" if each == dug else "flat", PULL, rad_to_deg(ACROSS), each.went, rad_to_deg(each.off), each.speed])
	check(flat_run.off < deg_to_rad(20.0), "its hover alone runs downwind (%.0f°)" % rad_to_deg(flat_run.off))
	check(dug.off > ACROSS - deg_to_rad(15.0), "dug in, it holds a line across the pull (%.0f°)" % rad_to_deg(dug.off))
	check(dug.went * sin(dug.off) > 10.0, "making ground across it (%.1f m)" % (dug.went * sin(dug.off)))
	set_rate(60)


## From rest towed along +x, steered on `keys` to 60° across the pull to its
## left, for 12 s: {went, off, speed}, the ground it made after its first 2 s
## and how far off downwind.
func _towed(flat: Dictionary, keys: Array) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var downwind := Vector2(1.0, 0.0)
	# Facing so that steering left points the board across the pull.
	await place(flat.x - 40.0, flat.z, downwind.rotated(-ACROSS).rotated(PI * 0.5))
	await ride_here()
	hold(keys)
	var seen := {"tick": 0, "from": Vector3.ZERO}
	await ride_for(12.0, func() -> void:
		seen.tick += 1
		if seen.tick == 2 * ticks_per_second():
			seen.from = where()
		player.ride.tow(Vector3(downwind.x, 0.0, downwind.y) * PULL / ticks_per_second()))
	var gone: Vector3 = where() - seen.from
	var flat_gone := Vector2(gone.x, gone.z)
	hold([])
	return {"went": flat_gone.length(), "off": absf(downwind.angle_to(flat_gone)), "speed": flat_speed()}
