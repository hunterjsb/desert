extends SalvageProbe
## Structure kits probe 9: the nomads' camps are rare, kept and lootable.
## Over the cells round each of three worlds' Surveyor's starts, wrecked
## nomad rigs lie in many and a camp in few. A camp laid by hand stands on
## the sand at any hour, never buried; its kept rig lies whole in it, its
## mast and sail on it, with things of more than one era round it; taking
## hold of the rig makes it, and all that's on it, yours.

const SEEDS := [1234, 42, 777]
## Round each start, this far, m.
const ROUND := 20000.0


func run() -> void:
	var tuning := Tuning.current()
	var rigs := 0
	var camps := 0
	var cells := 0
	for s: int in SEEDS:
		var history := History.new(s, tuning)
		var shape := TerrainShape.new(s, tuning)
		var at := Starts.find(shape, &"artery", tuning)
		for cell in history.cells.within(at, ROUND):
			cells += 1
			for each in history.sites_in_cell(cell):
				rigs += int(each.kind == &"nomad_rig")
				camps += int(each.kind == &"nomad_camp")
	print("%d cells: %d wrecked nomad rigs, %d nomad camps (one a %.0f km², one a %.0f km²)" % [cells, rigs, camps,
		cells * 0.25 / maxf(rigs, 1), cells * 0.25 / maxf(camps, 1)])
	check(camps > 0 and rigs >= camps * 15, "camps are rare, wrecked rigs common (%d camps, %d rigs)" % [camps, rigs])

	await load_salvage()
	var spot := open_sand(0.0, 250.0, 0.6)
	var camp: Structure = null
	for tries in 150:
		var off := Vector2.from_angle(tries * 2.39996) * 7.0 * sqrt(tries)
		camp = world.shape.sites.by_hand(&"nomad_camp", spot.x + off.x, spot.y + off.y, 0.7, 0.0)
		if camp.stands():
			break
	check(camp.stands(), "a camp stands where it's laid")
	if not camp.stands():
		return
	var buried := 0
	for hours in [0.0, 6.0, 30.0, 200.0]:
		buried += int(Exposure.state(camp.depth, camp.pure_taken(hours * 3600.0)) != Exposure.EXPOSED)
	check(buried == 0, "kept, it's never buried")
	world.shape.sites.add(camp)
	var beside := camp.to_world(camp.piece.approach)
	await go(beside.x, beside.y)
	await settle_finds()
	var rig: Chassis = null
	var eras := {}
	var held := 0
	for body in salvage.finds():
		if site_of(body) != camp:
			continue
		held += 1
		if body.has_meta(&"lineage"):
			eras[Eras.era_of(body.get_meta(&"lineage"))] = true
		if body is Chassis and (body as Chassis).pieces().size() > 1:
			rig = body
	print("the camp holds %d things, of %d eras, its rig %s" % [held, eras.size(), "lying whole" if rig != null else "missing"])
	check(held >= 6 and eras.size() >= 2, "it holds what any era made (%d things, %d eras)" % [held, eras.size()])
	var mast: Mast = null
	if rig != null:
		for each in rig.mounted():
			if each is Mast:
				mast = each
	check(rig != null and rig.pieces().size() >= 4 and mast != null and mast.sail() != null,
		"its kept rig lies whole, its mast and sail on it")
	if rig == null:
		return
	# Aim at the actual deck panel; the rig's bounds include empty air below its spar.
	var to := rig.global_transform * Vector3(-0.3, 0.04, 0.3)
	look(to + Vector3(1.6, 1.0, 0.4), to)
	await physics_frames(2)
	hands.grab()
	await physics_frames(20)
	check(not salvage.lying(rig) and not rig.freeze and not salvage.lying(mast),
		"taken hold of, the rig and all that's on it are yours")
