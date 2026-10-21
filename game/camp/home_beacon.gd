class_name HomeBeacon
extends Device
## An ordinary chassis-mounted transmitter identifies one Home, without protecting it.

func demand_w(t := NAN) -> float:
	return super(t) + (world.tuning.home_beacon_w if world != null and not wrecked() and host() != null else 0.0)

func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	var home := world.home
	var removing := home.has_home() and home.beacon == self
	var why := home.unmark() if removing else home.mark(self)
	if why != "":
		return by.hands.refuse(why)
	by.hands.say("home unmarked" if removing else "home marked · preparing support")
	Sounds.play_at(self, Sounds.BOARD_OFF if removing else Sounds.BOARD_ON)
	return true

func use(by: Player, _at: Vector3) -> bool:
	return by.hands.refuse("mount the beacon on a chassis first")

func readout() -> Dictionary:
	var result := {}
	if world != null and world.home != null and world.home.beacon == self:
		result["home"] = world.home.nav().status
	return result

func _physics_process(delta: float) -> void:
	super(delta)
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"lit", 1.0 if world != null and world.home != null \
			and world.home.beacon == self and powered and not wrecked() else 0.0)
