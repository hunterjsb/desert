extends MovementProbe
## Movement probe 7: origin shift at speed. Flat out on a board in real time,
## at a game's sixty frames a second, across three origin shifts, with the
## ruins and finds laid out with the ground as you go. No shift jumps you:
## tick to tick, your way changes no more than the ride itself changes it. No
## frame spends longer than the hitch line streaming, bar one, as world probe
## 7 allows. And the ground is solid well ahead of you the whole way.
## Runs alone: it times real frames.

const SHIFTS := 3
## Your way may change this much tick to tick, m: the ride's own hardest
## turn or landing, never a jump.
const SMOOTH := 0.02
## Solid at least this far ahead along your way, m, every tick.
const AHEAD := 64.0

var _limit := Tuning.current().stream_frame_max_ms
var _over := 0
var _timing := false


func run() -> void:
	# After the terrain's, so every frame's streaming time is seen.
	process_priority = 1
	await load_moving(1234, true)
	var way := _clear_way()
	check(way != Vector2.ZERO, "a way out from spawn clear of ruins and finds")
	if way == Vector2.ZERO:
		return
	face(way)
	var board := await ride_here()
	set_rate(60, 1)
	Engine.max_fps = 60
	var shifts := {"count": 0, "ticks": []}
	world.origin_shifted.connect(func(_by: Vector2i) -> void: shifts.count += 1)
	var seen := {"last": where(), "step": Vector3.ZERO, "worst": 0.0, "at_shift": 0.0, "short": 0, "nearest": INF,
		"shifts": 0, "ticks": 0}
	world.terrain.slowest_frame_ms = 0.0
	_timing = true
	hold(["move_forward"])
	await ride_for(60.0, func() -> void:
		var at := where()
		var step: Vector3 = at - seen.last
		seen.last = at
		seen.ticks += 1
		if seen.ticks > 1:
			var change: float = (step - seen.step).length()
			seen.worst = maxf(seen.worst, change)
			if shifts.count != seen.shifts:
				seen.at_shift = maxf(seen.at_shift, change)
		seen.shifts = shifts.count
		seen.step = step
		if not solid_ahead(AHEAD):
			seen.short += 1
		if seen.ticks % 10 == 0:
			var solid := 0.0
			while solid < 200.0 and solid_ahead(solid + 8.0):
				solid += 8.0
			seen.nearest = minf(seen.nearest, solid))
	_timing = false
	hold([])
	Engine.max_fps = 0
	print("%.0f m in real time across %d origin shifts: your way changed at most %.4f m a tick, %.4f at a shift"
		% [Vector2(seen.last.x - world.spawn.x, seen.last.z - world.spawn.y).length(), shifts.count, seen.worst,
			seen.at_shift])
	print("slowest streaming frame %.2f ms, %d over %.1f ms; the ground solid at least %.0f m ahead; finds the most of one %.2f ms"
		% [world.terrain.slowest_frame_ms, _over, _limit, seen.nearest, world.salvage.slowest_ms])
	check(shifts.count >= SHIFTS, "across %d origin shifts (%d)" % [SHIFTS, shifts.count])
	check(seen.worst < SMOOTH, "no shift jumped you (%.4f m)" % seen.worst)
	check(_over <= 1, "streaming stayed under %.1f ms a frame (%d frames over)" % [_limit, _over])
	check(seen.short == 0 and player.ride.waited == 0, "the ground was solid %d m ahead all the way (%d ticks short)"
		% [AHEAD, seen.short])
	check(player.board == board, "still riding")
	set_rate(60)


func _process(delta: float) -> void:
	super(delta)
	if _timing and world.terrain.frame_ms > _limit:
		_over += 1


## A way out from spawn whose first 1.4 km passes no ruin within 30 m and no
## find within 2 m; Vector2.ZERO if none.
func _clear_way() -> Vector2:
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var size := world.tuning.chunk_size
	for k in 16:
		var way := Vector2.from_angle(k * TAU / 16.0)
		var clear := true
		for ruin in world.shape.ruins.around(from.x, from.y, 1500.0):
			var off := Vector2(ruin.center) - from
			var along := clampf(off.dot(way), 0.0, 1400.0)
			clear = clear and off.distance_to(way * along) > 30.0
		var seen := {}
		var m := 0.0
		while clear and m < 1400.0:
			var at := from + way * m
			var coord := world.terrain.chunk_at(at.x, at.y)
			if not seen.has(coord):
				seen[coord] = true
				for find in Finds.plan(world.run_seed, coord, 0.0, world.tuning, world.height_at,
						world.shape.ruins.in_chunk(coord)):
					var off := Vector2(find.x, find.z) - from
					clear = clear and off.distance_to(way * clampf(off.dot(way), 0.0, 1400.0)) > 2.0
			m += size * 0.5
		if clear:
			return way
	return Vector2.ZERO
