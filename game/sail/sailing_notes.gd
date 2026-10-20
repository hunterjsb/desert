class_name SailingNotes
extends Device
## A field booklet you can keep beside the rig and reopen between attempts.
## Reading uses the normal menus, so controls and back behave as elsewhere.

const PAGES := [
	["Read the wind", "The streamer points downwind. Start across the wind, with the rig ahead.", "res://assets/tutorial/sailing/wind.png"],
	["Work the sheet", "{reel_in} hauls; {pay_out} eases. Wind swings the sail. A tighter sheet is not always faster.", "res://assets/tutorial/sailing/sheet.png"],
	["Carve an edge", "{move_left}/{move_right} carve; {move_back} digs the edge. Steer across the pull for grip.", "res://assets/tutorial/sailing/board.png"],
	["Choose the line", "One line works automatically. Choose among several in {inventory}. Hold an end and {interact} at a fitted hook to redirect it.", "res://assets/tutorial/sailing/hook.png"],
]


func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	return _read()


func use(_by: Player, _at: Vector3) -> bool:
	return _read()


func _read() -> bool:
	if Controls.ui == null:
		return false
	Controls.ui.open(chapters())
	return true


func book_title() -> String:
	return "Sailing field notes"


func pages() -> Array:
	return PAGES


func chapters() -> Words:
	var leaves := pages()
	var menu := Words.new(book_title())
	for i in leaves.size():
		menu.add(leaves[i][0], func() -> void: Controls.ui.open(page(i)))
	menu.add("Close", Controls.ui.close_top)
	return menu


func page(at: int, paragraph := 0) -> Words:
	var leaves := pages()
	if leaves[at].size() > 2:
		return _visual_page(at)
	var parts: PackedStringArray = leaves[at][1].split("\n\n", false)
	var menu := Words.new("%s · %d / %d" % [leaves[at][0], paragraph + 1, parts.size()])
	var body := Controls.keys_label()
	body.theme_type_variation = &"KeysList"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = minf(820.0, get_viewport().get_visible_rect().size.x - 100.0)
	body.text = Controls.bbcode(parts[paragraph])
	menu.add_body(body)
	if paragraph + 1 < parts.size():
		menu.add("Next", _turn_page.bind(at, paragraph + 1))
	elif at + 1 < leaves.size():
		menu.add("Next chapter", _turn_page.bind(at + 1, 0))
	if paragraph > 0:
		menu.add("Previous", _turn_page.bind(at, paragraph - 1))
	elif at > 0:
		var previous: PackedStringArray = leaves[at - 1][1].split("\n\n", false)
		menu.add("Previous chapter", _turn_page.bind(at - 1, previous.size() - 1))
	menu.add("Chapters", Controls.ui.close_top)
	return menu


## Visual leaves share the normal menu actions; prose-only books retain their layout.
func _visual_page(at: int) -> Words:
	var leaves := pages()
	var menu := Words.new("%s · %d / %d" % [leaves[at][0], at + 1, leaves.size()])
	menu._list.add_theme_constant_override("separation", 8)
	var image := TextureRect.new()
	image.texture = load(leaves[at][2])
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tall := minf(300.0, get_viewport().get_visible_rect().size.y * 0.42)
	image.custom_minimum_size = Vector2(tall * 16.0 / 9.0, tall)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_body(image)
	var caption := Controls.keys_label()
	caption.theme_type_variation = &"KeysList"
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size.x = minf(680.0, get_viewport().get_visible_rect().size.x - 180.0)
	caption.text = "[center]" + Controls.bbcode(leaves[at][1]) + "[/center]"
	menu.add_body(caption)
	if at + 1 < leaves.size():
		menu.add("Next", _turn_page.bind(at + 1, 0))
	if at > 0:
		menu.add("Previous", _turn_page.bind(at - 1, 0))
	menu.add("Chapters", Controls.ui.close_top)
	return menu


func _turn_page(at: int, paragraph: int) -> void:
	Controls.ui.close_top()
	Controls.ui.open(page(at, paragraph))
