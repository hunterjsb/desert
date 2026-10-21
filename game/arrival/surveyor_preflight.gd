class_name SurveyorPreflight
extends Node
## Walk, choose and load in the same saved World before its existing flight.

var arrival: SurveyorArrival
var world: World
var ship: SurveyorShip
var computer: Control
var _modal: CanvasLayer
var _cargo: Script
var _disposed := false
var _warp := 1.0
var _vitals := true
var _camera_at := Vector3.ZERO
var _camera_turn := Vector3.ZERO


func setup(controller: SurveyorArrival) -> void:
	arrival = controller
	world = arrival.world
	_warp = float(world.arrival_state.get("flight_warp", world.time_warp))
	_vitals = world.player.vitals.is_physics_processing()
	world.time_warp = 0.0
	world.player.vitals.set_physics_process(false)
	_cargo = load("res://game/arrival/preflight_cargo.gd")
	var state := world.arrival_state
	var fresh := not state.has("preflight")
	if fresh:
		var at := Vector2(world.player_world_x(), world.player_world_z())
		state.preflight = {"version": 1, "ship_world": at,
			"ship_y": world.height_at(at.x, at.y) + float(_rules().ship_height_m),
			"seated": false, "loaded_uids": [], "launched": false, "plan_confirmed": false}
	var saved: Dictionary = state.preflight
	var at: Vector2 = saved.ship_world
	ship = SurveyorShip.new()
	world.content.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, Vector3(world.engine_x(at.x), saved.ship_y, world.engine_z(at.y))), fresh)
	if fresh:
		_cargo.call(&"stage", world, ship, state)
	else:
		ship.pod = Rig.new()
		var restored := SurveyorRecovery.named(world)
		for spec: Array in SurveyorManifest.STRUCTURE:
			var role: StringName = spec[0]
			if restored.has(role):
				ship.pod.named[role] = restored[role]
		var floor := ship.pod.named.get(&"floor_a") as Chassis
		if is_instance_valid(floor):
			ship.pod.deck = floor.deck if floor.deck != null else floor
	world.arrival_nodes = SurveyorRecovery.named(world)
	var shelter := Shelter.new()
	shelter.position = Vector3(0, 1, -1)
	shelter.radius = float(_rules().cabin_radius_m)
	shelter.blocks = {&"wind": 1.0, &"storm": 1.0, &"temperature": 1.0}
	ship.add_child(shelter)
	if not state.has("landing_plan"):
		var anchor := Sites.Anchor.new(at.x, at.y,
			Sphere.point(world.moon.latitude, world.moon.longitude), -world.moon.north().z, world.moon.radius)
		state.landing_plan = LandingPlan.build(world.shape, anchor)
	_view_plan()
	if fresh:
		world.teleport(world.player, ship.spawn_at.global_transform)
		world.player.velocity = Vector3.ZERO
		world.player.camera.rotation = Vector3(0, 0, 0)
	if saved.seated:
		_seat()
	else:
		_walk()
	world.set_meta(&"kit", world.arrival_nodes.values())
	world.player.hands.say("Scout a landing zone at the computer. Load the pod, then enter it.")


func _rules() -> Dictionary:
	return world.tuning.surveyor_preflight


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(ship) or not is_instance_valid(world):
		return
	if world.player.global_position.y < ship.global_position.y - 3.0:
		world.teleport(world.player, ship.spawn_at.global_transform)
		world.player.velocity = Vector3.ZERO


func interact() -> bool:
	if is_instance_valid(computer) or world.player.hands.held != null:
		return false
	if world.arrival_state.preflight.seated:
		launch()
		return true
	if _computer_aim():
		open_computer()
		return true
	if _pod_aim():
		world.arrival_state.preflight.seated = true
		_seat()
		return true
	return false


func take() -> bool:
	if not world.arrival_state.preflight.seated or is_instance_valid(computer):
		return false
	world.arrival_state.preflight.seated = false
	_walk()
	world.player.restore_ground_pose(&"stand")
	world.teleport(world.player, ship.pod_entry_at.global_transform)
	world.player.camera.position = Vector3(_camera_at.x, world.player.posture.standing_eye, _camera_at.z)
	world.player.camera.rotation = _camera_turn
	return true


func hint() -> String:
	if not is_instance_valid(ship) or is_instance_valid(computer) or world.player.hands.held != null:
		return ""
	if world.arrival_state.preflight.seated:
		return "%s · launch pod   %s · leave seat" % [Controls.key_for(&"interact"), Controls.key_for(&"hands_grab")]
	if _computer_aim():
		return Controls.key_for(&"interact") + " · scout and plan landing"
	if _pod_aim():
		return Controls.key_for(&"interact") + " · enter pod"
	return ""


func _computer_aim() -> bool:
	var camera := world.player.camera
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position - camera.global_basis.z * float(_rules().interact_m), 1, [world.player.get_rid()])
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == ship.computer_body


func _pod_aim() -> bool:
	var camera := world.player.camera
	var toward := ship.pod_entry_at.global_position + Vector3.UP * 0.5 - camera.global_position
	return toward.length() < float(_rules().interact_m) and -camera.global_basis.z.dot(toward.normalized()) > 0.65


func open_computer() -> void:
	if is_instance_valid(computer):
		return
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	world.player.hands.set_process_unhandled_input(false)
	world.player.suit.set_process_unhandled_input(false)
	_modal = CanvasLayer.new()
	_modal.layer = 105
	add_child(_modal)
	computer = LaunchComputer.new()
	_modal.add_child(computer)
	computer.setup(world, world.arrival_state.landing_plan, _plan_changed)
	computer.closed.connect(close_computer)


func close_computer() -> void:
	if is_instance_valid(computer):
		computer.dispose()
	computer = null
	if is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	if is_instance_valid(world):
		_walk()


func _plan_changed(plan: Dictionary) -> void:
	var anchor := LandingPlan.anchor_for(plan, world.moon.radius)
	if not LandingPlan.validate(world.shape, anchor, plan):
		world.player.hands.say("That landing zone is no longer clear.")
		return
	world.arrival_state.landing_plan = plan.duplicate(true)
	world.arrival_state.preflight.plan_confirmed = true
	_view_plan()
	Deeds.done(world, &"plot_course")


func _view_plan() -> void:
	var plan: Dictionary = world.arrival_state.get("landing_plan", {})
	var selected := LandingPlan.selected(plan)
	if not selected.is_empty():
		ship.set_view(selected.point, plan.heading)


func readiness() -> PackedStringArray:
	var missing: PackedStringArray = _cargo.call(&"readiness", world, ship)
	if not world.arrival_state.preflight.get("plan_confirmed", false):
		missing.insert(0, "Choose a landing zone at the computer")
	var plan: Dictionary = world.arrival_state.landing_plan
	if not LandingPlan.validate(world.shape, LandingPlan.anchor_for(plan, world.moon.radius), plan):
		missing.append("Choose a clear landing zone")
	return missing


func launch() -> bool:
	if not world.arrival_state.preflight.seated:
		return false
	var missing := readiness()
	if not missing.is_empty():
		world.player.hands.say("Before launch: " + "; ".join(missing))
		return false
	var plan: Dictionary = world.arrival_state.landing_plan
	var profile: Dictionary = _rules().profiles[String(plan.profile)].duplicate(true)
	var candidate := world.arrival_state.duplicate(true)
	candidate.landing_point = LandingPlan.selected(plan).point
	var sealed: Dictionary = _cargo.call(&"seal", world, ship, candidate, profile)
	if sealed.is_empty():
		world.player.hands.say("Cargo could not be secured. Check the pod.")
		return false
	world.arrival_state = sealed
	var selected := LandingPlan.selected(plan)
	sealed.landing_point = selected.point
	sealed.landing_world = selected.landing_world
	sealed.heading = plan.heading
	sealed.exit_world = selected.landing_world + Vector2(-world.tuning.surveyor_arrival.exit_offset_m, 0).rotated(-plan.heading)
	sealed.phase = &"ejection"
	sealed.elapsed = 0.0
	sealed.progress = 0.0
	sealed.phase_seconds = world.tuning.surveyor_arrival.ejection_s
	sealed.materialized = false
	_move_transport(selected.landing_world)
	Deeds.done(world, &"pod_launch")
	dispose()
	arrival.restore()
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


func _seat() -> void:
	_camera_at = world.player.camera.position
	_camera_turn = world.player.camera.rotation
	world.player.restore_ground_pose(&"prone")
	world.teleport(world.player, ship.pod_seat_at.global_transform)
	world.player.camera.position.y = float(_rules().seat_eye_m)
	world.player.camera.rotation = Vector3(0.1, 0, 0)
	world.player.velocity = Vector3.ZERO
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	world.player.hands.set_process_unhandled_input(true)
	world.player.suit.set_process_unhandled_input(false)
	world.player.body.set_process(false)
	world.player.body.hide()


func _walk() -> void:
	world.player.set_physics_process(true)
	world.player.set_process_unhandled_input(true)
	world.player.hands.set_process_unhandled_input(true)
	world.player.suit.set_process_unhandled_input(true)
	world.player.body.set_process(true)
	world.player.body.show()


func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	close_computer()
	if is_instance_valid(ship):
		ship.queue_free()
	ship = null
	if is_instance_valid(world):
		_walk()
		world.player.restore_ground_pose(&"stand")
		world.player.vitals.set_physics_process(_vitals)
		world.time_warp = _warp
	queue_free()
