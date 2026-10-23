class_name Burner
extends Device
## Coalcane stores yesterday's light. The hopper feeds one real bundle into
## the chamber; only Power's lived tick spends it, even when the pool is full.

var on := false
var fuel_seconds := 0.0
var _ember: MeshInstance3D


func _ready() -> void:
	super()
	_ember = ChargeLight.make(Vector3(0.22, 0.055, 0.025))
	_ember.position = Vector3(0.0, -0.12, 0.34)
	add_child(_ember)
	show_charge()


func hopper() -> Socket:
	for socket in sockets():
		if socket.kind == &"fuel":
			return socket
	return null


func stocked() -> bool:
	var slot := hopper()
	return slot != null and is_instance_valid(slot.part) \
		and slot.part.get_meta(&"catalog", &"") == &"coalcane_bundle"


func interact(_by: Player) -> bool:
	if wrecked():
		return false
	world.salvage.claim(self)
	on = not on
	show_charge()
	world.power.wake(self)
	return true


func production_w(_t := NAN) -> float:
	return world.tuning.burner_w if world != null and not wrecked() and on \
		and (fuel_seconds > 0.0 or stocked()) else 0.0


func generate_wh(seconds: float, _t: float) -> float:
	if production_w() <= 0.0:
		return 0.0
	var left := seconds
	var burned := 0.0
	while left > 0.0:
		if fuel_seconds <= 0.0:
			if not stocked():
				break
			var fuel := take(hopper())
			fuel_seconds = world.tuning.coalcane_bundle_stalks * world.tuning.burner_stalk_seconds
			if is_instance_valid(fuel):
				fuel.free()
		var used := minf(left, fuel_seconds)
		fuel_seconds -= used
		left -= used
		burned += used
	var made := burned * world.tuning.burner_w / 3600.0
	if made > 0.0:
		Deeds.done(world, &"coalcane_power")
	return made


func show_charge() -> void:
	super()
	if not is_instance_valid(_ember):
		return
	var burning := production_w() > 0.0
	ChargeLight.paint(_ember, 0.4 if burning else 0.0)
	var held := fuel_seconds + (world.tuning.coalcane_bundle_stalks * world.tuning.burner_stalk_seconds if stocked() else 0.0)
	label = "Coalcane burner · %s · %.0fs" % ["burning" if burning else ("empty" if on else "off"), held]
