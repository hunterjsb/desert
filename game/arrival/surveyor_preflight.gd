class_name SurveyorPreflight
extends Node
## Walk, choose and load in the same saved World before the flight.

var arrival: SurveyorArrival
var world: World
var ship: SurveyorShip
var computer: PhysicalLaunchStation
## The one forecast the station shows, readiness judges and launch flies.
var forecast := {}
var _disposed := false
var _warp := 1.0
var _cabin: PlayerHold
var _seat: PlayerHold
var _camera_at := Vector3.ZERO
var _camera_turn := Vector3.ZERO
var _forecast_at := -INF
var _ready := PackedStringArray()
var _ready_fresh := false
## Seated, the one line sits low, clear of the window view.
var _prompt := Label.new()


func setup(controller: SurveyorArrival) -> void:
	arrival = controller
	world = arrival.world
	_warp = float(world.arrival_state.get("flight_warp", world.time_warp))
	world.time_warp = 0.0
	_cabin = PlayerHold.new(world.player)
	_cabin.take(PlayerHold.VITALS)
	_seat = PlayerHold.new(world.player)
	var state := world.arrival_state
	var fresh := not state.has("preflight")
	if fresh:
		var at := Vector2(world.player_world_x(), world.player_world_z())
		state.preflight = {"version": 1, "ship_world": at,
			"ship_y": world.height_at(at.x, at.y) + world.tuning.arrival_ship_height_m,
			"seated": false, "loaded_uids": [], "launched": false, "plan_confirmed": false}
	var saved: Dictionary = state.preflight
	var at: Vector2 = saved.ship_world
	ship = SurveyorShip.new()
	world.content.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, Vector3(world.engine_x(at.x), saved.ship_y, world.engine_z(at.y))), fresh)
	if fresh:
		PreflightCargo.stage(world, ship, state)
	else:
		ship.pod = Rig.new()
		var restored := SurveyorRecovery.named(world)
		for spec: Array in SurveyorManifest.STRUCTURE:
			if restored.has(spec[0]):
				ship.pod.named[spec[0]] = restored[spec[0]]
		var floor := ship.pod.named.get(&"floor_a") as Chassis
		if is_instance_valid(floor):
			ship.pod.deck = floor.deck if floor.deck != null else floor
	world.arrival_nodes = SurveyorRecovery.named(world)
	var shelter := Shelter.new()
	shelter.position = Vector3(0, 1, -1)
	shelter.radius = world.tuning.arrival_cabin_radius_m
	shelter.blocks = {&"wind": 1.0, &"storm": 1.0, &"temperature": 1.0}
	ship.add_child(shelter)
	if not state.has("landing_plan"):
		var anchor := Sites.Anchor.new(at.x, at.y,
			Sphere.point(world.moon.latitude, world.moon.longitude), -world.moon.north().z, world.moon.radius)
		state.landing_plan = LandingPlan.build(world.shape, anchor, world.tuning)
	if not saved.has("departure_time"):
		saved.departure_time = world.time
	# A model this build cannot fly is made again rather than leaving the station dead.
	if not DepartureTrajectory.valid(state.landing_plan.get("departure_trajectory", {})):
		state.landing_plan.departure_trajectory = DepartureTrajectory.build(state.landing_plan, saved.departure_time, world.tuning)
		saved.plan_confirmed = false
	computer = PhysicalLaunchStation.new()
	ship.add_child(computer)
	computer.setup(world, ship, self)
	computer.closed.connect(close_computer)
	if fresh:
		world.teleport(world.player, ship.spawn_at.global_transform)
		world.player.velocity = Vector3.ZERO
		world.player.camera.rotation = Vector3.ZERO
	if saved.seated:
		_sit()
	world.set_meta(&"kit", world.arrival_nodes.values())
	var layer := CanvasLayer.new()
	add_child(layer)
	_prompt.theme = preload("res://game/ui/theme.tres")
	_prompt.theme_type_variation = &"AsideValue"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -500.0
	_prompt.offset_right = 500.0
	_prompt.offset_top = -96.0
	_prompt.offset_bottom = -56.0
	_prompt.hide()
	refresh_forecast()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(ship) or not is_instance_valid(world):
		return
	var saved: Dictionary = world.arrival_state.preflight
	saved.departure_time = float(saved.get("departure_time", world.time)) + delta
	var clock := float(saved.departure_time)
	ship.set_departure_sample(DepartureTrajectory.frame(model(), clock), clock)
	if clock - _forecast_at >= world.tuning.arrival_forecast_s or clock < _forecast_at:
		refresh_forecast()
	ship.show_ready(readiness().is_empty())
	if world.player.global_position.y < ship.global_position.y - 3.0:
		world.teleport(world.player, ship.spawn_at.global_transform)
		world.player.velocity = Vector3.ZERO


## Until launch or cancel; a station may outlive the state by a frame.
func preparing() -> bool:
	return not _disposed and is_instance_valid(world) and world.arrival_state.get("phase") == &"preflight"


func model() -> Dictionary:
	return world.arrival_state.get("landing_plan", {}).get("departure_trajectory", {})


func clock() -> float:
	return float(world.arrival_state.get("preflight", {}).get("departure_time", world.time))


## The landing moves as the moon turns; this is the only place it is judged.
func refresh_forecast() -> void:
	forecast = DepartureTrajectory.resolve(world.shape, world.arrival_state.landing_plan, model(), clock(), world.tuning)
	_forecast_at = clock()
	_ready_fresh = false
	# Refitted panels make new surfaces; everything aboard stays as clean as space.
	PodShell.seal_weather(world.arrival_nodes.values(), true)


## A dragged pulse is pending until set; the next tick forecasts it.
func drag_pulse(origin: Vector3, direction: Vector3) -> void:
	var dragged := DepartureTrajectory.drag(model(), clock(), origin, direction)
	if dragged.is_empty():
		return
	world.arrival_state.landing_plan.departure_trajectory = dragged
	world.arrival_state.preflight.plan_confirmed = false
	_forecast_at = -INF
	_ready_fresh = false


func commit_pulse() -> bool:
	refresh_forecast()
	if not forecast.get("safe", false):
		return false
	world.arrival_state.landing_plan = (forecast.plan as Dictionary).duplicate(true)
	world.arrival_state.preflight.plan_confirmed = true
	_ready_fresh = false
	Deeds.done(world, &"plot_course")
	return true


func interact() -> bool:
	if computer_open() or world.player.hands.held != null:
		return false
	if world.arrival_state.preflight.seated:
		launch()
		return true
	if _computer_aim():
		open_computer()
		return true
	if _pod_aim():
		world.arrival_state.preflight.seated = true
		_sit()
		return true
	return false


func take() -> bool:
	if not world.arrival_state.preflight.seated or computer_open():
		return false
	world.arrival_state.preflight.seated = false
	_seat.release()
	world.player.restore_ground_pose(&"stand")
	world.teleport(world.player, ship.pod_entry_at.global_transform)
	world.player.camera.position = Vector3(_camera_at.x, world.player.posture.standing_eye, _camera_at.z)
	world.player.camera.rotation = _camera_turn
	return true


## One line: the action, or the first thing actually in the way. Seated, it shows low.
func hint() -> String:
	if not is_instance_valid(ship) or computer_open() or world.player.hands.held != null \
			or world.arrival_state.preflight.seated:
		return ""
	var missing := readiness()
	if _computer_aim():
		return Controls.key_for(&"interact") + " · launch computer"
	if _pod_aim():
		return Controls.key_for(&"interact") + " · enter pod" + ("" if missing.is_empty() else "   " + missing[0])
	return ""


func seated_line() -> String:
	var missing := readiness()
	var first := Controls.key_for(&"interact") + " · launch pod" if missing.is_empty() else missing[0]
	return "%s   %s · leave seat" % [first, Controls.key_for(&"hands_grab")]


func _process(_delta: float) -> void:
	var seated: bool = is_instance_valid(ship) and world.arrival_state.get("preflight", {}).get("seated", false)
	_prompt.visible = seated and Controls.playing() and not computer_open()
	if _prompt.visible:
		_prompt.text = seated_line()


func _computer_aim() -> bool:
	var camera := world.player.camera
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position - camera.global_basis.z * world.tuning.arrival_interact_m, 1, [world.player.get_rid()])
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == ship.computer_body


func _pod_aim() -> bool:
	var camera := world.player.camera
	var toward := ship.pod_entry_at.global_position + Vector3.UP * 0.5 - camera.global_position
	return toward.length() < world.tuning.arrival_interact_m and -camera.global_basis.z.dot(toward.normalized()) > 0.65


func computer_open() -> bool:
	return is_instance_valid(computer) and computer.focused


func open_computer() -> void:
	if computer_open() or not is_instance_valid(computer):
		return
	_seat.take(PlayerHold.WALK | PlayerHold.HANDS | PlayerHold.SUIT)
	computer.enter()


func close_computer() -> void:
	if computer_open():
		computer.leave()
		return
	if is_instance_valid(world) and not _disposed:
		_seat.release()


## Empty means the next launch goes. Judged with each forecast, and again at launch itself.
func readiness() -> PackedStringArray:
	if _ready_fresh:
		return _ready
	_ready_fresh = true
	_ready = PreflightCargo.readiness(world, ship)
	if not world.arrival_state.preflight.get("plan_confirmed", false):
		_ready.insert(0, "Set a launch pulse at the station")
	elif not forecast.get("safe", false):
		_ready.insert(0, "The landing has drifted %s; set a new pulse" % (
			"out of the survey" if not forecast.get("sample", {}).get("inside_survey", false) else "onto rough ground"))
	return _ready


func launch() -> bool:
	if not world.arrival_state.preflight.seated:
		return false
	_ready_fresh = false
	var missing := readiness()
	if not missing.is_empty():
		world.player.hands.say(missing[0])
		return false
	var plan: Dictionary = forecast.plan
	var selected := LandingPlan.selected(plan)
	var sample: Dictionary = forecast.sample
	# Fly the forecast that was shown, from its own moment.
	world.arrival_state.preflight.departure_time = float(forecast.clock)
	var candidate := world.arrival_state.duplicate(true)
	candidate.landing_plan = plan
	candidate.landing_point = selected.point
	var sealed := PreflightCargo.seal(world, ship, candidate, SurveyorManifest.approach(world.tuning, plan.profile))
	world.arrival_state = sealed
	sealed.landing_world = selected.landing_world
	sealed.heading = plan.heading
	sealed.exit_world = selected.landing_world + Vector2(world.tuning.arrival_exit_offset_m, 0).rotated(-plan.heading)
	sealed.phase = &"ejection"
	sealed.elapsed = 0.0
	sealed.progress = 0.0
	sealed.phase_seconds = world.tuning.arrival_ejection_s
	sealed.materialized = false
	sealed.preflight.flight_sample = sample
	sealed.preflight.flight_s = sample.flight_s
	sealed.preflight.profile.descent_s = maxf(float(sample.flight_s) - world.tuning.arrival_ejection_s - float(sealed.preflight.profile.entry_s), 0.1)
	sealed.flight_elapsed = 0.0
	world.time = float(sealed.preflight.departure_time)
	_move_transport(selected.landing_world)
	Deeds.done(world, &"pod_launch")
	dispose()
	arrival.restore()
	arrival.launch_sound()
	return true


func _move_transport(at: Vector2) -> void:
	var objects := SurveyorRecovery.named(world)
	var wanted := {}
	for entry: Dictionary in world.arrival_state.structure + world.arrival_state.equipment:
		wanted[StringName(entry.uid)] = true
	var delta := Vector3(world.engine_x(at.x), ship.global_position.y, world.engine_z(at.y)) - ship.global_position
	for uid: StringName in objects:
		var body := objects[uid] as RigidBody3D
		if not is_instance_valid(body) or body.get_parent() != world.content:
			continue
		if not wanted.has(uid):
			world.content.remove_child(body)
			body.queue_free()
		else:
			world.teleport(body, body.global_transform.translated(delta))
	world.teleport(world.player, world.player.global_transform.translated(delta))
	world.player.velocity = Vector3.ZERO
	world.arrival_nodes = SurveyorRecovery.named(world)


func _sit() -> void:
	_camera_at = world.player.camera.position
	_camera_turn = world.player.camera.rotation
	world.player.restore_ground_pose(&"prone")
	world.teleport(world.player, ship.pod_seat_at.global_transform)
	world.player.camera.position.y = world.tuning.arrival_seat_eye_m
	world.player.camera.rotation = Vector3(0.1, 0, 0)
	# The look line and its dot stand aside; the seat's own line sits low.
	_seat.take(PlayerHold.WALK | PlayerHold.SUIT | PlayerHold.EYE | PlayerHold.BODY | PlayerHold.FOCUS)


func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	if is_instance_valid(computer):
		computer.dispose()
	computer = null
	if is_instance_valid(ship):
		ship.queue_free()
	ship = null
	if is_instance_valid(world):
		_seat.release()
		world.player.restore_ground_pose(&"stand")
		_cabin.release()
		world.time_warp = _warp
	queue_free()
