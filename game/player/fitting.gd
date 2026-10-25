class_name Fitting
extends RefCounted
## Where what's in your hands would go, shown there until take sets it. What
## you hold leans toward the free socket of its kind your line of sight passes
## nearest, or the one the device you look at offers, and a ghost shows the
## spot; short of one, it goes where your look would stick it. A lone piece you
## have hold of shows at the deck's free ring or frame face it would join at,
## anything else that sticks where your look would stick it. Red where it
## won't go, amber with a warning.

## Aiming from this far behind a socket's face still counts as its open side, m.
const OPEN_MARGIN := 0.05
## Your line of sight passing this near a device's frame still offers it what
## you hold, m.
const NEAR_FRAME := 0.4
## An offered socket leans what you hold at least this far in, 0 to 1, so the
## tug shows where it goes even with your aim off the spot.
const OFFER := 0.35
## How fast the tug swings over when a nearer socket wins, 1/s.
const SWING := 16.0
## Having hold of a lone piece, a deck's free ring or frame face whose place
## is this near it is offered, m: it can't get nearer, held off by the deck's edge.
const STAND_REACH := 1.2
## What you hold eases onto where it would stick in about this long, s, and
## a red tint, or amber for a warning, shows where it won't go.
const PLACE_SECONDS := 0.08
const BLOCKED := Color(1.0, 0.2, 0.15, 0.5)
const WARNED := Color(1.0, 0.65, 0.15, 0.35)
## What a refusal calls each kind of socket that's full.
const SOCKET_NAMES := {&"fuel": "fuel hopper", &"battery": "battery slot", &"ring": "ring", &"bottom": "tray mount",
	&"plant_pot": "pot", &"plant_standard": "planter", &"plant_deep": "deep bed", &"port": "port", &"tie": "hook",
	&"water": "water socket", &"mod": "mod mount", &"food": "food slot", &"face": "frame face",
	&"computer_mod": "computer-mod port", &"computer_top": "computer-mod top", &"screen": "screen port", &"sail": "sail mount",
	&"radio_mod": "converter mount", &"radio_bay": "misc bay", &"lead": "lead clip", &"jack": "headset jack"}

## Why a lone piece you have hold of has nowhere to join, said if you let go.
var stand_why := ""
var _hands: Hands
var _player: Player
var _sight: Sight
var _tuning := Tuning.current()
## Where a lone piece you have hold of would sit at the hands' stand.
var _stand_pose := Transform3D.IDENTITY
## Where the tug leans the part, swung smoothly between sockets.
var _lean := Transform3D.IDENTITY
## Where on the device you look at you aim, for its offer.
var _offer_at := Vector3.ZERO
## Where what you hold would stick, in the deck's frame, eased toward as it
## moves; in the world as last placed; and how far it's gone there, 0 to 1.
var _stick_local := Transform3D.IDENTITY
var _stick_world := Transform3D.IDENTITY
var _placing := 0.0
## What's tinted now and how, so a tint is set and cleared once.
var _tinted: Node3D
var _tint := Color(0.0, 0.0, 0.0, 0.0)
var _tints := {}


func _init(hands: Hands, player: Player, sight: Sight) -> void:
	_hands = hands
	_player = player
	_sight = sight


## Having hold of a lone piece: the deck's free ring or frame face it would
## join at. Having hold of something that sticks: where your look would
## stick it. Either way the real thing is shown there, until it's set or you
## look away.
func find_stand(delta: float) -> void:
	var hands := _hands
	var grasp := hands.grasp
	var body := grasp.body
	var piece := body as Chassis
	if piece != null and not (piece.joined.is_empty() and piece.deck == null):
		piece = null
	var best: Socket = null
	stand_why = ""
	if piece != null:
		best = _find_ring(piece)
	hands.stand = best
	if hands.held == null:
		hands.sticking = _stick_target(body, grasp.held_basis()) if body != null and best == null else {}
	var share := 1.0 - exp(-SWING * delta)
	if body != null and hands.stand != null:
		grasp.show_at(_stand_pose, share)
	elif body != null and not hands.sticking.is_empty():
		grasp.show_at(hands.sticking.deck.global_transform * hands.sticking.pose, share)
	elif grasp.showing():
		grasp.unshow()
	if hands.held == null:
		_tint_as(body if grasp.showing() else null, hands.sticking)


## The free edge ring or frame face of a deck a lone piece you have hold of
## would join at: the one whose place is nearest the piece, within reach,
## with room there. Two whole decks don't merge yet.
func _find_ring(piece: Chassis) -> Socket:
	var best: Socket = null
	var nearest := STAND_REACH
	var at := _hands.grasp.where()
	for each in _sight.near():
		var deck := each as Chassis
		if deck == null or deck == piece or deck.deck != null:
			continue
		for ring in deck.sockets():
			var place := Transform3D()
			if Chassis.free_ring(ring):
				place = deck.global_transform * deck._pose_at(ring, 0)
			elif ring.kind == &"face" and ring.is_open():
				place = deck.global_transform * ring.transform * Frame.piece_seat()
			else:
				continue
			var d := place.origin.distance_to(at)
			if d < nearest:
				nearest = d
				best = ring
	if best == null:
		return null
	var deck := best.get_parent() as Chassis
	if best.kind == &"face":
		var on_face := deck.global_transform * best.transform * Frame.piece_seat()
		if not piece.fits_in(best) or Stick.clear(piece, on_face, _player) != "":
			stand_why = "something's in the way"
			return null
		_stand_pose = on_face
		_hands._stand_turns = 0
		return best
	var turns := deck._turns_for(piece, best, piece.global_basis)
	if turns < 0:
		stand_why = "wrecked" if piece.wrecked() or deck.wrecked() else "no room at that ring"
		return null
	var pose := deck.global_transform * deck._pose_at(best, turns)
	if not deck.room_for(piece, pose):
		stand_why = "something's in the way"
		return null
	_stand_pose = pose
	_hands._stand_turns = turns
	return best


## Joins the piece you have hold of to a deck at its ring or on a frame's face.
func stand_on(socket: Socket) -> void:
	var hands := _hands
	var piece := hands.grasp.body as Chassis
	var deck := socket.get_parent() as Chassis
	hands.grasp.let_go(false)
	hands.stand = null
	_tint_as(null, {})
	_player.world.salvage.claim(deck)
	deck.join(piece, socket, hands._stand_turns)
	hands.seat_sound()


## Where a thing would stick: the sticky face your look meets within reach,
## the thing under your look, turned as it's held, edged and settled there
## (Stick.aim), and why it can't go there, or a warning that it would sink a
## floating deck; {} where your look meets no sticky face.
func _stick_target(thing: RigidBody3D, held_basis: Basis) -> Dictionary:
	if thing == null or not Stick.sticks(thing) or not thing.is_inside_tree():
		return {}
	var from := _hands.sight_from
	var ray := PhysicsRayQueryParameters3D.create(from, from - _player.camera.global_basis.z * _tuning.reach)
	var skip := _hands._exclusions()
	skip.append(thing.get_rid())
	ray.exclude = skip
	# A standing mast's upper reach is there for your hands alone.
	ray.collide_with_areas = true
	var hit := _hands.get_world_3d().direct_space_state.intersect_ray(ray)
	var on := Stick.face_hit(hit, -_player.camera.global_basis.z)
	if on.is_empty():
		return {}
	var deck: Device = on[0]
	var face := Stick.face_for(deck, on[1], on[2], thing)
	var placed := Stick.aim(deck, on[1], face, hit.position, held_basis, thing)
	var pose := Stick.pose_on(deck, on[1], face, placed[0], placed[1], thing)
	var why := Stick.why_not(deck, on[1], face, thing)
	if why == "":
		why = Stick.clear(thing, deck.global_transform * pose, _player)
	# Floating now, and too much for its trays with this on: it'd settle.
	var camp := deck
	while camp.host() != null:
		camp = camp.host()
	var now := camp.stats()
	var warn := "too heavy" if now.can_float and not camp.resting \
		and now.lift_kg + _lift_of(thing) < camp.mass + thing.mass else ""
	return {"deck": deck, "piece": on[1], "face": face, "pose": pose,
		"out": Stick.frame_of(deck, on[1], face).basis.z, "why": why, "warn": warn}


## What a thing lifts once it's stuck facing down: a tray its lift, else none.
static func _lift_of(thing: Node) -> float:
	var part := thing as Part
	return part.stats.get("lift_kg", 0.0) if part != null else 0.0


## Sticks what you hold where it's shown, with a soft clunk.
func stick_held() -> void:
	var hands := _hands
	var target := hands.sticking
	var thing := hands.held
	var deck: Device = target.deck
	_player.world.salvage.claim(deck)
	hands._let_go()
	var into := deck.stick(thing, target.pose, target.out, target.piece)
	hands.seat_sound()
	if thing is Part:
		hands.fitted.emit(thing, deck, into)


## Sticks what you have hold of where it's shown.
func stick_grasped() -> void:
	var hands := _hands
	var target := hands.sticking
	var thing := hands.grasp.body as Device
	var deck: Device = target.deck
	_player.world.salvage.claim(deck)
	hands.grasp.let_go(false)
	hands.sticking = {}
	_tint_as(null, {})
	deck.stick(thing, target.pose, target.out, target.piece)
	hands.seat_sound()


## Each tick while you hold something: the socket it leans toward and how
## hard, else where it would stick, eased toward.
func tug(delta: float) -> void:
	var hands := _hands
	var was: Variant = hands.sticking.get("deck")
	_find_socket()
	var want := 0.0
	if hands.socket != null:
		var seat := _settle_in(seat_pose(hands.socket))
		want = maxf(smoothstep(_tuning.snap_reach, _tuning.snap_home, hands.gap), OFFER)
		_lean = seat if hands.pull == 0.0 else hands._blend(_lean, seat, 1.0 - exp(-SWING * delta))
	hands.pull = move_toward(hands.pull, want, delta / _tuning.tug_seconds)
	# Where it would stick, eased toward in the deck's frame, so it rides a floating deck.
	var sticking := hands.sticking
	if not sticking.is_empty():
		var deck: Device = sticking.deck
		if _placing <= 0.0 or not is_instance_valid(was) or was != deck:
			_stick_local = deck.global_transform.affine_inverse() * hands.held.global_transform
		var share := 1.0 - exp(-SWING * delta)
		_stick_local = Transform3D(_stick_local.basis.orthonormalized().slerp(sticking.pose.basis.orthonormalized(), share),
			_stick_local.origin.lerp(sticking.pose.origin, share))
		_stick_world = deck.global_transform * _stick_local
	_placing = move_toward(_placing, 1.0 if not sticking.is_empty() else 0.0, delta / PLACE_SECONDS)
	_tint_as(hands.held if not sticking.is_empty() else null, sticking)


## Where the held part sits, from where your hand has it: leaning toward a
## socket as hard as the tug pulls, or gone where it would stick; as drawn
## this frame, or as the tick knows it.
func lean(hand: Transform3D, drawn: bool) -> Transform3D:
	var hands := _hands
	if _placing > 0.0:
		var there := _stick_world
		if drawn and not hands.sticking.is_empty() and is_instance_valid(hands.sticking.deck):
			there = (hands.sticking.deck as Node3D).global_transform * _stick_local
		return hands._blend(hand, there, smoothstep(0.0, 1.0, _placing))
	return hand if hands.pull <= 0.0 else hands._blend(hand, _lean, smoothstep(0.0, 1.0, hands.pull))


## Let go: nothing's shown or tinted where it would go.
func forget() -> void:
	_tint_as(null, {})
	_placing = 0.0


## The world's origin moved by `offset`, m.
func shift(offset: Vector3) -> void:
	_lean.origin -= offset
	_stick_world.origin -= offset


## The free socket of the held part's kind nearest your line of sight, among
## the devices in reach, reached from its open side: measured from where the
## part would sit there, so aiming at the spot or at the ghost is the same.
## Aimed near none, the device you look at offers its own, so a low socket
## needs no crouch. Worked out afresh every tick from what's free now, so one
## just emptied takes a part straight back.
func _find_socket() -> void:
	var hands := _hands
	var target := _looked_at()
	var best: Socket = null
	var nearest := INF
	for device in _sight.near():
		if device == hands.held or _sight.far(device):
			continue
		for each in device.sockets():
			if not _takes(each):
				continue
			var seat := seat_pose(each)
			var d := _sight_gap(seat)
			if d < nearest and _open(frame_of(each), device) and hands._within_reach(seat) == seat:
				nearest = d
				best = each
	hands.sticking = {}
	if nearest >= _tuning.snap_reach:
		best = null
		# Short of a slot you aim right at, a sticky face your look meets wins.
		hands.sticking = _stick_target(hands.held, hands._held_basis())
		if hands.sticking.is_empty() and target != null:
			best = _offer(target)
		nearest = _sight_gap(seat_pose(best)) if best != null else INF
	hands.gap = nearest
	hands.socket = best


## The device you look at, or that your line of sight passes nearest within
## NEAR_FRAME of; one seated on another counts as its host, whose sockets are
## the ones open. _offer_at is where on it you aim.
func _looked_at() -> Device:
	var hands := _hands
	if hands.look_device != null:
		_offer_at = hands.look_point
		var root := _root(hands.look_device)
		return null if root == hands.held else root
	var best: Device = null
	var nearest := NEAR_FRAME
	for device in _sight.near():
		# A find under the sand you look at is out of sight.
		if device == hands.held or device.has_meta(&"buried") or _sight.far(device):
			continue
		var d := _sight.gap_to(device.global_transform, Hands._body_box(device))
		if d < nearest:
			nearest = d
			best = device
			_offer_at = _sight.aim
	return best


## What a device offers the held part: of its free sockets of the kind, the
## only one, or of several the one nearest your aim, among those facing you
## if any do.
func _offer(device: Device) -> Socket:
	var best: Socket = null
	var best_facing := false
	var nearest := INF
	for each in device.sockets():
		if not _takes(each):
			continue
		var seat := seat_pose(each)
		if _hands._within_reach(seat) != seat:
			continue
		var frame := frame_of(each)
		var facing := (_hands.sight_from - frame.origin).dot(frame.basis.z) > 0.0
		var d := Sight.outside(seat.affine_inverse() * _offer_at, _hands._bounds)
		if best == null or facing and not best_facing or facing == best_facing and d < nearest:
			best = each
			best_facing = facing
			nearest = d
	return best


## The device whose sockets a look at this one offers: its host, unless it
## stands on a deck, where it keeps its own.
static func _root(device: Device) -> Device:
	while device != null and device.host() != null and not device.on_deck():
		device = device.host()
	return device


## Whether a free socket takes what you hold: a part of its kind, a device
## that seats there, a chassis piece at a deck's free edge with room beyond.
func _takes(each: Socket) -> bool:
	var held := _hands.held
	# A hook on a deck's ring, or a loose part beyond it, gets out of a joining piece's way.
	if held is Chassis and each.kind == &"ring":
		return (held as Chassis).fits_in(each) \
			and (each.get_parent() as Chassis).room_for(held, seat_pose(each))
	if held is Chassis and each.kind == &"face":
		return (held as Chassis).fits_in(each) and Stick.clear(held, seat_pose(each), _player) == ""
	if not each.is_open() or each.stuck():
		return false
	if held is Device:
		return (held as Device).fits_in(each)
	return Catalog.fits(held.get(&"kind"), each.kind) or each.kind == &"face" and Frame.takes(held)


## How near your line of sight passes to the part as it would sit in this
## seat, m; Sight.aim is the point on it that passes nearest.
func _sight_gap(seat: Transform3D) -> float:
	return _sight.gap_to(seat, _hands._bounds)


func _open(seat: Transform3D, device: Device) -> bool:
	var out := seat.basis.z
	if (_sight.aim - seat.origin).dot(out) >= -OPEN_MARGIN:
		return true
	# A seat facing down into the sand is only reached from beside: you slide
	# the part under, aiming at the device's side.
	var tip := seat * Vector3(0.0, 0.0, _hands._bounds.end.z)
	return out.y < -0.7 and tip.y < _player.world.height_under(tip) and _hands.look_device == device \
		and absf(_hands.look_normal.dot(out)) < 0.5


## Parts are plain boxes, the same turned end over end about their middle, so
## the tug leans one toward whichever way of sitting in the seat is nearest
## how it's held, never flipping it over on the way; fit() then seats it
## exactly, and nothing you can see changes.
func _settle_in(seat: Transform3D) -> Transform3D:
	var held_turn := _hands._held_basis().get_rotation_quaternion()
	var middle := _hands._middle
	var best := seat
	var nearest := INF
	for flip: Basis in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI), Basis(Vector3.UP, PI), Basis(Vector3.BACK, PI)]:
		var basis := (seat.basis * flip).orthonormalized()
		var angle := held_turn.angle_to(basis.get_rotation_quaternion())
		if angle < nearest:
			nearest = angle
			best = Transform3D(basis, seat * middle - basis * middle)
	return best


## Fits what you hold in a socket: a part in, a device seated on it, a
## chassis piece joined at a deck's ring or on a frame's face.
func fit(into: Socket) -> void:
	var hands := _hands
	var device := into.get_parent() as Device
	_player.world.salvage.claim(device)
	if hands.held is Chassis and into.kind in [&"ring", &"face"]:
		var piece := hands.held as Chassis
		var turn := hands._held_basis()
		hands._let_go()
		var deck := device as Chassis
		deck.join(piece, into, deck._turns_for(piece, into, turn))
		hands.seat_sound()
		return
	if hands.held is Device:
		var seated := hands.held as Device
		hands._let_go()
		device.mount(seated, into)
		hands.seat_sound()
		return
	var part := hands.held as Part
	hands._let_go()
	device.fit(part, into)
	if part is RopeTip:
		var anchored := RopeBundle.live_lines(part, _player.world).filter(func(line: Line) -> bool:
			return line.rope.a.holder != line.rope.b.holder)
		if anchored.size() >= 2:
			Deeds.done(_player.world, &"make_fast")
	if part.has_meta(&"line"):
		hands._play(Sounds.TIE)
	else:
		hands.seat_sound()
	hands.fitted.emit(part, device, into)


## Holding something aimed at a device with sockets of its kind but nowhere
## it goes: why. "" where it has none of the kind, and what you hold is
## simply put down.
func no_fit() -> String:
	var hands := _hands
	var target := _root(hands.look_device) if hands.look_device != null else null
	if target == null or target == hands.held:
		return ""
	var piece := hands.held as Chassis
	var kind: StringName = &"ring" if piece != null else (hands.held.kind if hands.held is Part else &"")
	var named := kind
	var any := false
	var free := false
	for each in target.sockets():
		if piece != null:
			if each.kind != &"ring" or not target is Chassis or each.has_meta(&"socket"):
				continue
		elif not Catalog.fits(kind, each.kind) and not (hands.held is Device and (hands.held as Device).fits_in(each)):
			continue
		any = true
		named = each.kind
		free = free or (Chassis.free_ring(each) if piece != null else each.is_open())
	if not any:
		return ""
	if not free:
		return "no free %s" % SOCKET_NAMES.get(named, "socket")
	if piece != null:
		return "wrecked" if piece.wrecked() or target.wrecked() else "no room at that ring"
	return ""


## Where what you hold sits in a socket, in the world.
func seat_pose(into: Socket) -> Transform3D:
	return frame_of(into) * _seated(into)


## A socket's frame in the world: where a part's own frame sits in it.
static func frame_of(into: Socket) -> Transform3D:
	return ((into.get_parent() as Node3D).global_transform * into.transform).orthonormalized()


## Where what you hold sits in a socket's frame: a part on it, a device
## upright on it, a chassis piece flush beyond a deck's edge ring or flat on
## a frame's face.
func _seated(into: Socket) -> Transform3D:
	var hands := _hands
	if hands.held is Chassis and into.kind in [&"ring", &"face"]:
		return (hands.held as Chassis).seat_in(into, hands._held_basis())
	return (hands.held as Device).seat() if hands.held is Device else Transform3D.IDENTITY


## Drawn through everything, a ghost on a device's far side would read as on
## its near side, so it shows only from a socket's open side; one facing down
## is slid into from beside, so it always shows.
func in_sight(into: Socket) -> bool:
	var frame := frame_of(into)
	return frame.basis.z.y < -0.7 or (_hands.sight_from - frame.origin).dot(frame.basis.z) > 0.0


## Tints what's shown where it would stick: red where it won't go, amber
## with a warning, else as it is. Set and cleared once each.
func _tint_as(body: Node3D, target: Dictionary) -> void:
	var color := Color(0.0, 0.0, 0.0, 0.0)
	if body != null and not target.is_empty():
		color = BLOCKED if target.why != "" else (WARNED if target.warn != "" else color)
	if body == _tinted and color == _tint:
		return
	if is_instance_valid(_tinted):
		for mesh: MeshInstance3D in _tinted.find_children("*", "MeshInstance3D", true, false):
			mesh.material_overlay = null
	_tinted = body if color.a > 0.0 else null
	_tint = color
	if _tinted == null:
		return
	if not _tints.has(color):
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.albedo_color = color
		_tints[color] = look
	for mesh: MeshInstance3D in _tinted.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = _tints[color]
