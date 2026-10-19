class_name Power
extends Node
## Power, as cheap arithmetic on a fixed tick of world time, so the frame rate
## never changes a charge and F5 speeds charging like everything else. Devices
## joined by cables share one pool: what they make feeds what they draw, then
## fills their batteries; a pool that can't meet its draw goes dark. A device
## on a deck, like a shield stuck on one, shares its pool. Running short, a
## pool's lower-ranked devices give way first, like a deck's tray to the
## shield on it, or a board on it charging. A power box in a pool may let a
## Console rank who's served and switch draws off; a bay held to charge only
## takes. A ledger proves no energy appears from nowhere. A pool making more
## than the tuning's deed asks is a deed.

## A dark pool waits until its batteries hold this share before it tries again.
const RESTART := 0.05
## A device ranked below the highest in its pool stops drawing once the pool's
## batteries are down to this share, kept for the higher ones, unless the
## sources alone carry it and everything above it; it runs again once they
## hold RESTART more. Between the lowest and the highest, each rank gives way
## at its own share of it, so the last served goes first.
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


## One tick lived by a sleep, which steps the clock itself (Sleep): the same
## sums, and the next tick waits for the clock to pass this one.
func live(seconds: float, t: float) -> void:
	_tick(seconds, t)
	_next = t + seconds


## Everything stored right now, Wh, in batteries fitted or loose.
func stored_wh() -> float:
	var total := 0.0
	for node in _world.content.get_children():
		if node is Battery:
			total += node.charge_wh
	for device in _devices():
		for cell in device.batteries():
			total += cell.charge_wh
	return total


## Everything that makes or draws power: your devices in the world, and the
## ones you carry, working on you.
func _devices() -> Array[Device]:
	var all := _world.devices()
	all.append_array(_world.player.suit.devices())
	return all


## One tick, with every source reading the weather at the tick's own time,
## however many ticks a frame holds. Every battery in a pool takes a share of
## what's spare; only those that supply give.
func _tick(seconds: float, t: float) -> void:
	for pool in _pools():
		var made := 0.0
		var wants := {}
		var cells: Array[Battery] = []
		var givers: Array[Battery] = []
		for device: Device in pool:
			made += device.production_w(t) * seconds / 3600.0
			wants[device] = device.demand_w(t) * seconds / 3600.0
			cells.append_array(device.pooled())
			givers.append_array(device.supplies())
		generated_wh += made
		if _world.counts_deeds:
			Deeds.measure(_world, &"power", made * 3600.0 / seconds)
		var before := PackedFloat64Array()
		for cell in cells:
			before.append(cell.charge_wh)
		var share := _fraction(givers)
		var running := _running(pool, wants, made, share)
		var wanted := 0.0
		for device: Device in running:
			wanted += wants[device]
		var on := true
		if not running.all(func(d: Device) -> bool: return d.powered) and made < wanted \
				and share < RESTART:
			# Dark stays dark, with nothing running, until there's enough to restart:
			# everything made goes into the batteries meanwhile.
			spilled_wh += _share(made, cells, true)
			on = false
		elif made >= wanted:
			used_wh += wanted
			spilled_wh += _share(made - wanted, cells, true)
		else:
			var short := wanted - made
			var given := _share(short, givers, false)
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
		for i in cells.size():
			cells[i].flow_w = (cells[i].charge_wh - before[i]) * 3600.0 / seconds
			cells[i].show_charge()
		for device: Device in pool:
			device.show_charge()


## The devices in a pool that draw this tick, `wants` what each would draw:
## all but those switched off, and the lower ranks giving way to the higher
## while it runs short.
func _running(pool: Array, wants: Dictionary, made: float, share: float) -> Array:
	var ranks := _ranks(pool)
	var levels := _levels(ranks)
	# What each rank and every rank over it would draw.
	var over := {}
	for level: int in levels:
		over[level] = 0.0
		for device: Device in ranks:
			if ranks[device] >= level:
				over[level] += wants[device]
	return pool.filter(func(d: Device) -> bool:
		if not ranks.has(d):
			return false
		var level: int = ranks[d]
		return level == levels[0] or wants[d] <= 0.0 or made >= over[level] \
			or share > _gives_way(levels, level) + (0.0 if d.powered else RESTART))


## What a pool's power boxes let a Console do: rank who's served first, and
## switch draws off. Nothing without a box.
func control(pool: Array) -> Dictionary:
	var can := {"ranks": false, "switches": false}
	for device: Device in pool:
		var box := device as PowerBox
		if box != null and not box.wrecked():
			can.ranks = can.ranks or box.model().get("ranks", false)
			can.switches = can.switches or box.model().get("switches", false)
	return can


## Each device in a pool that isn't switched off, by its rank there.
func _ranks(pool: Array) -> Dictionary:
	var can := control(pool)
	var ranks := {}
	for device: Device in pool:
		if not (can.switches and device.switched_off):
			ranks[device] = rank_in(device, can)
	return ranks


## A device's rank as its pool's boxes allow: its own, or its kind's.
static func rank_in(device: Device, can: Dictionary) -> int:
	return device.priority if can.ranks and device.priority >= 0 else device.rank


## The ranks present, highest first.
static func _levels(ranks: Dictionary) -> Array[int]:
	var levels: Array[int] = []
	for device: Device in ranks:
		if not levels.has(ranks[device]):
			levels.append(ranks[device])
	levels.sort()
	levels.reverse()
	return levels


## The share of its pool's charge a rank gives way at: none for the highest,
## the reserve for the lowest, evenly between.
static func _gives_way(levels: Array[int], level: int) -> float:
	var at := levels.find(level)
	return RESERVE * at / (levels.size() - 1) if at > 0 else 0.0


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
		var givers: Array[Battery] = []
		for each: Device in pool:
			made += each.production_w()
			wants[each] = each.demand_w()
			wanted += wants[each]
			givers.append_array(each.supplies())
		if made >= wanted or _fraction(givers) >= RESTART:
			for each: Device in _running(pool, wants, made, _fraction(givers)):
				each.set_powered(true)
		return


## What the batteries in a device's pool can give now, Wh: all it could draw on.
func pool_wh(device: Device) -> float:
	var held := 0.0
	for each: Device in pool_of(device):
		for cell in each.supplies():
			held += cell.charge_wh
	return held


## How full the batteries its pool draws on are together, 0 to 1; NAN with none.
func pool_share(device: Device) -> float:
	var cells: Array[Battery] = []
	for each: Device in pool_of(device):
		cells.append_array(each.supplies())
	return _fraction(cells) if not cells.is_empty() else NAN


## The share of its pool's charge a device gives way at as the pool runs
## short: its rank's part of the reserve kept for those above it, else none.
func gives_way_at(device: Device) -> float:
	var ranks := _ranks(pool_of(device))
	return _gives_way(_levels(ranks), ranks[device]) if ranks.has(device) else 0.0


## The devices sharing a device's pool; none for a wrecked one.
func pool_of(device: Device) -> Array:
	for pool: Array in _pools():
		if pool.has(device):
			return pool
	return []


## Devices grouped by the cables joining them and the devices seated on them;
## an unjoined device is its own pool. A wrecked one is in none: it neither
## makes nor draws, ever again.
func _pools() -> Array:
	var devices: Array[Device] = []
	var cables: Array[Cable] = []
	for device in _devices():
		if not device.wrecked():
			devices.append(device)
	for node in _world.content.get_children():
		# A hose carries water, not power.
		if node is Cable and not node is Hose:
			cables.append(node)
	var root := {}
	for device in devices:
		root[device] = device
	var joins: Array = []
	for cable in cables:
		joins.append(cable.joined())
	for device in devices:
		if device.host() != null:
			joins.append([device, device.host()])
	for ends: Array in joins:
		if ends.size() == 2 and root.has(ends[0]) and root.has(ends[1]):
			root[_root_of(root, ends[0])] = _root_of(root, ends[1])
	var pools := {}
	for device in devices:
		var top := _root_of(root, device)
		if not pools.has(top):
			pools[top] = []
		pools[top].append(device)
	return pools.values()


## Where a device's chain of joins ends: its pool's first.
static func _root_of(root: Dictionary, device: Device) -> Device:
	while root[device] != device:
		device = root[device]
	return device
