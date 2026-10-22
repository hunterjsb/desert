class_name Suit
extends Node
## The suit: the one gift this world gives you. Its air and its shielding from
## the sun's radiation are built in and free, with no power and no bar. It
## carries whatever you can carry in your hands, with no slots and no count:
## weight is the only limit, and a soft one. Past what you carry easily you
## sink into the sand and slow down (Player). It feeds you from the water and
## food you carry. The inventory action opens a view of it all, like things
## stacked, each drawn as itself, and frees the mouse: a click on a thing
## brings it to your empty hands, a click on the view with something in your
## hands puts it in, and use on a thing uses it where it is. Rope and wire go
## in rolled up, as they're found, and unroll in your hands; a stake goes in
## as it is. A device you carry rides on you, out of sight, and works on its
## own battery as it would anywhere: a radio plays from you. Closing the view
## captures the mouse again, to look.

## Built in and free, so nothing ever drains them. The headlamp is the
## camera's (Headlamp), so it looks where you look.
const BUILT_IN := "air, radiation, headlamp"
const HINT := "click a thing to take it out, or + to put in what you hold · {interact} on a thing uses it · {inventory} closes"
const TILE := Vector2(120.0, 128.0)
## The thing's picture across the top of its tile, px.
const PICTURE := Vector2i(120, 88)
const GAP := 6.0
## At most this many tiles a row, and the rows end this far above the foot
## of the screen, clear of a radio's line of words, px.
const ROW := 8
const FOOT := 120.0
## A device you carry rides here on you, out of sight, from your feet.
const POUCH := Vector3(0.0, 1.0, 0.0)

## Everything you carry, in the order it went in. Parts wait off the tree,
## as fitted ones do; a device rides on you, working.
var carried: Array[RigidBody3D] = []
var open := false
## The stack under the mouse, or -1.
var hover := -1

var _player: Player
var _layer: CanvasLayer
var _view: Control
var _waist_lines: WaistLines
var _home_button := Button.new()
var _home_view := HomeView.new()
## Each stack's picture, made as the view first needs them.
var _looks: Array[InventoryLook] = []


func _ready() -> void:
	_player = get_parent() as Player
	add_to_group(UIRoot.PANELS)
	_layer = CanvasLayer.new()
	_layer.layer = 98
	_layer.visible = false
	add_child(_layer)
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Open, it takes every click, so none reaches the world to throw or look.
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_draw_view)
	_view.gui_input.connect(_on_view_input)
	_view.mouse_exited.connect(func() -> void: hover = -1)
	_layer.add_child(_view)
	_waist_lines = WaistLines.new()
	_waist_lines.reel = (_player.get_node("Hands") as Hands).reel
	_waist_lines.waist = _player.get_node("Waist") as Waist
	_waist_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.add_child(_waist_lines)
	_home_button.text = "Home"
	_home_button.theme_type_variation = &"MenuWordMain"
	_home_button.pressed.connect(_home_view.show_home)
	_view.add_child(_home_button)
	_home_view.source = _home_service
	_home_view.heading = _heading
	_home_view.closed.connect(_home_view.hide)
	_view.add_child(_home_view)
	_home_view.hide()
	restock()


func _exit_tree() -> void:
	# A run ending with the view open leaves the next one looking.
	if open:
		show_view(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# A device on you may have gone already, with you.
		for thing in carried:
			if is_instance_valid(thing):
				thing.free()


## A fresh suit's load: what the run's kit carries, and nothing else.
func restock() -> void:
	for thing in carried:
		thing.free()
	carried.clear()
	var world := World.of(self)
	if world != null and world.arrival_enabled:
		return
	var kit := Kit.of(world)
	for id in kit.carried_ids():
		if Catalog.DEVICES.has(id):
			var device := Catalog.device(id)
			# It comes with its batteries, to work on you from the first;
			# fitted before it's in the world, so before its _ready would set this.
			device.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			for socket in device.sockets():
				if socket.kind == &"battery":
					var cell := Catalog.part(&"battery") as Battery
					cell.charge_wh = cell.capacity() * kit.charge
					device.fit(cell, socket)
					cell.show_charge()
			# You may still be setting up, too busy to take it on yet.
			if _player.is_node_ready():
				_on_you(device)
			else:
				_carry_once_ready.call_deferred(device)
			carried.append(device)
		else:
			carried.append(Catalog.stake() if id == &"stake" else Catalog.part(id))


## Whether it goes in: anything you can carry in your hands with nothing
## fastened to it. Rope, wire and hose go in rolled up whole: a line held but
## not laid, a cable or a hose plugged into nothing; laid or plugged in,
## they'd lose their end. A stake goes in pulled up with nothing on its eye,
## so it comes out ready to drive, and a device whole, seated on nothing,
## nothing seated on it, no plug or hose in it and no line on its rings.
func fits(body: Object) -> bool:
	var stake := body as Stake
	if stake != null:
		return not stake.driven and stake.parts().is_empty() and not _player.waist.carries_line(stake)
	var device := body as Device
	if device != null:
		return device.carryable and device.host() == null and device.mounted().is_empty() \
			and not _player.waist.carries_line(device) \
			and not device.parts().any(_fastens)
	var part := body as Part
	if part == null:
		return false
	if part.has_meta(&"line"):
		return (part.get_meta(&"line") as Line).stowable()
	# A hook popped off a deck with its line's end still on it would lose that end.
	if part.get_children().any(func(n: Node) -> bool: return n is Socket and (n as Socket).part != null):
		return false
	return not (part.kind == &"port" or Hose.is_end(part)) or part.has_meta(&"rolled") or _loose_cable(part) != null


## A part that fastens something to its device: a plug, a hose's end, a
## line's end.
static func _fastens(part: Part) -> bool:
	return part.kind == &"port" or part.kind == &"tie" or Hose.is_end(part)


## Of the water or the food you carry, the least full that isn't empty, so
## one runs out before the next is opened.
func supply(kind: StringName) -> Supply:
	var best: Supply = null
	for thing in carried:
		var it := thing as Supply
		if it != null and it.kind == kind and it.amount > 0.0 and (best == null or it.amount < best.amount):
			best = it
	return best


## All the water, L, or food, kcal, you carry.
func stock(kind: StringName) -> float:
	var total := 0.0
	for thing in carried:
		if thing is Supply and thing.kind == kind:
			total += thing.amount
	return total


## What you carry weighs, kg.
func kg() -> float:
	var total := 0.0
	for thing in carried:
		total += thing.mass
	return total


## How far past what you carry easily you are: 0 up to carry_easy_kg, 1 at
## carry_sunk_kg, and on. The dev console's god carries anything easily.
func burden() -> float:
	if _player.vitals.god:
		return 0.0
	var tuning := Tuning.current()
	return maxf(kg() - tuning.carry_easy_kg, 0.0) / (tuning.carry_sunk_kg - tuning.carry_easy_kg)


## The share of your pace the load leaves you, before any line you haul:
## sunk in as far as hauling digs you in by carry_sunk_kg, and slower still
## for every kilogram past it.
func pace() -> float:
	var over := burden()
	return (1.0 - Tuning.current().haul_slow * minf(over, 1.0)) / maxf(over, 1.0)


## What the view says of the weight: what you carry against what you carry
## easily, or past it, that you're encumbered, how far over and what it
## leaves of your pace.
func weight_words() -> String:
	var weight := kg()
	var easy := Tuning.current().carry_easy_kg
	if _player.vitals.god and weight > easy:
		return "carried %.1f kg, all of it easily as god" % weight
	if burden() <= 0.0:
		return "carried %.1f of the %d kg you carry easily" % [weight, roundi(easy)]
	return "encumbered: %.1f kg, %.1f over · %d%% pace" % [weight, weight - easy, roundi(pace() * 100.0)]


## The devices you carry, working on you, which Power runs.
func devices() -> Array[Device]:
	var found: Array[Device] = []
	for thing in carried:
		var device := thing as Device
		if device != null and device.is_inside_tree():
			found.append(device)
	return found


## Every device you carry back on you and working, as a resume puts them in.
func carry_devices() -> void:
	for thing in carried:
		var device := thing as Device
		if device != null and device.get_parent() != _player:
			_on_you(device)


## A ration eaten to the end is gone, from what you carry or your hands.
func discard(part: Part) -> void:
	if not carried.has(part):
		part.queue_free()
		return
	carried.erase(part)
	part.free()


## Like things in a stack each, in the order they first went in: canisters,
## rations, stakes, hooks, coils of a length. A device with anything in it is
## a thing of its own.
func stacks() -> Array[Array]:
	var out: Array[Array] = []
	var at := {}
	for thing in carried:
		var key: Variant = _alike(thing)
		if not at.has(key):
			at[key] = out.size()
			out.append([])
		out[at[key]].append(thing)
	return out


## The view open, the mouse free to click it; or closed, and the mouse
## captured to look.
func show_view(to: bool) -> void:
	open = to
	hover = -1
	_layer.visible = to
	if not to:
		_home_view.hide()
	Controls.free_mouse(to)


## Back closes the view first, before any menu. Says whether it was open.
func close() -> bool:
	if not open:
		return false
	if _home_view.visible:
		_home_view.hide()
		return true
	show_view(false)
	Sounds.play(self, Sounds.BAG_CLOSE)
	return true


## What you hold goes in, if it fits. Says whether it did.
func put_in() -> bool:
	var hands := _player.hands
	if hands.held == null or hands.phase != Hands.Phase.HELD or hands.grasp.body != null or not fits(hands.held):
		return false
	carried.append(_rolled(hands.stow()))
	Sounds.play(self, Sounds.POUCH_IN)
	return true


## One of a stack to your empty hands: the fullest of water, food or charge,
## else the last that went in. Says whether it did.
func take_out(stack: int) -> bool:
	var hands := _player.hands
	var all := stacks()
	if stack < 0 or stack >= all.size() or hands.held != null or hands.grasp.body != null:
		return false
	var out := _pick(all[stack])
	carried.erase(out)
	if out.get_parent() == _player:
		_off_you(out as Device)
	_player.world.content.add_child(out)
	out.global_transform = _player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5))
	Finds.unroll(_player.world, out)
	hands.hold(out)
	Sounds.play(self, Sounds.POUCH_OUT)
	return true


## A click on the view: holding something, it goes in; empty-handed, one of
## the stack under the mouse comes out. Says whether it did anything.
func click(stack: int) -> bool:
	return put_in() if _player.hands.held != null else take_out(stack)


## Use on a stack: one of it is used where it is. A device is worked, as a
## radio's dial turns; water or food you drink or eat your fill of, the
## least full first, as the suit would. Anything else does nothing. Says
## whether it did anything.
func use(stack: int) -> bool:
	var all := stacks()
	if stack < 0 or stack >= all.size():
		return false
	var things: Array = all[stack]
	var device := things[-1] as Device
	if device != null:
		return device.interact(_player)
	if things[-1] is Remedy:
		return things[-1].use(_player, Vector3.ZERO)
	var least: Supply = null
	for each in things:
		var it := each as Supply
		if it != null and it.amount > 0.0 and (least == null or it.amount < least.amount):
			least = it
	return least != null and _player.vitals.take_in(least) > 0.0


## What goes in, off the tree: rope and wire as one rolled-up body, a device
## on you, anything else as it is.
func _rolled(body: RigidBody3D) -> RigidBody3D:
	var device := body as Device
	if device != null:
		_on_you(device)
		return device
	var part := body as Part
	if part != null and part.has_meta(&"line"):
		return (part.get_meta(&"line") as Line).roll()
	var cable := _loose_cable(part) if part != null and (part.kind == &"port" or Hose.is_end(part)) else null
	if cable == null:
		body.get_parent().remove_child(body)
		return body
	var id: StringName = part.get_meta(&"catalog")
	var rolled := Catalog.part(id)
	rolled.set_meta(&"rolled", id)
	if part.has_meta(&"layer"):
		Finds.mark(rolled, part.get_meta(&"layer"))
	var strong := cable as StrongCable
	if strong != null:
		_player.world.ropes.untie(strong.rope)
		strong.rope = null
	for plug in cable.plugs:
		_player.waist.untie(plug)
		Line._gone(plug)
	Line._gone(cable)
	return rolled


## On you, out of sight, touching nothing and held still, so it works on
## where you are: a radio plays from you, on its own battery.
func _on_you(device: Device) -> void:
	# How it sat, to come out as it went in.
	device.set_meta(&"carried", [device.collision_layer, device.collision_mask, device.freeze_mode])
	if device.get_parent() != null:
		device.get_parent().remove_child(device)
	device.visible = false
	device.collision_layer = 0
	device.collision_mask = 0
	device.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	device.freeze = true
	device.linear_velocity = Vector3.ZERO
	device.angular_velocity = Vector3.ZERO
	_player.add_child(device)
	device.transform = Transform3D(Basis.IDENTITY, POUCH)


## A device of the kit's on you once you're set up, unless a restock has
## dropped it meanwhile.
func _carry_once_ready(device: Variant) -> void:
	if is_instance_valid(device) and carried.has(device) and (device as Device).get_parent() == null:
		_on_you(device)


## Off you again, a body as it was, for your hands.
func _off_you(device: Device) -> void:
	var was: Array = device.get_meta(&"carried")
	device.remove_meta(&"carried")
	_player.remove_child(device)
	device.visible = true
	device.collision_layer = was[0]
	device.collision_mask = was[1]
	device.freeze_mode = was[2]
	device.freeze = false


## The cable a plug is on, if it's whole and plugged into nothing. A strong
## one that snapped is two loose plugs, not one piece.
func _loose_cable(plug: Part) -> Cable:
	for node in _player.world.content.get_children():
		var cable := node as Cable
		if cable == null or not cable.plugs.has(plug):
			continue
		var whole := cable.plugs.all(func(p: Variant) -> bool: return is_instance_valid(p) and (p as Part).socket == null)
		return cable if whole and (cable is not StrongCable or (cable as StrongCable).rope != null) else null
	return null


## What makes things alike enough to stack: what they are, and for rope or
## wire, which and how long. A device with anything in it stacks with
## nothing.
static func _alike(thing: RigidBody3D) -> Variant:
	var device := thing as Device
	if device != null and not device.parts().is_empty():
		return thing
	return [thing.get_meta(&"catalog", &""), thing.get_meta(&"rolled", &""), thing.get_meta(&"rolled_m", 0.0)]


## Of a stack, the one to hand you: the fullest of water, food or charge,
## else the last in.
static func _pick(things: Array) -> RigidBody3D:
	var best: RigidBody3D = things[-1]
	for thing: RigidBody3D in things:
		if _held_in(thing) > _held_in(best):
			best = thing
	return best


static func _held_in(thing: RigidBody3D) -> float:
	if thing is Supply:
		return (thing as Supply).amount
	if thing is Battery:
		return (thing as Battery).charge_wh
	return 0.0


## Where a stack's tile is drawn, and clicked, in the view, of `count`
## tiles (all you carry and the + after it, untold): rows of them low in the
## middle, the last row's foot clear of a radio's line of words.
func tile_rect(at: int, count := -1) -> Rect2:
	var size := _view.get_rect().size
	count = maxi(count if count >= 0 else stacks().size() + 1, 1)
	var across := _across()
	var cols := mini(count, across)
	var rows := ceili(float(count) / across)
	var width := cols * TILE.x + (cols - 1) * GAP
	var top := size.y - FOOT - _waist_height() - rows * TILE.y - (rows - 1) * GAP
	return Rect2(Vector2((size.x - width) * 0.5 + (at % across) * (TILE.x + GAP), top + (at / across) * (TILE.y + GAP)),
		TILE)


## How many tiles fit a row.
func _across() -> int:
	return clampi(floori((_view.get_rect().size.x - 64.0) / (TILE.x + GAP)), 1, ROW)


## The stack under a point, or past the last the + after them, else -1.
func _stack_at(point: Vector2) -> int:
	var count := stacks().size() + 1
	for i in count:
		if tile_rect(i, count).has_point(point):
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		show_view(not open)
		Sounds.play(self, Sounds.BAG_OPEN if open else Sounds.BAG_CLOSE)
		get_viewport().set_input_as_handled()
	elif open and not _home_view.visible and hover != -1 and event.is_action_pressed("interact"):
		# Over a thing, use is the thing's; elsewhere it's the world's.
		use(hover)
		get_viewport().set_input_as_handled()


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = _stack_at(event.position)
		_waist_lines.point_at(event.position if hover == -1 else Vector2(-100.0, -100.0))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hover = _stack_at(event.position)
		if hover != -1:
			click(hover)
		elif not _waist_lines.click(event.position):
			click(-1)
	_view.accept_event()


func _waist_height() -> float:
	return WaistLines.HEIGHT if not _player.waist.tied.is_empty() else 0.0


func _process(_delta: float) -> void:
	var showing := open and Controls.playing()
	if showing and not _layer.visible:
		Controls.free_mouse(true)
	_layer.visible = showing
	if showing:
		_home_button.visible = not _home_view.visible
		_home_button.position = tile_rect(0).position + Vector2(0.0, -78.0)
		_waist_lines.visible = not _home_view.visible
		if _home_view.visible:
			_view.queue_redraw()
			return
		var last := tile_rect(stacks().size()).end
		_waist_lines.controls_at = Vector2(tile_rect(0).position.x, last.y + 12.0)
		_waist_lines.refresh()
		_show_looks(stacks())
		_view.queue_redraw()


## Each stack's picture drawn again only if what it shows has changed since;
## a compass's as its needle turns, read as you'd hold it up.
func _show_looks(shown: Array[Array]) -> void:
	while _looks.size() < shown.size():
		_looks.append(InventoryLook.new(PICTURE))
		add_child(_looks[-1])
	var face := Basis(Vector3.UP, _player.global_rotation.y)
	for i in shown.size():
		var look := _looks[i]
		var thing: RigidBody3D = shown[i][0]
		var now := [thing, _brief(shown[i]), thing is Device and (thing as Device).powered,
			(thing as SurveyReceiver).meter_step if thing is SurveyReceiver else null]
		if now != look.key:
			look.key = now
			look.show_thing(thing)
		if thing is Compass:
			look.turn_needle((thing as Compass).needle_on(face, _player.world))
		elif thing is Streamer:
			look.stream(thing as Streamer, Time.get_ticks_msec() / 1000.0)


## The picture of a stack, for anything that reads the view.
func look_of(stack: int) -> InventoryLook:
	return _looks[stack] if stack < _looks.size() else null


## What you carry against what you carry easily, and past it how far over and
## what it leaves of your pace, in the accent; a bar up to where you're sunk
## in, marked where it starts to tell; the stacks, each drawn with its name,
## its number and how many; your waist; the keys.
func _draw_view() -> void:
	if _home_view.visible:
		return
	var tuning := Tuning.current()
	var shown := stacks()
	var tiles := shown.size() + 1
	var first := tile_rect(0, tiles)
	var cols := mini(tiles, _across())
	var width := maxf(cols * TILE.x + (cols - 1) * GAP, 420.0)
	var left := (_view.get_rect().size.x - width) * 0.5
	var weight := kg()
	_text(&"Readout", Vector2(left, first.position.y - 22.0), weight_words(), width,
		&"accent" if burden() > 0.0 else &"text")
	var bar := Rect2(left, first.position.y - 14.0, width, 4.0)
	var full := clampf(weight / tuning.carry_sunk_kg, 0.0, 1.0)
	var easy := tuning.carry_easy_kg / tuning.carry_sunk_kg
	_view.draw_rect(bar, _palette(&"panel"))
	_view.draw_rect(Rect2(bar.position, Vector2(bar.size.x * minf(full, easy), bar.size.y)), _palette(&"dim"))
	if full > easy:
		_view.draw_rect(Rect2(bar.position + Vector2(bar.size.x * easy, 0.0), Vector2(bar.size.x * (full - easy),
			bar.size.y)), _palette(&"accent"))
	_view.draw_rect(Rect2(bar.position + Vector2(bar.size.x * easy - 1.0, -2.0), Vector2(2.0, bar.size.y + 4.0)),
		_palette(&"text"))
	# The + after them, so it's plain that a click there puts what you hold in.
	var add := tile_rect(shown.size(), tiles)
	var lit := hover == shown.size() and _player.hands.held != null
	_view.draw_rect(add, _palette(&"panel"))
	_view.draw_rect(add, _palette(&"text" if lit else &"faint"), false, 2.0 if lit else 1.0)
	var mid := add.position + Vector2(TILE.x * 0.5, PICTURE.y * 0.5)
	var plus := _palette(&"text" if lit else &"dim")
	_view.draw_line(mid - Vector2(14.0, 0.0), mid + Vector2(14.0, 0.0), plus, 2.0)
	_view.draw_line(mid - Vector2(0.0, 14.0), mid + Vector2(0.0, 14.0), plus, 2.0)
	if shown.is_empty():
		_text(&"Label", add.position + Vector2(6.0, PICTURE.y + 16.0), "nothing carried", TILE.x - 12.0)
	for i in shown.size():
		var box := tile_rect(i, tiles)
		_view.draw_rect(box, _palette(&"panel"))
		_view.draw_rect(box, _palette(&"text" if i == hover else &"faint"), false, 2.0 if i == hover else 1.0)
		if i < _looks.size():
			_view.draw_texture_rect(_looks[i].get_texture(), Rect2(box.position, Vector2(PICTURE)), false)
		var things: Array = shown[i]
		if things.size() > 1:
			_text(&"Readout", box.position + Vector2(6.0, 16.0), "×%d" % things.size(), TILE.x - 12.0)
		_text(&"Label", box.position + Vector2(6.0, PICTURE.y + 16.0), _name(things[0]), TILE.x - 12.0)
		_text(&"Readout", box.position + Vector2(6.0, PICTURE.y + 32.0), _brief(things), TILE.x - 12.0)
	var under := tile_rect(tiles - 1, tiles).end.y
	var tied := PackedStringArray()
	var selectable := _player.hands.reel.waist_lines()
	for body in _player.waist.tied:
		if is_instance_valid(body) and not selectable.has(body):
			tied.append(str(body.get(&"label")))
	if not tied.is_empty():
		_text(&"Label", Vector2(left, under + 16.0), "waist: " + ", ".join(tied), width)
	Controls.draw_keys(_view, Vector2(left, under + 30.0 + _waist_height()), HINT)


func _palette(color: StringName) -> Color:
	return _view.get_theme_color(color, &"Palette")


## In the theme: names as text, amounts as a readout, in one of its colours.
func _text(type: StringName, at: Vector2, line: String, width: float, color := &"text") -> void:
	var font := _view.get_theme_font(&"font", type)
	var size := _view.get_theme_font_size(&"font_size", type)
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, size,
		_view.get_theme_constant(&"outline_size", &"Label"), _palette(&"shadow"))
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, size, _palette(color))


## A cable or a hose carried goes by its end, but it's the whole you have.
static func _name(thing: RigidBody3D) -> String:
	match thing.get_meta(&"rolled", &""):
		&"plug":
			return Catalog.NAMES[&"cable"]
		&"strong_plug":
			return Catalog.NAMES[&"strong_cable"]
		&"hose_end":
			return Catalog.NAMES[&"hose"]
	return thing.get(&"label")


## What a stack holds that you'd want to know at a glance, all of it
## together: water, food, charge, a coil's length, a radio's frequency.
static func _brief(things: Array) -> String:
	var first: RigidBody3D = things[0]
	if first.has_meta(&"rolled_m"):
		return "%.0f m" % first.get_meta(&"rolled_m")
	if first is Supply:
		var total: float = things.reduce(func(sum: float, s: Supply) -> float: return sum + s.amount, 0.0)
		return ("%.2f L" if first.kind == &"water" else "%d kcal") % total
	if first is Battery:
		return "%d Wh" % floori(things.reduce(func(sum: float, b: Battery) -> float: return sum + b.charge_wh, 0.0))
	if first is Plant:
		return "%d%% grown" % floori(first.growth * 100.0)
	var device := first as Device
	if device == null:
		return ""
	var cells := device.batteries()
	var held := "%d Wh" % floori(cells.reduce(func(sum: float, c: Battery) -> float: return sum + c.charge_wh, 0.0)) \
		if not cells.is_empty() else ""
	var radio := device as Radio
	if radio == null:
		return held
	var tuned: String = radio.stats()["tuned"]
	return tuned if held == "" else tuned + " · " + held


## Optional until the Home service is present in this build.
func _home_service() -> Object:
	var world := _player.world
	if not is_instance_valid(world):
		return null
	for property in world.get_property_list():
		if property.name == &"home":
			return world.get(&"home")
	return null


## Geographic north, matching the requested Home bearing across a pole.
func _heading() -> float:
	var forward := -_player.camera.global_basis.z
	var bearing := atan2(forward.x, -forward.z)
	return fposmod(bearing + (0.0 if _player.world.moon.north().z < 0.0 else PI), TAU)
