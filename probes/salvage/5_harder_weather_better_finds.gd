extends Probe
## Salvage & ruins probe 5: harder weather, better finds. Across thousands of
## chunks loaded at moments through three days on two seeds, the run's own
## weather read as each chunk would read it, the average find's tier rises
## with how hard the weather has been: from the calmest third to the middle
## to the hardest. A chunk a storm has sat on all of the last hours shows more
## of the deep layer than one a storm has touched for half of them or less.
## And every kind the sand holds turns up: rope and wire commonly, seeds mostly
## on ruins' floors (loose and in survival kits), the harvester rarely.

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
				_tally(spec)
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
	var where := func(id: StringName) -> String:
		return "%d (%d on ruins' floors)" % [_kinds.get(id, [0, 0])[0], _kinds.get(id, [0, 0])[1]]
	print(("of %d finds: %s coils, %s plugs, %s strong plugs, %s survival kits, %s harvesters, %s radios, "
		+ "%s compasses; seeds %d on open sand, %d in ruins") % [samples.size(), where.call(&"coil"),
			where.call(&"plug"), where.call(&"strong_plug"), where.call(&"survival_kit"), where.call(&"harvester"),
			where.call(&"radio"), where.call(&"compass"), _seeds[0], _seeds[1]])
	var missing: Array[StringName] = []
	for layer: StringName in Finds.PARTS:
		for table: Array in [Finds.PARTS[layer], Finds.DEVICES[layer], Finds.IN_RUINS[layer].parts, Finds.IN_RUINS[layer].devices]:
			for entry: Array in table:
				if _kinds.get(entry[0], [0, 0])[0] == 0 and not missing.has(entry[0]):
					missing.append(entry[0])
	check(missing.is_empty(), "every kind the sand holds turns up (never: %s)" % ", ".join(missing))
	check(_kinds[&"coil"][0] > samples.size() / 20 and _kinds[&"plug"][0] > samples.size() / 20,
		"rope and wire are common finds")
	check(_seeds[1] > _seeds[0], "seeds are mostly found in ruins (%d against %d)" % [_seeds[1], _seeds[0]])
	var commoner := 0
	for layer: StringName in Finds.PARTS:
		for entry: Array in Finds.PARTS[layer]:
			commoner += int(entry[0] != &"harvester" and _kinds.get(entry[0], [0, 0])[0] > _kinds[&"harvester"][0])
	check(commoner == Finds.PARTS[Finds.SURFACE].size() + Finds.PARTS[Finds.DEEP].size() - 1,
		"the harvester is the rarest part on open sand")


## Finds by kind, [all, on ruins' floors], and seeds [on open sand, in ruins],
## loose or in a kit.
var _kinds := {}
var _seeds := [0, 0]


func _tally(spec: Dictionary) -> void:
	var in_ruin := int(spec.has("floor"))
	var count: Array = _kinds.get(spec.id, [0, 0])
	count[0] += 1
	count[1] += in_ruin
	_kinds[spec.id] = count
	var held: Array = [spec.id] + spec.fill.map(func(f: Array) -> StringName: return f[1])
	for id: StringName in held:
		if id in [&"root_tuber", &"vat_fungus"]:
			_seeds[in_ruin] += 1


## The share of the hours a chunk's exposure reads that a storm sat on it.
func _hours(field: WeatherField, at: Vector2, t: float, tuning: Tuning) -> float:
	var step := tuning.exposure_step_minutes * 60.0
	var last := floorf(t / step) * step
	var count := roundi(tuning.exposure_hours * 60.0 / tuning.exposure_step_minutes)
	var stormy := 0
	for k in count:
		stormy += 1 if field.raw_storm_at(at.x, at.y, last - k * step) > 0.0 else 0
	return float(stormy) / count
