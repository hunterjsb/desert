class_name RopeBundle
extends RefCounted
## Several original line ends held together through ordinary nested fittings.

const SLOT := &"rope_bundle"
const OWN_MASS := &"rope_bundle_own_mass"


static func slots(primary: Part) -> Array[Socket]:
	var found: Array[Socket] = []
	var nodes: Array = primary.socket.fitted if primary.socket != null else primary.get_children()
	for node in nodes:
		if node is Socket and node.has_meta(SLOT) and node.has_meta(&"socket") == (primary.socket != null):
			found.append(node)
	return found


## Stable authored order lets ordinary added-fitting records rebuild the knot.
static func prepare(primary: Part, count: int) -> void:
	var own := slots(primary)
	for k in range(own.size(), count):
		var socket := Socket.new()
		socket.kind = &"tie"
		socket.position = Vector3(Catalog.PARTS[&"rope_end"].size.x * (k + 1), 0.0, 0.0)
		socket.set_meta(SLOT, true)
		primary.add_child(socket)


static func members(primary: Part) -> Array[Part]:
	var found: Array[Part] = [primary]
	for socket in slots(primary):
		if is_instance_valid(socket.part):
			found.append_array(members(socket.part))
	return found


static func own_mass(part: Part) -> float:
	if not part.has_meta(OWN_MASS):
		part.set_meta(OWN_MASS, part.mass)
	return part.get_meta(OWN_MASS)


static func refresh_mass(primary: Part) -> void:
	var weight := own_mass(primary)
	if primary.socket == null:
		for member in members(primary):
			if member != primary:
				weight += own_mass(member)
	primary.mass = weight


static func gather(primary: Part, end: Part) -> bool:
	if primary == end or primary.socket != null or end.socket != null or members(end).has(primary):
		return false
	own_mass(primary)
	own_mass(end)
	var own := slots(primary)
	prepare(primary, own.size() + 1)
	Device.seat_part(end, slots(primary).back())
	refresh_mass(primary)
	return true


static func live_lines(primary: Part, world: World) -> Array[Line]:
	var found: Array[Line] = []
	for member in members(primary):
		var line: Variant = member.get_meta(&"line", null)
		if is_instance_valid(line) and line is Line and line.state == Line.State.LAID \
				and line.rope != null and world.ropes.ropes.has(line.rope) and not found.has(line):
			found.append(line)
	return found
