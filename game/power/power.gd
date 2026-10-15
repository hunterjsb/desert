class_name Power
extends Node
## Power, as cheap arithmetic on a fixed tick of world time, so the frame rate
## never changes a charge and F5 speeds charging like everything else. Devices
## joined by cables share one pool: what they make feeds what they draw, then
## fills their batteries; a pool that can't meet its draw goes dark. A ledger
## proves no energy appears from nowhere.

## A dark pool waits until its batteries hold this share before it tries again.
const RESTART := 0.05

## Energy in, Wh, since the run began, and where it all went.
var generated_wh := 0.0
var used_wh := 0.0
var spilled_wh := 0.0

var _world: World
var _next := 0.0


func setup(world: World) -> void:
	_world = world
	_next = world.time


func _ready() -> void:
	# After the weather this tick, before the world moves the clock on.
	process_physics_priority = 150


func _physics_process(_delta: float) -> void:
	var step := _world.tuning.power_tick
	# A jump in time (a scenario) isn't lived through: nothing charged meanwhile.
	if _world.time < _next - step or _world.time - _next > 60.0:
		_next = _world.time
	while _next + step <= _world.time + 1e-9:
		_tick(step, _next)
		_next += step
	Dev.put("power/made", "%.2fWh" % generated_wh)
	Dev.put("power/used", "%.2fWh" % used_wh)
	Dev.put("power/spilled", "%.2fWh" % spilled_wh)
	Dev.put("power/stored", "%.2fWh" % stored_wh())


## Everything stored right now, Wh, in batteries fitted or loose.
func stored_wh() -> float:
	var total := 0.0
	for node in _world.content.get_children():
		if node is Battery:
			total += node.charge_wh
		elif node is Device:
			var cell: Battery = node.battery()
			if cell != null:
				total += cell.charge_wh
	return total


## One tick, with every source reading the weather at the tick's own time,
## however many ticks a frame holds.
func _tick(seconds: float, t: float) -> void:
	for pool in _pools():
		var made := 0.0
		var wanted := 0.0
		var cells: Array[Battery] = []
		for device: Device in pool:
			made += device.production_w(t) * seconds / 3600.0
			wanted += device.demand_w(t) * seconds / 3600.0
			var cell := device.battery()
			if cell != null:
				cells.append(cell)
		generated_wh += made
		var on := true
		if not pool.all(func(d: Device) -> bool: return d.powered) and made < wanted \
				and _fraction(cells) < RESTART:
			# Dark stays dark, with nothing running, until there's enough to restart:
			# everything made goes into the batteries meanwhile.
			spilled_wh += _share(made, cells, true)
			on = false
		elif made >= wanted:
			used_wh += wanted
			spilled_wh += _share(made - wanted, cells, true)
		else:
			var short := wanted - made
			var given := _share(short, cells, false)
			if given >= short - 1e-12:
				used_wh += wanted
			else:
				# Not enough: everything that came in or was left is spent trying.
				used_wh += made + given
				on = false
		for device: Device in pool:
			device.set_powered(on)
			if device.charge_light != null:
				var cell := device.battery()
				ChargeLight.paint(device.charge_light, cell.charge_wh / maxf(cell.capacity(), 1e-9) if cell != null else 0.0)
		for cell in cells:
			cell.show_charge()


func _fraction(cells: Array[Battery]) -> float:
	var held := 0.0
	var room := 0.0
	for cell in cells:
		held += cell.charge_wh
		room += cell.capacity()
	return held / room if room > 0.0 else 0.0


## Spreads energy over batteries, filling or draining each by its share; returns
## what was left over (filling) or what they gave (draining).
func _share(wh: float, cells: Array[Battery], filling: bool) -> float:
	var left := wh
	var given := 0.0
	# A few passes, so a full or empty battery's share goes to the others.
	for pass_index in 4:
		var open := cells.filter(func(c: Battery) -> bool:
			return c.charge_wh < c.capacity() if filling else c.charge_wh > 0.0)
		if open.is_empty() or left <= 1e-12:
			break
		var each := left / open.size()
		for cell: Battery in open:
			if filling:
				left -= each - cell.fill(each)
			else:
				var got := cell.drain(each)
				given += got
				left -= got
	return left if filling else given


## What the batteries in a device's pool hold now, Wh: all it could draw on.
func pool_wh(device: Device) -> float:
	for pool: Array in _pools():
		if pool.has(device):
			var held := 0.0
			for each: Device in pool:
				held += each.battery().charge_wh if each.battery() != null else 0.0
			return held
	return 0.0


## Devices grouped by the cables joining them; an unjoined device is its own
## pool. A wrecked one is in none: it neither makes nor draws, ever again.
func _pools() -> Array:
	var devices: Array[Device] = []
	var cables: Array[Cable] = []
	for node in _world.content.get_children():
		if node is Device and not node.wrecked():
			devices.append(node)
		elif node is Cable:
			cables.append(node)
	var root := {}
	for device in devices:
		root[device] = device
	var find := func(d: Device, f: Callable) -> Device:
		return d if root[d] == d else f.call(root[d], f)
	for cable in cables:
		var ends := cable.joined()
		if ends.size() == 2 and root.has(ends[0]) and root.has(ends[1]):
			root[find.call(ends[0], find)] = find.call(ends[1], find)
	var pools := {}
	for device in devices:
		var top: Device = find.call(device, find)
		if not pools.has(top):
			pools[top] = []
		pools[top].append(device)
	return pools.values()
