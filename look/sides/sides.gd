extends Node
## Look-test: telling Zan's near side from its far side (world-and-terrain.md,
## "Near and far side readability"), on seed 1234 deep in the dune sea nearest
## spawn (look/dunes' "sea"), in clear, still air with the eye on, as the game
## plays. Near is where a run begins, Tu 30° up due west; far is as far past
## the Rim, Tu 30° under the horizon. Only the sky moves between them: the
## dunes don't follow longitude, so the ground is the same, and the vents'
## plumes are hidden. Each look is shot on both sides at 07:00 local, the sun an
## hour up, and at 04:00, a full Tu's small hours where a run begins, looking
## past Tu's bearing; and at 04:00 by the headlamp, looking down at the sand:
##   0  the game as it is;
##   A  Tu's light in the near side's air: a glow round Tu, and only the
##      brightest stars through it, while the far side keeps every star;
##   B  the far side's frost: its sand rimed overnight, going after sunrise
##      from what faces the sun first;
##   C  both.
## The key is which side of the moon you stand on, side(). Nothing here is on
## the game's path: each look patches the game's own sky and sand shaders
## (EDITS) and drives them from here. It prints what it shot and, with --gpu,
## each look's frame time against the game's, alternated:
##   godot --path . --disable-vsync res://look/sides/sides.tscn -- --capture <dir> [--only 0,A] [--gpu]
## look/sides/shoot.sh shoots it unseen and builds the sheet. A small window
## that never takes focus, nothing but this script moving anything, and silence.

const Dunes := preload("res://look/dunes/dunes.gd")
const SEED := 1234
const EYE := 1.65
## Degrees of longitude east of the point under Tu: where a run begins, and
## its mirror past the Rim.
const SIDES := {"near": 60.0, "far": 120.0}
## Each shot's local hour as a share of the day, how far up it looks,
## degrees, and whether by the headlamp.
const TIMES := {"day": [7.0 / 24.0, 6.0, false], "night": [4.0 / 24.0, 6.0, false],
	"lamp": [4.0 / 24.0, -24.0, true]}
## Looking this far round from Tu's bearing toward the north, degrees.
const TURN := 20.0
const LOOKS := {"0": [], "A": ["air"], "B": ["frost"], "C": ["air", "frost"]}

## A: how strongly the dust throws Tu-shine about Tu, against the light it
## puts on open ground; and the faintest star left, per unit of that light:
## at a full Tu's 0.31% of the sun, about the brightest tenth.
const AUREOLE := 1.6
const STAR_WASH := 9.0
## B: the frost begins once Tu's whole disc is set and lies fully this far
## under, sines of Tu's height; it grows from these hours after sunset (shares
## of the day) and the morning takes it all within this many hours.
const COLD := Vector2(0.1, 0.35)
const FROST_GROWS := Vector2(0.08, 0.35)
const MELT_HOURS := 4.0

const SKY := "res://game/weather/sky.gdshader"
const SAND := "res://game/world/sand.gdshader"
## Each part's edits to a game shader: the game's text, which must be there
## exactly once, and what takes its place.
const EDITS := {
	"air": [SKY, [
		["vec3 hash33(vec3 p) {", "#include \"res://look/sides/tu_air.gdshaderinc\"\n\nvec3 hash33(vec3 p) {"],
		["light += tint * bright * exp(", "light += tint * max(bright - star_limit, 0.0) * exp("],
		["vec3 base = mix(gradient(d) * sky_glow, haze_light, haze_share);",
			"vec3 base = mix(gradient(d) * sky_glow, haze_light, haze_share) + tu_air(d);"],
	]],
	"frost": [SAND, [
		["void fragment() {", "#include \"res://look/sides/frost.gdshaderinc\"\n\nvoid fragment() {"],
		["\t// Glitter, after Wang and Bowles", "\tfloat rime = frost_cover(n, at, foot, trough);\n\t// Glitter, after Wang and Bowles"],
		["grain.w * near);", "grain.w * near * (1.0 + FROST_GLINT * rime));"],
		["colour = mountain_colour(colour, world_pos.y, normalize(world_normal));",
			"colour = mountain_colour(colour, world_pos.y, normalize(world_normal));\n\tcolour = mix(colour, FROST, rime);"],
	]],
}
const GPU_FRAMES := 60
const GPU_ROUNDS := 7

@onready var world: World = $World

var _out := ""
var _only := PackedStringArray()
var _look := "0"
var _sky: ShaderMaterial
var _sand: ShaderMaterial
## Each material's shader as the game has it, and each part's patched one.
var _shaders := {}


## Which side of Zan a place is on: the sine of Tu's mean height in its sky,
## 1 under Tu, 0 on the Rim and -1 at the far side's centre. Tu's nod is left
## out, so the frost line keeps still through the day.
static func side(tuning: Tuning, latitude: float, longitude: float) -> float:
	return Sphere.point(latitude, longitude).dot(Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees)))


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = true
	# No storm anywhere, and still air, so nothing but the side changes.
	tuning.storm_threshold = 10.0
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0


func _ready() -> void:
	# After Weather has lit the frame and handed out its plumes.
	process_physics_priority = 200
	process_priority = 200
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_out = args[at + 1] if args.size() > at + 1 else "user://sides"
	var only := args.find("--only")
	if only != -1 and args.size() > only + 1:
		_only = args[only + 1].split(",")
	_capture()


func _capture() -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	# Its aim dot would show again.
	player.hands.set_process(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(_out)
	_sky = world.weather.sky.material
	_sand = world.terrain.sand_material as ShaderMaterial
	_shaders = {SKY: _sky.shader, SAND: _sand.shader}
	for part: String in EDITS:
		var patched := _patched(EDITS[part][0], EDITS[part][1])
		if patched == null:
			get_tree().quit(1)
			return
		_shaders[part] = patched
	var spot: Vector2 = Dunes.spots()["sea"]
	world.respawn(spot.x, spot.y, 0.0, 0.0)
	await _ground()
	for i in 600:
		if world.weather.map.ready:
			break
		await get_tree().process_frame
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()
	player.set_physics_process(false)
	player.flying = true
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false

	var fade := roundi(world.tuning.headlamp_fade_seconds * Engine.physics_ticks_per_second) + 10
	for where: String in SIDES:
		for when: String in TIMES:
			var shot: Array = TIMES[when]
			_stand(spot, SIDES[where], shot[0], shot[1])
			if player.headlamp.on != shot[2]:
				player.headlamp.on = shot[2]
				for i in fade:
					await get_tree().physics_frame
			for look: String in LOOKS:
				if not _only.is_empty() and not _only.has(look):
					continue
				_wear(look)
				await _settle()
				_save("%s-%s-%s" % [look, where, when])
	if OS.get_cmdline_user_args().has("--gpu"):
		for view: Array in [["near", "night"], ["far", "day"]]:
			_stand(spot, SIDES[view[0]], TIMES[view[1]][0], TIMES[view[1]][1])
			await _gpu_cost("%s side by %s" % view)
	_wear("0")
	get_tree().quit()


## The game's shader at `path` with a part's edits, or null if the game's
## text has moved on from them.
func _patched(path: String, edits: Array) -> Shader:
	var code := FileAccess.get_file_as_string(path)
	for edit: Array in edits:
		var found := code.count(edit[0])
		if found != 1:
			push_error("sides: %s holds %d of %s" % [path, found, edit[0]])
			return null
		code = code.replace(edit[0], edit[1])
	var shader := Shader.new()
	shader.code = code
	return shader


## Puts on a look: each material its game shader, or a part's.
func _wear(look: String) -> void:
	_look = look
	var parts: Array = LOOKS[look]
	_sky.shader = _shaders["air" if parts.has("air") else SKY]
	_sand.shader = _shaders["frost" if parts.has("frost") else SAND]
	_drive()


## The sky over a place `east` degrees east of the point under Tu, at local
## `hour`, over the same ground, looking past Tu's bearing toward the north
## and `pitch` degrees up.
func _stand(spot: Vector2, east: float, hour: float, pitch: float) -> void:
	var tuning := world.tuning
	var longitude := deg_to_rad(tuning.tu_longitude_degrees + east)
	# Set, not placed: a place() lays history afresh and could change the ground.
	world.moon.latitude = 0.0
	world.moon.longitude = wrapf(longitude, -PI, PI)
	var day := world.weather.day
	var now := day.time_of_day(0.0, world.moon.longitude)
	world.time = fposmod(hour - now, 1.0) * tuning.day_minutes * 60.0
	world.time_warp = 0.0
	world.weather.forecast_now()
	var tu := day.tu_direction(world.time, 0.0, world.moon.longitude)
	var player := world.player
	var engine := Vector3(world.engine_x(spot.x), 0.0, world.engine_z(spot.y))
	player.global_position = Vector3(engine.x, world.height_under(engine) + EYE, engine.z) - player.camera.position
	player.rotation.y = atan2(-tu.x, -tu.z) - deg_to_rad(TURN)
	player.camera.rotation_degrees.x = pitch


func _physics_process(_delta: float) -> void:
	if _sky != null:
		_drive()


## The vents near where a run begins send up plumes the far side's sky has
## none of; hidden, so the shots differ only by the side.
func _process(_delta: float) -> void:
	if _sky != null:
		for plume in world.weather.plumes:
			plume.visible = false


## Hands the look's parts what they read where you stand, after Weather has
## lit the frame.
func _drive() -> void:
	var parts: Array = LOOKS[_look]
	var day := world.weather.day
	var moon := world.moon
	var t := world.time
	if parts.has("air"):
		var dim := lerpf(1.0, 1.0 - world.tuning.storm_darkness, world.weather.seen_shade)
		var shine := day.tu_light(t, moon.latitude, moon.longitude) * world.tuning.tu_shine_scale * dim
		var c := SkyView.TU_SHINE_COLOR.srgb_to_linear()
		_sky.set_shader_parameter("tu_air_light", Vector3(c.r, c.g, c.b) * shine * AUREOLE)
		_sky.set_shader_parameter("star_limit", STAR_WASH * shine)
	if parts.has("frost"):
		var frost := frost_at(t, moon.latitude, moon.longitude)
		_sand.set_shader_parameter("frost", frost.x)
		_sand.set_shader_parameter("frost_melt", frost.y)
		_sand.set_shader_parameter("frost_sun", day.sun_direction(t, moon.latitude, moon.longitude))


## The frost the night has laid at a place, 0 to 1, and how far the morning
## has gone to taking it: none on the near side, whose water has drained to
## the far side's cold (the-moon.md), and none from mid-morning to evening.
func frost_at(t: float, latitude: float, longitude: float) -> Vector2:
	var cold := smoothstep(COLD.x, COLD.y, -side(world.tuning, latitude, longitude))
	var since_dusk := fposmod(world.weather.day.time_of_day(t, longitude) - 0.75, 1.0)
	if since_dusk < 0.5:
		return Vector2(cold * smoothstep(FROST_GROWS.x, FROST_GROWS.y, since_dusk), 0.0)
	var morning := (since_dusk - 0.5) * 24.0 / MELT_HOURS
	return Vector2(cold if morning < 1.0 else 0.0, minf(morning, 1.0))


func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out.path_join(name + ".png"))
	var seen := Dunes.readability(image)
	var moon := world.moon
	var day := world.weather.day
	var t := world.time
	var tu := day.tu_direction(t, moon.latitude, moon.longitude)
	var sun := day.sun_direction(t, moon.latitude, moon.longitude)
	var frost := frost_at(t, moon.latitude, moon.longitude)
	print("sides: %-14s %05.2f local, side %+.2f, Tu %+5.1f°, sun %+5.1f°, frost %.2f/%.2f, ground L* %.1f spread %.1f, eye x%.1f"
		% [name, day.time_of_day(t, moon.longitude) * 24.0, side(world.tuning, moon.latitude, moon.longitude),
			rad_to_deg(asin(tu.y)), rad_to_deg(asin(sun.y)), frost.x, frost.y, seen.x, seen.y,
			world.weather.eye.exposure()])


## The GPU's time per frame with each look, alternated so a busy machine
## weighs on each alike; and the middle of the rounds' differences from the
## game's own, which a burst of someone else's load in one round moves least.
func _gpu_cost(what: String) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var rounds := []
	for round in GPU_ROUNDS:
		var got := {}
		for look: String in LOOKS:
			_wear(look)
			await _frames(10)
			var sum := 0.0
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			got[look] = sum / GPU_FRAMES
		rounds.append(got)
	for look: String in LOOKS:
		var mean := 0.0
		var differences := []
		for got: Dictionary in rounds:
			mean += got[look] / GPU_ROUNDS
			differences.append(got[look] - got["0"])
		differences.sort()
		print("sides: gpu %s, %s: %.3f ms a frame, median %+.3f ms against the game's (%+.3f to %+.3f), at %s%s"
			% [what, look, mean, differences[floori(GPU_ROUNDS / 2.0)], differences[0], differences[-1],
				get_viewport().get_visible_rect().size, _shared_gpu()])


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""


## Long enough for the light, the eye and a new shader to settle.
func _settle() -> void:
	world.weather.eye.settle()
	for i in 30:
		await get_tree().physics_frame
	await _frames(6)


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
