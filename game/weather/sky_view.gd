class_name SkyView
extends Node
## Zan's sky as seen from where you stand: the dusty gradient and its haze, the
## stars turning about the pole, and Tu, drawn by sky.gdshader from the day's
## one frame; and Tu-shine, Tu's weak light on the ground. Weather works out the
## light and hands it here each frame. The sun's disc stays with the storm
## pass, where Tu hides it.

## Tu-shine: cool, off Tu's pale clouds.
const TU_SHINE_COLOR := Color(0.78, 0.86, 1.0)
## Tu's edge is softened over this much, radians, where it cuts the sun.
const TU_EDGE := 0.0008
## A low satellite looks no smaller than this share of its size overhead.
const LOW_SMALLEST := 0.2
## By day only the nearest and brightest show (gonkhub, 2026-10-20: "the
## closest and brightest satellites should still be visible during the
## daytime"): one starts to show once it looks this bright (its light, times
## how near it is), and shows fully at this. A low hull always shows by day,
## a dark shape against the bright sky.
const DAY_FROM := 0.3
const DAY_FULL := 0.5
## How bright the relay shows at night, against the brightest stars' 0.09.
const RELAY_LIGHT := 0.35

## An eclipse watched: none going on, watched since the sun began to go in,
## watched through totality, or missed some of.
enum { CLEAR, GOING_IN, TOTAL, MISSED }
## A jump in the clock this long, s, is no eclipse watched through.
const JUMP := 2.0

var material := ShaderMaterial.new()
## The crop survey, modelled: the one satellite drawn as a thing, not on the sky.
var crop_survey: CropSurvey
## Tu's light on open ground round the camera, as a share of the sun's overhead.
var tu_seen := 0.0
## How the eclipse going on now has been watched, and the clock when last seen.
var watched := CLEAR
var _watched_at := -INF

var _world: World
var _day: DayCycle
var _face: StormFace
var _sun: DirectionalLight3D
var _sun_energy: float
var _tu_shine := DirectionalLight3D.new()
var _environment: Environment


func setup(world: World, day: DayCycle, environment: Environment, face: StormFace, sun: DirectionalLight3D) -> void:
	_world = world
	_day = day
	_face = face
	_sun = sun
	_sun_energy = sun.light_energy
	_environment = environment
	material.shader = preload("res://game/weather/sky.gdshader")
	# The day's gradient stays the scene's, drawn now under Tu and the stars.
	var stock := environment.sky.sky_material as ProceduralSkyMaterial
	if stock != null:
		for colour: String in ["sky_top_color", "sky_horizon_color", "ground_bottom_color", "ground_horizon_color"]:
			material.set_shader_parameter(colour, stock.get(colour))
	# The sky does its own haze, by how much air each way looks through.
	material.set_shader_parameter("haze_share", environment.fog_sky_affect)
	environment.sky.sky_material = material
	# Nothing reads the sky's light, so the map of it kept for reflections is tiny.
	environment.sky.radiance_size = Sky.RADIANCE_SIZE_32
	environment.background_energy_multiplier = 1.0
	_tu_shine.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_tu_shine.light_color = TU_SHINE_COLOR
	_tu_shine.directional_shadow_max_distance = sun.directional_shadow_max_distance
	_tu_shine.visible = false
	add_child(_tu_shine)
	crop_survey = CropSurvey.new(world.tuning)
	add_child(crop_survey)


## Every frame, after Weather has worked out the light: where the sun stands
## and how much of it shows past Tu, the air's glow and haze, Tu's light as a
## share of the sun's, how far into a storm's dust the camera is, and the
## eclipse ring's light low in the air.
func show(t: float, eye: Vector3, sun: Vector3, sun_shown: float, glow: Vector3, haze: Vector3,
		tu_light: float, seen_shade: float, dim: float, ring_air: Vector3) -> void:
	var moon := _world.moon
	var dip := SurfaceProjection.horizon_dip(maxf(eye.y, 0.0), SurfaceProjection.radius(_world.tuning))
	material.set_shader_parameter("horizon_dip", dip)
	_face.set_light(&"horizon_dip", dip)
	var tu := _day.tu_direction(t, moon.latitude, moon.longitude)
	var radius := _day.tu_radius()
	material.set_shader_parameter("sky_glow", glow)
	material.set_shader_parameter("haze_light", haze)
	material.set_shader_parameter("veil", 1.0 - seen_shade)
	material.set_shader_parameter("sun_dir", sun)
	# Tu is lit in space, whether or not the sun is up here.
	material.set_shader_parameter("sun_light", Weather._linear(Weather.SUN_COLOR) * _sun_energy)
	material.set_shader_parameter("tu_dir", tu)
	material.set_shader_parameter("tu_radius", radius)
	# Tu spins about Zan's own axis.
	material.set_shader_parameter("tu_pole", Vector3(0.0, sin(moon.latitude), -cos(moon.latitude)))
	material.set_shader_parameter("tu_time", t)
	material.set_shader_parameter("tu_spin", _day.tu_turn(t))
	material.set_shader_parameter("to_stars", _day.stars_from(t, moon.latitude, moon.longitude))
	material.set_shader_parameter("eclipse", _day.eclipse(t))
	material.set_shader_parameter("eclipse_air", ring_air)
	_show_relay(t)
	_show_satellites(t)
	_face.set_light("tu_dir", tu)
	_face.set_light("tu_edge", Vector2(cos(radius + TU_EDGE), cos(radius - TU_EDGE)))
	_face.set_light("sun_shown", sun_shown)

	# The storms between you and Tu dim its light as they do the sun's.
	var through := maxf(_face.sun_at(eye, tu), seen_shade * 0.6)
	var energy := _sun_energy * tu_light * through * dim
	_tu_shine.light_energy = energy
	# By day it's lost in the sun's light, so it isn't drawn at all.
	_tu_shine.visible = energy > 1e-5 and energy > 0.01 * _sun.light_energy
	if _tu_shine.visible:
		_tu_shine.global_basis = Basis.looking_at(-tu, Vector3.UP if absf(tu.y) < 0.9 else Vector3.FORWARD)
	# One light casts shadows at a time, so the sun keeps the whole shadow map.
	var tu_leads := energy > _sun.light_energy
	if _tu_shine.shadow_enabled != tu_leads:
		_tu_shine.shadow_enabled = tu_leads
		_sun.shadow_enabled = not tu_leads
	tu_seen = energy / _sun_energy * maxf(tu.y, 0.0)
	_report(t, tu)
	if _world.counts_deeds:
		_deeds(t, sun, sun_shown, tu)


## What the sky shows you counts: an eclipse watched whole in the open, from
## the sun going in until it's out again, Tu overhead, or Tu never rising.
func _deeds(t: float, sun: Vector3, sun_shown: float, tu: Vector3) -> void:
	var moon := _world.moon
	var open := _world.weather.shelter_at(_world.player.global_position, &"storm") <= 0.0
	if sun_shown >= 1.0:
		if watched == TOTAL:
			Deeds.done(_world, &"totality")
		watched = CLEAR
	elif watched == CLEAR:
		watched = GOING_IN if open and sun.y > 0.0 and absf(t - _watched_at) < JUMP else MISSED
	elif not open or sun.y <= 0.0 or absf(t - _watched_at) >= JUMP:
		watched = MISSED
	elif sun_shown <= 0.0 and watched == GOING_IN:
		watched = TOTAL
	_watched_at = t
	if tu.y >= cos(deg_to_rad(_world.tuning.deed_tu_overhead_degrees)):
		Deeds.done(_world, &"under_tu")
	if _day.never_rises(moon.latitude, moon.longitude):
		Deeds.done(_world, &"dark_side")


## The relay satellite, a bright point crossing the night sky while it's over
## the horizon and the sun lights it, gone into Zan's shadow; the stars' own
## darkness decides whether it shows.
func _show_relay(t: float) -> void:
	var moon := _world.moon
	var relay := Radio.relay_of(_world)
	var p := Sphere.point(moon.latitude, moon.longitude)
	var to := relay.at(t) - p
	var dir := DayCycle.local(to.normalized(), moon.latitude, moon.longitude)
	var lit := relay.sunlit(t, _day.sun_toward(t))
	var up := smoothstep(0.0, deg_to_rad(4.0), asin(clampf(dir.y, -1.0, 1.0)))
	var light := RELAY_LIGHT * up * (1.0 if lit else 0.0) * Radio.constellation_of(_world).glint(&"relay", t) \
		* relay.nearness(t)
	material.set_shader_parameter("relay_dir", dir)
	material.set_shader_parameter("relay_light", light)
	material.set_shader_parameter("relay_day", smoothstep(DAY_FROM, DAY_FULL, light))


## The other satellites, each as the constellation has it look, while it's
## over the horizon and the sun lights it; one that blinks, blinking.
func _show_satellites(t: float) -> void:
	var moon := _world.moon
	var sky := Radio.constellation_of(_world)
	var p := Sphere.point(moon.latitude, moon.longitude)
	var sun := _day.sun_toward(t)
	var dirs := PackedVector3Array()
	var colors := PackedColorArray()
	var forms := PackedVector3Array()
	for id: StringName in Constellation.voiced():
		var orbit: Satellite = sky.orbits[id]
		var look: Dictionary = sky.rows[id].look
		if look.get("hidden", false):
			# Heard and never seen: the one round Tu.
			dirs.append(Vector3.DOWN)
			colors.append(Color(0.0, 0.0, 0.0, 0.0))
			forms.append(Vector3.ZERO)
			continue
		var to := orbit.at(t) - p
		var dir := DayCycle.local(to.normalized(), moon.latitude, moon.longitude)
		if look.shape == Constellation.Shape.HULK:
			# Only this finite ship has observer parallax; the ephemerides stay intact.
			var camera := get_viewport().get_camera_3d()
			if camera != null:
				to -= p * (maxf(camera.global_position.y, 0.0) / orbit.radius)
				dir = DayCycle.local(to.normalized(), moon.latitude, moon.longitude)
			_show_crop_survey(t, orbit, dir, to.length() * orbit.radius, sky.flash(id, t))
			dirs.append(dir)
			colors.append(Color(0.0, 0.0, 0.0, 0.0))
			forms.append(Vector3(look.shape, 0.0, 0.0))
			continue
		var up := smoothstep(0.0, deg_to_rad(4.0), asin(clampf(dir.y, -1.0, 1.0)))
		var near := orbit.nearness(t)
		var lit := 1.0 if orbit.sunlit(t, sun) else 0.0
		if look.get("low", false):
			# So low it shows as its shadow, sunlit or not; and as big as it is near:
			# overhead at its own height, the size it's drawn; out toward the horizon, smaller.
			lit = 1.0
			near = clampf(orbit.height(t) * orbit.radius / maxf(to.length() * orbit.radius, 1.0), LOW_SMALLEST, 1.0)
		var light: float = look.light * up * lit * (near if not look.get("low", false) else 1.0)
		if look.get("blink", false) and fposmod(t + float(hash(id) % 100) * 0.01, 1.2) > 0.25:
			light *= 0.15
		light *= sky.glint(id, t)
		# A decaying one flares as it fires its burn; one that fires its cannon, as it fires.
		if sky.burning(id, t):
			light *= Constellation.BURN_FLARE
		var flash := sky.flash(id, t)
		light *= flash
		var color: Color = look.color
		color.a = light
		dirs.append(dir)
		colors.append(color)
		# Nearer, it looks a little bigger too; a low one, as big as it is near. By day
		# only the nearest and brightest show; a low hull always.
		# A muzzle flash shows by day as well as night, whitening as it flares.
		if flash > 1.0:
			color = color.lerp(Color.WHITE, 0.6)
			color.a = light
			colors[-1] = color
		var by_day := 1.0 if look.get("low", false) or flash > 1.0 else smoothstep(DAY_FROM, DAY_FULL, light)
		forms.append(Vector3(look.shape, look.size * (near if look.get("low", false) else sqrt(near)), by_day))
	material.set_shader_parameter("sat_count", dirs.size())
	material.set_shader_parameter("sat_dir", dirs)
	material.set_shader_parameter("sat_color", colors)
	material.set_shader_parameter("sat_form", forms)


## The crop survey where its orbit has it, `dir` from you and `metres` off,
## lit by the scene's sun, its muzzle flashing as `flash` (the constellation's,
## 1 when it isn't firing) says.
func _show_crop_survey(t: float, orbit: Satellite, dir: Vector3, metres: float, flash: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		crop_survey.visible = false
		return
	var moon := _world.moon
	var along := DayCycle.local((orbit.at(t + 1.0) - orbit.at(t)).normalized(), moon.latitude, moon.longitude)
	var up := DayCycle.local(orbit.at(t).normalized(), moon.latitude, moon.longitude)
	crop_survey.place(camera.global_position, dir, metres, along, up)
	var ambient := _environment.ambient_light_color * _environment.ambient_light_energy
	crop_survey.light(-_sun.global_basis.z, _sun.light_color.srgb_to_linear() * _sun.light_energy if _sun.visible
		else Color.BLACK, ambient)
	crop_survey.flash((flash - 1.0) / (Constellation.MUZZLE_FLARE - 1.0))


func _report(t: float, tu: Vector3) -> void:
	# Compass bearing to Tu; north is -z.
	var bearing := fposmod(rad_to_deg(atan2(tu.x, -tu.z)), 360.0)
	Dev.put("sky/tu", "%d° %d° up %03d %d%% lit" % [roundi(_world.tuning.tu_degrees),
		roundi(rad_to_deg(asin(clampf(tu.y, -1.0, 1.0)))), roundi(bearing) % 360, roundi(_day.tu_lit(t) * 100.0)])
	var eta := _day.next_eclipse(t) - _day.totality() * 0.5 - t
	Dev.put("sky/ecl", "now" if _day.sun_shown(t) < 1.0 else "%d:%02d" % [floori(eta / 60.0), floori(fmod(eta, 60.0))])
