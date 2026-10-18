extends SalvageProbe
## Loot probe 2: the sand decides what's within reach. Every kind of
## structure, laid by hand where the weather comes and goes, read buried,
## partly exposed and dug out. Buried, nothing it holds under the sand lies
## within reach, only what stands on top of it (a watchtower's platform, a
## house's hall). Partly exposed, some of it, half in the sand that fills it.
## Dug out, all of it but what stands higher than a hand reaches; and what
## lies deeper than the rest of a site only once a storm has stripped past
## it, so a revisit after a storm finds more. In the world, at a house ruin
## dug out, your hands take what lies on its floor.

const SEED := 1234
const EACH := 12
## Searched for a moment the storms had taken this much off, m.
const STRIPPED := 1.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(SEED, tuning)
	var field := WeatherField.new(SEED, tuning)
	shape.sites.follow(32.0, 32.0, 0.0, 0.0, 1.0, tuning.history_lay_m)
	var under := 0
	var drawn := [0, 0, 0]
	var shown := [0, 0, 0]
	var short := PackedStringArray()
	var deep := [0, 0, 0]
	var k := 0
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		var kind_drawn := 0
		var kind_shown := 0
		for n in EACH:
			var site := _standing(shape, kind, k)
			k += 1
			var t := _stripped_moment(field, site, tuning)
			var taken := Exposure.stripped(field, site.x, site.z, t, tuning)
			# As deep as makes each state, and between a deep socket's depth and past it.
			for state in 3:
				site.depth = [taken * 4.0, taken * 1.5, taken * 0.5][state]
				var found := _read(site, t, shape)
				drawn[state] += _drawn(site)
				shown[state] += found.size()
				if state == Exposure.BURIED:
					under += found.filter(func(spec: Dictionary) -> bool: return spec.bury > 0.0).size()
				if state == Exposure.EXPOSED:
					kind_drawn += _drawn(site)
					kind_shown += found.size()
			for i in piece.sockets.size():
				if piece.sockets[i].deep <= 0.0 or SiteLoot.draw(site, i).is_empty():
					continue
				deep[0] += 1
				site.depth = taken / (1.0 + piece.sockets[i].deep * 0.5)
				deep[1] += int(_read(site, t, shape).any(func(spec: Dictionary) -> bool: return spec.index == i))
				site.depth = taken / (1.0 + piece.sockets[i].deep * 2.0)
				deep[2] += int(_read(site, t, shape).any(func(spec: Dictionary) -> bool: return spec.index == i))
		# The watchtower's platform stands higher than a hand reaches, dug out.
		if kind_shown < kind_drawn and not (kind == &"watchtower" and kind_shown * 4 >= kind_drawn * 3):
			short.append("%s %d of %d" % [kind, kind_shown, kind_drawn])
	print("buried, partly exposed and dug out, of what the sites held: shown %d of %d, %d of %d, %d of %d; deep sockets %d, reached short of a storm past them %d, past it %d"
		% [shown[0], drawn[0], shown[1], drawn[1], shown[2], drawn[2], deep[0], deep[1], deep[2]])
	check(under == 0 and shown[0] < drawn[0] / 4, "buried, nothing under the sand is within reach (%d were)" % under)
	check(shown[1] > shown[0] and shown[1] < shown[2], "partly exposed, some of it")
	check(short.is_empty(), "dug out, all of it within a hand's reach (short: %s)" % ", ".join(short))
	check(deep[0] > 20 and deep[1] == 0 and deep[2] == deep[0],
		"what lies deeper only once a storm has stripped past it")
	await _taken_by_hand()


## In front of a house ruin dug out, a find on its floor comes to your hands.
func _taken_by_hand() -> void:
	await load_salvage()
	world.time_warp = 0.0
	var ruin := await go_looking()
	var on_floor := salvage.finds().filter(func(b: RigidBody3D) -> bool:
		return b.get_meta(&"find").size() > 2 and b.get_meta(&"find")[2] == ruin.id and b is Part)
	check(not on_floor.is_empty(), "a part lies on its floor")
	if on_floor.is_empty():
		return
	var find: RigidBody3D = on_floor[0]
	var middle := find.global_transform * Finds.bounds(find).get_center()
	await go(world.world_x(middle.x) + 0.9, world.world_z(middle.z))
	look(Vector3(middle.x + 0.9, middle.y + 1.0, middle.z), middle)
	await simulate(1.0 / 60.0)
	check(hands.grab() and not find.has_meta(&"find"), "your hands take it, and it's yours")


## A structure of a kind standing by hand where the dunes take it.
func _standing(shape: TerrainShape, kind: StringName, k: int) -> Structure:
	var site: Structure = null
	for tries in 60:
		site = shape.sites.by_hand(kind, 3000.0 + (k % 12) * 120.0 + tries * 31.0, 2000.0 + (k / 12) * 120.0,
			0.4 * k, 1.0, 0.3)
		if site.stands():
			break
	shape.sites.add(site)
	return site


## A moment the storms had stripped a place hard, within three days.
func _stripped_moment(field: WeatherField, site: Site, tuning: Tuning) -> float:
	var step := tuning.site_exposure_step_minutes * 60.0
	var best := 0.0
	var most := -1.0
	for n in 144:
		var taken := Exposure.stripped(field, site.x, site.z, n * step, tuning)
		if taken > most:
			most = taken
			best = n * step
		if taken >= STRIPPED:
			break
	return best


## What lies within reach at a structure read at a moment.
func _read(site: Structure, t: float, shape: TerrainShape) -> Array[Dictionary]:
	site.decide(t)
	var found := SiteLoot.plan(site, shape.height_at)
	site.forget()
	return found


func _drawn(site: Structure) -> int:
	var count := 0
	for i in site.piece.sockets.size():
		count += int(not SiteLoot.draw(site, i).is_empty())
	return count
