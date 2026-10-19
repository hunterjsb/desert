extends Probe
## Loot probe 1: site loot is pure per seed and site. Round six towns, every
## socket of every structure draws the same in two histories of the same
## seed, laid from places on the ground kilometres apart: the site the same,
## the sheet not. Two sites of a kind seldom draw alike; what lies within
## reach at any moment is drawn as the site holds it, whatever the weather;
## and each find carries its site's era and kind and a seed of its own (what
## the nomads left or keep, the era that made it), so made again it's given
## the same hands it passed through.

const SEED := 1234
const TOWNS := 6
## Two sites of a kind with a few sockets draw alike at most this share of the time.
const ALIKE := 0.2
## Devices made from what's within reach, twice each, for their lineage.
const MADE := 10


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var one := TerrainShape.new(SEED, tuning)
	var two := TerrainShape.new(SEED, tuning)
	var grounds := [Vector2.ONE * tuning.chunk_size * 0.5, Vector2(5032.0, -3032.0)]
	var differ := 0
	var matched := 0
	var unlike := 0
	var pairs := 0
	var off_draw := 0
	var lineage_wrong := 0
	var shared := 0
	var made := 0
	var shown := 0
	for town in StructureKit.starts_among(SEED, tuning, Sphere.point(0.0, 0.0), grounds[0], TOWNS):
		for k in 2:
			var shape: TerrainShape = [one, two][k]
			shape.sites.follow(grounds[k].x, grounds[k].y, Sphere.latitude(town), Sphere.longitude(town), 1.0,
				tuning.history_lay_m)
		var there := _structures(two)
		var by_kind := {}
		for site: Structure in _structures(one).values():
			var other: Structure = there.get(site.id)
			if other == null:
				continue
			matched += 1
			var draws := _draws(site)
			differ += int(var_to_str(draws) != var_to_str(_draws(other)))
			var seeds := {}
			for each: Dictionary in draws:
				if not each.is_empty():
					seeds[each.seed] = true
			shared += draws.filter(func(d: Dictionary) -> bool: return not d.is_empty()).size() - seeds.size()
			var seen: Array = by_kind.get(site.kind, [])
			if site.piece.sockets.size() >= 3:
				for each: Array in seen:
					pairs += 1
					unlike += int(var_to_str(each) == var_to_str(draws))
				seen.append(draws)
				by_kind[site.kind] = seen
			for moment in 3:
				site.decide(moment * 9.0 * 3600.0)
				for spec in SiteLoot.plan(site, one.height_at):
					shown += 1
					var drawn := SiteLoot.draw(site, spec.index)
					off_draw += int(drawn.id != spec.id or var_to_str(drawn.fill) != var_to_str(spec.fill))
					var made_by: bool = spec.era == site.era or (spec.get("nomads", false) or site.era == Eras.NOMAD) \
						and Eras.BUILT.has(spec.era)
					lineage_wrong += int(not made_by or spec.kind != site.kind)
					if made < MADE and spec.device:
						made += 1
						var one_body := Finds.make(spec)
						var two_body := Finds.make(spec)
						lineage_wrong += int(not one_body.has_meta(&"lineage")
							or var_to_str(one_body.get_meta(&"lineage")) != var_to_str(two_body.get_meta(&"lineage")))
						one_body.free()
						two_body.free()
				site.forget()
	print("%d structures matched in both, %d finds shown over three moments, %d pairs of a kind compared"
		% [matched, shown, pairs])
	check(matched >= 20 and differ == 0, "the same seed's sites draw the same, laid from anywhere (%d of %d differ)"
		% [differ, matched])
	check(pairs > 20 and unlike <= pairs * ALIKE, "two sites of a kind seldom draw alike (%d of %d)" % [unlike, pairs])
	check(shown > 20 and off_draw == 0, "what lies within reach is what the site holds (%d off)" % off_draw)
	check(shared == 0 and made == MADE and lineage_wrong == 0,
		"each find carries its site's era and kind and a seed of its own, made with the same hands each time (%d wrong)"
		% (lineage_wrong + shared))


## The standing structures of a laid sheet, by id.
func _structures(shape: TerrainShape) -> Dictionary:
	var out := {}
	for unit in shape.sites.units():
		for site in unit.sites:
			if site is Structure and shape.sites.covering(site.x, site.z) == site:
				out[site.id] = site
	return out


## What every socket of a site holds.
func _draws(site: Structure) -> Array:
	var out := []
	for i in site.piece.sockets.size():
		out.append(SiteLoot.draw(site, i))
	return out
