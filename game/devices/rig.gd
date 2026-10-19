class_name Rig
extends RefCounted
## A deck put together from data, the one way kits, scenarios, the main
## menu's showpiece and finds build one. Its steps, in order, from a first
## piece at grid place (0, 0):
##   [&"piece", cell]                    a piece joined at that grid place
##   [&"frame", cell, quarter turns]     a frame square on that piece's top
##   [&"wall", cell, face]               a piece on that frame's face: top,
##                                       left, right, front or back
##   [&"stick", on, face, place, turn°, thing, name]   something stuck on a
##       piece's top or bottom at a place on it: `on` a grid place, or
##       [cell, face] for the piece on a frame's face; `thing` a catalog id,
##       or [id, [what fills its own slots]]; `name` optional, for lines
##   [&"hook", cell, toward]             a hook on that piece's ring facing
##                                       `toward` along the grid
##   [&"face", cell, face, id]           a screen or fabric on a frame's face
## Batteries start as full as `charge` says.

## What it built: the deck, every device made, the deck first, and the named
## things. Parts stuck on it live in its body, so they aren't listed.
var deck: Chassis
var made: Array[Node] = []
var named := {}


## Builds a rig's steps off the tree, so nothing near where it'll go is
## moved by its joins, then puts it under a parent, if given, at its origin.
static func build(parent: Node, steps: Array, charge := 1.0) -> Rig:
	var rig := Rig.new()
	rig.deck = Catalog.device(&"chassis") as Chassis
	rig.deck.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	rig.made.append(rig.deck)
	for step: Array in steps:
		rig._step(step, charge)
	if parent != null:
		parent.add_child(rig.deck)
	return rig


func _step(step: Array, charge: float) -> void:
	match step[0]:
		&"piece":
			var cell: Vector2i = step[1]
			deck.join(Catalog.device(&"chassis") as Chassis, ring_toward(deck, cell), 0)
		&"frame":
			var frame := Catalog.part(&"frame")
			Stick.put(deck, piece(deck, step[1]), Chassis.TOP, Vector2.ZERO, step[2] * Chassis.QUARTER if step.size() > 2 else 0.0, frame)
		&"wall":
			deck.join(Catalog.device(&"chassis") as Chassis, face_of(deck, step[1], step[2]))
		&"stick":
			var thing := make(step[5], charge)
			Stick.put(deck, piece(deck, step[1]), step[2], step[3], deg_to_rad(step[4]), thing)
			if thing is Device:
				made.append(thing)
			if step.size() > 6:
				named[step[6]] = thing
		&"hook":
			var hook := Catalog.part(&"hook")
			deck.fit(hook, ring_of(deck, step[1], step[2]))
		&"face":
			var part := Catalog.part(step[3])
			deck.fit(part, face_of(deck, step[1], step[2]))


## A thing for a step: a catalog part or device, its own slots filled, its
## batteries charged.
static func make(spec: Variant, charge := 1.0) -> RigidBody3D:
	var id: StringName = spec[0] if spec is Array else spec
	var thing: RigidBody3D = Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id)
	# Fitted before it's in the world, so before its _ready would set this.
	if thing is Device:
		thing.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_charge(thing, charge)
	if spec is Array:
		for fill: StringName in spec[1]:
			var part := Catalog.part(fill)
			_charge(part, charge)
			var device := thing as Device
			for socket in device.sockets():
				if socket.is_open() and socket.kind == part.kind:
					device.fit(part, socket)
					break
	return thing


static func _charge(thing: Node, charge: float) -> void:
	var cell := thing as Battery
	if cell != null:
		cell.charge_wh = cell.capacity() * charge
		cell.show_charge()


## The deck's piece on the grid at a place, or on a frame's face: [cell, face].
static func piece(on: Chassis, at: Variant) -> Chassis:
	if at is Array:
		var face := face_of(on, at[0], at[1])
		for each in on.joined:
			if each.joined_at == face:
				return each
		return null
	for each in on.grid():
		if each.cell == at:
			return each
	return null


## The free ring of a grid piece that faces a place beside it.
static func ring_toward(on: Chassis, cell: Vector2i) -> Socket:
	for socket in on.sockets():
		if Chassis.free_ring(socket) and on._cell_of(socket) + Chassis._step(socket) == cell:
			return socket
	return null


## A grid piece's own ring facing a way along the grid.
static func ring_of(on: Chassis, cell: Vector2i, toward: Vector2i) -> Socket:
	for socket in on.sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and on.own_piece(socket) == piece(on, cell) \
				and Chassis._step(socket) == toward:
			return socket
	return null


## A face of the frame on a grid piece's top, by name.
static func face_of(on: Chassis, cell: Vector2i, face: StringName) -> Socket:
	var host := piece(on, cell)
	for socket in on.stuck():
		if socket.part is Frame and on.own_piece(socket) == host:
			return (socket.part as Frame).faces().get(face)
	return null


## Everything a rig's steps give, counted by catalog id, a frame's walls as pieces.
static func count(steps: Array, into: Dictionary) -> void:
	_add(into, &"chassis")
	for step: Array in steps:
		match step[0]:
			&"piece", &"wall":
				_add(into, &"chassis")
			&"frame":
				_add(into, &"frame")
			&"hook":
				_add(into, &"hook")
			&"face":
				_add(into, step[3])
			&"stick":
				var spec: Variant = step[5]
				_add(into, spec[0] if spec is Array else spec)
				if spec is Array:
					for fill: StringName in spec[1]:
						_add(into, fill)


static func _add(into: Dictionary, id: StringName) -> void:
	into[id] = into.get(id, 0) + 1
