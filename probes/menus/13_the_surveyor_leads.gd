extends MenuProbe
## Menus & UI probe 13: the Surveyor leads. On a fresh profile New game opens
## on the Surveyor, first and highlighted, its crate on show, and down passes
## over the starts still locked. With every start open it still opens there,
## its word larger than the rest.


func run() -> void:
	await open_main()
	var surveyor := Kit.standard()
	press(&"ui_accept")
	var menu := main.ui.top()
	check(menu.words()[0] == surveyor.label.to_upper() and menu.highlighted() == 0
		and main.showpiece.shown == surveyor.id,
		"a fresh profile's New game opens on the Surveyor, first (%s)" % ", ".join(menu.words()))
	press(&"ui_down")
	check(menu.highlighted() == 0, "down passes over the starts still locked")
	press(&"ui_cancel")
	open_every_start()
	press(&"ui_accept")
	menu = main.ui.top()
	var sizes := []
	for item in menu._items:
		sizes.append(item.button.get_theme_font_size(&"font_size"))
	check(menu.highlighted() == 0 and sizes[0] > sizes.slice(1).max(),
		"with every start open it still opens on the Surveyor, its word the largest (%s)" % [sizes])
