extends Node3D
## Look-test: Tu alone, no world, quick to shoot. The sky shader as SkyView
## feeds it on a full-Tu night where a run begins (Tu 30° up, due west, the
## eye about three times open), shot at each size under trial as the game
## frames it and close, at a few turns of Tu; and its clouds unrolled.
##   godot --path . --disable-vsync res://look/tu/alone.tscn -- --capture <dir> [time]

const SIZES: Array[float] = [6.0, 9.0, 13.0]
const EYE := 3.0
const UP := 30.0

@onready var camera: Camera3D = $Camera3D
@onready var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
@onready var map: ColorRect = $Map

var material := ShaderMaterial.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	var out := args[at + 1] if args.size() > at + 1 else "user://tu_alone"
	var time := float(args[at + 2]) if args.size() > at + 2 else 0.0
	get_window().unfocusable = true
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out)
	material.shader = preload("res://game/weather/sky.gdshader")
	environment.sky.sky_material = material
	environment.tonemap_exposure = EYE
	var tu := Vector3(-cos(deg_to_rad(UP)), sin(deg_to_rad(UP)), 0.0)
	material.set_shader_parameter("tu_dir", tu)
	material.set_shader_parameter("sun_dir", -tu)
	material.set_shader_parameter("sun_light", Vector3(1.0, 0.89, 0.71))
	material.set_shader_parameter("sky_glow", Vector3.ONE * 0.0005)
	material.set_shader_parameter("haze_light", Vector3.ZERO)
	material.set_shader_parameter("tu_pole", Vector3(0.0, 0.0, -1.0))
	material.set_shader_parameter("tu_time", time)
	map.visible = false
	for degrees: float in SIZES:
		var radius := deg_to_rad(degrees) * 0.5
		material.set_shader_parameter("tu_radius", radius)
		camera.fov = 75.0
		camera.look_at_from_position(Vector3.ZERO, tu, Vector3.UP)
		await _save(out.path_join("tu%d.png" % degrees), radius)
		for turn in 4:
			material.set_shader_parameter("tu_spin", TAU * turn / 4.0)
			camera.fov = rad_to_deg(2.0 * atan(tan(radius) / 0.9))
			await _save(out.path_join("tu%d_close_%d.png" % [degrees, turn]), -1.0)
		material.set_shader_parameter("tu_spin", 0.0)
	map.visible = true
	var unrolled := map.material as ShaderMaterial
	unrolled.set_shader_parameter("time", time)
	unrolled.set_shader_parameter("rows", map.size.y)
	await _save(out.path_join("unrolled.png"), -1.0, Rect2i(Vector2i.ZERO, Vector2i(map.size)))
	get_tree().quit()


## The frame, and with `radius` given Tu cut from its middle blown up pixel
## for pixel to about 480 across.
func _save(path: String, radius: float, only := Rect2i()) -> void:
	for i in 4:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if only.has_area():
		image = image.get_region(only)
	if radius < 0.0:
		image.save_png(path)
		return
	var size := image.get_size()
	var across := size.y / (2.0 * tan(deg_to_rad(camera.fov) * 0.5)) * tan(radius) * 2.0
	var side := ceili(across * 1.25)
	var piece := image.get_region(Rect2i(size / 2 - Vector2i(side, side) / 2, Vector2i(side, side)))
	var times := maxi(1, 480 / side)
	piece.resize(side * times, side * times, Image.INTERPOLATE_NEAREST)
	piece.save_png(path)
