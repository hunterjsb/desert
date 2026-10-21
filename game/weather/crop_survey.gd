class_name CropSurvey
extends Node3D
## Frontier Ag's crop survey (Constellation &"thermal") in the sky, modelled
## (CropSurveyLooks) and lit by the scene's own sun, where the sky shader
## drew a flat H (gonkhub, 2026-10-20: "ship appearance still too flat.
## Needs to be modeled out fully this low to the ground"). SkyView places it
## each frame from its orbit. It's drawn inside the camera's reach at the
## same angular size, belly to the moon's centre, nose along its track; its
## overlay (crop_survey.gdshader) adds the sand's light thrown up at its
## belly and the air between it and you along the real line of sight, since
## the scene's fog is for looking across the ground. Its cannon's muzzle
## flashes as the constellation fires it.

const BOUNCE := preload("res://game/weather/crop_survey.gdshader")
## The sand's albedo, linear, for the light it throws back up at the belly.
const SAND := Color(0.46, 0.31, 0.16)
## It's drawn this near at most, at the same angular size: inside the
## scene's fog, so the overlay can veil it as the air really would.
const PROXY := 380.0
## Below this many pixels across it draws its far mesh; above this, its near
## one (CropSurveyLooks). Apart, so it doesn't flicker between them.
const FAR_BELOW := 260.0
const NEAR_ABOVE := 320.0
## How worn its paint is: kept up, it's still flying.
const AGE := 0.12

## "near" or "far" to hold one mesh (look-tests); empty picks by its size.
var hold := ""
var _view := MeshInstance3D.new()
var _muzzle := MeshInstance3D.new()
var _overlay := ShaderMaterial.new()
var _paint: ShaderMaterial
var _far := true
var _tuning: Tuning


func _init(tuning: Tuning) -> void:
	_tuning = tuning


func _ready() -> void:
	_view.mesh = CropSurveyLooks.craft(_far)
	_paint = Paint.worn().duplicate() as ShaderMaterial
	_paint.set_shader_parameter(&"sky_proxy", true)
	_view.material_override = _paint
	_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_view)
	_view.set_instance_shader_parameter(&"age", AGE)
	_overlay.shader = BOUNCE
	_view.material_overlay = _overlay
	_muzzle.mesh = CropSurveyLooks.flash()
	_muzzle.material_override = _paint
	_muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_muzzle.visible = false
	add_child(_muzzle)
	visible = false


## Where it is: `toward` from `eye` (unit), `slant` m off, flying along
## `along`, its top facing `up` (away from the moon's centre). Below the
## horizon it isn't drawn.
func place(eye: Vector3, toward: Vector3, slant: float, along: Vector3, up: Vector3) -> void:
	visible = toward.y > -0.02
	if not visible:
		return
	var env := get_world_3d().environment
	var near := minf(slant, PROXY)
	if env != null and env.fog_enabled:
		near = minf(near, maxf(env.fog_depth_begin * 0.95, 40.0))
	var y := up.normalized()
	var z := -(along - y * along.dot(y)).normalized()
	var x := y.cross(z)
	var size := near / slant * _tuning.crop_survey_scale
	global_transform = Transform3D(Basis(x, y, z).scaled_local(Vector3.ONE * size), eye + toward * near)
	_pick_detail(slant)
	_veil(env, toward, slant)


## The scene's light: which way the sun is and its light (linear, times its
## energy), and the ambient's, for the sky's light at its sides.
func light(sun_dir: Vector3, sun_light: Color, ambient: Color) -> void:
	var ground := SAND * sun_light * maxf(sun_dir.y, 0.0) / PI * 2.0
	_overlay.set_shader_parameter(&"bounce", Vector3(ground.r, ground.g, ground.b))
	_overlay.set_shader_parameter(&"sky_side", Vector3(ambient.r, ambient.g, ambient.b) / PI)


## Its cannon's muzzle, 0 dark to 1 at the shot.
func flash(amount: float) -> void:
	_muzzle.visible = amount > 0.0
	_muzzle.set_instance_shader_parameter(&"lit", amount)


## Whether it's drawing its far mesh.
func is_far() -> bool:
	return _far


## Its span in pixels on the current camera, and the mesh for it.
func _pick_detail(slant: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var across := CropSurveyLooks.SPAN * _tuning.crop_survey_scale / slant
	var pixels := across * get_viewport().get_visible_rect().size.y * 0.5 / tan(deg_to_rad(camera.fov) * 0.5)
	var far := pixels < (NEAR_ABOVE if _far else FAR_BELOW)
	if hold != "":
		far = hold == "far"
	if far != _far:
		_far = far
		_view.mesh = CropSurveyLooks.craft(_far)


## The air between: the dust thins with height, so the veil comes from the
## dust along the line of sight, matched at the ground to the scene's own
## haze (its fog reaching its density by its end). Overhead at 6 km that's
## about a fifth; low over the horizon, about half. In a storm, all of it.
func _veil(env: Environment, toward: Vector3, slant: float) -> void:
	if env == null or not env.fog_enabled:
		_overlay.set_shader_parameter(&"veil", 0.0)
		return
	var ground_k := -log(1.0 - clampf(env.fog_density, 0.0, 0.99)) / maxf(env.fog_depth_end, 1.0)
	var moon := _tuning.moon_circumference / TAU
	var dust := _tuning.dust_height_m
	# Its height over the curved ground, and the dust between.
	var height := maxf(toward.y * slant + slant * slant * (1.0 - toward.y * toward.y) / (2.0 * moon), 1.0)
	var column := dust * (1.0 - exp(-height / dust))
	_overlay.set_shader_parameter(&"veil", 1.0 - exp(-ground_k * column * slant / height))
	var behind := _sky_behind(env, toward)
	_overlay.set_shader_parameter(&"veil_color", Vector3(behind.r, behind.g, behind.b))


## The sky's colour behind it, as sky.gdshader draws it: its gradient times
## its glow, pulled toward the haze's light. Else (before the sky has set
## them) the fog's colour.
static func _sky_behind(env: Environment, toward: Vector3) -> Color:
	var sky_material := env.sky.sky_material as ShaderMaterial if env.sky != null else null
	var got := []
	if sky_material != null:
		for name: StringName in [&"sky_top_color", &"sky_horizon_color", &"sky_glow", &"haze_light", &"haze_share"]:
			got.append(sky_material.get_shader_parameter(name))
	if got.is_empty() or got.has(null):
		return env.fog_light_color * env.fog_light_energy
	var glow: Vector3 = got[2]
	var haze: Vector3 = got[3]
	var t := clampf(pow(1.0 - clampf(toward.y, 0.0, 1.0), 4.0), 0.0, 1.0)
	var grad := (got[0] as Color).srgb_to_linear().lerp((got[1] as Color).srgb_to_linear(), t)
	var lit := Color(grad.r * glow.x, grad.g * glow.y, grad.b * glow.z)
	return lit.lerp(Color(haze.x, haze.y, haze.z), got[4])
