extends WorldProbe
## Sightlines probe 2: a far stand-in is what you find when you arrive. At the
## Surveyor's start, a structure past the sheet's reach, drawn only as a
## stand-in from where you stand, is walked to. When the sheet lays it, it
## stands where its stand-in last stood, give or take the metre a stand-in
## may lag the sheet's seams; when its own chunk draws it, it's in the state
## its stand-in showed, as high over its ground as the stand-in stood over
## the far ring's.
## Time limit: 900 s

const WORLD_SCENE := preload("res://game/world/world.tscn")
## How far off the one walked to stands, m.
const FROM := Vector2(1500.0, 2600.0)
const STEP := 16.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	tuning.run_seed = 1234
	world = WORLD_SCENE.instantiate()
	world.kit = Kit.origins()[0]
	add_child(world)
	await settle()
	# Its state holds still while you walk to it.
	world.time_warp = 0.0
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var far: Structure = null
	for site in world.terrain.skyline.seen():
		var by := site.distance_to(here.x, here.y)
		if by >= FROM.x and by <= FROM.y and not site.piece.far.is_empty() and _laid(site.id) == null \
				and not world.terrain.skyline.stand_in(site).is_empty() and (far == null or site.top_in(0) > far.top_in(0)):
			far = site
	check(far != null, "a stand-in past the sheet's reach, %.0f to %.0f m off" % [FROM.x, FROM.y])
	if far == null:
		return
	var first := world.terrain.skyline.stand_in(far)
	var state := far.state()
	print("walking to a %s %.0f m off, %s" % [far.kind, far.distance_to(here.x, here.y), Exposure.NAMES[state]])
	var last := first
	var laid: Structure = null
	var view: MeshInstance3D = null
	var x := here.x
	var z := here.y
	var way := (Vector2(far.x, far.z) - here).normalized()
	for i in int(FROM.y / STEP) + 20:
		var found := _laid(far.id)
		if found == null:
			var sighted := _sighted(far.id)
			if sighted != null and not world.terrain.skyline.stand_in(sighted).is_empty():
				last = world.terrain.skyline.stand_in(sighted)
		elif laid == null:
			laid = found
			var off := Vector2(laid.x - last.x, laid.z - last.z).length()
			print("laid %.2f m from where its stand-in last stood, %.1f m from where it first stood" % [off,
				Vector2(laid.x - first.x, laid.z - first.z).length()])
			check(off < 1.5, "the sheet lays it where its stand-in last stood (%.2f m off)" % off)
		var chunk := world.terrain.chunk_under(far.x, far.z)
		view = chunk.view_of(laid) if laid != null and chunk != null else null
		if view != null:
			break
		x += way.x * STEP
		z += way.y * STEP
		teleport(x, z)
		await settle(true)
	check(view != null, "its own chunk draws it on arrival")
	if view == null:
		return
	var top := (view.global_transform * view.mesh.get_aabb()).end.y - laid.pad()
	print("its stand-in stood %.2f m over the far ring, %s; it stands %.2f m over its ground, %s" % [
		first.top - first.ground, Exposure.NAMES[state], top, Exposure.NAMES[laid.state()]])
	check(laid.state() == state, "in the state its stand-in showed")
	check(absf(top - (first.top - first.ground)) < 0.15, "as high over its ground as its stand-in stood over the far ring's")


func _laid(id: int) -> Structure:
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site.id == id:
				return site as Structure
	return null


func _sighted(id: int) -> Structure:
	for site in world.terrain.skyline.seen():
		if site.id == id:
			return site
	return null
