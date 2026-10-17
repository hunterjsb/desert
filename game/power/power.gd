class_name Power
extends Node
## Power, as cheap arithmetic on a fixed tick of world time, so the frame rate
## never changes a charge and F5 speeds charging like everything else. Devices
## joined by cables share one pool: what they make feeds what they draw, then
## fills their batteries; a pool that can't meet its draw goes dark. A device
## seated on another, like a shield on a crate, shares its pool. Running short,
## a pool's lower-ranked devices give way first, like a crate's tray to the
## shield on it, or a board racked on it charging. A ledger proves no energy
## appears from nowhere.

## A dark pool waits until its batteries hold this share before it tries again.
const RESTART := 0.05
## A device ranked below the highest in its pool stops drawing once the pool's
## batteries are down to this share, kept for the higher ones, unless the
## sources alone carry everything; it runs again once they hold RESTART more.
const RESERVE := 0.25

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
	for device in _world.devices():
		for cell in device.batteries():
			total += cell.charge_wh
	return total


## One tick, with every source reading the weather at the tick's own time,
## however many ticks a frame holds.
func _tick(seconds: float, t: float) -> void:
	for pool in _pools():
		var made := 0.0
		var wants := {}
		var cells: Array[Battery] = []
		for device: Device in pool:
			made += device.production_w(t) * seconds / 3600.0
			wants[device] = device.demand_w(t) * seconds / 3600.0
			cells.append_array(device.pooled())
		generated_wh += made
		var running := _running(pool, wants, made, _fraction(cells))
		var wanted := 0.0
		for device: Device in running:
			wanted += wants[device]
		var on := true
		if not running.all(func(d: Device) -> bool: return d.powered) and made < wanted \
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
			var runs := on and running.has(device)
			device.set_powered(runs)
			if runs:
				used_wh -= device.work(seconds, t)
			if device.charge_light != null:
				ChargeLight.paint(device.charge_light, device.charge_share())
		for cell in cells:
			cell.show_charge()


## The devices in a pool that draw this tick, `wants` what each would draw:
## all but the lower ranks that give way to the highest while it runs short.
func _running(pool: Array, wants: Dictionary, made: float, share: float) -> Array:
	var top: int = pool[0].rank
	var all := 0.0
	for device: Device in pool:
		top = maxi(top, device.rank)
		all += wants[device]
	return pool.filter(func(d: Device) -> bool:
		return d.rank >= top or wants[d] <= 0.0 or made >= all \
			or share > RESERVE + (0.0 if d.powered else RESTART))


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


## A device just become yours runs now if its pool can, as the next tick
## would have it, rather than a tick late.
func wake(device: Device) -> void:
	for pool: Array in _pools():
		if not pool.has(device):
			continue
		var made := 0.0
		var wanted := 0.0
		var wants := {}
		var cells: Array[Battery] = []
		for each: Device in pool:
			made += each.production_w()
			wants[each] = each.demand_w()
			wanted += wants[each]
			cells.append_array(each.pooled())
		if made >= wanted or _fraction(cells) >= RESTART:
			for each: Device in _running(pool, wants, made, _fraction(cells)):
				each.set_powered(true)
		return


## What the batteries in a device's pool hold now, Wh: all it could draw on.
func pool_wh(device: Device) -> float:
	for pool: Array in _pools():
		if pool.has(device):
			var held := 0.0
			for each: Device in pool:
				for cell in each.pooled():
					held += cell.charge_wh
			return held
	return 0.0


## Devices grouped by the cables joining them and the devices seated on them;
## an unjoined device is its own pool. A wrecked one is in none: it neither
## makes nor draws, ever again.
func _pools() -> Array:
	var devices: Array[Device] = []
	var cables: Array[Cable] = []
	for device in _world.devices():
		if not device.wrecked():
			devices.append(device)
	for node in _world.content.get_children():
		# A hose carries water, not power.
		if node is Cable and not node is Hose:
			cables.append(node)
	var root := {}
	for device in devices:
		root[device] = device
	var find := func(d: Device, f: Callable) -> Device:
		return d if root[d] == d else f.call(root[d], f)
	var joins: Array = []
	for cable in cables:
		joins.append(cable.joined())
	for device in devices:
		if device.host() != null:
			joins.append([device, device.host()])
	for ends: Array in joins:
		if ends.size() == 2 and root.has(ends[0]) and root.has(ends[1]):
			root[find.call(ends[0], find)] = find.call(ends[1], find)
	var pools := {}
	for device in devices:
		var top: Device = find.call(device, find)
		if not pools.has(top):
			pools[top] = []
		pools[top].append(device)
	return pools.values()
