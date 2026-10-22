class_name CampHome
extends Node
## One claimed travelling camp. Ground support is confirmed by Terrain, not the marker.
var world: World
var beacon: HomeBeacon
var root: Chassis
var members: Array[RigidBody3D] = []
var anchor: Sites.Anchor
var bounds := Rect2()
## Written by Terrain alone: Home's ground and collision are in place.
var supported := false
## Why the last growth was refused; Home itself is the only writer.
var attention := ""
var restoring := false
## World checks the complete support budget before admission and safe retirement.
var admit: Callable
var release_check: Callable
var _marked := false
var _envelopes: Array = []
var _fix := Vector3.ZERO
var _has_fix := false
var _departed := false
## Members as a set, so every body's per-tick check is a lookup.
var _set := {}
## A rebuild waits for something to change: bodies arriving or leaving, a rope,
## a join, or the slow sweep that notices belongings drifting into the shield.
var _dirty := true
var _sweep := 0.0
var _rope_count := -1
## The root's place at the last rebuild; between rebuilds the footprint follows it.
var _root_at := Vector2.ZERO
var _rebuilt_bounds := Rect2()
var _content: Node
var _board: Node
var _held: Node

func _ready() -> void:
	if world != null and world.content != null:
		world.content.child_entered_tree.connect(_touch)
		world.content.child_exiting_tree.connect(_touch)

func _touch(_node: Node) -> void:
	_dirty = true

func has_home() -> bool:
	return _marked

func contains(body: Node) -> bool:
	if not is_instance_valid(body):
		return false
	var actual := _physical(body)
	return actual != null and _set.has(actual)

func mark(marker: HomeBeacon) -> String:
	if not is_instance_valid(marker) or marker.wrecked():
		return "beacon is damaged"
	var deck := deck_of(marker)
	if deck == null:
		return "mount the beacon on a chassis first"
	if not _owned(deck) or not _owned(marker):
		return "claim this chassis first"
	if _marked and (marker != beacon or deck != root):
		var unsafe := _release_reason()
		if unsafe != "":
			return unsafe
	var envelopes := _shield_envelopes(deck)
	var graph := _graph(deck, envelopes)
	var footprint := _footprint(graph)
	var why := _admission(graph, footprint)
	if why != "":
		return why
	root = deck
	beacon = marker
	_envelopes = envelopes
	_adopt(graph, footprint)
	var player_anchor := Sites.Anchor.new(world.player_world_x(), world.player_world_z(),
		Sphere.point(world.moon.latitude, world.moon.longitude), -world.moon.north().z, world.shape.history.radius)
	var x := world.world_x(root.global_position.x)
	var z := world.world_z(root.global_position.z)
	anchor = Sites.Anchor.new(x, z, player_anchor.point_at(x, z), player_anchor.facing, player_anchor.radius)
	_marked = true
	_fix = anchor.p
	_has_fix = true
	_departed = false
	supported = false
	attention = ""
	return ""

func unmark() -> String:
	if not _marked:
		return ""
	var why := _release_reason()
	if why != "":
		return why
	_clear()
	return ""

func _clear() -> void:
	_marked = false
	restoring = false
	beacon = null
	root = null
	members.clear()
	_set.clear()
	anchor = null
	bounds = Rect2()
	_envelopes.clear()
	_has_fix = false
	_departed = false
	supported = false
	attention = ""
	_dirty = true

func _release_reason() -> String:
	return release_check.call() if release_check.is_valid() else ""

## Every physics tick, before terrain planning and distant-body retirement.
func tick(delta: float) -> void:
	if not _marked or restoring:
		return
	_sweep -= delta
	var ropes := world.ropes.ropes.size()
	if _dirty or _sweep <= 0.0 or ropes != _rope_count or (is_instance_valid(root) and root.deck != null):
		refresh()
		return
	if is_instance_valid(root) and _rebuilt_bounds.has_area():
		var at := Vector2(world.world_x(root.global_position.x), world.world_z(root.global_position.z))
		bounds = Rect2(_rebuilt_bounds.position + at - _root_at, _rebuilt_bounds.size)
	_receive()

## Rebuilds membership now; additions that exceed the limits are refused together.
func refresh() -> void:
	if not _marked or restoring:
		return
	_dirty = false
	_sweep = world.tuning.home_sweep_s
	_rope_count = world.ropes.ropes.size()
	if not is_instance_valid(root) or root.is_queued_for_deletion():
		attention = "home chassis is missing"
		supported = false
		var alive: Array[RigidBody3D] = []
		for body in members:
			if is_instance_valid(body) and not body.is_queued_for_deletion():
				alive.append(body)
		_adopt(alive, bounds)
		return
	# A joined deck may choose another root without changing its identity.
	root = root.deck if root.deck != null else root
	var shields := _shield_envelopes(root)
	if not shields.is_empty():
		_envelopes = shields
	var graph := _graph(root, _envelopes)
	var footprint := _footprint(graph)
	var why := _admission(graph, footprint)
	if why == "":
		attention = ""
	else:
		# Reject additions together; ordinary removal still works during a refusal.
		var kept: Array[RigidBody3D] = []
		var seen := {}
		var proposed := {}
		for body in graph:
			proposed[body] = true
		for body in members:
			var actual := _physical(body)
			if proposed.has(actual) and not seen.has(actual):
				seen[actual] = true
				kept.append(actual)
		graph = kept
		footprint = _footprint(graph)
		attention = why
	_adopt(graph, footprint)
	_receive()

func _adopt(graph: Array[RigidBody3D], footprint: Rect2) -> void:
	members = graph
	_set.clear()
	for body in graph:
		_set[body] = true
	bounds = footprint
	_rebuilt_bounds = footprint
	if is_instance_valid(root):
		_root_at = Vector2(world.world_x(root.global_position.x), world.world_z(root.global_position.z))

func _admission(graph: Array[RigidBody3D], footprint: Rect2) -> String:
	if _work_count(graph) > world.tuning.home_max_bodies:
		return "too much to keep as one camp"
	if maxf(footprint.size.x, footprint.size.y) > world.tuning.home_span_m:
		return "the camp is spread too wide"
	return admit.call(footprint) if admit.is_valid() else ""

## What Home's members cost against `home_max_bodies`.
func work_count() -> int:
	return _work_count(members)

## Fitted parts and joined pieces still cost work even without active rigid bodies.
func _work_count(graph: Array[RigidBody3D]) -> int:
	var count := graph.size()
	for body in graph:
		if body is Device:
			count += (body as Device).parts().size()
		if body is Chassis:
			count += (body as Chassis).joined.size()
	return count

func _graph(deck: Chassis, envelopes: Array) -> Array[RigidBody3D]:
	var graph: Array[RigidBody3D] = []
	var seen := {}
	# Read once per rebuild: this runs for every body in the world.
	_content = world.content
	_board = world.player.board
	_held = world.player.hands.held
	_add_assembly(deck, graph, seen)
	var to_deck := deck.global_transform.affine_inverse()
	for child in world.content.get_children():
		var body := child as RigidBody3D
		if body == null or seen.has(body):
			continue
		var local := to_deck * body.global_position
		for envelope: Array in envelopes:
			if local.distance_to(envelope[0]) <= envelope[1]:
				_add_assembly(body, graph, seen)
				break
	var expanded := true
	while expanded:
		expanded = false
		for rope in world.ropes.ropes:
			var a := _endpoint(rope.a)
			var b := _endpoint(rope.b)
			var guide := _endpoint(rope.through) if is_instance_valid(rope.through) else null
			if not _eligible(a) or not _eligible(b):
				continue
			if not seen.has(a) and not seen.has(b) and (guide == null or not seen.has(guide)):
				continue
			var count := graph.size()
			_add_assembly(a, graph, seen)
			_add_assembly(b, graph, seen)
			_add_assembly(guide, graph, seen)
			expanded = expanded or graph.size() != count
	return graph

func _add_assembly(body: RigidBody3D, graph: Array[RigidBody3D], seen: Dictionary) -> void:
	body = _physical(body)
	if body == null or seen.has(body) or not _eligible(body):
		return
	seen[body] = true
	graph.append(body)
	if body is Device:
		for mounted in (body as Device).mounted():
			_add_assembly(mounted, graph, seen)

func _eligible(body: RigidBody3D) -> bool:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or body == _board or body == _held:
		return false
	if body.get_parent() != _content and not _content.is_ancestor_of(body):
		return false
	# A member stays claimed: nothing makes a belonging a find again.
	return _set.has(body) or _owned(body)

func _owned(body: Node) -> bool:
	if not is_instance_valid(body) or not body.has_meta(&"catalog"):
		return false
	var at: Node = body
	var content := world.content
	while at != null and at != content:
		if at.has_meta(&"find") or at.has_meta(&"buried") or at.has_meta(&"slot") or at.has_meta(&"unclaimed_rig"):
			return false
		at = at.get_parent()
	return true

## The deck a beacon is fitted to, through any devices between.
func deck_of(marker: HomeBeacon) -> Chassis:
	var at: Device = marker.host()
	while at != null:
		if at is Chassis:
			return at.deck if at.deck != null else at
		at = at.host()
	return null

func _physical(node: Node) -> RigidBody3D:
	if node is Part and (node as Part).socket != null:
		node = (node as Part).socket.get_parent()
	if node is Chassis and (node as Chassis).deck != null:
		node = (node as Chassis).deck
	return node as RigidBody3D

func _endpoint(tip: RopeEnd) -> RigidBody3D:
	if not is_instance_valid(tip) or world.ropes.on_you(tip.holder):
		return null
	var node := tip.get_parent()
	if node is RopeHook and (node as Part).socket != null:
		node = (node as Part).socket.get_parent()
	return _physical(node)

func _shield_envelopes(deck: Chassis) -> Array:
	var found: Array = []
	for node in deck.camp():
		var shield := node as ShieldGenerator
		if is_instance_valid(shield):
			found.append([deck.global_transform.affine_inverse() * shield.global_position, shield.size])
	return found

func _footprint(graph: Array[RigidBody3D]) -> Rect2:
	var rect := Rect2()
	var first := true
	var origin := Vector2(world.world_x(0.0), world.world_z(0.0))
	for body in graph:
		if not is_instance_valid(body) or not body.is_inside_tree():
			continue
		var box: AABB = body.global_transform * (body.shape_bounds() if body is Device else Hands._box_of(body))
		var own := Rect2(Vector2(box.position.x, box.position.z) + origin, Vector2(box.size.x, box.size.z))
		rect = own if first else rect.merge(own)
		first = false
	return rect

func _receive() -> void:
	if not is_instance_valid(root) or anchor == null:
		return
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var home := anchor.point_at(world.world_x(root.global_position.x), world.world_z(root.global_position.z))
	var distance := Sphere.angle(here, home) * anchor.radius
	if is_instance_valid(beacon) and not beacon.wrecked() and beacon.powered and deck_of(beacon) == root and distance <= world.tuning.home_signal_m:
		_fix = home
		_has_fix = true
	if distance >= world.tuning.home_depart_m:
		_departed = true
	elif _departed and supported and distance <= world.tuning.home_return_m:
		Deeds.done(world, &"home_again")
		_departed = false

func nav() -> Dictionary:
	if not _marked:
		return {"marked": false, "supported": false, "live": false, "metres": NAN, "bearing": NAN}
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var home := anchor.point_at(world.world_x(root.global_position.x), world.world_z(root.global_position.z)) if is_instance_valid(root) and anchor != null else _fix
	var live := is_instance_valid(root) and anchor != null and is_instance_valid(beacon) and not beacon.wrecked() and beacon.powered and deck_of(beacon) == root \
		and Sphere.angle(here, home) * anchor.radius <= world.tuning.home_signal_m
	return {"marked": true, "supported": supported, "live": live, "metres": Sphere.angle(here, _fix) * world.shape.history.radius if _has_fix else NAN,
		"bearing": fposmod(Sphere.bearing(here, _fix), TAU) if _has_fix else NAN}

func snapshot(ref: Callable) -> Dictionary:
	if not _marked:
		return {}
	var refs := []
	for body in members:
		if is_instance_valid(body):
			refs.append(ref.call(body))
	return {"root": ref.call(root) if is_instance_valid(root) else -1,
		"beacon": ref.call(beacon) if is_instance_valid(beacon) else -1, "members": refs,
		"bounds": bounds, "anchor": [anchor.x, anchor.z, Sphere.latitude(anchor.p), Sphere.longitude(anchor.p), anchor.facing, anchor.radius] if anchor != null else [],
		"envelopes": _envelopes.duplicate(true), "fix": _fix, "has_fix": _has_fix, "departed": _departed}

func prepare_restore(data: Dictionary) -> void:
	_clear()
	if data.is_empty():
		return
	_marked = true
	restoring = true
	bounds = data.get("bounds", Rect2())
	var a: Array = data.get("anchor", [])
	if a.size() == 6:
		anchor = Sites.Anchor.new(a[0], a[1], Sphere.point(a[2], a[3]), a[4], a[5])
	_envelopes = data.get("envelopes", []).duplicate(true)
	_fix = data.get("fix", Vector3.ZERO)
	_has_fix = data.get("has_fix", false)
	_departed = data.get("departed", false)

func finish_restore(data: Dictionary, resolve: Callable) -> void:
	if data.is_empty():
		return
	restoring = false
	root = resolve.call(data.get("root", -1)) as Chassis
	beacon = resolve.call(data.get("beacon", -1)) as HomeBeacon
	var restored: Array[RigidBody3D] = []
	for saved in data.get("members", []):
		var body := resolve.call(saved) as RigidBody3D
		if is_instance_valid(body):
			restored.append(body)
	_adopt(restored, bounds)
	attention = "home chassis is missing" if not is_instance_valid(root) else ""
	_dirty = true
