extends MovementProbe
## Movement probe 25: the skid. Flat out, a carve the hover can hold grips;
## turn harder than it holds and the board breaks loose and skids, well off
## its way for as long as you keep turning into it, and bites again once you
## straighten up.

## Turning your view this fast, rad/s, move forward held.
const GENTLE := 0.4
const HARD := 1.6
const TURNING := 2.5
const STRAIGHT := 1.5


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var gentle := await _carve(flat, GENTLE)
	var hard := await _carve(flat, HARD)
	print("turning %.1f rad/s from %.1f m/s: %s, %.1f° off its way at most"
		% [GENTLE, gentle.from, "skids" if gentle.broke < INF else "grips", rad_to_deg(gentle.slid)])
	print("turning %.1f rad/s: loose in %.2f s, skidding %.2f s of %.1f, %.0f° to %.0f° off its way, %.1f m/s at the end; straightened, it bites in %.2f s"
		% [HARD, hard.broke, hard.held, TURNING, rad_to_deg(hard.least), rad_to_deg(hard.slid), hard.out, hard.bit])
	check(gentle.broke == INF and gentle.slid < deg_to_rad(5.0), "a carve the hover holds grips (%.1f°)"
		% rad_to_deg(gentle.slid))
	check(hard.broke < 0.8, "a harder one breaks loose (%.2f s)" % hard.broke)
	check(hard.held > 1.2 and hard.least > deg_to_rad(10.0) and hard.slid < deg_to_rad(80.0),
		"and skids, held well off its way while you turn into it (%.2f s, %.0f° to %.0f°)"
		% [hard.held, rad_to_deg(hard.least), rad_to_deg(hard.slid)])
	check(hard.bit < 0.75, "straightened, it bites again (%.2f s)" % hard.bit)
	set_rate(60)


## Up to speed along +x, then your view turning at `rate` while you hold
## move forward, then held still: {from, broke, held, least, slid, out, bit}.
## `least` is the nearest the board came to its way while skidding, after
## its first half second; `bit`, how long after straightening it stopped.
func _carve(flat: Dictionary, rate: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(6.0)
	var ride := player.ride
	var seen := {"from": flat_speed(), "broke": INF, "held": 0.0, "least": PI, "slid": 0.0, "out": 0.0, "bit": INF,
		"t": 0.0}
	var dt := 1.0 / ticks_per_second()
	await ride_for(TURNING, func() -> void:
		player.rotation.y -= rate * dt
		seen.t += dt
		var off := _off(ride)
		seen.slid = maxf(seen.slid, off)
		if ride.skidding:
			seen.broke = minf(seen.broke, seen.t)
			seen.held += dt
			if seen.t > seen.broke + 0.5:
				seen.least = minf(seen.least, off))
	seen.out = flat_speed()
	seen.t = 0.0
	await ride_for(STRAIGHT, func() -> void:
		seen.t += dt
		if not ride.skidding:
			seen.bit = minf(seen.bit, seen.t))
	if seen.held == 0.0:
		seen.least = 0.0
	hold([])
	return seen


## How far the board points off its way, either end first, radians.
func _off(ride: Ride) -> float:
	if ride.velocity.length() < 0.5:
		return 0.0
	var a := absf(ride.velocity.angle_to(ride.ahead))
	return minf(a, PI - a)
