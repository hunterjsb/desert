extends HandsProbe
## A precise fitted-part hit wins over assistance targeting its carryable host.

func run() -> void:
	await load_hands()
	var radio := spawn_device(&"radio", 2.0, 0.8, false)
	radio.freeze = true
	var battery := fit_part(radio, &"battery")
	var socket := battery.socket
	await physics_frames(3)
	var frame := seat(socket)
	var target := frame * Vector3(0.0, 0.0, 0.05)
	look(target + frame.basis.z * 1.0, target)
	await physics_frames(2)
	hands.grab()
	await simulate(0.5)
	check(hands.held == battery and socket.part == null,
		"taking the visible battery removes it instead of picking up its radio")
