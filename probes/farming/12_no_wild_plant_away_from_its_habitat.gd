extends FeralProbe
## Farming probe 12: no wild plant grows away from its habitat. At the run's
## start in open desert, then on a pilgrim road out of Sister and 2 km on
## over the Rim, every wild plant laid out stands on its habitat: one
## of a road's or a water line's within its row's reach of a laid line of the
## kind it grows along, one of a site's within its spread of a laid site of
## its kinds. Desert no habitat reaches stays empty.

const HOPS := 5
const HOP := 450.0


func run() -> void:
	await load_world(1234, true, true)
	feral = world.farm.feral
	await laid_out()
	var at_start := planned().size()
	print("at the start, in open desert: %d wild plants" % at_start)
	check(at_start == 0, "the open desert round the start holds none")
	await on_path(&"pilgrim_road")
	var seen := 0
	var away := 0
	var empty := 0
	var x := world.player_world_x()
	var z := world.player_world_z()
	for hop in HOPS + 1:
		if hop > 0:
			teleport(x + HOP * hop, z - HOP * 0.4 * hop)
			await laid_out()
		var plants := planned()
		seen += plants.size()
		var lines := {}
		for r in Feral.HABITATS.size():
			if Feral.HABITATS[r].has("along"):
				lines[r] = pieces_for(Feral.HABITATS[r])
		for each: Dictionary in plants:
			if not _on_habitat(each, lines):
				away += 1
		for chunk: TerrainChunk in world.terrain.chunks():
			empty += 1 if feral.plants_in(chunk.coord).is_empty() else 0
	print("%d wild plants seen, %d away from their habitat; %d chunk looks were empty" % [seen, away, empty])
	check(seen > 300, "wild plants grow along the way (%d)" % seen)
	check(away == 0, "none away from its habitat (%d)" % away)
	check(empty > seen / 10, "and most ground holds none")


func _on_habitat(each: Dictionary, lines: Dictionary) -> bool:
	var row: Dictionary = Feral.HABITATS[each.row]
	var at := Vector2(each.x, each.z)
	if row.has("along"):
		var pieces: Array[Sites.Piece] = lines[each.row]
		return off_line(at, pieces) <= row.side.y + row.get("spread", 0.0) + 0.6
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if Feral._stands_at(row.at, site) and Vector2(site.x, site.z).distance_to(at) <= row.spread + 0.01:
				return true
	return false
