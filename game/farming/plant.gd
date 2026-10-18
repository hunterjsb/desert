class_name Plant
extends Part
## A crop in a planter's slot, known by its crop, never by its name. Every
## crop grows by this one path, reading its own data in the catalog: the
## light it grows by, and the temperature, wind and dust its planter feels
## against its tolerances. Within all of them it grows, past one it holds,
## and past what it holds through it wilts back, but never dies. Growing, it
## drinks from the tank. It goes seedling, growing, mature; mature it's ripe
## and holds until it's picked, but one that fruits in bursts waits for a
## storm's humid air to fruit. Picked, it's sown again from its propagule, or
## one that regrows keeps its share and grows again where it stands. One that
## folds closes its leaves ahead of a storm, a pose and nothing more. Wild
## stock (Feral) grows the same, and gives less.

const GROWING := &"growing"
const RIPE := &"ripe"
const DARK := &"too dark"
const BRIGHT := &"too bright"
const HOT := &"too hot"
const COLD := &"too cold"
const WINDY := &"too windy"
const DUSTY := &"too dusty"
const WILTING := &"wilting"
const DRY := &"dry"
const WAITING := &"waiting for a storm"
const FRUITING := &"fruiting"
const BURNT := &"too much sun"
## The shared stages. Going to seed is how a plant drifts toward wild stock;
## nothing does yet.
const SEEDLING := &"seedling"
const YOUNG := &"growing"
const MATURE := &"mature"
const TO_SEED := &"to seed"
## Below this share grown it's a seedling.
const SEEDLING_UNTIL := 0.25
## Each tolerance, [the crop's, what its planter feels, which way is worse,
## what it says past it]. Radiation is a crop's too, but nothing feels a dose.
const AXES := [
	[&"cold", &"temperature", -1.0, COLD],
	[&"heat", &"temperature", 1.0, HOT],
	[&"wind", &"wind", 1.0, WINDY],
	[&"particles", &"particles", 1.0, DUSTY],
	[&"radiation", &"radiation", 1.0, BURNT],
]
## Leaves fold or open this share a second, and their look in this many steps.
const FOLD_RATE := 1.0 / 30.0
const FOLD_STEPS := 6

## Its crop, the catalog id it's known by, and that crop's data.
var crop: StringName
var data: Dictionary
## 0 sown to 1 mature.
var growth := 0.0
## A crop that fruits in bursts: 0 to 1 fruited, once mature.
var fruit := 0.0
## Growing, ripe, or why it isn't growing: what it did on its last tick.
var state := GROWING
## Wild stock rather than clean: cut or dug from a feral plant, or grown
## from one, it gives the wild share of its harvest, and says so.
var wild := false:
	set(to):
		wild = to
		if crop != &"":
			var named: String = Catalog.PARTS[crop].label
			label = "Wild %s" % named.to_lower() if wild else named
## Its leaves, 0 open to 1 folded shut.
var fold := 0.0
var ripen_seconds: float:
	get:
		return data.minutes * 60.0
var burst_seconds: float:
	get:
		return data.stages.get("bursts", 0.0) * 60.0
var litres: float:
	get:
		return data.litres
## A harvest of what comes to your hands, units, and its kcal each.
var harvest: int:
	get:
		return yields()[0][1]
var kcal: float:
	get:
		return Catalog.PARTS[data.yields[0][0]].get("each", 0.0)

var _look: MeshInstance3D
var _folded_once := false


func sow(id: StringName) -> void:
	crop = id
	data = Catalog.PARTS[id].crop
	for child in get_children():
		if child is MeshInstance3D:
			_look = child
			break
	set_growth(0.0)


func ripe() -> bool:
	return growth >= 1.0 and (not data.stages.has("bursts") or fruit >= 1.0)


func stage() -> StringName:
	return stage_of(growth)


static func stage_of(grown: float) -> StringName:
	return MATURE if grown >= 1.0 else (SEEDLING if grown < SEEDLING_UNTIL else YOUNG)


## How far into its stage's look it has filled out, as a share of full size.
static func fill_of(grown: float) -> float:
	var at := stage_of(grown)
	var into := grown / SEEDLING_UNTIL if at == SEEDLING \
		else ((grown - SEEDLING_UNTIL) / (1.0 - SEEDLING_UNTIL) if at == YOUNG else 1.0)
	return lerpf(0.7, 1.0, into)


## Its harvest as [part, units]: wild stock gives its share of each, never none.
func yields() -> Array:
	if not wild:
		return data.yields
	var share := Tuning.current().feral_wild_yield
	return data.yields.map(func(gives: Array) -> Array: return [gives[0], maxi(1, roundi(gives[1] * share))])


## One tick of `seconds` in what its planter feels (Planter.felt()), with
## this much water left in the tank, L; returns the water it drank.
func grow(seconds: float, felt: Dictionary, water: float) -> float:
	if ripe():
		state = RIPE
		return 0.0
	var full := seconds / ripen_seconds
	var why := GROWING
	for axis: Array in AXES:
		if not felt.has(axis[1]):
			continue
		var limits: Vector2 = data[axis[0]]
		var past: float = felt[axis[1]] * axis[2]
		if past > limits.y * axis[2] and not data.stages.get("never_dies", false):
			state = WILTING
			set_growth(growth - Tuning.current().wilt_rate * full)
			return 0.0
		if past > limits.x * axis[2] and why == GROWING:
			why = axis[3]
	var share := clampf(inverse_lerp(data.lit.x, data.lit.y, felt.lamp if data.light == &"lamp" else felt.light), 0.0, 1.0)
	if why != GROWING:
		share = 0.0
	elif share <= 0.0:
		why = DARK if data.lit.y > data.lit.x else BRIGHT
	state = why
	if growth >= 1.0:
		# Mature, it fruits only in a storm's humid air, which no bubble keeps out.
		if felt.storm <= 0.0:
			state = WAITING if state == GROWING else state
			return 0.0
		state = FRUITING if state == GROWING else state
		fruit = minf(fruit + share * seconds / burst_seconds, 1.0)
		set_growth(growth)
		return 0.0
	var gain := full * share
	if gain * litres > water:
		gain = water / litres
		state = DRY
	var before := growth
	set_growth(growth + gain)
	return (growth - before) * litres


## Picked: sown again from nothing, or what's left of one that regrows.
func pick() -> void:
	fruit = 0.0
	set_growth(data.stages.get("regrows", 0.0))


## Whether a storm is due within its fold's lead, or here: its leaves close
## toward shut, or open, over `seconds`. The first it hears, they're there.
func forecast(stormy: bool, seconds: float) -> void:
	fold = fold_toward(fold, stormy, seconds, not _folded_once)
	_folded_once = true
	_show()


## Leaves at `fold` closing toward shut, or opening, over `seconds`; the first
## time they're read, they're there.
static func fold_toward(from: float, stormy: bool, seconds: float, first: bool) -> float:
	var to := 1.0 if stormy else 0.0
	return to if first else move_toward(from, to, FOLD_RATE * seconds)


## A save from before the crops fruited in bursts: one that was ripe still is.
func restored() -> void:
	if state == RIPE and data.stages.has("bursts"):
		fruit = 1.0
	set_growth(growth)


## Its look is its crop's at its stage, growing into it: as it reaches
## mature, not a rounding short of it.
func set_growth(to: float) -> void:
	growth = 1.0 if to > 1.0 - 1e-9 else clampf(to, 0.0, 1.0)
	if growth < 1.0:
		fruit = 0.0
	_show()


func _show() -> void:
	if _look == null:
		return
	var at := stage()
	var look := Dress.crop(crop, RIPE if ripe() else at, roundi(fold * FOLD_STEPS) / float(FOLD_STEPS))
	if look != null:
		_look.mesh = look
	# Within a stage it fills out toward the next.
	var own := Transform3D(Basis.from_scale(Vector3.ONE * fill_of(growth)), Vector3.ZERO)
	_look.transform = (socket.transform if socket != null else Transform3D.IDENTITY) * own
