extends MovementProbe
## Runs alone
## World & terrain probe 16: walking the open desert in live weather, among
## history's sites, with a storm's wall in view, the main thread's CPU stays
## inside its frame budget: ground streaming, sites, sky, weather and the
## storm's drawing together. Linux user+system CPU of the main thread over 15
## s of 60 Hz frames, as the large-camp budgets read it; elsewhere only the
## walk is checked.

const BUDGET_MS := 3.6
const FRAMES := 900

var _clock_hz := 0.0


func run() -> void:
	await load_world(1234, false, true)
	player = world.player
	hold([])
	var field := world.weather.field
	var start := _storm_in_view(field)
	check(not is_nan(start), "a storm's wall in view")
	if is_nan(start):
		return
	world.time = start
	world.weather.forecast_now()
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	await place(world.player_world_x(), world.player_world_z(), down)
	Engine.max_fps = 60
	var output := []
	if OS.get_name() == "Linux" and OS.execute("getconf", ["CLK_TCK"], output) == 0:
		_clock_hz = float(output[0])
	hold(["move_forward", "sprint"])
	for i in 120:
		await get_tree().process_frame
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var cpu := _main_cpu_ms()
	for i in FRAMES:
		await get_tree().process_frame
	var per_frame := (_main_cpu_ms() - cpu) / FRAMES
	var walked := Vector2(world.player_world_x(), world.player_world_z()).distance_to(from)
	hold([])
	print("WALK main_cpu=%.3f ms/frame walked=%.0f m wall %.0f m off" % [per_frame, walked, -world.weather.seen_front])
	check(walked > FRAMES / 60.0 * 2.0, "you walked (%.0f m)" % walked)
	check(world.weather.seen_front > -INF, "the wall stayed in view")
	if _clock_hz > 0.0:
		metric("Walk in weather main-thread CPU per frame", per_frame, "ms", BUDGET_MS)
		check(per_frame < BUDGET_MS, "the walk stays inside its frame budget (%.2f ms)" % per_frame)


## The first moment in two days with clear air where you stand and storm
## fronts within sight in at least 8 of 16 directions.
func _storm_in_view(field: WeatherField) -> float:
	var x := world.player_world_x()
	var z := world.player_world_z()
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0:
		if field.storm_at(x, z, t) == 0.0 and _fronts(field, x, z, t) >= 8:
			return t
		t += 60.0
	return NAN


func _fronts(field: WeatherField, x: float, z: float, t: float) -> int:
	var seen := 0
	for i in 16:
		var dir := Vector2.from_angle(TAU * i / 16.0)
		var d := 200.0
		while d < 3000.0:
			if field.raw_storm_at(x + dir.x * d, z + dir.y * d, t) > 0.0:
				seen += 1
				break
			d += 100.0
	return seen


func _main_cpu_ms() -> float:
	if _clock_hz <= 0.0:
		return -1.0
	var file := FileAccess.open("/proc/thread-self/stat", FileAccess.READ)
	var stat := file.get_buffer(4096).get_string_from_utf8() if file != null else ""
	var fields := stat.substr(stat.rfind(") ") + 2).split(" ", false)
	if fields.size() < 13:
		return -1.0
	return (float(fields[11]) + float(fields[12])) * 1000.0 / _clock_hz
