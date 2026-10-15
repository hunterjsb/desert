extends Node
## The dune look-test's numbers, headless. For each style, over several seeds
## and tiles spread across ~10 km, sampled at the collision's 1 m: the share
## of ground over 15°, 28° and 33°, the steepest, the share you could camp on
## (a shield-sized square all under 5°), and height_at's cost per call.
##   godot --headless --path . res://look/dunes/measure.tscn -- stats [styles] [seeds]
## And a top-down map, low sun from across the wind, slip faces tinted:
##   godot --headless --path . res://look/dunes/measure.tscn -- map <style> <seed> <x> <z> <size m> <m per px> <out.png>

const STYLES := ["Noise", "Ridges", "Crescents", "Scalloped", "Regions"]
const SEEDS := [1234, 7, 42, 2026]
## Tiles a side per seed, and their size and spacing, m.
const TILES := 3
const TILE := 400
const TILE_SPACING := 3000.0
## A camp needs this square all under CAMP_DEGREES: the base shield's 7 m bubble.
const CAMP_HALF := 7
const CAMP_DEGREES := 5.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args[0] == "stats":
		var styles := Array(args[1].split(",")) if args.size() > 1 else STYLES
		var seeds := Array(args[2].split(",")).map(func(s: String) -> int: return int(s)) if args.size() > 2 else SEEDS
		for style: String in styles:
			_stats(style, seeds)
	elif args[0] == "map":
		_map(args[1], int(args[2]), float(args[3]), float(args[4]), float(args[5]), float(args[6]), args[7])
	get_tree().quit()


func _shape(style: String, run_seed: int) -> TerrainShape:
	var tuning := Tuning.current()
	tuning.dune_style = STYLES.find(style)
	assert(tuning.dune_style >= 0, "no dune style %s" % style)
	return TerrainShape.new(run_seed, tuning)


func _stats(style: String, seeds: Array) -> void:
	var over := [0, 0, 0]
	var limits := [tan(deg_to_rad(15.0)), tan(deg_to_rad(28.0)), tan(deg_to_rad(33.0))]
	var steepest := 0.0
	var total := 0
	var camp := 0
	var camp_total := 0
	var relief := 0.0
	for run_seed: int in seeds:
		var shape := _shape(style, run_seed)
		for tj in TILES:
			for ti in TILES:
				var x0 := (ti - 1) * TILE_SPACING
				var z0 := (tj - 1) * TILE_SPACING
				var n := TILE + 2
				var h := PackedFloat32Array()
				h.resize(n * n)
				for j in n:
					for i in n:
						h[j * n + i] = shape.height_at(x0 + i - 1, z0 + j - 1)
				var low := INF
				var high := -INF
				# Slope as the mesh's normals see it: central differences over 1 m samples.
				var grade := PackedFloat32Array()
				grade.resize(TILE * TILE)
				for j in TILE:
					for i in TILE:
						var k := (j + 1) * n + i + 1
						var g := Vector2(h[k + 1] - h[k - 1], h[k + n] - h[k - n]).length() * 0.5
						grade[j * TILE + i] = g
						for b in 3:
							if g > limits[b]:
								over[b] += 1
						steepest = maxf(steepest, g)
						low = minf(low, h[k])
						high = maxf(high, h[k])
				total += TILE * TILE
				relief = maxf(relief, high - low)
				var sites := _camp_sites(grade)
				camp += sites.x
				camp_total += sites.y
	var cost := _cost(_shape(style, SEEDS[0]))
	var reference := _cost(_shape("Noise", SEEDS[0]))
	var builds := _builds(_shape(style, SEEDS[0]))
	print("%-10s %5.1f km²  >15° %5.2f%%  >28° %5.2f%%  >33° %5.3f%%  max %4.1f°  camp %5.1f%%  relief %5.1f m  %5.2f µs/call (%.1fx)  near chunk %3.0f ms  far ring %4.0f ms"
		% [style, total / 1e6, 100.0 * over[0] / total, 100.0 * over[1] / total, 100.0 * over[2] / total,
			rad_to_deg(atan(steepest)), 100.0 * camp / camp_total, relief, cost, cost / reference, builds.x, builds.y])


## Of the points with a whole camp square inside the tile, how many have it all under CAMP_DEGREES.
func _camp_sites(grade: PackedFloat32Array) -> Vector2i:
	var limit := tan(deg_to_rad(CAMP_DEGREES))
	var flat := PackedByteArray()
	flat.resize(TILE * TILE)
	for k in grade.size():
		flat[k] = 1 if grade[k] < limit else 0
	# Running sums, so each square's count is four lookups.
	var w := TILE + 1
	var sums := PackedInt32Array()
	sums.resize(w * w)
	for j in TILE:
		var row := 0
		for i in TILE:
			row += flat[j * TILE + i]
			sums[(j + 1) * w + i + 1] = sums[j * w + i + 1] + row
	var side := 2 * CAMP_HALF + 1
	var good := 0
	var all := 0
	for j in range(0, TILE - side, 2):
		for i in range(0, TILE - side, 2):
			var count := sums[(j + side) * w + i + side] - sums[j * w + i + side] - sums[(j + side) * w + i] + sums[j * w + i]
			all += 1
			if count == side * side:
				good += 1
	return Vector2i(good, all)


## Microseconds per height_at at scattered points, best of three.
func _cost(shape: TerrainShape) -> float:
	var best := INF
	for round in 3:
		var started := Time.get_ticks_usec()
		for i in 50000:
			shape.height_at(i * 7.31 - 9000.0, i * 3.17 + 500.0)
		best = minf(best, (Time.get_ticks_usec() - started) / 50000.0)
	return best


## A worker's time to build one near chunk and one far ring, ms.
func _builds(shape: TerrainShape) -> Vector2:
	var tuning := Tuning.current()
	var indices := ChunkBuild.indices_for(tuning.chunk_size)
	var started := Time.get_ticks_usec()
	for i in 4:
		ChunkBuild.make(shape, Vector2i(i, 3), tuning.chunk_size, 1, tuning.skirt_depth, indices)
	var near := (Time.get_ticks_usec() - started) / 4000.0
	started = Time.get_ticks_usec()
	FarRing.make(shape, Vector2i(2, 5), tuning)
	return Vector2(near, (Time.get_ticks_usec() - started) / 1000.0)


func _map(style: String, run_seed: int, x0: float, z0: float, size: float, per_px: float, out: String) -> void:
	var shape := _shape(style, run_seed)
	var px := int(size / per_px)
	var n := px + 2
	var h := PackedFloat32Array()
	h.resize(n * n)
	for j in n:
		for i in n:
			h[j * n + i] = shape.height_at(x0 + (i - 1) * per_px, z0 + (j - 1) * per_px)
	var down := Vector2.from_angle(WeatherField.mean_heading(run_seed))
	# Low sun from across the wind, so ridges and slip faces both show.
	var sun := Vector3(-down.y, 0.0, down.x).rotated(Vector3.UP, 0.4)
	sun = (sun * cos(deg_to_rad(30.0)) + Vector3.UP * sin(deg_to_rad(30.0))).normalized()
	var image := Image.create(px, px, false, Image.FORMAT_RGB8)
	var slip := tan(deg_to_rad(28.0))
	for j in px:
		for i in px:
			var k := (j + 1) * n + i + 1
			var gx := (h[k + 1] - h[k - 1]) / (2.0 * per_px)
			var gz := (h[k + n] - h[k - n]) / (2.0 * per_px)
			var normal := Vector3(-gx, 1.0, -gz).normalized()
			var light := clampf(normal.dot(sun) / sun.y, 0.0, 2.0) * 0.45 + 0.3
			var colour := Color(0.86, 0.72, 0.52) * light
			if Vector2(gx, gz).length() > slip:
				colour = colour.lerp(Color(0.85, 0.25, 0.15), 0.45)
			image.set_pixel(i, j, colour)
	image.save_png(out)
	print("map %s seed %d: %s, downwind (%.2f, %.2f), heights %.1f to %.1f m" % [style, run_seed, out,
		down.x, down.y, Array(h).min(), Array(h).max()])
