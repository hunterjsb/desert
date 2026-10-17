class_name Planter
extends Device
## The hover planter: plant slots on top, its own water tank, and a mod mount
## on its back. On the farm's tick its crops grow by the light and the
## temperature where it stands, drinking from the tank, whether or not it has
## power. A canister in its water socket, or what a hose there joins it to,
## keeps the tank full (Water). A ripe crop taken by hand comes out as its
## food and starts again. With a harvester fitted, ripe crops go into its own
## storage instead, the share you set going back in as seed, and it drops food
## onto you when you're near and you're carrying little food. Use on it sets
## its tray as on any device; the share it replants waits for its own control
## (Hunter, 2026-10-17).

## The shares use steps through.
const SPLITS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
## Where its crops feel the weather: just over the slots.
const CROWN := Vector3(0.0, 0.3, 0.0)

var tank_l := 0.0
## The share of each harvest the harvester sows again.
var split: float = Tuning.current().replant_share
## What it holds, units of each crop: food, and seed waiting for a free slot.
var stored := {}
var seeds := {}
## Its harvests since it was found, units of each crop: what ripened under
## the harvester, and of that what went back in as seed and what was stored;
## what it dropped onto you; what was picked by hand.
var ripened := {}
var replanted := {}
var banked := {}
var dropped := {}
var picked := {}
## Food it has dropped onto you, kcal.
var fed_kcal := 0.0

## What a harvest of each crop it has stored gives: [food, units, kcal each].
var _gives := {}
## Seed owed to each crop but not yet whole, so the split holds over many harvests.
var _owed := {}


## The farm's tick: the crops grow, and with a harvester the ripe ones are
## harvested, seed is sown and food dropped.
func tick(seconds: float, t: float) -> void:
	var crops := plants()
	if not crops.is_empty():
		var at := global_position + CROWN
		var lit := world.weather.felt_light(at, t)
		var warmth := world.weather.felt_temperature(at, t)
		for plant in crops:
			tank_l = maxf(tank_l - plant.grow(seconds, lit, warmth, tank_l), 0.0)
	if not harvests():
		return
	for plant in crops:
		if plant.ripe():
			_harvest(plant)
	_sow()
	_drop()


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


## Taken by hand, a ripe crop comes out as its harvest, food in your hands,
## and starts again: fungus fruits again where it stands, and another crop's
## seed goes in with what you carry.
func take(socket: Socket) -> Part:
	var plant := socket.part as Plant
	if plant == null or not plant.ripe():
		return super(socket)
	var food := Catalog.food(plant.food, plant.harvest * plant.kcal)
	_count(picked, plant.crop, plant.harvest)
	plant.set_growth(0.0)
	var player := world.player
	if not plant.regrows:
		var seed := super(socket)
		seed.get_parent().remove_child(seed)
		player.suit.carried.append(seed)
		_fall(seed, player)
	get_parent().add_child(food)
	food.global_transform = global_transform * socket.transform
	food.linear_velocity = linear_velocity
	return food


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
	for crop: StringName in stored:
		kcal += stored[crop] * _gives[crop][2]
	return kcal


## A ripe crop's harvest: its share of seed goes back in, first into its own
## slot, and the rest is stored.
func _harvest(plant: Plant) -> void:
	var crop := plant.crop
	_gives[crop] = [plant.food, plant.harvest, plant.kcal]
	var owed: float = _owed.get(crop, 0.0) + split * plant.harvest
	var seed := mini(floori(owed + 1e-9), plant.harvest)
	_owed[crop] = owed - seed
	_count(ripened, crop, plant.harvest)
	_count(replanted, crop, seed)
	_count(banked, crop, plant.harvest - seed)
	_count(stored, crop, plant.harvest - seed)
	plant.set_growth(0.0)
	if seed > 0:
		# Sown again where it stood.
		_count(seeds, crop, seed - 1)
	else:
		# Not ripe now, so it comes out whole, and goes.
		take(plant.socket).free()


## Seed into every free slot it fits.
func _sow() -> void:
	for crop: StringName in seeds:
		if seeds[crop] <= 0:
			continue
		var kind: StringName = Catalog.PARTS[crop].kind
		for socket in sockets():
			if seeds[crop] > 0 and socket.part == null and socket.kind == kind:
				fit(Catalog.part(crop), socket)
				seeds[crop] -= 1


## Onto you, if you're near, while you carry less food than the tuning asks:
## a harvest's worth at a time, one a tick.
func _drop() -> void:
	var player := world.player
	var tuning := world.tuning
	if player.vitals.dead or player.global_position.distance_to(global_position) > tuning.drop_reach:
		return
	var suit := player.suit
	if suit.stock(&"food") >= tuning.drop_until_kcal:
		return
	for crop: StringName in stored:
		if stored[crop] <= 0:
			continue
		var gives: Array = _gives[crop]
		var units: int = mini(stored[crop], gives[1])
		stored[crop] -= units
		_count(dropped, crop, units)
		fed_kcal += units * gives[2]
		var food := Catalog.food(gives[0], units * gives[2])
		suit.carried.append(food)
		_fall(food, player)
		return


func _count(tally: Dictionary, crop: StringName, units: int) -> void:
	tally[crop] = tally.get(crop, 0) + units


## Something to see: food or seed falling from the planter onto you.
func _fall(part: Part, onto: Player) -> void:
	var falling := Falling.new()
	for child in part.get_children():
		if child is MeshInstance3D:
			falling.mesh = (child as MeshInstance3D).mesh
			break
	falling.onto = onto
	falling.offset = global_position + CROWN - onto.global_position - Falling.CHEST
	world.content.add_child(falling)
	falling.global_position = global_position + CROWN


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
