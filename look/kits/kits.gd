extends Node
## Look-test: the structure kits. Every kit piece, by era, buried, partly
## exposed and exposed, stood by hand on fresh ground and shot from the same
## angle on a clear midmorning; then a stretch of the artery by Halfrise, the
## sites history strung along it, from beside it and from above.
##   scripts/unseen.sh --path . --disable-vsync res://look/kits/kits.tscn -- --capture <dir>
## Each shot is <era>_<kind>_<state>.png; the road's road_low and road_high.

const SEED := 1234
const ERAS: Array[StringName] = [Eras.COLONIAL, Eras.SKIMMER, Eras.FIRST, Eras.SECOND]
## Pieces stand this far apart, and their states' rows.
const APART := 75.0
## Midmorning, local; the camera looks from this far round from the front,
## and down at this.
const MOMENT := 0.38
const AROUND := 35.0
const DOWN := 20.0
## The road shot: this far along the artery from Halfrise, m.
const ALONG := 2300.0

@onready var world: World = $World

var _placed: Array[Array] = []


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	# Clear skies; the wind takes sand off steadily, so how deep each lies
	# alone sets its state.
	tuning.storm_threshold = 0.9
	tuning.site_return_m = -0.1
	tuning.salvage = true
	tuning.finds_per_chunk = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[args.find("--capture") + 1] if args.has("--capture") else "user://kits"
	_quiet()
	DirAccess.make_dir_recursive_absolute(out)
	world.time = _run_time(MOMENT)
	world.time_warp = 0.0
	await _ground()
	var started := Time.get_ticks_msec()
	_stand_all()
	print("kits: stood %d pieces by hand in %d ms" % [_placed.size(), Time.get_ticks_msec() - started])
	for each: Array in _placed:
		await _shoot(each[0], each[1], out)
	await _road(out)
	get_tree().quit()


## Every piece in its three states, in rows of state, by hand where the dunes take it.
func _stand_all() -> void:
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var col := 0
	for era in ERAS:
		for kind: StringName in StructureKit.kinds():
			var piece := StructureKit.piece(kind)
			if piece.era != era:
				continue
			for s in 3:
				var lean := deg_to_rad(Eras.TILT.get(era, Vector2.ZERO).y * 0.7)
				for j in 30:
					var at := from + Vector2(-450.0 + col * APART, 120.0 + s * APART + j * 6.0)
					var site := sites.by_hand(kind, at.x, at.y, 0.25, 0.0, lean)
					if not site.stands():
						continue
					var taken := Exposure.taken(world.weather.field, site.x, site.z, world.time, world.tuning)
					site.depth = [taken * 4.0, taken * 1.5, 0.0][s]
					sites.add(site)
					_placed.append([site, s])
					break
			col += 1


## A piece in its state, from in front of it and round to one side.
func _shoot(site: Structure, s: int, out: String) -> void:
	var piece := site.piece
	var high := 0.0
	var wide := piece.half.length()
	for box in piece.boxes:
		high = maxf(high, box.end.y)
		wide = maxf(wide, Vector2(box.position.x, box.position.z).length())
	var shows := maxf(high - piece.sink[s], 1.0)
	var front := (site.to_world(Vector2(0.0, 1.0)) - Vector2(site.x, site.z)).rotated(deg_to_rad(AROUND))
	var far := maxf(wide * 1.7, shows * 1.4) + 5.0
	var ground := world.shape.height_at(site.x, site.z)
	var target := Vector3(site.x, ground + shows * 0.32, site.z)
	var eye := target + Vector3(front.x, 0.0, front.y) * far * cos(deg_to_rad(DOWN)) \
		+ Vector3.UP * far * sin(deg_to_rad(DOWN))
	await _look(eye, target)
	var name := "%s_%s_%s" % [piece.era, piece.kind, ["buried", "partly", "exposed"][s]]
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("kits: %s %s at %.0f,%.0f, %s as built" % [name, Exposure.NAMES[s], site.x, site.z,
		Exposure.NAMES[world.terrain.chunk_under(site.x, site.z).state_of(site)]])


## The artery out of Halfrise, from beside it and from above, looking along it.
func _road(out: String) -> void:
	var history := world.shape.history
	var path: PathNetwork.Path = null
	for each in history.network.paths:
		var ends := [history.network.places[each.a].kind, history.network.places[each.b].kind]
		if each.kind == &"artery" and &"halfrise" in ends and &"port_morgan" in ends:
			path = each
	var from_halfrise := history.network.places[path.a].kind == &"halfrise"
	var s := ALONG if from_halfrise else path.length() - ALONG
	var p := path.at(s)
	var heading := path.bearing_at(s) + (0.0 if from_halfrise else PI)
	world.travel(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)), 0.0)
	world.time = _run_time(MOMENT)
	world.time_warp = 0.0
	await _ground()
	var at := Vector2(world.player_world_x(), world.player_world_z())
	var along := Vector2(sin(heading), -cos(heading))
	var aside := Vector2(along.y, -along.x)
	for shot: Array in [["road_low", 30.0, 14.0, 160.0], ["road_high", 60.0, 90.0, 420.0]]:
		var eye2: Vector2 = at - along * 40.0 + aside * shot[1]
		var target2: Vector2 = at + along * shot[3]
		var eye := Vector3(eye2.x, world.shape.height_at(eye2.x, eye2.y) + shot[2], eye2.y)
		var target := Vector3(target2.x, world.shape.height_at(target2.x, target2.y), target2.y)
		await _look(eye, target)
		get_viewport().get_texture().get_image().save_png(out.path_join(shot[0] + ".png"))
		var laid := 0
		for unit in world.shape.sites.units():
			for site in unit.sites:
				if site is Structure and site.stands() and Vector2(site.x, site.z).distance_to(at) < 800.0:
					laid += 1
		print("kits: %s, %d structures standing within 800 m" % [shot[0], laid])


## Puts the camera at `eye`, world metres, looking at `target`, and waits for
## the ground there.
func _look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var offset := player.camera.global_position - player.global_position
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	await _ground()
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	for i in 30:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


## The run's clock when it's `of_day` where you stand: the day is local.
func _run_time(of_day: float) -> float:
	var off := of_day - world.weather.day.time_of_day(0.0, world.moon.longitude)
	return fposmod(off, 1.0) * world.tuning.day_minutes * 60.0


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


## No focus, no keys, no sound, nothing drawn over the world.
func _quiet() -> void:
	var window := get_window()
	window.unfocusable = true
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
