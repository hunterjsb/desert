extends WreckProbe
## Wreck probe 7: a storm keeps what you cut. A tithe hauler stood by hand
## where a storm will lay it bare, its ground built while it's under the
## sand: as the storm bares it what's welded into it rises with its hull,
## frame by frame, and its cargo deck, packed under the sand when it was
## built, has sand of its own to clear once it's bared. At the storm's
## height its cargo door is cut away and falls, its cab door's seams half
## cut and its cab's first slice cleared. The storm lets go and buries it
## again: the door lying on the sand sinks with it, out of sight, and the
## rest is kept as left; bared once more, the door lies where it fell, the
## seams cut as far, the slice still gone.
## Time limit: 400 s

const KIND := &"tithe_hauler"
const BEARING := 0.4
## Seconds of weather a frame as you watch.
const WARP := 3.0

var _site: Structure
var _wreck: Wreckage


func run() -> void:
	await load_hands(1234, true)
	salvage = world.salvage
	world.time_warp = 0.0
	var sites := world.shape.sites
	var lean := deg_to_rad(Eras.TILT.get(StructureKit.piece(KIND).era, Vector2.ZERO).y * 0.6)
	var from := Vector2(world.player_world_x() + 320.0, world.player_world_z())
	# Where it stands without sliding off the storm's place.
	var stands := func(at: Vector2) -> bool:
		var tried := sites.by_hand(KIND, at.x, at.y, BEARING, 0.0, lean)
		return tried.stands() and tried.distance_to(at.x, at.y) < 1.0
	var storm := StormSite.find(world.weather.field, world.tuning, from.x, from.y, 2, 100.0, 1.0, 0.5, stands, world.shape)
	check(not storm.is_empty(), "a storm that lays a hauler bare between sand before and after")
	if storm.is_empty():
		return
	_site = sites.by_hand(KIND, storm.x, storm.z, BEARING, storm.depth, lean)
	world.time = storm.before
	sites.add(_site)
	# Off its ground, so nothing holds the sand off it.
	await go(_site.x + _site.reach + 25.0, _site.z)
	for i in 300:
		if salvage.wreckage_of(_site) != null and salvage.is_idle():
			break
		await get_tree().process_frame
	_wreck = salvage.wreckage_of(_site)
	check(_wreck != null and _site.state() == Exposure.BURIED, "its scrapping built under the sand (%s)"
		% Exposure.NAMES[_site.state()])
	if _wreck == null:
		return
	var plan := _wreck.plan
	var door := _named(plan.plates, "armoured cargo door")
	var cab_door := _named(plan.plates, "cab door")
	var cab := _named(plan.holds, "cab")
	var deck := _named(plan.holds, "cargo deck")
	check(_wreck.slice_body(deck, 0) == null, "its cargo deck lies under the sand")

	# The storm bares it as you watch.
	var apart := await _watch(storm.before, storm.peak, cab_door)
	check(_site.state() == Exposure.EXPOSED and apart < 0.002,
		"its welds rise with its hull frame by frame (%.4f m off at most)" % apart)
	check(_wreck.slice_body(deck, 0) != null, "bared, its cargo deck has packed sand to clear")

	# Worked at the storm's height.
	cut_away(_wreck, door)
	await physics_frames(roundi(Wreckage.SETTLE_MOST * Engine.physics_ticks_per_second) + 10)
	var fell := _lying(door)
	var cells := _wreck.plan.plates[cab_door].cells.size()
	var cab_body := _wreck.plate_body(cab_door)
	for c in range(0, cells / 2):
		_wreck.cut(cab_body, _wreck.cell_point(cab_door, c), _wreck.cell_seconds() * 2.0)
	var cut: PackedFloat32Array = (_wreck.state.cut[cab_door] as PackedFloat32Array).duplicate()
	clear_out(_wreck, cab, 1)
	check(_wreck.state.fallen.has(door) and fell.is_finite(), "its cargo door cut away lies where it fell")
	print("worked at its height: the door down at %.2f m over the sand, the cab door %d%% cut, a slice of the cab cleared"
		% [fell.y - world.height_under(fell), _wreck.progress(cab_door) * 100.0])

	# The storm lets go: buried again.
	apart = await _watch(storm.peak, storm.after, cab_door)
	var under := _lying(door)
	check(_site.state() == Exposure.BURIED and apart < 0.002,
		"buried again, its welds sank with its hull (%s, %.4f m off at most)" % [Exposure.NAMES[_site.state()], apart])
	check(under.y + 0.1 < world.height_under(under) and Vector2(under.x, under.z).distance_to(Vector2(fell.x, fell.z)) < 0.05,
		"the door lying on the sand sank under it with the hull (%.2f m under)" % (world.height_under(under) - under.y))
	_kept(cut, cab_door, cab, "buried")

	# Bared once more.
	await _at(storm.peak)
	await physics_frames(2)
	var again := _lying(door)
	check(again.distance_to(fell) < 0.05, "bared again, the door lies where it fell (%.3f m off)" % again.distance_to(fell))
	_kept(cut, cab_door, cab, "bared again")


## Watches the weather from one moment to another, a few seconds of it a
## frame: how far a plate's first seam cell is at most from where the hull's
## look has it.
func _watch(from: float, to: float, plate: int) -> float:
	var chunk := world.terrain.chunk_under(_site.x, _site.z)
	var p: WreckPlan.Plate = _wreck.plan.plates[plate]
	var most := 0.0
	var t := from
	while t < to:
		t = minf(t + WARP, to)
		await _at(t)
		var view := chunk.view_of(_site)
		if view != null and _wreck.plate_body(plate) != null:
			var want := view.global_transform * (p.cells[0] + p.normal() * 0.02)
			most = maxf(most, _wreck.cell_point(plate, 0).distance_to(want))
	return most


## What was cut and cleared is as it was left.
func _kept(cut: PackedFloat32Array, plate: int, hold: int, how: String) -> void:
	check(_wreck.state.cut[plate] == cut and _wreck.plate_body(plate) != null,
		"%s, its cab door's seams are cut as far (%d%%)" % [how, _wreck.progress(plate) * 100.0])
	check(_wreck.cleared(hold) == 1 and _wreck.slice_body(hold, 0) == null, "%s, its cab's slice is still cleared" % how)


## Where a fallen plate's body lies, the engine's frame, or NAN.
func _lying(plate: int) -> Vector3:
	for child in _wreck.get_children():
		if child.has_meta(&"fallen_plate") and child.get_meta(&"fallen_plate") == plate:
			var at := (child as Node3D).global_position
			var want := _wreck.global_transform * _wreck.lying_at(plate).origin
			return at if at.distance_to(want) < 0.01 else Vector3(NAN, NAN, NAN)
	return Vector3(NAN, NAN, NAN)


func _named(of: Array, label: String) -> int:
	for i in of.size():
		if of[i].label == label:
			return i
	check(false, "the hauler has its %s" % label)
	return 0


## The weather at world time `t`, and a frame for the ground to follow it.
func _at(t: float) -> void:
	world.time = t
	await get_tree().process_frame
	await get_tree().process_frame
