class_name Farm
extends Node
## Every planter's crops grow on power's tick of world time, so the frame
## rate never changes a harvest and the dev time warp grows them with
## everything else, and each tank is topped up again from its canisters and
## hoses as its crops drink (Water). A wrecked planter grows nothing. Wild
## plants (Feral) grow and fold on the same tick.

## The wild plants on their habitats.
var feral := Feral.new()

var _world: World
var _next := 0.0


func setup(world: World) -> void:
	_world = world
	_next = world.time
	add_child(feral)
	feral.setup(world)


func _ready() -> void:
	# After wear; before the suit eats what a planter drops.
	process_physics_priority = 165


func _physics_process(_delta: float) -> void:
	var step := _world.tuning.power_tick
	# A jump in time (a scenario) isn't lived through.
	if _world.time < _next - step or _world.time - _next > 60.0:
		_next = _world.time
	while _next + step <= _world.time + 1e-9:
		for node in _world.content.get_children():
			var planter := node as Planter
			if planter != null and not planter.wrecked():
				planter.tick(step, _next)
		feral.tick(step, _next)
		Water.flow(_world)
		_next += step
	_report()


func _report() -> void:
	var growing := 0
	var ripe := 0
	var water := 0.0
	var stored := 0.0
	var fed := 0.0
	for node in _world.content.get_children():
		var planter := node as Planter
		if planter == null:
			continue
		for plant in planter.plants():
			ripe += 1 if plant.ripe() else 0
			growing += 1 if plant.state == Plant.GROWING else 0
		water += planter.tank_l
		stored += planter.stored_kcal()
		fed += planter.fed_kcal
	Dev.put("farm/crops", "%d growing %d ripe" % [growing, ripe])
	Dev.put("farm/water", "%.2fL" % water)
	Dev.put("farm/stored", "%dkcal" % stored)
	Dev.put("farm/fed", "%dkcal" % fed)
