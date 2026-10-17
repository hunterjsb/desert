class_name Water
extends RefCounted
## Water shared over hoses, as power is over cables: devices joined by hoses
## are one network, and a device on no hose is one by itself. Its canisters
## are those in its water sockets, a hose's end's included, and its tanks are
## its planters'. Water coming in, a condenser's, goes to the emptiest tank
## first, then to the fullest canister with room, so one fills for you to take
## away. On the farm's tick the tanks are kept full from the canisters, the
## least full first, so one empties and frees up, as your suit drinks from
## them. Nothing flows from canister to canister. Cheap arithmetic on the
## farm's tick of world time, so the frame rate never changes it.

## A tank gaining this much in a tick, L, is heard filling: a canister just fitted.
const POURS := 0.05


## The devices a device's hoses join it to, and theirs, itself first.
static func network(world: World, device: Device) -> Array[Device]:
	var found: Array[Device] = [device]
	if not device.parts().any(func(p: Part) -> bool: return Hose.is_end(p)):
		return found
	var joins: Array = []
	for node in world.content.get_children():
		var hose := node as Hose
		if hose != null and not hose.joined().is_empty():
			joins.append(hose.joined())
	var i := 0
	while i < found.size():
		for ends: Array in joins:
			for k in 2:
				if ends[k] == found[i] and not found.has(ends[1 - k]):
					found.append(ends[1 - k])
		i += 1
	return found


## The canisters in a network's water sockets.
static func canisters(net: Array[Device]) -> Array[Supply]:
	var found: Array[Supply] = []
	for device in net:
		for socket in device.sockets():
			if socket.kind == &"water" and socket.part is Supply:
				found.append(socket.part)
	return found


## The planters a network waters: a wrecked one grows nothing.
static func tanks(net: Array[Device]) -> Array[Planter]:
	var found: Array[Planter] = []
	for device in net:
		if device is Planter and not device.wrecked():
			found.append(device)
	return found


## How much more a device's network could hold, L.
static func room(world: World, device: Device) -> float:
	var net := network(world, device)
	var free := 0.0
	for tank in tanks(net):
		free += world.tuning.planter_tank_litres - tank.tank_l
	for can in canisters(net):
		free += can.capacity() - can.amount
	return free


## Water into a device's network; returns what didn't fit.
static func give(world: World, device: Device, litres: float) -> float:
	var net := network(world, device)
	var left := _into_tanks(tanks(net), litres, world.tuning.planter_tank_litres)
	for can in _by_amount(canisters(net), false):
		if left <= 0.0:
			break
		left = can.fill(left)
	return left


## The farm's tick: every network's tanks topped up from its canisters.
static func flow(world: World) -> void:
	var full := world.tuning.planter_tank_litres
	var done := {}
	for device in world.devices():
		if not device is Planter or done.has(device):
			continue
		var net := network(world, device)
		for each in net:
			done[each] = true
		var held := tanks(net)
		var wants := 0.0
		for tank in held:
			wants += full - tank.tank_l
		var got := 0.0
		for can in _by_amount(canisters(net), true):
			if got >= wants:
				break
			got += can.drain(wants - got)
		if got <= 0.0:
			continue
		var was := held.map(func(p: Planter) -> float: return p.tank_l)
		_into_tanks(held, got, full)
		for i in held.size():
			if held[i].tank_l - was[i] >= POURS:
				Sounds.play_at(held[i], Sounds.POUR)


## Into tanks, the emptiest first: the lowest raised together to the next,
## until it runs out or all are full. Returns what didn't fit.
static func _into_tanks(held: Array[Planter], litres: float, full: float) -> float:
	if held.is_empty() or litres <= 0.0:
		return litres
	var low := held.duplicate()
	low.sort_custom(func(a: Planter, b: Planter) -> bool: return a.tank_l < b.tank_l)
	var level: float = low[0].tank_l
	var left := litres
	var n := 1
	while true:
		var next: float = minf(low[n].tank_l, full) if n < low.size() else full
		var cost := (next - level) * n
		if cost >= left:
			level += left / n
			left = 0.0
			break
		left -= cost
		level = next
		if n == low.size():
			break
		n += 1
	for i in n:
		low[i].tank_l = clampf(level, low[i].tank_l, full)
	return left


## Canisters by how full they are, the least first or the most, in the order
## they were found among equals.
static func _by_amount(cans: Array[Supply], least: bool) -> Array[Supply]:
	var order := range(cans.size())
	order.sort_custom(func(i: int, j: int) -> bool:
		if cans[i].amount != cans[j].amount:
			return (cans[i].amount < cans[j].amount) == least
		return i < j)
	var out: Array[Supply] = []
	for i: int in order:
		out.append(cans[i])
	return out
