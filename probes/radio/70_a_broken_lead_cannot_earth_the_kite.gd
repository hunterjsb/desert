extends KiteProbe
## Recoverable plugs on a snapped strong cable are not an aerial or earth connection.
func run() -> void:
	await load_storm(0.0, 9.0)
	var rig := await kite_rig(true, true)
	var kite: AntennaKite = rig.kite
	var radio: Radio = rig.radio
	var cable := rig.cable as StrongCable
	radio.on = true
	radio.switch_band()
	var bare := radio.antenna_gain()
	await fly_up(kite)
	check(kite.earthed() and radio.antenna_gain() > bare * 4.0, "the original intact staked lead carries the aerial")
	var plugs := cable.plugs.duplicate()
	world.ropes.snap(cable.rope)
	check(not kite.earthed(), "rupture stops the earth path immediately")
	await physics_frames(2)
	check(cable.rope == null and plugs.all(func(plug: Part) -> bool: return is_instance_valid(plug) and plug.socket != null),
		"real rupture keeps both original fitted plugs recoverable")
	check(kite.find_rig().is_empty() and not kite.earthed() and radio.kite() == null and radio.antenna_gain() == bare,
		"the broken lead supplies neither reception nor an earth path")
