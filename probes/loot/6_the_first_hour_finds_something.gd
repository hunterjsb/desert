extends Probe
## Loot probe 6: each origin's first hour finds something within reach. On
## six worlds, from each origin's start, what history's sites hold within a
## fair walk, as each would lie when you'd walked there, and the loose finds
## on the way: there's always something worth finding, water, food, a
## survival kit or a device, nearer than a fair walk. The Surveyor's walk is
## in toward Tu to the line it starts off; the others' are short.

const SEEDS := [1234, 1, 2, 42, 777, 1001]
## A fair walk, m: the Surveyor's line is never farther (Spawns).
const FAIR := 3000.0
const WORTH: Array[StringName] = [&"canister", &"ration", &"tubers", &"root_tuber", &"vat_fungus", &"saltbush",
	&"saltbush_leaves", &"fungus_caps"]


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var lay := tuning.history_lay_m
	tuning.history_lay_m = FAIR + 200.0
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	var missing := PackedStringArray()
	for s: int in SEEDS:
		var shape := TerrainShape.new(s, tuning)
		for kit in Kit.origins():
			var at := Starts.find(shape, kit.start, tuning)
			shape.sites.follow(ground.x, ground.y, Sphere.latitude(at), Sphere.longitude(at), 1.0, INF)
			var best := _nearest(shape, ground, tuning)
			if best.is_empty():
				missing.append("seed %d, the %s" % [s, kit.label])
				print("seed %4d %-11s nothing within %.0f m" % [s, kit.label, FAIR])
			else:
				print("seed %4d %-11s %4.0f m: %s, %s (%d finds within %.0f m, %d loose)" % [s, kit.label, best.m,
					best.id, best.where, best.count, FAIR, best.loose])
	tuning.history_lay_m = lay
	check(missing.is_empty(), "every origin finds something worth finding within %.0f m (none for %s)"
		% [FAIR, ", ".join(missing)])


## The nearest thing worth finding within a fair walk, as you'd find it when
## you'd walked there: {m, id, where, count, loose}, or {}.
func _nearest(shape: TerrainShape, ground: Vector2, tuning: Tuning) -> Dictionary:
	var best := {}
	var count := 0
	var loose := 0
	for unit in shape.sites.units():
		for site in unit.sites:
			var m := site.distance_to(ground.x, ground.y)
			if not site is Structure or m > FAIR or shape.sites.covering(site.x, site.z) != site:
				continue
			site.decide(m / tuning.walk_speed)
			for spec in SiteLoot.plan(site, shape.height_at):
				count += 1
				if _worth(spec) and (best.is_empty() or m < best.m):
					best = {"m": m, "id": spec.id, "where": "%s %s" % [Exposure.NAMES[site.state()], site.kind]}
			site.forget()
	var on_way := func(x: float, z: float) -> bool: return Finds.on_way(shape.sites, x, z, tuning.finds_scatter_m)
	var on_site := func(x: float, z: float) -> bool: return shape.sites.covering(x, z) != null
	var reach := ceili(FAIR / tuning.chunk_size)
	for j in range(-reach, reach + 1):
		for i in range(-reach, reach + 1):
			var coord := Vector2i(i, j)
			var middle := (Vector2(coord) + Vector2.ONE * 0.5) * tuning.chunk_size
			var m := middle.distance_to(ground)
			if m > FAIR:
				continue
			for spec in Finds.plan(shape.history.run_seed, coord, 0.5, tuning, shape.height_at, on_way, on_site):
				loose += 1
				if _worth(spec) and (best.is_empty() or m < best.m):
					best = {"m": m, "id": spec.id, "where": "loose on the way"}
	if not best.is_empty():
		best.count = count
		best.loose = loose
	return best


func _worth(spec: Dictionary) -> bool:
	return spec.device or spec.id in WORTH or spec.fill.any(func(f: Array) -> bool: return f[1] in WORTH)
