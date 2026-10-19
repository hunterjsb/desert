extends Node
## Look-test: the wrecks and their scrapping. Every wreck kind stood by hand
## on fresh ground, dug out, on a clear midmorning, and shot four ways: whole
## from its way in; at work, a plate half cut along its seams, the kerf still
## glowing, and its first hold half cleared; with a heat cutter firing at the
## next seam, its beam and sparks; and stripped, every plate fallen, every
## hold cleared, every hazard made safe, its modules showing.
##   godot --path . --resolution 1280x720 res://look/wrecks/wrecks.tscn -- --capture <dir>
## Each shot is <kind>_<whole|work|cutting|stripped>.png, each plate face on
## as <kind>_plate<i>.png, and the skimmer
## hull's <kind>_hands.png, a cutter in your hands firing along its seam.

const SEED := 1234
const APART := 70.0
const MOMENT := 0.4

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.storm_threshold = 0.9
	tuning.site_return_m = -0.1
	tuning.salvage = true


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[args.find("--capture") + 1] if args.has("--capture") else "user://wrecks"
	DirAccess.make_dir_recursive_absolute(out)
	_quiet()
	world.time = _run_time(MOMENT)
	world.time_warp = 0.0
	await _ground()
	var from := Vector2(world.player_world_x(), world.player_world_z()) + Vector2(300.0, 200.0)
	var n := 0
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		if piece.wreck == null:
			continue
		var site := _stand(kind, from + Vector2((n % 3) * APART, (n / 3) * APART), 0.9 + n * 1.7)
		n += 1
		if site == null:
			print("wrecks: the dunes took every %s tried" % kind)
			continue
		await _shoot(site, out)
	get_tree().quit()


## A wreck stood by hand, dug out, its era's lean as a wreck of theirs would.
func _stand(kind: StringName, at: Vector2, bearing: float) -> Structure:
	var sites := world.shape.sites
	var lean := deg_to_rad(Eras.TILT.get(StructureKit.piece(kind).era, Vector2.ZERO).y * 0.6)
	for tries in 150:
		var off := Vector2.from_angle(tries * 2.39996) * 7.0 * sqrt(tries)
		var site := sites.by_hand(kind, at.x + off.x, at.y + off.y, bearing, 0.0, lean)
		if site.stands():
			sites.add(site)
			return site
	return null


func _shoot(site: Structure, out: String) -> void:
	var piece := site.piece
	var reach := piece.half.length()
	var approach := site.to_world(piece.approach)
	var middle := Vector3(site.x, site.floor_y + 1.4, site.z)
	var from := Vector2(approach.x, approach.y) - Vector2(site.x, site.z)
	var round := from.normalized().rotated(deg_to_rad(28.0)) * (reach * 1.3 + 5.0)
	var eye := Vector3(site.x + round.x, 0.0, site.z + round.y)
	eye.y = world.shape.height_at(eye.x, eye.z) + 2.6 + reach * 0.25
	await _look(eye, middle)
	var wreck := await _wreckage(site)
	if wreck == null:
		print("wrecks: %s built no scrapping" % piece.kind)
		return
	_save(out, "%s_whole" % piece.kind)

	# At work: its first plate half cut, its first hold half cleared.
	var plate := wreck.plate_body(0)
	var p: WreckPlan.Plate = piece.wreck.plates[0]
	for c in range(0, p.cells.size() * 6 / 10):
		wreck.cut(plate, wreck.cell_point(0, c), wreck.cell_seconds() * 1.2)
	var sand := wreck.slice_body(0, 0)
	if sand != null:
		wreck.clear(sand, wreck.slice_seconds(0, 0) * 0.55)
	var face := plate.global_transform * p.face()
	var normal := wreck.plate_normal(0)
	var close := face + normal * 3.0 + Vector3.UP * 0.9
	var close_w := Vector3(world.world_x(close.x), close.y, world.world_z(close.z))
	var face_w := Vector3(world.world_x(face.x), face.y, world.world_z(face.z))
	await _look(close_w, face_w)
	_save(out, "%s_work" % piece.kind)

	# The cutter firing at the next seam.
	var cutter := Catalog.device(&"cutter") as Cutter
	world.content.add_child(cutter)
	var next := wreck.cell_point(0, mini(p.cells.size() * 6 / 10 + 1, p.cells.size() - 1))
	cutter.global_transform = Transform3D(Basis.looking_at(next - (next + normal * 1.0 + Vector3.UP * 0.3)),
		next + normal * 1.0 + Vector3.UP * 0.3)
	cutter.powered = true
	for k in 40:
		cutter.fire(next, true)
		wreck.cut(plate, next, 1.0 / 60.0)
		await get_tree().physics_frame
	var side := normal.cross(Vector3.UP).normalized()
	var by := next + normal * 1.6 + side * 0.9 + Vector3.UP * 0.5
	await _look(Vector3(world.world_x(by.x), by.y, world.world_z(by.z)),
		Vector3(world.world_x(next.x), next.y, world.world_z(next.z)), func() -> void:
			cutter.fire(next, true))
	_save(out, "%s_cutting" % piece.kind)
	cutter.queue_free()
	if piece.kind == &"wreck_hull":
		await _in_hands(out, wreck, next, normal)

	# Every plate face on, its holds cleared: each seam in plain sight.
	for h in piece.wreck.holds.size():
		for k in piece.wreck.holds[h].slices:
			var slice := wreck.slice_body(h, k)
			if slice != null:
				wreck.clear(slice, wreck.slice_seconds(h, k) + 0.01)
	for i in piece.wreck.plates.size():
		var body := wreck.plate_body(i)
		if body == null:
			continue
		var at := body.global_transform * piece.wreck.plates[i].face()
		var front := at + wreck.plate_normal(i) * 2.2 + Vector3.UP * 0.4
		await _look(Vector3(world.world_x(front.x), front.y, world.world_z(front.z)),
			Vector3(world.world_x(at.x), at.y, world.world_z(at.z)))
		_save(out, "%s_plate%d" % [piece.kind, i])

	# Stripped: everything done, plates fallen, modules showing.
	for i in piece.wreck.plates.size():
		var body := wreck.plate_body(i)
		if body != null:
			for c in piece.wreck.plates[i].cells.size():
				wreck.cut(body, wreck.cell_point(i, c), wreck.cell_seconds() * 2.0)
	for h in piece.wreck.holds.size():
		for k in piece.wreck.holds[h].slices:
			var slice := wreck.slice_body(h, k)
			if slice != null:
				wreck.clear(slice, wreck.slice_seconds(h, k) + 0.01)
	for socket: int in piece.wreck.modules:
		var hazard := wreck.hazard_body(socket)
		if hazard != null and hazard.has_meta(&"work"):
			wreck.make_safe(hazard, hazard.get_meta(&"work")[0])
	for k in 400:
		await get_tree().physics_frame
	await _look(eye, middle)
	_save(out, "%s_stripped" % piece.kind)
	print("wrecks: %s at %.0f,%.0f, %d plates, %d holds, %d modules" % [piece.kind, site.x, site.z,
		piece.wreck.plates.size(), piece.wreck.holds.size(), piece.wreck.modules.size()])


## As you'd see it: a cutter in your hands, firing along the seam.
func _in_hands(out: String, wreck: Wreckage, next: Vector3, normal: Vector3) -> void:
	var hands := world.player.hands
	var cutter := Catalog.device(&"cutter") as Cutter
	world.content.add_child(cutter)
	Scenarios.fill(world, cutter, [&"battery"])
	cutter.global_position = world.player.camera.global_position - world.player.camera.global_basis.z * 0.6
	hands.hold(cutter)
	var eye := next + normal * 1.3 + Vector3.UP * 0.35
	await _look(Vector3(world.world_x(eye.x), eye.y, world.world_z(eye.z)),
		Vector3(world.world_x(next.x), next.y, world.world_z(next.z)), func() -> void:
			hands.scrap(1.0 / Engine.physics_ticks_per_second))
	var layers := world.find_children("*", "CanvasLayer", true, false)
	for layer: CanvasLayer in layers:
		layer.visible = true
	await RenderingServer.frame_post_draw
	_save(out, "%s_hands" % wreck.site.kind)
	for layer: CanvasLayer in layers:
		layer.visible = false
	hands.drop()


func _wreckage(site: Structure) -> Wreckage:
	for k in 600:
		var wreck := world.salvage.wreckage_of(site)
		if wreck != null and world.salvage.is_idle():
			return wreck
		await get_tree().process_frame
	return world.salvage.wreckage_of(site)


func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("wrecks: shot %s" % name)


## Puts the camera at `eye`, world metres, looking at `target`, and waits for
## the ground there; `each` runs every frame meanwhile.
func _look(eye: Vector3, target: Vector3, each := Callable()) -> void:
	var player := world.player
	var offset := player.camera.global_position - player.global_position
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	await _ground()
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	for i in 30:
		if each.is_valid():
			each.call()
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


func _run_time(of_day: float) -> float:
	var off := of_day - world.weather.day.time_of_day(0.0, world.moon.longitude)
	return fposmod(off, 1.0) * world.tuning.day_minutes * 60.0


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


func _quiet() -> void:
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.flying = true
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
