class_name AntennaReel
extends Device
## An antenna reel, after the reel of aerial wire in the WWII survival
## radios' kit: use it on a radio and its wire clips to the set's aerial
## terminal; carry it off and it pays out, as far as it holds
## (antenna_reel_m); set it down or stick it anywhere and the wire stays strung
## from the set to it. Use it again and it reels in. Walk past the end of its
## wire and the clip pops off the set. A radio hears by it on shortwave and at
## the bottom of the AM dial (Radio.wire): how far it's strung, and how high
## its two ends stand.

const GROUP := &"antenna_reels"
## Where its wire clips on a radio, in the set's frame: its aerial terminal,
## on its top toward the back.
const TERMINAL := Vector3(0.1, 0.11, -0.03)
## It finds a radio to clip to this near where you use it, m.
const CLIPS_WITHIN := 2.5
## Carried, its wire runs from about this high on you, m.
const ON_YOU := Vector3(0.0, 1.0, 0.0)
## The wire's thickness as drawn, m, and its colour: copper, dulled.
const THICK := 0.004
const COPPER := Color(0.55, 0.36, 0.2)

## The radio its wire is clipped to, or null.
var radio: Radio
var _wire: MeshInstance3D


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


func _ready() -> void:
	super()
	_wire = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(THICK, THICK, 1.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = COPPER
	paint.roughness = 0.5
	paint.metallic = 0.6
	box.material = paint
	_wire.mesh = box
	_wire.top_level = true
	_wire.visible = false
	add_child(_wire)


## Looked at with empty hands: reels in a strung wire; otherwise as any device.
func interact(by: Player) -> bool:
	if radio != null and by.hands.held == null:
		reel_in()
		return true
	return super(by)


## In your hands, aimed at `at`: clips to the radio there, or reels in.
func use(_by: Player, at: Vector3) -> bool:
	if radio != null:
		reel_in()
		return true
	var near := _radio_near(at)
	if near == null:
		return false
	clip(near)
	return true


## Its wire clipped to a radio's aerial terminal.
func clip(to: Radio) -> void:
	radio = to
	Sounds.play_at(self, Sounds.TIE)


## Its wire wound back in, off the set.
func reel_in() -> void:
	radio = null
	Sounds.play_at(self, Sounds.REEL)


## Where its wire ends: at the reel, or on you while it's carried.
func end() -> Vector3:
	if has_meta(&"carried") and world != null:
		return world.player.global_position + ON_YOU
	return global_position


## Where its wire starts: the radio's terminal.
func start() -> Vector3:
	return radio.global_transform * TERMINAL


## How far its wire is strung, m; none unclipped.
func strung() -> float:
	return start().distance_to(end()) if radio != null else 0.0


func stats() -> Dictionary:
	var now := super()
	if radio != null:
		now["rope_m"] = strung()
	return now


func _physics_process(delta: float) -> void:
	super(delta)
	if radio == null:
		return
	if not is_instance_valid(radio) or not radio.is_inside_tree() or radio.wrecked():
		radio = null
	elif strung() > Tuning.current().antenna_reel_m:
		# Past the end of its wire: the clip pops off the set.
		radio = null
		Sounds.play_at(self, Sounds.UNSEAT)


## Its wire drawn from the set's terminal to it, every frame.
func _process(_delta: float) -> void:
	if _wire == null:
		return
	_wire.visible = radio != null and is_instance_valid(radio)
	if not _wire.visible:
		return
	var from := start()
	var to := end()
	var span := from.distance_to(to)
	if span < 0.01:
		_wire.visible = false
		return
	var up := Vector3.UP if absf((to - from).normalized().dot(Vector3.UP)) < 0.99 else Vector3.BACK
	_wire.global_transform = Transform3D(Basis.looking_at(to - from, up).scaled(Vector3(1.0, 1.0, span)),
		(from + to) * 0.5)


## The radio nearest a place, within CLIPS_WITHIN of it, or null.
func _radio_near(at: Vector3) -> Radio:
	var best: Radio = null
	var nearest := CLIPS_WITHIN
	for node in get_tree().get_nodes_in_group(Radio.GROUP):
		var each := node as Radio
		if each == null or each is SurveyReceiver or not each.is_inside_tree():
			continue
		var d := each.global_position.distance_to(at)
		if d < nearest:
			nearest = d
			best = each
	return best
