extends DeviceProbe
## Water probe 2: a hose holds, until it pops. A floating planter hosed to a
## condenser on a staked plate stays on the end of its hose in a 15 m/s wind. In a 40 m/s
## storm wind the same hose pops an end out of a water socket rather than
## snapping, and the planter blows away; a rope beside it, tied to its
## plate, under the same pull, holds its planter.

const MODERATE := 15.0
const STORM := 40.0


func run() -> void:
	# The wind a probe picks is the wind felt: no dune's lee takes any of it.
	Tuning.current().lee_wind = 0.0
	Tuning.current().lee_storm = 0.0
	await load_world(1234, false)
	_blow(MODERATE)
	var wind := world.weather.field.prevailing_at(world.time)
	var downwind := Vector3(wind.x, 0.0, wind.y).normalized()
	world.time_warp = 0.0
	var hosed := _rig(false, Vector3(downwind.z, 0, -downwind.x) * 6.0, downwind)
	var roped := _rig(true, Vector3(-downwind.z, 0, downwind.x) * 6.0, downwind)
	var hose: Hose = hosed.hose
	var reach: float = hose.length * (1.0 + hose.rope.max_stretch) + 1.5
	var seen := await _blown(15.0, hosed, roped)
	print("%.0f m/s: the hose %.0f N at most, its planter %.2f m off (reach %.2f)" % [MODERATE, seen.hose_n, seen.far, reach])
	check(hose.joined().size() == 2 and seen.far <= reach and seen.hose_n > 0.0,
		"in a moderate wind the hose holds its planter on its end")
	_blow(STORM)
	seen = await _blown(20.0, hosed, roped)
	var gone: float = hosed.condenser.global_position.distance_to(hosed.planter.global_position)
	print("%.0f m/s: the hose %.0f N at most, its planter %.1f m off; the rope %.0f N at most, its planter %.2f m off"
		% [STORM, seen.hose_n, gone, seen.rope_n, seen.held])
	check(hose.joined().is_empty() and hose.rope != null and gone > 15.0,
		"in a storm wind it pops an end rather than snapping, and the planter blows away")
	check(roped.line.rope != null and seen.rope_n > world.tuning.hose_holding and seen.held <= reach,
		"a rope under the same pull holds its planter")


## Wind everywhere at `speed`, steady.
func _blow(speed: float) -> void:
	var tuning := Tuning.current()
	tuning.prevailing_speed = speed
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)


## `seconds` of wind on both rigs: the most each line bore while it held, N,
## and how far the hosed planter and the roped one got from their condensers.
func _blown(seconds: float, hosed: Dictionary, roped: Dictionary) -> Dictionary:
	var seen := {"hose_n": 0.0, "rope_n": 0.0, "far": 0.0, "held": 0.0}
	var hose: Hose = hosed.hose
	for i in roundi(seconds * 60.0):
		await get_tree().physics_frame
		if hose.joined().size() == 2:
			seen.hose_n = maxf(seen.hose_n, hose.rope.sustained)
			seen.far = maxf(seen.far, hosed.condenser.global_position.distance_to(hosed.planter.global_position))
		if roped.line.rope != null:
			seen.rope_n = maxf(seen.rope_n, roped.line.rope.sustained)
		seen.held = maxf(seen.held, roped.condenser.global_position.distance_to(roped.planter.global_position))
	return seen


## A condenser on a staked plate and a floating planter 3 m downwind of it,
## on a hose from water socket to water socket, or tied from the plate's
## hook to the planter's instead if `tied`.
func _rig(tied: bool, offset: Vector3, downwind: Vector3) -> Dictionary:
	var plate := spawn_device(&"chassis", 0.0, 0.07, false) as Chassis
	plate.global_position += offset
	plate.freeze = true
	var condenser := Catalog.device(&"condenser") as Device
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, condenser)
	var planter := spawn_device(&"planter", 0.0, 1.2, false)
	planter.global_position = condenser.global_position + downwind * 3.0 + Vector3.UP * 1.2
	fit_part(planter, &"hover_tray")
	fit_part(planter, &"battery")
	var out := {"condenser": condenser, "planter": planter}
	if tied:
		fit_part(plate, &"hook")
		fit_part(planter, &"hook")
		var a := planter.free_tie(condenser.global_position)
		out.line = Line.between(world, a, plate.free_tie(a.global_position), 0.3)
	else:
		out.hose = Scenarios.plumb(world, condenser, planter)
	return out
