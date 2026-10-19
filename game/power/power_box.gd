class_name PowerBox
extends Device
## A power box: battery bays that stick on a deck like any device, the deck's
## one pool taking in every battery in them. A bay supplies, giving to the pool
## and taking what's spare, or is held to charge only, a charger for spares;
## its light strip shows which way it's flowing and how full it is at a
## glance. What a box lets you do is its make's: a skimmer's bodged rack is
## shared pool only, some of its bays dead, while a colonial cabinet lets a
## Console set its bays, rank who's served and switch devices off (MODELS).

## A bay that holds nothing: a skimmer rack's burnt-out ones.
const DEAD := &"dead_bay"
## What each make lets you do: hold a bay to charge with use at it ("hold"),
## and from a Console set its bays ("screen_bays"), rank who's served first
## ("ranks") and switch devices off ("switches"). Its strips: how many
## segments (none, a smooth glass), where one sits by its bay in the bay's
## frame [across, up], whether it lies under the bay rather than up its side,
## how long and wide, and how far in from the face its bays are set. A
## "readout" prints its bank exactly across its head.
## Company issue has breakers but no load-shedding logic: built to a budget,
## it keeps the rule every pool has, the shield first. A temple's box ranks
## what's served, its order a rite, but has no breakers: crude, everything
## wired to it runs while there's power.
const MODELS := {
	&"power_cabinet": {"hold": true, "screen_bays": true, "ranks": true, "switches": true, "readout": true,
		"segments": 10, "strip": Vector2(0.178, 0.0), "under": false, "long": 0.19, "wide": 0.024, "recess": 0.06},
	&"power_box": {"hold": true, "switches": true,
		"segments": 5, "strip": Vector2(0.0, -0.122), "under": true, "long": 0.22, "wide": 0.022, "recess": 0.05},
	&"power_shrine": {"hold": true, "ranks": true,
		"segments": 0, "strip": Vector2(0.175, 0.0), "under": false, "long": 0.2, "wide": 0.03, "recess": 0.05},
	&"power_rack": {
		"segments": 4, "strip": Vector2(0.0, -0.122), "under": true, "long": 0.17, "wide": 0.02, "recess": 0.05},
}
## A strip's pulse runs at full pace from this flow, W.
const BRISK_W := 60.0
const STRIP := preload("res://game/power/bay_strip.gdshader")

## Each bay held to charge only, in its bays' order.
var held: Array = []
## What each bay's strip shows: how full, its flow's pace, its state and its
## segments, as its instance carries them to the strips' shader.
var strip_states := PackedColorArray()
var _strips: MultiMeshInstance3D
var _readout: Label3D
var _shown := ""

static var _look: ShaderMaterial


func _ready() -> void:
	super()
	held.resize(bays().size())
	for i in held.size():
		held[i] = held[i] == true
	_build_strips()
	show_charge()


## Its make's terms.
func model() -> Dictionary:
	return MODELS.get(get_meta(&"catalog", &""), {})


## Its bays in its catalog's order, dead ones too.
func bays() -> Array[Socket]:
	var found: Array[Socket] = []
	for socket in frame_sockets():
		if socket.kind == &"battery" or socket.kind == DEAD:
			found.append(socket)
	return found


func pooled() -> Array[Battery]:
	var cells: Array[Battery] = []
	for bay in bays():
		if bay.part is Battery:
			cells.append(bay.part)
	return cells


## A held bay only takes; on a rack, shared pool only, every bay gives.
func supplies() -> Array[Battery]:
	var cells: Array[Battery] = []
	var all := bays()
	for i in all.size():
		if all[i].part is Battery and not is_held(i):
			cells.append(all[i].part)
	return cells


## Whether a bay only charges.
func is_held(i: int) -> bool:
	return model().get("hold", false) and i < held.size() and held[i] == true


## Holds a bay to charge only, or lets it supply. Says whether it changed.
func hold(i: int, on: bool) -> bool:
	var all := bays()
	if not model().get("hold", false) or i < 0 or i >= all.size() or all[i].kind == DEAD or is_held(i) == on:
		return false
	if held.size() < all.size():
		held.resize(all.size())
	held[i] = on
	show_charge()
	return true


## Use at a battery in a bay holds it to charge or lets it supply; anywhere
## else on it, as any device on a deck.
func interact(by: Player) -> bool:
	var i := bays().find(by.hands.look_socket) if by != null and by.hands.look_device == self else -1
	if i < 0 or by.hands.held != null:
		return super(by)
	if not model().get("hold", false):
		return by.hands.refuse("shared pool only")
	hold(i, not is_held(i))
	Sounds.play_at(self, Sounds.BOARD_ON if is_held(i) else Sounds.BOARD_OFF)
	by.hands.say("charging only" if is_held(i) else "supplying")
	return true


## Each bay's strip: how full, which way and how fast it flows, and whether
## it's held, dead or empty; the readout, its bank exactly.
func show_charge() -> void:
	if _strips == null:
		return
	var all := bays()
	var segments: float = model().get("segments", 5)
	strip_states.resize(all.size())
	var held_wh := 0.0
	var room := 0.0
	var flow := 0.0
	for i in all.size():
		var cell := all[i].part as Battery
		var state := 2.0 if all[i].kind == DEAD else (3.0 if cell == null else (1.0 if is_held(i) else 0.0))
		var fill := 0.0
		var pace := 0.0
		if cell != null:
			fill = cell.charge_wh / maxf(cell.capacity(), 1e-9)
			pace = clampf(cell.flow_w / BRISK_W, -1.0, 1.0)
			held_wh += cell.charge_wh
			room += cell.capacity()
			flow += cell.flow_w
		var shows := Color(fill, pace, state, segments)
		if strip_states[i] != shows:
			strip_states[i] = shows
			_strips.multimesh.set_instance_custom_data(i, shows)
	if _readout != null:
		var said := "%4d Wh %3d%% %+4d W" % [floori(held_wh), roundi(100.0 * held_wh / room), roundi(flow)] \
			if room > 0.0 else "NO CELLS"
		if said != _shown:
			_shown = said
			_readout.text = said


func _recompute() -> void:
	super()
	show_charge()


## A bay's frame on its box, from its catalog entry: facing out, maybe turned.
static func bay_frame(entry: Array) -> Transform3D:
	var bay: Dictionary = entry[3] if entry.size() > 3 else {}
	return Transform3D(Catalog._facing(entry[2]) * Basis(Vector3.BACK, deg_to_rad(bay.get("turn", 0.0))), entry[1])


## Where a bay's strip lies on its make's face, in the bay's frame: up its
## side or under it, a little proud.
static func strip_frame(id: StringName, bay: Dictionary) -> Transform3D:
	var spec: Dictionary = MODELS[id]
	var at: Vector2 = bay.get("strip", spec.strip)
	var turn := Basis(Vector3.BACK, -PI / 2.0) if spec.under else Basis.IDENTITY
	return Transform3D(turn, Vector3(at.x, at.y, spec.recess + 0.003))


## Its strips, one draw for them all, each bay's state riding on its instance.
func _build_strips() -> void:
	if _strips != null:
		return
	var id: StringName = get_meta(&"catalog")
	var spec: Dictionary = model()
	var all := bays()
	var strips := MultiMesh.new()
	strips.transform_format = MultiMesh.TRANSFORM_3D
	strips.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	strips.mesh = quad
	strips.instance_count = all.size()
	for i in all.size():
		var at := all[i].transform * strip_frame(id, all[i].get_meta(&"bay", {}))
		strips.set_instance_transform(i, Transform3D(at.basis.scaled_local(Vector3(spec.wide, spec.long, 1.0)), at.origin))
	_strips = MultiMeshInstance3D.new()
	_strips.multimesh = strips
	_strips.material_override = look()
	_strips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_strips)
	if spec.get("readout", false):
		_readout = Label3D.new()
		_readout.font = preload("res://assets/fonts/GeistMono-Regular.ttf")
		_readout.font_size = 40
		_readout.pixel_size = 0.0011
		_readout.outline_size = 0
		_readout.modulate = Color(0.55, 1.0, 0.92)
		_readout.shaded = false
		_readout.double_sided = false
		var h: Vector3 = Catalog.DEVICES[id].size * 0.5
		# Facing out of its front, on the dark glass across its head.
		_readout.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, h.y - 0.08, -h.z - 0.007))
		add_child(_readout)


## The strips' one look, shared by every box.
static func look() -> ShaderMaterial:
	if _look == null:
		_look = ShaderMaterial.new()
		_look.shader = STRIP
	return _look
