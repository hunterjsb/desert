extends Probe
## Salvage & ruins probe 5: harder weather, better finds. Across thousands of
## chunks loaded at moments through three days on two seeds, the run's own
## weather read as each chunk would read it, the average find's tier rises
## with how hard the weather has been: from the calmest third to the middle
## to the hardest. A chunk a storm has sat on all of the last hours shows more
## of the deep layer than one a storm has touched for half of them or less.

const SEEDS := [1234, 7]
const CHUNKS_PER_SEED := 1500
## The hardest third must beat the calmest by at least this much tier.
const RISE := 0.15
## A storm touched a calm chunk for at most this share of the hours.
const CALM := 0.5


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var samples: Array[Vector2] = []
	var stormed := [0, 0]
	var calm := [0, 0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for run_seed: int in SEEDS:
		var shape := TerrainShape.new(run_seed, tuning)
		var field := WeatherField.new(run_seed, tuning)
		for n in CHUNKS_PER_SEED:
			var coord := Vector2i(rng.randi_range(-150, 150), rng.randi_range(-150, 150))
			var middle := (Vector2(coord) + Vector2.ONE * 0.5) * tuning.chunk_size
			var t := rng.randf() * 3.0 * 24.0 * 3600.0
			var exposed := Finds.exposure(field, middle.x, middle.y, t, tuning)
			var specs := Finds.plan(run_seed, coord, exposed, tuning, shape.height_at, shape.ruins.in_chunk(coord))
			for spec in specs:
				samples.append(Vector2(exposed, Finds.tier(spec)))
			# The two ends of the weather, read straight from the field.
			var hours := _hours(field, middle, t, tuning)
			var into: Array = stormed if hours == 1.0 else (calm if hours <= CALM else [])
			for spec in specs:
				if not into.is_empty():
					into[0] += Finds.tier(spec) - 1
					into[1] += 1
	samples.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var thirds: Array[float] = []
	for k in 3:
		var part := samples.slice(samples.size() * k / 3, samples.size() * (k + 1) / 3)
		var sum := 0.0
		for each in part:
			sum += each.y
		thirds.append(sum / part.size())
	var exposure_range := [samples[0].x, samples[samples.size() / 2].x, samples[-1].x]
	print("%d finds; exposure from %.2f through %.2f to %.2f; mean tier by third %.3f, %.3f, %.3f" % [samples.size(),
		exposure_range[0], exposure_range[1], exposure_range[2], thirds[0], thirds[1], thirds[2]])
	var deep_stormed := float(stormed[0]) / maxi(stormed[1], 1)
	var deep_calm := float(calm[0]) / maxi(calm[1], 1)
	print("deep share after hours of storm %.2f (%d finds), after hours mostly clear %.2f (%d finds)"
		% [deep_stormed, stormed[1], deep_calm, calm[1]])
	check(samples.size() > CHUNKS_PER_SEED, "chunks have finds (%d)" % samples.size())
	check(thirds[0] < thirds[1] and thirds[1] < thirds[2], "the average tier rises with exposure, third by third")
	check(thirds[2] - thirds[0] >= RISE, "the hardest third beats the calmest by %.2f tier (%.3f)" % [RISE, thirds[2] - thirds[0]])
	check(stormed[1] >= 50 and calm[1] >= 50, "both ends of the weather were met (%d stormed, %d calm)" % [stormed[1], calm[1]])
	check(deep_stormed > deep_calm + RISE, "hours under a storm show more of the deep layer than hours mostly clear")


## The share of the hours a chunk's exposure reads that a storm sat on it.
func _hours(field: WeatherField, at: Vector2, t: float, tuning: Tuning) -> float:
	var step := tuning.exposure_step_minutes * 60.0
	var last := floorf(t / step) * step
	var count := roundi(tuning.exposure_hours * 60.0 / tuning.exposure_step_minutes)
	var stormy := 0
	for k in count:
		stormy += 1 if field.raw_storm_at(at.x, at.y, last - k * step) > 0.0 else 0
	return float(stormy) / count
