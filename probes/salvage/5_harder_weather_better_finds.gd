extends Probe
## Salvage & ruins probe 5: harder weather, better finds, the expedition.
## History's structures round towns on two worlds, each read at moments
## through three days and at its storm's height, the moment in a day a storm
## worked hardest on it: at the moment the storms had taken the most sand off
## it, more of a site's loot is within reach than at the moment they'd taken
## the least, and better; an era's best lies only where a storm stripped
## past. Every kind a site's tables hold
## turns up, over the sites history put round the great sites and the Rim.
## And open sand's few loose finds still come from the deep layer where the
## weather has been hard.

const SEEDS := [1234, 7]
const TOWNS := 6
## Moments each structure is read at.
const MOMENTS := 6
## The most stripped moments must show this many times what the least did,
## and this much better a find. A site coming out of the sand shows what
## stands proud of it on the way, so the least stripped already show some.
const MORE := 1.12
const RISE := 0.03
## Sites drawn round each of these landmarks for every kind to turn up, m.
const AROUND: Array[StringName] = [&"halloran", &"black_site", &"port_morgan", &"halfrise", &"starcom"]
const AROUND_M := 6000.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	# [finds, tiers] at each site's least stripped moment, then its most.
	var ends := [0, 0, 0, 0]
	var sites := 0
	var early := 0
	var loose := [0, 0, 0, 0]
	var drawn := {}
	for run_seed: int in SEEDS:
		var shape := TerrainShape.new(run_seed, tuning)
		var field := WeatherField.new(run_seed, tuning)
		for town in StructureKit.starts_among(run_seed, tuning, Sphere.point(0.0, 0.0), ground, TOWNS):
			shape.sites.follow(ground.x, ground.y, Sphere.latitude(town), Sphere.longitude(town), 1.0, tuning.history_lay_m)
			for unit in shape.sites.units():
				for site in unit.sites:
					if not site is Structure or shape.sites.covering(site.x, site.z) != site:
						continue
					sites += 1
					var readings: Array[Vector3] = []
					var moments := []
					for k in MOMENTS:
						moments.append(rng.randf() * 3.0 * 24.0 * 3600.0)
					var extremes := _storm_range(field, site, tuning)
					moments.append(extremes.x)
					moments.append(extremes.y)
					for moment: float in moments:
						site.decide(moment)
						var found := SiteLoot.plan(site, shape.height_at)
						var tiers := 0
						for spec in found:
							tiers += Finds.tier(spec)
							var socket: StructureKit.SiteSocket = site.piece.sockets[spec.index]
							early += int(socket.deep > 0.0 and site.taken() < site.depth * (1.0 + socket.deep))
						readings.append(Vector3(site.taken(), found.size(), tiers))
						site.forget()
					readings.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)
					ends[0] += readings[0].y
					ends[1] += readings[0].z
					ends[2] += readings[-1].y
					ends[3] += readings[-1].z
			_loose(shape, run_seed, tuning, loose)
		_drawn(shape.history, drawn)
	_verdict(sites, ends, drawn, early, loose)


## Least and most stripped in the first day, including calm after a wake.
func _storm_range(field: WeatherField, site: Site, tuning: Tuning) -> Vector2:
	var memo := Exposure.Memo.new()
	var most := -1.0
	var at := 0
	var least := INF
	var low := 0
	for m in 24 * 60:
		var s := Exposure.taken(field, site.x, site.z, (m + 1) * Exposure.SURGE_STEP_S, tuning, memo, site.dune)
		if s < least:
			least = s
			low = m
		if s > most:
			most = s
			at = m
	return Vector2(low + 1, at + 1) * Exposure.SURGE_STEP_S


## Every socket of history's built sites round the great sites, drawn.
func _drawn(history: History, into: Dictionary) -> void:
	for id in AROUND:
		for cell in history.cells.within(history.landmark(id).p, AROUND_M):
			for each in history.sites_in_cell(cell):
				var piece := StructureKit.piece(each.kind)
				if piece == null:
					continue
				var site := Site.new()
				for key: String in ["id", "kind", "era", "loot", "region"]:
					site.set(key, each[key])
				for i in piece.sockets.size():
					var spec := SiteLoot.draw(site, i)
					if not spec.is_empty():
						into[spec.id] = into.get(spec.id, 0) + 1


## Open sand's loose finds round where the sheet is laid, in the calmest
## weather and the hardest, into [deep, all, deep, all].
func _loose(shape: TerrainShape, run_seed: int, tuning: Tuning, tally: Array) -> void:
	var on_way := func(x: float, z: float) -> bool: return Finds.on_way(shape.sites, x, z, tuning.finds_scatter_m)
	var reach := floori(tuning.history_lay_m / tuning.chunk_size) - 1
	for j in range(-reach, reach + 1, 2):
		for i in range(-reach, reach + 1, 2):
			for k in 2:
				for spec in Finds.plan(run_seed, Vector2i(i, j), float(k), tuning, shape.height_at, on_way):
					tally[k * 2] += Finds.tier(spec) - 1
					tally[k * 2 + 1] += 1


func _verdict(sites: int, ends: Array, drawn: Dictionary, early: int, loose: Array) -> void:
	var calm_tier := float(ends[1]) / maxi(ends[0], 1)
	var hard_tier := float(ends[3]) / maxi(ends[2], 1)
	print("%d sites: at each one's least stripped moment %d finds within reach, mean tier %.3f; at its most, %d, %.3f"
		% [sites, ends[0], calm_tier, ends[2], hard_tier])
	check(sites > 100, "sites read (%d)" % sites)
	check(ends[2] >= ends[0] * MORE, "more lies within reach the more the storms took off (%d against %d)" % [ends[2], ends[0]])
	check(hard_tier >= calm_tier + RISE, "and it's better (%.3f against %.3f)" % [hard_tier, calm_tier])
	check(early == 0, "an era's best only where a storm stripped past it (%d sooner)" % early)
	var missing: Array[StringName] = []
	for id in SiteLoot.ids():
		if not drawn.has(id):
			missing.append(id)
	print("drawn round the great sites: %s" % drawn)
	check(missing.is_empty(), "every kind a site holds turns up (never: %s)" % ", ".join(missing))
	var calm := float(loose[0]) / maxi(loose[1], 1)
	var hard := float(loose[2]) / maxi(loose[3], 1)
	print("loose finds on the way: deep share %.2f of %d calm, %.2f of %d in the hardest weather" % [calm, loose[1],
		hard, loose[3]])
	check(loose[1] >= 20 and hard > calm + 0.3, "loose finds come from the deep layer where the weather was hard")
