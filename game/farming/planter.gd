class_name Planter
extends Device
## The hover planter: three standard planters and a pot on top, its own water
## tank, and a mod mount on its back. On the farm's tick its crops grow by
## what it feels where it stands, drinking from the tank, whether or not it
## has power. A canister in its water socket, or what a hose there joins it
## to, keeps the tank full (Water). A ripe crop taken by hand comes out as
## its harvest and starts again. With a harvester fitted, ripe crops go into
## its own storage instead, the share you set going back in as seed, and it
## drops food onto you when you're near and you're carrying little food, and
## anything else it grew whenever you're near. Use on it sets its tray as on
## any device; the share it replants waits for its own control (Hunter,
## 2026-10-17).

## The shares use steps through.
const SPLITS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
## What wild seed waiting for a slot is kept under, after its crop's id.
const WILD := "/wild"
## Where its crops feel the weather: just over the slots.
const CROWN := Vector3(0.0, 0.3, 0.0)

var tank_l := 0.0
## The share of each harvest the harvester sows again.
var split: float = Tuning.current().replant_share
## What it holds: units of each output its harvests gave, and seed of each
## crop waiting for a free slot.
var stored := {}
var seeds := {}
## Its harvests since it was found: what ripened under the harvester, units
## of each crop, and of that what went back in as seed; what was stored and
## what it dropped onto you, units of each output; what was picked by hand.
var ripened := {}
var replanted := {}
var banked := {}
var dropped := {}
var picked := {}
## Food it has dropped onto you, kcal.
var fed_kcal := 0.0

## Seed owed to each crop but not yet whole, so the split holds over many harvests.
var _owed := {}


## The farm's tick: the crops grow, those that fold read the storm ahead,
## and with a harvester the ripe ones are harvested, seed is sown and food dropped.
func tick(seconds: float, t: float) -> void:
	var crops := plants()
	if not crops.is_empty():
		var feels := felt(t)
		for plant in crops:
			tank_l = maxf(tank_l - plant.grow(seconds, feels, tank_l), 0.0)
			var lead: float = plant.data.stages.get("folds", 0.0) * 60.0
			if lead > 0.0:
				plant.forecast(_stormy(t) or _stormy(t + lead), seconds)
	if not harvests():
		return
	for plant in crops:
		if plant.ripe():
			_harvest(plant)
	_sow()
	_drop()


## What its crops feel at time t, just over its slots: the sun's light, the
## storm's dark in it; a lamp's, which none of its sockets takes yet; the
## temperature, wind and dust with shelter applied; and the storm in the air,
## its humid dark, which no bubble keeps out.
func felt(t: float) -> Dictionary:
	return felt_at(world.weather, global_position + CROWN, t)


## What a crop feels at a place, engine metres, at time t: in a planter or
## wild in the sand alike.
static func felt_at(weather: Weather, at: Vector3, t: float) -> Dictionary:
	return {&"light": weather.felt_light(at, t), &"lamp": 0.0, &"temperature": weather.felt_temperature(at, t),
		&"wind": weather.felt_wind(at, t).length(), &"particles": weather.felt_storm(at, t),
		&"storm": weather.field_storm(at, t)}


## Whether the storm field is over it at time t, as a forecast reads it:
## the weather's own pressure, not what a bubble lets through.
func _stormy(t: float) -> bool:
	var at := global_position + CROWN
	return world.weather.field.raw_storm_at(world.world_x(at.x), world.world_z(at.z), t) > 0.0


func plants() -> Array[Plant]:
	var found: Array[Plant] = []
	for socket in sockets():
		if socket.part is Plant:
			found.append(socket.part)
	return found


## Whether a harvester is fitted.
func harvests() -> bool:
	for part in parts():
		if part.stats.get("harvester", 0) > 0:
			return true
	return false


## Taken by hand, a ripe crop comes out as its harvest, the first of it in
## your hands, and starts again: one that regrows grows again where it
## stands, and another's seed goes in with what you carry, as does the rest
## of its harvest.
func take(socket: Socket) -> Part:
	var plant := socket.part as Plant
	if plant == null or not plant.ripe():
		return super(socket)
	var harvest: Array[Part] = []
	for gives: Array in plant.yields():
		harvest.append_array(Catalog.output(gives[0], gives[1]))
	_count(picked, plant.crop, plant.harvest)
	plant.pick()
	var player := world.player
	if not plant.data.stages.has("regrows"):
		var seed := super(socket)
		seed.get_parent().remove_child(seed)
		harvest.append(seed)
	for i in range(1, harvest.size()):
		player.suit.carried.append(harvest[i])
		_fall(harvest[i], player)
	var first := harvest[0]
	get_parent().add_child(first)
	first.global_transform = global_transform * socket.transform
	first.linear_velocity = linear_velocity
	return first


func stats() -> Dictionary:
	var now := super()
	now["water_l"] = Tuning.current().planter_tank_litres
	now["water_left_l"] = tank_l
	if now.get("harvester", 0) > 0:
		now["replant"] = split
		now["stored_kcal"] = stored_kcal()
		now["seeds"] = seeds.values().reduce(func(a: int, b: int) -> int: return a + b, 0)
	return now


## The food in its storage, kcal.
func stored_kcal() -> float:
	var kcal := 0.0
	for out: StringName in stored:
		if Catalog.PARTS[out].kind == &"food":
			kcal += stored[out] * Catalog.PARTS[out].each
	return kcal


## A save from before the crops had their names: carrots are root-tubers and
## fungus vat fungus, and what a harvest stored was kept by the crop it came from.
func restored() -> void:
	for tally: Dictionary in [seeds, ripened, replanted, picked, _owed]:
		_rename(tally, func(id: StringName) -> StringName: return Catalog.current(id))
	for tally: Dictionary in [stored, banked, dropped]:
		_rename(tally, func(id: StringName) -> StringName:
			var now := Catalog.current(id)
			return Catalog.PARTS[now].crop.yields[0][0] if Catalog.PARTS[now].has("crop") else now)


static func _rename(tally: Dictionary, to: Callable) -> void:
	for id: StringName in tally.keys():
		var now: StringName = to.call(id)
		if now != id:
			tally[now] = tally.get(now, 0) + tally[id]
			tally.erase(id)


## A ripe crop's harvest: its share of seed goes back in, first into its own
## slot, and the rest of it is stored with all else it gives.
func _harvest(plant: Plant) -> void:
	var crop := plant.crop
	var owed: float = _owed.get(crop, 0.0) + split * plant.harvest
	var seed := mini(floori(owed + 1e-9), plant.harvest)
	_owed[crop] = owed - seed
	_count(ripened, crop, plant.harvest)
	_count(replanted, crop, seed)
	var yields := plant.yields()
	for i in yields.size():
		var gives: Array = yields[i]
		var units: int = gives[1] - (seed if i == 0 else 0)
		_count(banked, gives[0], units)
		_count(stored, gives[0], units)
	plant.pick()
	if seed > 0:
		# Sown again where it stood; wild seed stays wild.
		_count(seeds, StringName(str(crop) + WILD) if plant.wild else crop, seed - 1)
	else:
		# Not ripe now, so it comes out whole, and goes.
		take(plant.socket).free()


## Seed into every free slot it fits.
func _sow() -> void:
	for held: StringName in seeds:
		if seeds[held] <= 0:
			continue
		var crop := StringName(str(held).trim_suffix(WILD))
		var kind: StringName = Catalog.PARTS[crop].kind
		for socket in sockets():
			if seeds[held] > 0 and socket.part == null and socket.kind == kind:
				var seed := Catalog.part(crop) as Plant
				seed.wild = held != crop
				fit(seed, socket)
				seeds[held] -= 1


## Onto you, if you're near: food while you carry less than the tuning asks,
## and anything else whenever; a harvest's worth at a time, one a tick.
func _drop() -> void:
	var player := world.player
	var tuning := world.tuning
	if player.vitals.dead or player.global_position.distance_to(global_position) > tuning.drop_reach:
		return
	var suit := player.suit
	var hungry := suit.stock(&"food") < tuning.drop_until_kcal
	for out: StringName in stored:
		var food: bool = Catalog.PARTS[out].kind == &"food"
		if stored[out] <= 0 or (food and not hungry):
			continue
		var units: int = mini(stored[out], _per_harvest(out))
		stored[out] -= units
		_count(dropped, out, units)
		for made in Catalog.output(out, units):
			if food:
				fed_kcal += (made as Supply).amount
			suit.carried.append(made)
			_fall(made, player)
		return


## The most of an output any crop's harvest gives.
static func _per_harvest(out: StringName) -> int:
	var most := 1
	for id: StringName in Catalog.PARTS:
		for gives: Array in Catalog.PARTS[id].get("crop", {}).get("yields", []):
			if gives[0] == out:
				most = maxi(most, gives[1])
	return most


func _count(tally: Dictionary, id: StringName, units: int) -> void:
	tally[id] = tally.get(id, 0) + units


## Something to see: food or seed falling from the planter onto you.
func _fall(part: Part, onto: Player) -> void:
	fall(world, part, global_position + CROWN, onto)


## A thing falling from a place, engine metres, onto you.
static func fall(in_world: World, part: Part, from: Vector3, onto: Player) -> void:
	var falling := Falling.new()
	for child in part.get_children():
		if child is MeshInstance3D:
			falling.mesh = (child as MeshInstance3D).mesh
			break
	falling.onto = onto
	falling.offset = from - onto.global_position - Falling.CHEST
	in_world.content.add_child(falling)
	falling.global_position = from


## Only drawn: it touches nothing and the simulation never reads it.
class Falling extends MeshInstance3D:
	const SECONDS := 0.5
	const CHEST := Vector3(0.0, 1.2, 0.0)
	var onto: Node3D
	## Where it began, from you, so an origin shift moves both.
	var offset: Vector3
	var _t := 0.0

	func _process(delta: float) -> void:
		_t = minf(_t + delta / SECONDS, 1.0)
		if not is_instance_valid(onto) or _t >= 1.0:
			if is_instance_valid(onto):
				Sounds.play(onto, Sounds.FOOD_DROP)
			queue_free()
			return
		global_position = onto.global_position + CHEST + offset * (1.0 - _t) + Vector3.UP * sin(PI * _t) * 0.6
