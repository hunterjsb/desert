extends MovementProbe
## Movement probe 19: the tilt settles, never twitches. Flat out across the
## ridges, over crests and slip faces, carving hard one way then the other,
## the board's pitch and its lean over the sand change by no more than a
## small angle a tick at sixty ticks a second. Drawn, it's smoothed between
## ticks, so a frame never sees more; your view leans with a share of it.

const SECONDS := 40.0
## The most the pitch and the lean may change in a sixtieth of a second,
## degrees: a lean from one hard carve to the other, 60°, takes about half a
## second.
const PITCH := 1.5
const LEAN := 3.0
const STEERS := [["move_forward"], ["move_forward", "move_left"], ["move_forward"], ["move_left"],
	["move_forward", "move_right"], ["move_right"], ["move_forward", "crouch"], ["move_forward", "jump"]]


func run() -> void:
	var tuning := Tuning.current()
	tuning.view_radius = tuning.near_radius
	tuning.far_radius = (tuning.view_radius + 1) * tuning.chunk_size
	await load_moving()
	set_rate(60, 8)
	var heading := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	face(heading)
	await ride_here()
	var ride := player.ride
	var seen := {"t": 0, "was": _tilt(), "pitch": 0.0, "lean": 0.0, "steepest": 0.0}
	await ride_for(SECONDS, func() -> void:
		seen.t += 1
		if seen.t % 90 == 0:
			hold(STEERS[(seen.t / 90) % STEERS.size()])
			if seen.t % 720 == 0:
				face(-Vector2(player.velocity.x, player.velocity.z).normalized())
		var tilt := _tilt()
		var moved: Vector2 = (tilt - seen.was).abs()
		seen.was = tilt
		seen.pitch = maxf(seen.pitch, moved.x)
		seen.lean = maxf(seen.lean, moved.y)
		seen.steepest = maxf(seen.steepest, absf(ride.pitch)), false)
	hold([])
	print("%.0f s across the ridges: the pitch changed %.2f° a tick at most, the lean %.2f°; pitched %.0f° at most"
		% [SECONDS, rad_to_deg(seen.pitch), rad_to_deg(seen.lean), rad_to_deg(seen.steepest)])
	check(seen.steepest > deg_to_rad(15.0), "over steep sand (%.0f°)" % rad_to_deg(seen.steepest))
	check(seen.pitch < deg_to_rad(PITCH), "the pitch never jumps (%.2f° a tick)" % rad_to_deg(seen.pitch))
	check(seen.lean < deg_to_rad(LEAN), "nor the lean (%.2f° a tick)" % rad_to_deg(seen.lean))
	set_rate(60)


## The board's pitch along the sand and its lean side to side, as drawn at a tick.
func _tilt() -> Vector2:
	var ride := player.ride
	return Vector2(ride.pitch, ride.roll - ride.bank)
