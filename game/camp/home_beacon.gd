class_name HomeBeacon
extends Device
## An ordinary chassis-mounted transmitter identifies one Home, without protecting it.
## Its lamp says what Home is doing: dark unmarked or unpowered, blinking while
## Home's ground is being made ready, steady once it is, with a pulse when it gets there.

var _shown := -1.0
var _was_ready := false

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
	by.hands.say("home unmarked" if removing else "home marked")
	Sounds.play_at(self, Sounds.BOARD_OFF if removing else Sounds.BOARD_ON)
	return true

func use(by: Player, _at: Vector3) -> bool:
	return by.hands.refuse("mount the beacon on a chassis first")

func _physics_process(delta: float) -> void:
	super(delta)
	if frame_view == null or world == null or world.home == null:
		return
	var home := world.home
	var serving := home.beacon == self and is_instance_valid(home.root) and powered and not wrecked() \
		and home.deck_of(self) == home.root
	var ready := serving and home.supported
	if ready and not _was_ready:
		Sounds.play_at(self, Sounds.RECEIVER_PULSE)
	_was_ready = ready
	var blink := fposmod(world.time, world.tuning.home_beacon_blink_s) < world.tuning.home_beacon_blink_s * 0.5
	var lit := 1.0 if ready or (serving and blink) else 0.0
	if lit != _shown:
		_shown = lit
		frame_view.set_instance_shader_parameter(&"lit", lit)
