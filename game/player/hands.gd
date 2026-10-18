class_name Hands
extends Node3D
## Your hands, with room for one thing: a part, or a device small enough to
## carry, like a stake. Look at a loose part and take it, or at a fitted one and
## it slides out the way it went in. Carry it in front of your eyes and look at
## a device: it's offered the free socket of its kind there, the only one or
## the one nearest your aim, facing you, or one you aim right at on any device.
## It leans in, a ghost shows the spot, and take seats it home with a soft click. Only
## a part held here ever snaps, and only when you take it home; nothing fits by
## being bumped. Take picks up, takes out, puts in and puts down; use works what
## you look at or uses what you hold. Finds lying in the sand are taken the same
## way, and whatever you take, take from, fit to or use becomes yours. A small
## device that seats in a socket, like a shield on a top mount, fits the same
## way, and take lifts it off again whole. A chassis piece joins a deck at a
## free edge ring the same way. Take on a deck takes hold of the whole of it,
## and only a bare piece comes off. Having hold of a device that stands on a
## deck, a free deck mount near it is offered, and take seats it there
## instead of letting go; having hold of a piece with something standing on
## it, a deck's free ring is offered, and take joins it there. Whenever take
## or use can't do what you aim at, it says why, with a soft knock.

signal fitted(part: Part, device: Device, socket: Socket)
signal taken(part: Part, device: Device, socket: Socket)

enum Phase { EMPTY, TAKING, ARRIVING, HELD }

## A part that's come free reaches your hand in this long, s.
const ARRIVE := 0.12
## Blocked on its way to your hand this long, it skips there instead, s.
const STUCK := 0.3
## Aiming from this far behind a socket's face still counts as its open side, m.
const OPEN_MARGIN := 0.05
## Your line of sight passing this near a device's frame still offers it what
## you hold, m.
const NEAR_FRAME := 0.4
## Empty-handed, your line of sight passing this near a part fitted under a
## device looks at it, m: standing, it's out of sight under the frame. A look
## at the frame itself counts only this low on it, and only in this lower share
## of its height, so a thin frame like a chassis piece is still itself by its
## top and the upper half of its edges.
const UNDER := 0.15
const UNDER_SHARE := 0.5
## An offered socket leans what you hold at least this far in, 0 to 1, so the
## tug shows where it goes even with your aim off the spot.
const OFFER := 0.35
## How fast the tug swings over when a nearer socket wins, 1/s.
const SWING := 16.0
## The small thing your aim settled on stays the one until another is this much
## nearer your aim, so a wavering aim doesn't flicker between them.
const STICKY := 0.7
## Shapes are shrunk this much a side when asking whether a part is inside
## something, so resting against it doesn't count, m.
const SKIN := 0.005
const GHOST := Color(0.75, 0.95, 1.0)
## Why use did nothing stays in the readout this long, s.
const NOTICE := 1.5
## Reel in and pay out bring what you carry this near your eyes, or push it
## this far out, m; nothing comes nearer than clears you.
const HOLD_NEAREST := 0.5
const HOLD_FARTHEST := 2.0
## How fast what you carry eases to a new distance, 1/s.
const HOLD_EASE := 12.0
## What you have hold of comes no nearer than this clear of you, m.
const GRASP_CLEAR := 0.1
## Having hold of a device, a free deck mount whose seat is this near it is
## offered, m: it can't get nearer, held off by the deck's edge.
const STAND_REACH := 1.2
## Something too heavy to carry comes off its seat this far, m, so it starts
## clear of what it sat on; a chassis piece slides this far off its deck
## before it comes to your hand.
const LIFT_OFF := 0.02
const SLIDE_OFF := 0.15
## Hits asked for when asking whether something has room: the sand answers
## once for each of its faces a shape crosses, which mustn't crowd out the rest.
const TOUCHES := 64
## What a refusal calls each kind of socket that's full.
const SOCKET_NAMES := {&"battery": "battery slot", &"ring": "ring", &"bottom": "tray mount", &"top": "top mount",
	&"plant_pot": "pot", &"plant_standard": "planter", &"plant_deep": "deep bed", &"port": "port", &"tie": "hook",
	&"water": "water socket", &"mod": "mod mount", &"food": "food slot", &"rack": "rack", &"deck": "deck mount",
	&"computer_mod": "computer-mod port", &"computer_top": "computer-mod top", &"screen": "screen port", &"sail": "sail mount"}
const RIDING := "not from the board"

var held: RigidBody3D
var phase := Phase.EMPTY
## What you hold that's too heavy to carry.
var grasp: Grasp
## The free deck mount what you have hold of would stand on, if you took it
## home, or the deck's free ring a piece would join at; where it would sit
## there and, for a piece, at how many quarter turns; or why there's none.
var stand: Socket
var _stand_pose := Transform3D.IDENTITY
var _stand_turns := 0
var _stand_why := ""
## The line you work hand over hand.
var reel: Reel
## What the look ray hits: a loose part, or a device and, when it's a fitted
## part, that part's socket, or the sand itself (not a ruin standing in it);
## and where it hit.
var look_part: Part
var look_device: Device
var look_socket: Socket
var look_sand := false
var look_point := Vector3.ZERO
var look_normal := Vector3.UP
## Your line of sight, from your eyes to whatever it stops at, or as far as you reach.
var sight_from := Vector3.ZERO
var sight_to := Vector3.ZERO
## The free socket the held part leans toward, how far your line of sight
## passes from where the part would sit there, m, and how hard it leans, 0 to 1.
var socket: Socket
var gap := INF
var pull := 0.0
## What the readout says about why use did nothing, while it shows.
var notice := ""

var _player: Player
var _tuning := Tuning.current()
var _hooked := false
## The held part's shapes, shrunk copies of them, and their bounds and middle
## in the part's own frame.
var _shapes: Array[CollisionShape3D] = []
var _skins: Array[Shape3D] = []
var _bounds := AABB()
var _middle := Vector3.ZERO
var _layers := Vector2i.ZERO
var _freeze_mode := RigidBody3D.FREEZE_MODE_STATIC
## How the held part is turned relative to your heading.
var _carry := Basis.IDENTITY
## How far in front of your eyes you'd carry it, and how far it is now, m.
var _away := 0.0
var _held_at := 0.0
## Where the held part is as the simulation knows it: placed by the tick
## alone, so its lines pull the same at any frame rate.
var _ticked := Transform3D.IDENTITY
## Where the tug leans the part, swung smoothly between sockets.
var _lean := Transform3D.IDENTITY
## Progress through sliding out or arriving, 0 to 1; where arriving began, and
## how long the way has been blocked.
var _t := 0.0
var _from := Transform3D.IDENTITY
var _stuck := 0.0
var _slide := 0.0
## How far from its socket a part starts sliding out: past the crop, when
## picking leaves one there.
var _slide_from := 0.0
## The device a part is coming out of, held still meanwhile so it can't drop
## onto the part, and what it was doing before.
var _source: Device
var _source_socket: Socket
var _source_was := {}
## The socket a part just came out of: it won't tug again, nor its device offer
## anything, until you look away.
var _rearm: Socket
## The deck mount what you have hold of just came off: its deck offers
## nothing until it's been carried clear of it.
var _stood: Socket
var _aim := Vector3.ZERO
## Where on the device you look at you aim, for its offer.
var _offer_at := Vector3.ZERO
## The small loose thing your aim settled on.
var _picked: RigidBody3D
## Parts just let go, which can't push you until they're clear of you.
var _released: Array[Dictionary] = []
var _body_radius := 0.35
var _ghost: Node3D
var _ghost_look: StandardMaterial3D
var _readout: Label
## The aim dot and its line, out of the way while a menu is up.
var _hud: CanvasLayer
var _sound: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _seated_count := 0
var _notice_left := 0.0
var _cast := PhysicsShapeQueryParameters3D.new()
var _inside := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	_player = get_parent() as Player
	grasp = Grasp.new(_player)
	reel = Reel.new()
	add_child(reel)
	for child in _player.get_children():
		var body := child as CollisionShape3D
		if body != null and body.shape is CapsuleShape3D:
			_body_radius = (body.shape as CapsuleShape3D).radius
	_ghost = Node3D.new()
	_ghost.top_level = true
	_ghost.visible = false
	add_child(_ghost)
	_ghost_look = StandardMaterial3D.new()
	_ghost_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Seen through whatever is in the way, even the sand under a resting device.
	_ghost_look.no_depth_test = true
	_ghost_look.albedo_color = GHOST
	_sound = AudioStreamPlayer.new()
	_sound.max_polyphony = 2
	_sound.bus = Sounds.WORLD
	add_child(_sound)
	var hum: AudioStreamOggVorbis = Sounds.TUG
	hum.loop = true
	_hum = AudioStreamPlayer.new()
	_hum.stream = hum
	_hum.bus = Sounds.WORLD
	add_child(_hum)
	_build_hud()
	get_tree().physics_frame.connect(_back_to_tick)


## Take: take what you're looking at, or, holding something, fit it if a socket
## is in tug range and put it down if not. Something too heavy to carry, you
## take hold of instead, and taking again lets go. Says whether it did anything.
func grab() -> bool:
	if grasp.body != null:
		if stand != null:
			_stand_on(stand)
			return true
		var why := _stand_why
		grasp.let_go()
		if why != "":
			refuse(why)
		return true
	if held != null:
		if phase != Phase.HELD:
			return false
		if socket != null:
			_fit(socket)
			return true
		var why := _no_fit()
		if why != "":
			return refuse(why)
		drop()
		return true
	_look()
	var salvage := _player.world.salvage
	# The board tows nothing: riding, you take only what comes off no line,
	# loose, into your hands.
	var riding := _player.board != null
	# Standing on a deck, a device keeps its sockets: a part you aim at comes out of it.
	var own_part := look_socket != null and look_socket.part != null
	if look_device != null and look_device.host() != null and not (look_device.on_deck() and own_part):
		if riding:
			return refuse(RIDING)
		# Last on, first off: a seated device comes off whole, whatever of it you aim at.
		_take_off(look_device)
		return true
	if look_part != null:
		if riding and _player.waist.carries_line(look_part):
			return refuse(RIDING)
		salvage.unbury(look_part)
		_pick_up(look_part)
		return true
	if look_socket != null and look_socket.part != null:
		if riding:
			return refuse(RIDING)
		salvage.claim(look_device)
		_take_out(look_device, look_socket)
		return true
	# A bare piece the rest of the deck holds together without comes off when
	# you aim at it; at any other, you take hold of the whole deck.
	var deck := look_device as Chassis
	if deck != null and deck.comes_off(deck.piece_at(look_point)):
		if riding:
			return refuse(RIDING)
		_unjoin(deck, deck.piece_at(look_point))
		return true
	if look_device != null and look_device.carryable:
		if riding and _player.waist.carries_line(look_device):
			return refuse(RIDING)
		salvage.unbury(look_device)
		_pick_up(look_device)
		return true
	if riding:
		return refuse(RIDING) if look_device != null else false
	if look_device != null and (not look_device.freeze or salvage.lying(look_device)):
		# Something found comes up out of the sand as you take hold of it.
		salvage.unbury(look_device)
		grasp.take(look_device)
		return true
	return false


## Use: work the device you look at, or use what you hold. Holding a line with
## nothing else to do, it goes on your waist; empty-handed, the last line at
## your waist comes back to your hands. Says whether it did anything.
func interact() -> bool:
	_look()
	if look_device != null and look_device.interact(_player):
		_player.world.salvage.claim(look_device)
		return true
	if held == null:
		if grasp.body == null and _player.waist.give_back():
			return true
		return refuse("wrecked" if look_device.wrecked() else "nothing to use") if look_device != null else false
	if phase != Phase.HELD:
		return false
	var used := false
	if held is Part:
		used = (held as Part).use(_player, look_point)
	elif held is Device:
		used = (held as Device).use(_player, look_point)
	if used or _player.waist.take_from_hands():
		return true
	return refuse("no use for it there") if look_device != null else false


## Rotate held down: the mouse turns what you hold, or have hold of, instead
## of your view, `by` rad along and up the screen, its near side following the
## mouse: across turns it about the vertical, up and down about your view's
## right. Says whether it did.
func turn(by: Vector2) -> bool:
	if not rotating():
		return false
	var turned := Basis(Vector3.UP, by.x) * Basis(Vector3.RIGHT, by.y)
	if grasp.body != null:
		grasp.turn(turned)
	else:
		_carry = (turned * _carry).orthonormalized()
	return true


## Whether rotate has the mouse: held down, with something in your hands, and
## the mouse looking rather than free to click.
func rotating() -> bool:
	return (held != null or grasp.body != null) and not Controls.mouse_free and Controls.held(&"hands_rotate")


## Takes a body straight into your hands from wherever it is, if they're free:
## a coil's rest once its first end is on, a line untied from your waist.
func hold(body: RigidBody3D) -> void:
	if held != null or body == null:
		return
	grasp.let_go()
	_grip(body)
	_arrive_from(body.global_transform)


## Reel in by `notches`, or pay out for a negative count: a line's end in
## your hand or at your waist reels; else what you carry, or have hold of,
## comes nearer or goes farther. Not in a menu, the inventory or riding. Says
## whether it did anything.
func scroll(notches: int) -> bool:
	if not reel.working():
		return false
	var by := notches * Reel.NOTCH
	if grasp.body != null:
		var box := _box_of(grasp.body)
		grasp.bring(by, _body_radius + Vector2(box.size.x, box.size.z).length() * 0.5 + GRASP_CLEAR, _tuning.reach)
		return true
	if held != null and phase == Phase.HELD:
		var nearest := maxf(HOLD_NEAREST, _body_radius + _bounds.size.length() * 0.5)
		_away = clampf(_away - by, nearest, maxf(HOLD_FARTHEST, nearest))
		return true
	return false


## Lets go of what you hold without dropping it, for something else to take.
func stow() -> RigidBody3D:
	var body := held
	if body != null:
		_let_go()
	return body


## Let go, moving as you were.
func drop() -> void:
	_landing()
	_release(_player.velocity)


## Throw: let go with a throw along your aim.
func throw() -> void:
	if held != null:
		_play(Sounds.THROW)
	_landing()
	_release(_player.velocity - _player.camera.global_basis.z * _tuning.throw_speed)


## One line saying what something is and what it does.
static func describe(label: String, mass: float, stats: Dictionary) -> String:
	var bits := PackedStringArray([label, ("%d kg" % roundi(mass)) if is_equal_approx(mass, roundf(mass))
		else ("%.1f kg" % mass)])
	if stats.has("rope_m"):
		bits.append("%d m line" % roundi(stats.rope_m) if stats.get("paying", 0.0) <= 0.0
			else "%d of %d m out" % [roundi(stats.rope_m), roundi(stats.paying)])
	if stats.has("holding"):
		bits.append("holds %.1f kN" % (stats.holding / 1000.0))
	if stats.has("load"):
		bits.append("load %d%%" % roundi(stats.load * 100.0))
	if stats.get("capacity_wh", 0.0) > 0.0:
		if stats.has("charge_wh"):
			bits.append("%d/%d Wh" % [floori(stats.charge_wh), roundi(stats.capacity_wh)])
		else:
			bits.append("%d Wh" % roundi(stats.capacity_wh))
	var hooks: int = stats.get("hooks", 0)
	if hooks > 0:
		bits.append("%d hook%s" % [hooks, "" if hooks == 1 else "s"])
	if stats.get("pieces", 1) > 1:
		bits.append("%d pieces" % stats.pieces)
	if stats.has("take"):
		bits.append(stats.take)
	if stats.get("lift_kg", 0.0) > 0.0:
		bits.append("floats %d kg" % roundi(stats.lift_kg))
	if stats.get("runners", 0) > 0:
		bits.append("on runners")
	elif stats.has("glide"):
		bits.append("glides on the sand")
	if stats.has("sail"):
		bits.append("sail %s" % stats.sail if stats.sail == "torn" else "%.1f m² sail %s" % [stats.sail_m2, stats.sail])
	if stats.has("sail_n") and stats.get("sail", "") == "raised":
		bits.append("pulls %d N" % roundi(stats.sail_n))
	if stats.get("resting", false):
		bits.append("resting")
	elif stats.get("can_float", false):
		bits.append("floating")
	# Said as the device does it: what it makes, what it draws.
	if stats.get("in_w", 0.0) > 0.0:
		bits.append("makes %d W" % roundi(stats.in_w))
	if stats.get("out_w", 0.0) > 0.0:
		bits.append("draws %d W" % roundi(stats.out_w))
	if stats.has("water_l"):
		bits.append("%.2f/%.1f L" % [stats.get("water_left_l", 0.0), stats.water_l])
	if stats.has("food_kcal"):
		bits.append("%d/%d kcal" % [stats.get("food_left_kcal", 0.0), stats.food_kcal])
	if stats.has("making_lph"):
		bits.append("making %.1f L/h" % stats.making_lph)
	if stats.has("growth"):
		bits.append("ripe" if stats.get("ripe", false) else ("mature" if stats.growth >= 1.0
			else "%d%% grown" % floori(stats.growth * 100.0)))
	if stats.has("growing") and stats.growing != Plant.RIPE:
		bits.append(str(stats.growing))
	if stats.has("replant"):
		bits.append("replants %d%%" % roundi(stats.replant * 100.0))
	if stats.get("stored_kcal", 0.0) > 0.0:
		bits.append("%d kcal stored" % roundi(stats.stored_kcal))
	if stats.get("seeds", 0) > 0:
		bits.append("%d seed%s" % [stats.seeds, "" if stats.seeds == 1 else "s"])
	if stats.has("tuned"):
		bits.append(stats.tuned)
	var instruments: int = stats.get("instruments", 0)
	if instruments > 0:
		bits.append("%d instrument%s" % [instruments, "" if instruments == 1 else "s"])
	if stats.has("found"):
		bits.append("%s find" % stats.found)
	if stats.get("dark", false):
		bits.append("DARK")
	if stats.get("solar_w", 0.0) > 0.0:
		bits.append("%d W solar" % roundi(stats.solar_w))
	if stats.get("light_w", 0.0) > 0.0:
		bits.append("%d W light" % roundi(stats.light_w))
	var plants: int = stats.get("plants", 0)
	if plants > 0:
		bits.append("%d plant%s" % [plants, "" if plants == 1 else "s"])
	return " · ".join(bits)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hands_grab"):
		if grab():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if interact():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_throw") and held != null and not Controls.mouse_free:
		throw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reel_in") or event.is_action_pressed("pay_out"):
		# Each wheel step is a press: a notch.
		if reel.working() and reel.notch(1 if event.is_action_pressed("reel_in") else -1):
			get_viewport().set_input_as_handled()
	# Exactly, so the line's ctrl and the wheel never move what you hold too.
	elif event.is_action_pressed("bring_near", false, true) or event.is_action_pressed("push_out", false, true):
		if scroll(1 if event.is_action_pressed("bring_near", false, true) else -1):
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	if not _hooked:
		world.origin_shifted.connect(_on_origin_shifted)
		_hooked = true
	if phase != Phase.EMPTY and not is_instance_valid(held):
		_forget()
	_look()
	_held_at = _away + (_held_at - _away) * exp(-HOLD_EASE * delta)
	match phase:
		Phase.TAKING:
			if not is_instance_valid(_source):
				_arrive_from(held.global_transform)
			else:
				_t = minf(_t + delta / _tuning.take_seconds, 1.0)
				held.global_transform = _sliding()
				if _t >= 1.0:
					_arrive_from(held.global_transform)
		Phase.ARRIVING:
			_arrive(delta)
		Phase.HELD:
			_tug(delta)
			held.global_transform = _within_reach(_pose(false))
	if phase == Phase.HELD:
		_ticked = held.global_transform
	grasp.step(delta)
	if grasp.slipped:
		grasp.slipped = false
		refuse("it won't shift")
	_find_stand()
	_unblock_released()
	_show(delta)


## Drawn frame by frame too, so a held part never trails your view as you
## turn; the next tick puts it back where the last one left it.
func _process(_delta: float) -> void:
	if _hud != null:
		_hud.visible = Controls.playing()
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _within_reach(_pose(true))
		held.global_position += reel.stroke(held)


## Before anything reads it this tick.
func _back_to_tick() -> void:
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _ticked


func _look() -> void:
	look_part = null
	look_device = null
	look_socket = null
	look_sand = false
	var eye := _player.camera.global_transform
	sight_from = eye.origin
	sight_to = eye.origin - eye.basis.z * _tuning.reach
	var ray := PhysicsRayQueryParameters3D.create(sight_from, sight_to)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.collider is StaticBody3D:
		_assist(eye)
	if hit.is_empty():
		if look_part == null and look_device == null:
			_under()
		return
	sight_to = hit.position
	look_point = hit.position
	look_normal = hit.normal
	var body: Object = hit.collider
	look_sand = _is_sand(hit)
	if look_part != null or look_device != null:
		# Assisted: the small thing you aimed near, not the sand under it.
		return
	if body is Part:
		look_part = body
	elif body is Device:
		look_device = body
		var met := look_device.shape_owner_get_owner(look_device.shape_find_owner(hit.shape)) as Node
		look_socket = _outermost(look_device.socket_of(met))
		if look_socket == null and not _low_on(look_device, met as CollisionShape3D, hit.position):
			return
	if look_part == null and look_socket == null:
		_under()


## Whether a look meets a frame low enough to mean what's fitted under it.
func _low_on(device: Device, frame: CollisionShape3D, point: Vector3) -> bool:
	if frame == null or frame.shape == null:
		return true
	var box := frame.transform * Catalog.bounds(frame.shape)
	var up := (device.global_transform.affine_inverse() * point).y - box.position.y
	return up <= minf(UNDER, box.size.y * UNDER_SHARE)


## Empty-handed, what a look at a device's frame, or just past one, finds under
## it: the part fitted facing down that your line of sight passes nearest.
func _under() -> void:
	if held != null:
		return
	var best: Socket = null
	var nearest := UNDER
	var near: Array = [look_device] if look_device != null \
		else _player.world.content.get_children() + _player.world.salvage.near(sight_from)
	for child in near:
		var device := child as Device
		if device == null or device.host() != null or device.has_meta(&"buried") or _far(device):
			continue
		for each in device.sockets():
			if each.part == null or _frame_of(each).basis.z.y > -0.7:
				continue
			var d := _gap_to(device.global_transform, _shapes_box(each.fitted))
			if d < nearest:
				nearest = d
				best = each
	if best != null:
		look_device = best.get_parent() as Device
		look_socket = best


## The ground's own heightmap; a ruin's boxes share its body.
static func _is_sand(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var shape := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	return shape != null and shape.shape is HeightMapShape3D


## How far along your look it meets something, out to `far`, m, or INF.
func meets(far: float) -> float:
	var eye := _player.camera.global_transform
	var ray := PhysicsRayQueryParameters3D.create(eye.origin, eye.origin - eye.basis.z * far)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return INF if hit.is_empty() else eye.origin.distance_to(hit.position)


## Says in the readout, for a moment, why use did nothing.
func say(why: String) -> void:
	notice = why
	_notice_left = NOTICE


## Take or use can't do what you aim at: the readout says why for a moment
## and a soft knock sounds, never silence (Hunter, 2026-10-17: "we should
## have a way to communicate when a slot is full"). Every refusal comes
## through here. Says it answered.
func refuse(why: String) -> bool:
	say(why)
	_play(Sounds.REFUSE)
	return true


## Holding something aimed at a device with sockets of its kind but nowhere
## it goes: why. "" where it has none of the kind, or one just emptied that
## waits for you to look away, and what you hold is simply put down.
func _no_fit() -> String:
	var target := _root(look_device) if look_device != null else null
	if target == null or target == held or _rearm != null and _on(_rearm):
		return ""
	var piece := held as Chassis
	var kind: StringName = &"ring" if piece != null else held.get(&"kind")
	var named := kind
	var any := false
	var free := false
	for each in target.sockets():
		if piece != null:
			if each.kind != &"ring" or not target is Chassis or each.has_meta(&"socket"):
				continue
		elif each.kind != kind and not (held is Device and (held as Device).fits_in(each)):
			continue
		any = true
		named = each.kind
		free = free or (Chassis.free_ring(each) if piece != null else each.is_open())
	if not any:
		return ""
	if not free:
		return "no free %s" % SOCKET_NAMES.get(named, "socket")
	if piece != null:
		if _mixes(piece, target):
			return "runners and trays don't mix"
		return "wrecked" if piece.wrecked() or target.wrecked() else "no room at that ring"
	return target.refuses(held) if held is Part else ""


## Last on, first off: aimed at a hook with a line tied to it, it's the line's
## end you take, and the hook once it's bare.
static func _outermost(socket: Socket) -> Socket:
	if socket == null or socket.part == null:
		return socket
	for node in socket.fitted:
		var added := node as Socket
		if added != null and added.part != null:
			return _outermost(added)
	return socket


## Aiming at the sand near a small loose thing takes it, so a battery lying
## there needs no pixel-perfect aim: the nearest your aim among those you can
## see, and the one it settled on until another is clearly nearer.
func _assist(eye: Transform3D) -> void:
	if held != null:
		_picked = null
		return
	var forward := -eye.basis.z
	var space := get_world_3d().direct_space_state
	var best: RigidBody3D = null
	var best_score := INF
	var kept := INF
	if not is_instance_valid(_picked):
		_picked = null
	for child in _player.world.content.get_children() + _player.world.salvage.near(eye.origin):
		var body := child as RigidBody3D
		if body == null or not (body is Part or (body is Device and (body as Device).carryable)):
			continue
		var box := _box_of(body)
		var size := box.size.length() * 0.5
		if size * 2.0 > _tuning.pick_small:
			continue
		var middle := body.global_transform * box.get_center()
		var along := (middle - eye.origin).dot(forward)
		if along <= 0.0 or along > _tuning.reach:
			continue
		var score := (middle - eye.origin - forward * along).length() / (size + _tuning.pick_assist)
		if score > 1.0 or score >= best_score and body != _picked:
			continue
		var ray := PhysicsRayQueryParameters3D.create(eye.origin, middle)
		ray.exclude = _exclusions()
		var seen := space.intersect_ray(ray)
		if not seen.is_empty() and seen.collider != body:
			continue
		if body == _picked:
			kept = score
		if score < best_score:
			best_score = score
			best = body
	if best != _picked and kept <= 1.0 and best_score > kept * STICKY:
		best = _picked
	_picked = best
	if best is Part:
		look_part = best
	elif best is Device:
		look_device = best


## A body's bounds in its own frame, kept once worked out.
static func _box_of(body: RigidBody3D) -> AABB:
	if body.has_meta(&"hands_box"):
		return body.get_meta(&"hands_box")
	var box := _body_box(body)
	body.set_meta(&"hands_box", box)
	return box


## A body's bounds in its own frame, as its shapes stand now.
static func _body_box(body: Node3D) -> AABB:
	return _shapes_box(body.get_children())


## The bounds of the shapes among some nodes, in their parent's frame.
static func _shapes_box(nodes: Array) -> AABB:
	var box := AABB()
	var first := true
	for child: Node in nodes:
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var each := shape.transform * Catalog.bounds(shape.shape)
			box = each if first else box.merge(each)
			first = false
	return box

func _pick_up(body: RigidBody3D) -> void:
	var stake := body as Stake
	if stake != null and stake.driven:
		# Pulled up out of the sand first, so its way to your hand is clear.
		stake.driven = false
		stake.global_position.y = _player.world.height_under(stake.global_position) + Stake.LENGTH * 0.5 + 0.02
	_grip(body)
	_arrive_from(body.global_transform)
	_play(Sounds.SAND_TAKE)


## Its host holds still while a seated device lifts straight off along the
## socket's +Z, then it comes to your hand; too heavy to carry, it comes off
## standing where it stood, and you have hold of it.
func _take_off(device: Device) -> void:
	var host := device.host()
	var from := host.seat_of(device)
	if not device.carryable:
		host.dismount(from)
		var beside := _beside_deck(device, host) if from.kind == &"deck" else Transform3D()
		if beside != Transform3D():
			_player.world.teleport(device, beside)
		else:
			# Clear of all that's fitted under its foot too, so it never starts off
			# inside what it stood on.
			var below := device.seat().origin.z + _shapes_box(device.get_children()).position.y
			_player.world.teleport(device, device.global_transform.translated(
				_frame_of(from).basis.z * (maxf(-below, 0.0) + LIFT_OFF)))
		grasp.take(device)
		_stood = from
		_play(Sounds.UNSEAT)
		return
	_source = host
	_source_socket = from
	_source_was = {"freeze": host.freeze, "velocity": host.linear_velocity, "spin": host.angular_velocity}
	host.freeze = true
	host.dismount(from)
	_grip(device)
	_slide = _bounds.size.y + 0.02
	_slide_from = 0.0
	_t = 0.0
	phase = Phase.TAKING
	_rearm = from
	_play(Sounds.UNSEAT)


## Off a deck, a device comes down on the sand beside it, on the clear side
## nearest you: left standing on a floating deck, dragging it would rub the
## deck along with it. Empty if no side is clear.
func _beside_deck(device: Device, deck: Device) -> Transform3D:
	var reach := _shapes_box(deck.get_children())
	var own := _shapes_box(device.get_children())
	var half := maxf(own.size.x, own.size.z) * 0.5
	var middle := Vector3(reach.get_center().x, 0.0, reach.get_center().z)
	var world := _player.world
	var sides: Array[Transform3D] = []
	for along: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out := deck.global_transform * (middle + along * (absf(along.dot(reach.size)) * 0.5 + half + 0.25))
		# Its foot clear of the highest sand under it, so it never starts in a slope.
		var ground := world.height_under(out)
		for corner: Vector3 in [Vector3(1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(-1, 0, -1)]:
			ground = maxf(ground, world.height_under(out + corner * half))
		out.y = ground - own.position.y + 0.05
		sides.append(Transform3D(device.global_basis, out))
	var me := _player.global_position
	sides.sort_custom(func(a: Transform3D, b: Transform3D) -> bool:
		return a.origin.distance_squared_to(me) < b.origin.distance_squared_to(me))
	# Tested a little above the sand, so only something standing there, a wall,
	# you or another device, rules a side out.
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = own.size
	query.shape = box
	query.exclude = [device.get_rid(), deck.get_rid()]
	for side in sides:
		query.transform = side.translated_local(own.get_center() + Vector3.UP * 0.25)
		if _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return side
	return Transform3D()


## A bare piece comes off the deck the way one goes on, out across a ring it
## leaves while the deck holds still, then to your hand.
func _unjoin(deck: Chassis, off: Chassis) -> void:
	var at := deck.global_transform * off.pose().origin
	var was := {"freeze": deck.freeze, "velocity": deck.linear_velocity, "spin": deck.angular_velocity}
	var piece := deck.detach(off)
	var from := deck.ring_to(at)
	_play(Sounds.UNSEAT)
	_source = deck
	_source_socket = from
	_source_was = was
	deck.freeze = true
	_grip(piece)
	_slide = SLIDE_OFF
	_slide_from = 0.0
	_t = 0.0
	phase = Phase.TAKING
	_rearm = from


## Having hold of a device that stands on a deck: the free deck mount whose
## seat is nearest it, within reach and with nothing else in the way there.
## The deck it just came off waits until it's been taken clear, so take lets
## go rather than standing it straight back on. Having hold of a lone piece,
## the deck's free ring it would join at.
func _find_stand() -> void:
	var device := grasp.body as Device
	var piece := device as Chassis
	if piece != null and not (piece.joined.is_empty() and piece.deck == null):
		piece = null
	if device == null or not device.stands_on_deck:
		device = null
		_stood = null
	var best: Socket = null
	_stand_why = ""
	if piece != null:
		best = _find_ring(piece)
	elif device != null:
		if _stood != null and (not is_instance_valid(_stood) or _stand_gap(device, _stood) > STAND_REACH):
			_stood = null
		var nearest := STAND_REACH
		for each in _near():
			if not (each is Chassis) or each == device or _stood != null and each == _stood.get_parent():
				continue
			for socket in each.sockets():
				if socket.kind == &"deck" and socket.is_open():
					var d := _stand_gap(device, socket)
					if d < nearest:
						nearest = d
						best = socket
		if best != null and not _stands_clear(device, best):
			_stand_why = "something's in the way"
			best = null
		# The deck's trays or runners carry what stands on it; its own would sit in the deck.
		if best != null and device.carriage() != &"":
			_stand_why = "take its tray off first" if device.has_tray() else "take its runners off first"
			say(_stand_why)
			best = null
		if best != null:
			_stand_pose = _frame_of(best) * device.seat()
	if best != stand:
		stand = best
		if held == null:
			_clear_ghost()
			if stand != null:
				_build_ghost(grasp.body)


## The free edge ring of a deck a lone piece you have hold of would join at:
## the one whose place beside it is nearest the piece, within reach, with
## room there. Two whole decks don't merge yet.
func _find_ring(piece: Chassis) -> Socket:
	var best: Socket = null
	var nearest := STAND_REACH
	for each in _near():
		var deck := each as Chassis
		if deck == null or deck == piece or deck.deck != null:
			continue
		for ring in deck.sockets():
			if not Chassis.free_ring(ring):
				continue
			var d := (deck.global_transform * deck._pose_at(ring, 0)).origin.distance_to(piece.global_position)
			if d < nearest:
				nearest = d
				best = ring
	if best == null:
		return null
	var deck := best.get_parent() as Chassis
	if _mixes(piece, deck):
		_stand_why = "runners and trays don't mix"
		return null
	var turns := deck._turns_for(piece, best, piece.global_basis)
	if turns < 0:
		_stand_why = "wrecked" if piece.wrecked() or deck.wrecked() else "no room at that ring"
		return null
	var pose := deck.global_transform * deck._pose_at(best, turns)
	if not deck.room_for(piece, pose):
		_stand_why = "something's in the way"
		return null
	_stand_pose = pose
	_stand_turns = turns
	return best


## Whether a piece joining a deck would put trays and runners on one deck.
static func _mixes(piece: Device, deck: Device) -> bool:
	var a := piece.carriage()
	var b := deck.carriage()
	return a != &"" and b != &"" and a != b


## How far a device is from where it would stand on a deck mount, m.
func _stand_gap(device: Device, socket: Socket) -> float:
	return (_frame_of(socket) * device.seat()).origin.distance_to(device.global_position)


## Whether a device would stand on a deck mount touching nothing but the
## deck: not another device, a loose thing, nor you.
func _stands_clear(device: Device, socket: Socket) -> bool:
	var pose := _frame_of(socket) * device.seat()
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var skip: Array[RID] = [(socket.get_parent() as Device).get_rid()]
	var riding: Array[Device] = [device]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		skip.append(each.get_rid())
		riding.append_array(each.mounted())
	query.exclude = skip
	for child in device.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		query.shape = _skin(shape.shape)
		query.transform = pose * shape.transform
		for hit in space.intersect_shape(query, TOUCHES):
			if not _sand(hit):
				return false
	return true


## Seats what you have hold of on a deck mount, standing, or joins the piece
## you have hold of to a deck at its ring.
func _stand_on(socket: Socket) -> void:
	var device := grasp.body as Device
	var deck := socket.get_parent() as Device
	grasp.let_go()
	stand = null
	_clear_ghost()
	_player.world.salvage.claim(deck)
	if socket.kind == &"ring":
		(deck as Chassis).join(device as Chassis, socket, _stand_turns)
	else:
		deck.mount(device, socket)
	_seat_sound()


## The device holds still while the part slides straight out along its
## socket's +Z, then the part comes to your hand.
func _take_out(device: Device, from: Socket) -> void:
	_source = device
	_source_socket = from
	_source_was = {"freeze": device.freeze, "velocity": device.linear_velocity, "spin": device.angular_velocity}
	device.freeze = true
	var part := device.take(from)
	_grip(part)
	_slide = part.depth()
	_slide_from = from.part.depth() if from.part != null else 0.0
	_t = 0.0
	phase = Phase.TAKING
	_rearm = from
	_play(Sounds.PICK if device is Planter and part.kind == &"food" else Sounds.UNSEAT)
	taken.emit(part, device, from)


func _grip(part: RigidBody3D) -> void:
	held = part
	_layers = Vector2i(part.collision_layer, part.collision_mask)
	_freeze_mode = part.freeze_mode
	part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	part.freeze = true
	# Held, it touches nothing: it can't shove a device, a part or you.
	part.collision_layer = 0
	part.collision_mask = 0
	_unblock(part)
	_shapes.clear()
	_skins.clear()
	var first := true
	for child in part.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		_shapes.append(shape)
		_skins.append(_skin(shape.shape))
		var box := shape.transform * Catalog.bounds(shape.shape)
		_bounds = box if first else _bounds.merge(box)
		first = false
	_middle = _bounds.get_center()
	_carry = _tidy(Basis(Vector3.UP, -_player.global_rotation.y) * part.global_basis.orthonormalized())
	_away = _tuning.hold_distance
	_held_at = _away
	pull = 0.0
	socket = null
	gap = INF
	_build_ghost(part)


func _arrive_from(pose: Transform3D) -> void:
	_from = pose
	_t = 0.0
	_stuck = 0.0
	phase = Phase.ARRIVING


## Eases to your hand, but never through anything: blocked, it waits, and
## blocked too long it skips to your hand, which is always clear.
func _arrive(delta: float) -> void:
	var next := minf(_t + delta / ARRIVE, 1.0)
	var pose := _within_reach(_blend(_from, _hand(false), smoothstep(0.0, 1.0, next)))
	if _clear(pose):
		_t = next
		_stuck = 0.0
		held.global_transform = pose
	else:
		_stuck += delta
		if _stuck > STUCK:
			_t = 1.0
			held.global_transform = _within_reach(_hand(false))
	if _t >= 1.0:
		phase = Phase.HELD
		_release_source()


func _tug(delta: float) -> void:
	_find_socket()
	var want := 0.0
	if socket != null:
		var seat := _settle_in(_seat(socket))
		want = maxf(smoothstep(_tuning.snap_reach, _tuning.snap_home, gap), OFFER)
		_lean = seat if pull == 0.0 else _blend(_lean, seat, 1.0 - exp(-SWING * delta))
	pull = move_toward(pull, want, delta / _tuning.tug_seconds)


## The free socket of the held part's kind nearest your line of sight, among
## the devices in reach, reached from its open side: measured from where the
## part would sit there, so aiming at the spot or at the ghost is the same.
## Aimed near none, the device you look at offers its own, so a low socket
## needs no crouch. One just emptied waits until you look away from its device.
func _find_socket() -> void:
	if _rearm != null and (not is_instance_valid(_rearm) or not _rearm.is_open()
			or not _on(_rearm) and _sight_gap(_seat(_rearm)) > _tuning.snap_reach):
		_rearm = null
	var target := _looked_at()
	var best: Socket = null
	var nearest := INF
	for device in _near():
		if device == held or _far(device):
			continue
		for each in device.sockets():
			if not _takes(each) or each == _rearm:
				continue
			var seat := _seat(each)
			var d := _sight_gap(seat)
			if d < nearest and _open(_frame_of(each), device) and _within_reach(seat) == seat:
				nearest = d
				best = each
	if nearest >= _tuning.snap_reach:
		best = null
		if target != null and not (_rearm != null and _on(_rearm)):
			best = _offer(target)
		nearest = _sight_gap(_seat(best)) if best != null else INF
	gap = nearest
	socket = best


## The device you look at, or that your line of sight passes nearest within
## NEAR_FRAME of; one seated on another counts as its host, whose sockets are
## the ones open. _offer_at is where on it you aim.
func _looked_at() -> Device:
	if look_device != null:
		_offer_at = look_point
		var root := _root(look_device)
		return null if root == held else root
	var best: Device = null
	var nearest := NEAR_FRAME
	for device in _near():
		# A find under the sand you look at is out of sight.
		if device == held or device.has_meta(&"buried") or _far(device):
			continue
		var d := _gap_to(device.global_transform, _body_box(device))
		if d < nearest:
			nearest = d
			best = device
			_offer_at = _aim
	return best


## What a device offers the held part: of its free sockets of the kind, the
## only one, or of several the one nearest your aim, among those facing you
## if any do.
func _offer(device: Device) -> Socket:
	var best: Socket = null
	var best_facing := false
	var nearest := INF
	for each in device.sockets():
		if not _takes(each) or each == _rearm:
			continue
		var seat := _seat(each)
		if _within_reach(seat) != seat:
			continue
		var frame := _frame_of(each)
		var facing := (sight_from - frame.origin).dot(frame.basis.z) > 0.0
		var d := _outside(seat.affine_inverse() * _offer_at, _bounds)
		if best == null or facing and not best_facing or facing == best_facing and d < nearest:
			best = each
			best_facing = facing
			nearest = d
	return best


## Whether your look ray is on the device a socket belongs to, or one seated on it.
func _on(each: Socket) -> bool:
	return look_device != null and _root(look_device) == _root(each.get_parent() as Device)


## The device whose sockets a look at this one offers: its host, unless it
## stands on a deck, where it keeps its own.
static func _root(device: Device) -> Device:
	while device != null and device.host() != null and not device.on_deck():
		device = device.host()
	return device


## The devices your hands look over: yours in the world, the finds round
## you, and whatever stands on a deck, which keeps its own sockets.
func _near() -> Array[Device]:
	var found: Array[Device] = []
	for child in _player.world.content.get_children() + _player.world.salvage.near(sight_from):
		var device := child as Device
		if device != null:
			found.append(device)
			_on_decks(device, found)
	return found


static func _on_decks(device: Device, found: Array[Device]) -> void:
	for each in device.mounted():
		if each.on_deck():
			found.append(each)
			_on_decks(each, found)


## Whether a device is past what your hands work on from your eyes: a deck
## by its nearest piece, since its far end can lie well past its first.
func _far(device: Device) -> bool:
	var nearest := device.global_position.distance_to(sight_from)
	var deck := device as Chassis
	if deck != null:
		for piece in deck.joined:
			nearest = minf(nearest, (deck.global_transform * piece.pose().origin).distance_to(sight_from))
	return nearest > _tuning.reach + 2.0


## Whether a free socket takes what you hold: a part of its kind, a device
## that seats there, a chassis piece at a deck's free edge with room beyond.
func _takes(each: Socket) -> bool:
	# A hook on a deck's ring, or a loose part beyond it, gets out of a joining piece's way.
	if held is Chassis and each.kind == &"ring":
		return (held as Chassis).fits_in(each) and not _mixes(held, each.get_parent()) \
			and (each.get_parent() as Chassis).room_for(held, _seat(each))
	if not each.is_open():
		return false
	# Standing on a deck a device takes no tray or runners, and a device
	# takes trays or runners, never both.
	if held is Part and (each.get_parent() as Device).refuses(held) != "":
		return false
	return (held as Device).fits_in(each) if held is Device else each.kind == held.get(&"kind")


## Whether a hit is the sand's own surface, which a deck lifts itself clear
## of: a ruin's wall still counts as in the way.
static func _sand(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var holder := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	return holder != null and holder.shape is HeightMapShape3D


## How near your line of sight passes to the part as it would sit in this
## seat, m; _aim is the point on it that passes nearest.
func _sight_gap(seat: Transform3D) -> float:
	return _gap_to(seat, _bounds)


## How near your line of sight passes to a box in a frame, m; _aim is the
## point on it that passes nearest.
func _gap_to(frame: Transform3D, box: AABB) -> float:
	var inverse := frame.affine_inverse()
	var a := inverse * sight_from
	var b := inverse * sight_to
	# The distance to a box along a line has one valley: close in on it.
	var lo := 0.0
	var hi := 1.0
	for i in 24:
		var one := lerpf(lo, hi, 1.0 / 3.0)
		var two := lerpf(lo, hi, 2.0 / 3.0)
		if _outside(a.lerp(b, one), box) <= _outside(a.lerp(b, two), box):
			hi = two
		else:
			lo = one
	var nearest := a.lerp(b, (lo + hi) * 0.5)
	_aim = frame * nearest
	return _outside(nearest, box)


## How far a point is outside a box in the same frame.
static func _outside(local: Vector3, box: AABB) -> float:
	return local.distance_to(local.clamp(box.position, box.end))


func _open(seat: Transform3D, device: Device) -> bool:
	var out := seat.basis.z
	if (_aim - seat.origin).dot(out) >= -OPEN_MARGIN:
		return true
	# A seat facing down into the sand is only reached from beside: you slide
	# the part under, aiming at the device's side.
	var tip := seat * Vector3(0.0, 0.0, _bounds.end.z)
	return out.y < -0.7 and tip.y < _player.world.height_under(tip) and look_device == device \
		and absf(look_normal.dot(out)) < 0.5


## Parts are plain boxes, the same turned end over end about their middle, so
## the tug leans one toward whichever way of sitting in the seat is nearest
## how it's held, never flipping it over on the way; fit() then seats it
## exactly, and nothing you can see changes.
func _settle_in(seat: Transform3D) -> Transform3D:
	var held_turn := (Basis(Vector3.UP, _player.global_rotation.y) * _carry).get_rotation_quaternion()
	var best := seat
	var nearest := INF
	for flip: Basis in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI), Basis(Vector3.UP, PI), Basis(Vector3.BACK, PI)]:
		var basis := (seat.basis * flip).orthonormalized()
		var angle := held_turn.angle_to(basis.get_rotation_quaternion())
		if angle < nearest:
			nearest = angle
			best = Transform3D(basis, seat * _middle - basis * _middle)
	return best


func _fit(into: Socket) -> void:
	var device := into.get_parent() as Device
	_player.world.salvage.claim(device)
	if held is Chassis and into.kind == &"ring":
		var piece := held as Chassis
		var turn := _held_basis()
		_let_go()
		var deck := device as Chassis
		deck.join(piece, into, deck._turns_for(piece, into, turn))
		_seat_sound()
		return
	if held is Device:
		var seated := held as Device
		_let_go()
		device.mount(seated, into)
		_seat_sound()
		return
	var part := held as Part
	_let_go()
	device.fit(part, into)
	if part.has_meta(&"line"):
		_play(Sounds.TIE)
	else:
		_seat_sound()
	fitted.emit(part, device, into)


func _release(velocity: Vector3) -> void:
	if held == null:
		return
	var part := held
	var middle := _middle
	var radius := _bounds.size.length() * 0.5
	_let_go()
	part.linear_velocity = velocity
	part.angular_velocity = Vector3.ZERO
	# It may start inside you: it can't push you until it's clear of you.
	part.add_collision_exception_with(_player)
	_released.append({"part": part, "middle": middle, "radius": radius})


func _let_go() -> void:
	var part := held
	_release_source()
	part.freeze = false
	part.freeze_mode = _freeze_mode
	part.collision_layer = _layers.x
	part.collision_mask = _layers.y
	_forget()


func _forget() -> void:
	_release_source()
	held = null
	phase = Phase.EMPTY
	socket = null
	pull = 0.0
	gap = INF
	_clear_ghost()


func _release_source() -> void:
	if is_instance_valid(_source):
		_source.freeze = _source_was.freeze
		if not _source.freeze:
			_source.linear_velocity = _source_was.velocity
			_source.angular_velocity = _source_was.spin
	_source = null
	_source_socket = null


func _unblock_released() -> void:
	for i in range(_released.size() - 1, -1, -1):
		var gone: Dictionary = _released[i]
		if not is_instance_valid(gone.part):
			_released.remove_at(i)
			continue
		var part: RigidBody3D = gone.part
		var off: Vector3 = part.global_transform * gone.middle - _player.global_position
		if Vector2(off.x, off.z).length() > _body_radius + gone.radius or off.y < -gone.radius or off.y > 2.5:
			_unblock(part)


func _unblock(part: RigidBody3D) -> void:
	for i in range(_released.size() - 1, -1, -1):
		if is_instance_valid(_released[i].part) and _released[i].part == part:
			_released.remove_at(i)
			part.remove_collision_exception_with(_player)


## Where the held part sits: in your hand, leaning toward a socket as hard as
## the tug pulls; as drawn this frame, or as the tick knows it.
func _pose(drawn: bool) -> Transform3D:
	var hand := _hand(drawn)
	return hand if pull <= 0.0 else _blend(hand, _lean, smoothstep(0.0, 1.0, pull))


## As far in front of your eyes as you'd carry it, turned with you, and
## stopped short of anything in the way, so it never ends up inside the sand
## or a device.
func _hand(drawn: bool) -> Transform3D:
	var eye := _player.camera.global_transform
	if not drawn:
		eye.origin = _player.global_transform * _player.feel.steady_eye()
	var basis := Basis(Vector3.UP, _player.global_rotation.y) * _carry
	var ahead := -eye.basis.z.normalized() * _held_at
	var start := Transform3D(basis, eye.origin - basis * _middle)
	return start.translated(ahead * _sweep(start, ahead))


## A pose for what you hold, kept within reach of its lines: turning round or
## a tug toward a ring further off can't stretch a line, only your body can.
func _within_reach(pose: Transform3D) -> Transform3D:
	for child in held.get_children():
		var end := child as RopeEnd
		if end != null:
			var at := pose * end.position
			pose.origin += _player.world.ropes.reach(end, at) - at
	return pose


## How far along motion the held part can move from start before it touches
## something, 0 to 1. Starting inside something, it can't tell, so all the way.
func _sweep(start: Transform3D, motion: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	_cast.exclude = _exclusions()
	_cast.motion = motion
	var safe := 1.0
	for shape in _shapes:
		_cast.shape = shape.shape
		_cast.transform = start * shape.transform
		var fraction := space.cast_motion(_cast)
		if fraction[1] > 0.0:
			safe = minf(safe, fraction[0])
	return safe


func _clear(pose: Transform3D) -> bool:
	var space := get_world_3d().direct_space_state
	_inside.exclude = _exclusions()
	for i in _shapes.size():
		_inside.shape = _skins[i]
		_inside.transform = pose * _shapes[i].transform
		if not space.intersect_shape(_inside, 1).is_empty():
			return false
	return true


func _sliding() -> Transform3D:
	var out := 1.0 - (1.0 - _t) * (1.0 - _t)
	return _frame_of(_source_socket).translated_local(Vector3(0.0, 0.0, _slide_from + _slide * out)) \
		* _seated(_source_socket)


## Where what you hold sits in a socket, in the world.
func _seat(into: Socket) -> Transform3D:
	return _frame_of(into) * _seated(into)


## A socket's frame in the world: where a part's own frame sits in it.
func _frame_of(into: Socket) -> Transform3D:
	return ((into.get_parent() as Node3D).global_transform * into.transform).orthonormalized()


## Where what you hold sits in a socket's frame: a part on it, a device
## upright on it, a chassis piece flush beyond a deck's edge ring.
func _seated(into: Socket) -> Transform3D:
	if held is Chassis and into.kind == &"ring":
		return (held as Chassis).seat_in(into, _held_basis())
	return (held as Device).seat() if held is Device else Transform3D.IDENTITY


## How what you hold is turned in the world as the tick has it.
func _held_basis() -> Basis:
	return Basis(Vector3.UP, _player.global_rotation.y) * _carry


## Between two poses of the held part, turning about its own middle.
func _blend(a: Transform3D, b: Transform3D, t: float) -> Transform3D:
	var basis := a.basis.orthonormalized().slerp(b.basis.orthonormalized(), t)
	var middle := (a * _middle).lerp(b * _middle, t)
	return Transform3D(basis, middle - basis * _middle)


func _exclusions() -> Array[RID]:
	var out: Array[RID] = [_player.get_rid()]
	if is_instance_valid(held):
		out.append(held.get_rid())
	return out


## Squared up to your heading, whatever way it lay.
static func _tidy(turn: Basis) -> Basis:
	var x := _axis(turn.x)
	var y := _axis(turn.y - x * turn.y.dot(x))
	return Basis(x, y, x.cross(y))


static func _axis(v: Vector3) -> Vector3:
	var a := v.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3(signf(v.x), 0.0, 0.0)
	if a.y >= a.z:
		return Vector3(0.0, signf(v.y), 0.0)
	return Vector3(0.0, 0.0, signf(v.z))


static func _skin(shape: Shape3D) -> Shape3D:
	var box := shape as BoxShape3D
	if box == null:
		return shape
	var thinner := BoxShape3D.new()
	thinner.size = (box.size - Vector3.ONE * SKIN * 2.0).max(Vector3.ONE * SKIN)
	return thinner


func _on_origin_shifted(by: Vector2i) -> void:
	var offset := Vector3(by.x, 0.0, by.y) * _tuning.chunk_size
	_from.origin -= offset
	_lean.origin -= offset
	_ticked.origin -= offset


func _build_ghost(part: RigidBody3D) -> void:
	_clear_ghost()
	for child in part.get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = mesh.mesh
		copy.transform = mesh.transform
		copy.material_override = _ghost_look
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.add_child(copy)


## Drawn through everything, a ghost on a device's far side would read as on
## its near side, so it shows only from a socket's open side; one facing down
## is slid into from beside, so it always shows.
func _in_sight(into: Socket) -> bool:
	var frame := _frame_of(into)
	return frame.basis.z.y < -0.7 or (sight_from - frame.origin).dot(frame.basis.z) > 0.0


func _clear_ghost() -> void:
	for child in _ghost.get_children():
		child.free()
	_ghost.visible = false


func _play(stream: AudioStream) -> void:
	_sound.stream = stream
	_sound.play()


func _seat_sound() -> void:
	_play(Sounds.SEAT[_seated_count % Sounds.SEAT.size()])
	_seated_count += 1


## What you let go of lands softly in the sand, heard where it does.
func _landing() -> void:
	if held != null and phase == Phase.HELD:
		Sounds.on_landing(held, self)


## A dot where you aim and, under it, one short line about what it's on.
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 99
	add_child(hud)
	_hud = hud
	var dot := Control.new()
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func() -> void:
		dot.draw_circle(Vector2.ZERO, 2.5, dot.get_theme_color(&"shadow", &"Palette"))
		dot.draw_circle(Vector2.ZERO, 1.5, dot.get_theme_color(&"text", &"Palette")))
	hud.add_child(dot)
	_readout = Label.new()
	_readout.theme_type_variation = &"Readout"
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.set_anchors_preset(Control.PRESET_CENTER)
	_readout.offset_left = -400.0
	_readout.offset_right = 400.0
	_readout.offset_top = 10.0
	_readout.offset_bottom = 28.0
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.modulate.a = 0.0
	hud.add_child(_readout)


## A part's stats as they stand: a battery's charge, a line's length and
## load, the layer it was found in.
func _part_stats(part: Part) -> Dictionary:
	var now := part.stats.duplicate()
	if part is Battery:
		now["charge_wh"] = part.charge_wh
	if part is Plant:
		now.erase("plants")
		now["growth"] = part.growth
		now["ripe"] = part.ripe()
		if part.socket != null:
			now["growing"] = part.state
	if part.has_meta(&"line"):
		now.merge((part.get_meta(&"line") as Line).readout())
	if part.has_meta(&"layer"):
		now["found"] = part.get_meta(&"layer")
	return now


func _show(delta: float) -> void:
	var line := ""
	_notice_left = maxf(_notice_left - delta, 0.0)
	if _notice_left <= 0.0:
		notice = ""
	if notice != "":
		line = notice
	elif look_part != null:
		line = describe(look_part.label, look_part.mass, _part_stats(look_part))
	elif look_socket != null and look_socket.part != null:
		line = describe(look_socket.part.label, look_socket.part.mass, _part_stats(look_socket.part))
	elif look_device != null:
		var stats := look_device.stats()
		stats["in_w"] = look_device.production_w()
		stats["out_w"] = look_device.demand_w() if look_device.powered else 0.0
		stats["dark"] = not look_device.powered
		if look_device.has_meta(&"layer"):
			stats["found"] = look_device.get_meta(&"layer")
		# Which take does to a deck: has a bare piece off, or drags it all.
		var deck := look_device as Chassis
		if deck != null and not deck.joined.is_empty():
			var piece := deck.piece_at(look_point)
			stats["take"] = "this piece comes off" if deck.comes_off(piece) \
				else ("drags the whole deck; bare, this piece comes off" if deck.outer(piece) else "drags the whole deck")
		line = describe(look_device.label, stats.mass, stats)
	if line != "" and line != _readout.text:
		_readout.text = line
	_readout.modulate.a = move_toward(_readout.modulate.a, 1.0 if line != "" else 0.0, delta * 8.0)

	_ghost.visible = socket != null and _in_sight(socket)
	if socket != null:
		_ghost.global_transform = _seat(socket)
		_ghost_look.albedo_color.a = 0.2 + 0.3 * pull
	elif stand != null and grasp.body is Device:
		# Where what you have hold of would stand, or join.
		_ghost.visible = true
		_ghost.global_transform = _stand_pose
		_ghost_look.albedo_color.a = 0.35
	elif held is Stake and phase == Phase.HELD and look_sand:
		# Where it will go in.
		_ghost.visible = true
		_ghost.global_transform = Transform3D(Basis(Vector3.UP, held.global_rotation.y),
			Vector3(look_point.x, _player.world.height_under(look_point) + Stake.DRIVEN_AT, look_point.z))
		_ghost_look.albedo_color.a = 0.3
	if pull > 0.01:
		_hum.volume_db = linear_to_db(pull)
		if not _hum.playing:
			_hum.play()
	elif _hum.playing:
		_hum.stop()

	Dev.put("hands/held", held.get(&"label") if held != null
		else ("hold " + str(grasp.body.get(&"label")) if grasp.body != null else "-"))
	Dev.put("hands/tug", "%.2f %.2fm" % [pull, gap] if socket != null else "-")
