extends LineProbe
## Profile & saves probe 14: an older crate. A save from before the crate
## lost its side rings numbers its sockets with them. Two crates are saved
## that way, as a build of then saved them, in a breeze: one floating with a
## hook on each side ring, moored upwind by both, and one resting on the sand
## with a hook on all four rings, its side hooks tied to stakes. Resumed,
## every part and seated device is back in its own socket. The first crate's
## side hooks are on its front and back rings, each on the free one nearest
## where it was, its line still tied to it and let out if it must be to
## reach it there, so nothing is yanked; the second keeps its front and
## back hooks, and its side hooks come out beside it, as your hands take a
## hook out, each line's end loose there and still tied to its stake. The
## first floats on, moored, nothing flung.

## The crate's side rings as the catalog had them, second and third in its
## list: [position, outward].
const SIDES := [[Vector3(0.4, 0.0, 0.0), Vector3.RIGHT], [Vector3(-0.4, 0.0, 0.0), Vector3.LEFT]]
const BREEZE := 6.0
## Beside the crate means this near its middle, m; flung, this fast, m/s.
const BESIDE := 1.5
const FLUNG := 3.0

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	blow(Vector2(0.0, BREEZE))
	var moved := _older(spot(-3.0, 4.0), 2, true)
	var spilled := _older(spot(3.0, 4.0), 4, false)
	await simulate(4.0)
	var held := [_held(moved), _held(spilled)]
	var at := _place(moved)
	check(saves.save(world), "saved")
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	check(data.get("layout", -1) == Snapshot.LAYOUT, "a save says how it numbers frames' sockets")
	data.erase("layout")
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data)

	check(await resume(), "the older save resumes")
	var crates := world.devices().filter(func(d: Device) -> bool: return d.get_meta(&"catalog") == &"crate_frame")
	check(crates.size() == 2, "both crates came back")
	if crates.size() != 2:
		return
	crates.sort_custom(func(a: Device, b: Device) -> bool: return a.global_position.x < b.global_position.x)
	moved = crates[0]
	spilled = crates[1]
	var after := [_held(moved), _held(spilled)]
	print("before: ", held, "\nafter: ", after)
	for k in 2:
		check(after[k] == _without_sides(held[k]), "crate %d: every part and seated device in its own socket" % k)
	var lines := world.content.get_children().filter(func(n: Node) -> bool: return n is Line)
	var on := lines.filter(func(l: Line) -> bool: return _crate_end(l, moved) != null)
	check(on.size() == 2 and on.all(func(l: Line) -> bool: return _on_stake(l)),
		"the first crate's side hooks are on its front and back rings, their lines still tied")
	var front: Socket = moved.frame_sockets().filter(func(s: Socket) -> bool:
		return s.kind == &"ring" and s.position.z < 0.0)[0]
	check(on.any(func(l: Line) -> bool: return (front.fitted.has(_crate_end(l, moved).socket)
		and moved.to_local(_stake_of(l).global_position).x > 0.0)),
		"the right side's hook went to the front ring, the free one nearest it")
	var loose := lines.filter(func(l: Line) -> bool: return _loose_end(l, spilled) != null)
	check(loose.size() == 2 and loose.all(func(l: Line) -> bool: return _on_stake(l)),
		"the second crate's side lines lie loose beside it, still tied to their stakes")
	var hooks := world.content.get_children().filter(func(n: Node) -> bool: return (n is Part
		and n.get_meta(&"catalog") == &"hook" and n.global_position.distance_to(spilled.global_position) < BESIDE))
	check(hooks.size() == 2, "and its side hooks lie loose beside it (%d)" % hooks.size())
	check(ropes.ropes.all(func(r: Rope) -> bool: return r.strand.a == r.a and r.strand.b == r.b),
		"every line is drawn between its own ends")
	check(ropes.ropes.all(func(r: Rope) -> bool: return r.a.global_position.distance_to(r.b.global_position) <= r.length + 1e-4),
		"none is past its length, a moved hook's let out to reach it")

	var fastest := {"v": 0.0}
	await simulate(4.0, func() -> void: fastest.v = maxf(fastest.v, moved.linear_velocity.length()))
	var drift := _place(moved).distance_to(at)
	print("the first crate after 4 s: %.2f m from where it was saved, at most %.2f m/s" % [drift, fastest.v])
	check(moved.stats().hovering and ropes.ropes.size() == 4 and drift < BESIDE and fastest.v < FLUNG,
		"the first crate floats on, moored, nothing flung")


## A crate as a build from before 2026-10-17 made it, side rings and all: a
## battery, a big battery, a panel, a plug, a light shield seated on top and
## a board in its rack, and `hooks` hooks, the side rings' first. Each side
## hook is tied to a stake upwind. Floating on a tray, or resting on the sand.
func _older(at: Vector3, hooks: int, floats: bool) -> Device:
	var crate := device(&"crate_frame", at, world.tuning.hover_height if floats else 0.26)
	var first := crate.frame_sockets()[0]
	for k in SIDES.size():
		var ring := Socket.new()
		ring.kind = &"ring"
		ring.transform = Transform3D(Catalog._facing(SIDES[k][1]), SIDES[k][0])
		crate.add_child(ring)
		crate.move_child(ring, first.get_index() + 1 + k)
	for id: StringName in [&"battery", &"big_battery", &"solar_panel", &"plug"] + ([&"hover_tray"] if floats else []):
		fit_part(crate, id)
	for k in hooks:
		fit_part(crate, &"hook")
	for id: StringName in [&"light_shield", &"board"]:
		var seated := Catalog.device(id)
		world.content.add_child(seated)
		var socket: Socket = crate.frame_sockets().filter(func(s: Socket) -> bool: return s.is_open() and seated.fits_in(s))[0]
		crate.mount(seated, socket)
	for k in SIDES.size():
		var tie := crate.free_tie(crate.global_transform * (SIDES[k][0] * 2.0))
		var stake := driven_stake(tie.global_position + Vector3(0.0, 0.0, -4.0))
		Line.between(world, tie, stake.free_tie(tie.global_position), 0.3)
	return crate


## What sits in each of a crate's own sockets, by where the socket is.
func _held(crate: Device) -> Dictionary:
	var out := {}
	for socket in crate.frame_sockets():
		var inside: Node = socket.part if socket.part != null else socket.mounted
		out[_where(socket.position)] = str(inside.get_meta(&"catalog")) if inside != null else ""
	return out


## The same with the side rings gone, and a hook on both rings left.
func _without_sides(held: Dictionary) -> Dictionary:
	var out := {}
	var sides := SIDES.map(func(side: Array) -> String: return _where(side[0]))
	for at: String in held:
		if not at in sides:
			out[at] = "hook" if Catalog.DEVICES[&"crate_frame"].sockets.any(func(e: Array) -> bool:
				return e[0] == &"ring" and _where(e[1]) == at) else held[at]
	return out


static func _where(p: Vector3) -> String:
	return "%.2f %.2f %.2f" % [p.x, p.y, p.z]


## A line's end on a hook in the crate, or null.
func _crate_end(line: Line, crate: Device) -> Part:
	for end in line.ends:
		if end.socket != null and end.socket.get_parent() == crate:
			return end
	return null


## A line's end lying loose beside the crate, or null.
func _loose_end(line: Line, crate: Device) -> Part:
	for end in line.ends:
		if end.socket == null and end.is_inside_tree() and end.global_position.distance_to(crate.global_position) < BESIDE:
			return end
	return null


func _stake_of(line: Line) -> Stake:
	for end in line.ends:
		if end.socket != null and end.socket.get_parent() is Stake:
			return end.socket.get_parent()
	return null


func _on_stake(line: Line) -> bool:
	return _stake_of(line) != null


func _place(node: Node3D) -> Vector3:
	return Vector3(world.world_x(node.global_position.x), node.global_position.y, world.world_z(node.global_position.z))
