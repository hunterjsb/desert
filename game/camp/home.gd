class_name CampHome
extends Node
## One claimed travelling camp. Ground support is confirmed by World, not the marker.
signal changed
var world: World
var beacon: HomeBeacon
var root: Chassis
var members: Array[RigidBody3D] = []
var anchor: Sites.Anchor
var bounds := Rect2()
var revision := 0
var supported := false
var attention := ""
var restoring := false
var item_count := 0
## World checks the complete support budget before admission and safe retirement.
var admit: Callable
var release_check: Callable
var _marked := false
var _envelopes: Array = []
var _fix := Vector3.ZERO
var _has_fix := false
var _departed := false

func has_home() -> bool:
	return _marked

func contains(body: Node) -> bool:
	if not is_instance_valid(body):
		return false
	var actual := _physical(body)
	return actual != null and members.has(actual)

func mark(marker: HomeBeacon) -> String:
	if not is_instance_valid(marker) or marker.wrecked():
		return "beacon is damaged"
	var deck := _deck(marker)
	if deck == null:
		return "mount the beacon on a chassis first"
	if not _owned(deck):
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
	members = graph
	item_count = _work_count(graph)
	bounds = footprint
	_envelopes = envelopes
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
	revision += 1
	changed.emit()
	return ""

func unmark() -> String:
	if not _marked:
		return ""
	var why := _release_reason()
	if why != "":
		return why
	_clear()
	changed.emit()
	return ""

func _clear() -> void:
	_marked = false
	restoring = false
	item_count = 0
	beacon = null
	root = null
	members.clear()
	anchor = null
	bounds = Rect2()
	_envelopes.clear()
	_has_fix = false
	_departed = false
	supported = false
	attention = ""
	revision += 1

func _release_reason() -> String:
	if release_check.is_valid():
		return release_check.call()
	# Until the terrain owner supplies its exact check, retire only beside Home.
	var player := Vector2(world.player_world_x(), world.player_world_z())
	return "return to home before unmarking it" if bounds.get_center().distance_to(player) > world.tuning.home_return_m else ""

## Called before terrain planning and distant-body retirement on every physics tick.
func refresh() -> void:
	if not _marked or restoring:
		return
	var previous := members.duplicate()
	members = members.filter(func(body: RigidBody3D) -> bool: return is_instance_valid(body) and not body.is_queued_for_deletion())
	if not is_instance_valid(root) or root.is_queued_for_deletion():
		attention = "home chassis is missing"
		supported = false
		if previous != members:
			revision += 1
		return
	# A joined deck may choose another root without changing its identity.
	root = root.deck if root.deck != null else root
	var shields := _shield_envelopes(root)
	if not shields.is_empty():
		_envelopes = shields
	var graph := _graph(root, _envelopes)
	var proposed := _footprint(graph)
	var why := _admission(graph, proposed)
	if why == "":
		members = graph
		attention = ""
	else:
		# Reject additions together; ordinary removal still works during a refusal.
		var kept: Array[RigidBody3D] = []
		for body in members:
			var actual := _physical(body)
			if graph.has(actual) and not kept.has(actual):
				kept.append(actual)
		members = kept
		attention = why
	item_count = _work_count(members)
	var actual := _footprint(members)
	if members != previous or not actual.is_equal_approx(bounds):
		bounds = actual
		revision += 1
		changed.emit()
	_receive()

func _admission(graph: Array[RigidBody3D], footprint: Rect2) -> String:
	if _work_count(graph) > world.tuning.home_max_bodies:
		return "home has too many bodies"
	if maxf(footprint.size.x, footprint.size.y) > world.tuning.home_span_m:
		return "home is spread too far"
	return admit.call(footprint) if admit.is_valid() else ""

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
	_add_assembly(deck, graph)
	for child in world.content.get_children():
		var body := child as RigidBody3D
		if not _eligible(body):
			continue
		var local := deck.global_transform.affine_inverse() * body.global_position
		for envelope: Array in envelopes:
			if local.distance_to(envelope[0]) <= envelope[1]:
				_add_assembly(body, graph)
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
			if not graph.has(a) and not graph.has(b) and (guide == null or not graph.has(guide)):
				continue
			var count := graph.size()
			_add_assembly(a, graph)
			_add_assembly(b, graph)
			if _eligible(guide):
				_add_assembly(guide, graph)
			expanded = expanded or graph.size() != count
	return graph

func _add_assembly(body: RigidBody3D, graph: Array[RigidBody3D]) -> void:
	body = _physical(body)
	if not _eligible(body) or graph.has(body):
		return
	graph.append(body)
	if body is Device:
		for mounted in (body as Device).mounted():
			_add_assembly(mounted, graph)

func _eligible(body: RigidBody3D) -> bool:
	return is_instance_valid(body) and not body.is_queued_for_deletion() and _owned(body) \
		and body != world.player.board and body != world.player.hands.held \
		and body.is_inside_tree() and world.content.is_ancestor_of(body)

func _owned(body: Node) -> bool:
	if not is_instance_valid(body) or not body.has_meta(&"catalog"):
		return false
	var at: Node = body
	while at != null and at != world.content:
		if at.has_meta(&"find") or at.has_meta(&"buried") or at.has_meta(&"stoker_slot") or at.has_meta(&"unclaimed_rig"):
			return false
		at = at.get_parent()
	return true

func _deck(marker: HomeBeacon) -> Chassis:
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
	for body in graph:
		if not is_instance_valid(body) or not body.is_inside_tree():
			continue
		var box: AABB = body.global_transform * (body.shape_bounds() if body is Device else Hands._box_of(body))
		var own := Rect2(Vector2(world.world_x(box.position.x), world.world_z(box.position.z)), Vector2(box.size.x, box.size.z))
		rect = own if first else rect.merge(own)
		first = false
	return rect

func _receive() -> void:
	if not is_instance_valid(root) or anchor == null:
		return
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var home := anchor.point_at(world.world_x(root.global_position.x), world.world_z(root.global_position.z))
	var distance := Sphere.angle(here, home) * anchor.radius
	if is_instance_valid(beacon) and not beacon.wrecked() and beacon.powered and _deck(beacon) == root and distance <= world.tuning.home_signal_m:
		_fix = home
		_has_fix = true
	if distance >= world.tuning.home_depart_m:
		_departed = true
	elif _departed and supported and distance <= world.tuning.home_return_m:
		Deeds.done(world, &"home_again")
		_departed = false

func nav() -> Dictionary:
	if not _marked:
		return {"marked": false, "supported": false, "live": false, "metres": 0.0, "bearing": 0.0, "status": "No home marked"}
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var home := anchor.point_at(world.world_x(root.global_position.x), world.world_z(root.global_position.z)) if is_instance_valid(root) and anchor != null else _fix
	var live := is_instance_valid(root) and anchor != null and is_instance_valid(beacon) and not beacon.wrecked() and beacon.powered and _deck(beacon) == root \
		and Sphere.angle(here, home) * world.shape.history.radius <= world.tuning.home_signal_m
	var status := "Receiving" if live else "Last known fix"
	if attention != "":
		status = attention
	elif not supported:
		status = "Preparing home support"
	return {"marked": true, "supported": supported, "live": live, "metres": Sphere.angle(here, _fix) * world.shape.history.radius if _has_fix else NAN,
		"bearing": fposmod(Sphere.bearing(here, _fix), TAU) if _has_fix else NAN, "status": status}

func snapshot(ref: Callable) -> Dictionary:
	if not _marked:
		return {}
	var refs := []
	var poses := []
	for body in members:
		if is_instance_valid(body):
			var id: int = ref.call(body)
			refs.append(id)
			if anchor != null:
				poses.append([id, Transform3D(body.global_basis, Vector3(world.world_x(body.global_position.x) - anchor.x,
					body.global_position.y, world.world_z(body.global_position.z) - anchor.z))])
	return {"root": ref.call(root) if is_instance_valid(root) else -1,
		"beacon": ref.call(beacon) if is_instance_valid(beacon) else -1, "members": refs, "poses": poses,
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
	members.clear()
	for saved in data.get("members", []):
		var body := resolve.call(saved) as RigidBody3D
		if is_instance_valid(body):
			members.append(body)
	attention = "home chassis is missing" if not is_instance_valid(root) else ""
	revision += 1
	changed.emit()
