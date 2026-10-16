extends MenuProbe
## Menus & UI probe 2: back closes the topmost first. In a run with the
## inventory open, back closes it and nothing else; pressed again, it opens
## the system menu and frees the mouse; again, it closes that and captures the
## mouse to look. A menu over a menu closes first, and nothing pressed while a
## menu is up reaches the game behind it.


func run() -> void:
	await open_main(false)
	var suit := world.player.suit
	press(&"inventory")
	check(suit.open and Controls.mouse_free, "the inventory is open")
	press(&"ui_cancel")
	check(not suit.open and not main.ui.is_open() and not Controls.mouse_free,
		"back closes the inventory, and nothing else opens")
	press(&"ui_cancel")
	var system := main.ui.top()
	check(system != null and Controls.mouse_free, "back again opens the system menu (%s)"
		% (", ".join(system.words()) if system != null else "-"))
	press(&"inventory")
	press(&"hands_grab")
	check(not suit.open and world.player.hands.held == null, "nothing pressed under a menu reaches the game")
	press(&"ui_accept")
	check(main.ui.top() != system, "confirm on Options opens them over it")
	press(&"ui_cancel")
	check(main.ui.top() == system and system.highlighted() == 0, "back closes Options first, back to where you were")
	press(&"ui_cancel")
	check(not main.ui.is_open() and not Controls.mouse_free, "back again closes the system menu and captures the mouse")
