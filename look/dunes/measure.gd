extends Node
## The dunes' numbers, headless. Over several seeds and tiles spread across
## ~10 km, sampled at the collision's 1 m: the share of ground over 15°, 28°
## and 33°, the steepest, the share you could camp on (a shield-sized square
## all under 5°), and what the ground costs to compute.
##   godot --headless --path . res://look/dunes/measure.tscn -- stats [seeds]
## And a top-down map, low sun from across the wind, slip faces tinted:
##   godot --headless --path . res://look/dunes/measure.tscn -- map <seed> <x> <z> <size m> <m per px> <out.png>

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
		_stats(Array(args[1].split(",")).map(func(s: String) -> int: return int(s)) if args.size() > 1 else SEEDS)
	elif args[0] == "map":
		_map(int(args[1]), float(args[2]), float(args[3]), float(args[4]), float(args[5]), args[6])
	get_tree().quit()


func _stats(seeds: Array) -> void:
	var over := [0, 0, 0]
	var limits := [tan(deg_to_rad(15.0)), tan(deg_to_rad(28.0)), tan(deg_to_rad(33.0))]
	var steepest := 0.0
	var total := 0
	var camp := 0
	var camp_total := 0
	var relief := 0.0
	for run_seed: int in seeds:
		var shape := TerrainShape.new(run_seed, Tuning.current())
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
	var shape := TerrainShape.new(SEEDS[0], Tuning.current())
	var builds := _builds(shape)
	print("%.1f km²  >15° %5.2f%%  >28° %5.2f%%  >33° %5.3f%%  max %4.1f°  camp %5.1f%%  relief %5.1f m" % [total / 1e6,
		100.0 * over[0] / total, 100.0 * over[1] / total, 100.0 * over[2] / total, rad_to_deg(atan(steepest)),
		100.0 * camp / camp_total, relief])
	print("height_at %.2f µs on a lattice point, %.2f µs between; a near chunk %.0f ms, a mid chunk %.0f ms, the far ring %.0f ms"
		% [_cost(shape, 1.0), _cost(shape, 0.37), builds.x, builds.y, builds.z])


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


## Microseconds per height_at at scattered points `step` m apart, best of three.
func _cost(shape: TerrainShape, step: float) -> float:
	var best := INF
	for round in 3:
		var started := Time.get_ticks_usec()
		for i in 50000:
			shape.height_at(-9000.0 + i * 7.0 * step, 500.0 + i * 3.0 * step)
		best = minf(best, (Time.get_ticks_usec() - started) / 50000.0)
	return best


## A worker's time to build a near chunk, a mid chunk and the far ring, ms.
func _builds(shape: TerrainShape) -> Vector3:
	var tuning := Tuning.current()
	var size := tuning.chunk_size
	var took := Vector3()
	for k in 2:
		var step := 1 if k == 0 else tuning.mid_step
		var indices := ChunkBuild.indices_for(size / step)
		var started := Time.get_ticks_usec()
		for i in 4:
			ChunkBuild.make(shape, Vector2i(i, 3), size, step, tuning.skirt_depth, indices)
		took[k] = (Time.get_ticks_usec() - started) / 4000.0
	var started := Time.get_ticks_usec()
	FarRing.make(shape, Vector2i(2, 5), tuning)
	took.z = (Time.get_ticks_usec() - started) / 1000.0
	return took


func _map(run_seed: int, x0: float, z0: float, size: float, per_px: float, out: String) -> void:
	var shape := TerrainShape.new(run_seed, Tuning.current())
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
	var sand := Tuning.current().sand_color
	for j in px:
		for i in px:
			var k := (j + 1) * n + i + 1
			var gx := (h[k + 1] - h[k - 1]) / (2.0 * per_px)
			var gz := (h[k + n] - h[k - n]) / (2.0 * per_px)
			var normal := Vector3(-gx, 1.0, -gz).normalized()
			var light := clampf(normal.dot(sun) / sun.y, 0.0, 2.0) * 0.45 + 0.3
			var colour := sand * light
			if Vector2(gx, gz).length() > slip:
				colour = colour.lerp(Color(0.85, 0.25, 0.15), 0.45)
			image.set_pixel(i, j, colour)
	image.save_png(out)
	print("map seed %d: %s, downwind (%.2f, %.2f), heights %.1f to %.1f m" % [run_seed, out,
		down.x, down.y, Array(h).min(), Array(h).max()])
