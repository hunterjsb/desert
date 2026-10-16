class_name Plant
extends Part
## A crop in a planter's slot, known by its crop, never by its name. It grows
## by the light and the temperature its planter feels, each crop between its
## own limits: carrots in the sun, fungus in the dark. Past its hardy limits
## it wilts back. Growing, it drinks from the planter's tank. Ripe, it stops
## and holds until it's picked.

const GROWING := &"growing"
const RIPE := &"ripe"
const DARK := &"too dark"
const BRIGHT := &"too bright"
const HOT := &"too hot"
const COLD := &"too cold"
const WILTING := &"wilting"
const DRY := &"dry"
## Sown it stands this share of its full height, and this share of its width.
const SOWN_HEIGHT := 0.35
const SOWN_WIDTH := 0.6

## Its crop, whose tuning numbers it grows by, and the food a harvest gives.
var crop: StringName
var food: StringName
## 0 sown to 1 ripe.
var growth := 0.0
## Growing, ripe, or why it isn't growing: what it did on its last tick.
var state := GROWING
## Its crop's numbers, from the tuning when it was sown: the felt light it
## starts and is full at, the temperatures it grows and survives between,
## seconds of full growth to ripen, water to ripen, L, and its harvest.
var light: Vector2
var grows: Vector2
var hardy: Vector2
var ripen_seconds: float
var litres: float
var harvest: int
var kcal: float

var _look: MeshInstance3D
var _paint: StandardMaterial3D
var _size: Vector3
var _young: Color
var _ripe: Color


func sow(id: StringName, gives: StringName, young: Color, ripe_color: Color) -> void:
	var tuning := Tuning.current()
	crop = id
	food = gives
	light = tuning.get(StringName("%s_light" % id))
	grows = tuning.get(StringName("%s_grows" % id))
	hardy = tuning.get(StringName("%s_hardy" % id))
	ripen_seconds = tuning.get(StringName("%s_minutes" % id)) * 60.0
	litres = tuning.get(StringName("%s_litres" % id))
	harvest = tuning.get(StringName("%s_harvest" % id))
	kcal = tuning.get(StringName("%s_kcal" % id))
	_young = young
	_ripe = ripe_color
	for child in get_children():
		if child is MeshInstance3D:
			_look = child
			_paint = (_look.mesh as BoxMesh).material
			_size = (_look.mesh as BoxMesh).size
			break
	set_growth(0.0)


func ripe() -> bool:
	return growth >= 1.0


## One tick of `seconds` in this felt light and temperature, °C, with this
## much water left in the tank, L; returns the water it drank.
func grow(seconds: float, lit: float, warmth: float, water: float) -> float:
	if ripe():
		state = RIPE
		return 0.0
	var full := seconds / ripen_seconds
	if warmth < hardy.x or warmth > hardy.y:
		state = WILTING
		set_growth(growth - Tuning.current().wilt_rate * full)
		return 0.0
	var share := clampf(inverse_lerp(light.x, light.y, lit), 0.0, 1.0)
	if warmth < grows.x or warmth > grows.y:
		share = 0.0
		state = COLD if warmth < grows.x else HOT
	elif share <= 0.0:
		state = DARK if light.y > light.x else BRIGHT
	else:
		state = GROWING
	var gain := full * share
	if gain * litres > water:
		gain = water / litres
		state = DRY
	var before := growth
	set_growth(growth + gain)
	return (growth - before) * litres


## It grows taller and fuller as it grows, and turns its ripe colour when
## ripe: as it reaches ripe, not a rounding short of it.
func set_growth(to: float) -> void:
	growth = 1.0 if to > 1.0 - 1e-9 else clampf(to, 0.0, 1.0)
	if _look == null:
		return
	var tall := lerpf(SOWN_HEIGHT, 1.0, growth)
	var wide := lerpf(SOWN_WIDTH, 1.0, growth)
	var own := Transform3D(Basis.from_scale(Vector3(wide, wide, tall)), Vector3(0.0, 0.0, _size.z * tall * 0.5))
	_look.transform = (socket.transform if socket != null else Transform3D.IDENTITY) * own
	_paint.albedo_color = _ripe if ripe() else _young.lerp(_ripe, 0.25 * growth)
