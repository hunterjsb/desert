class_name DeedsGrid
extends GridContainer
## Every deed as a tile, in the table's order (Deeds): its name, what it asks,
## and what it opens, lit once done and dim until then. A hidden one shows
## ???? until it's done.

const COLUMNS := 3
## A tile's width, px, so the columns line up whatever the words.
const TILE := 340.0
## A deed not yet done: its words at this share of a done one's brightness,
## on the same dark tile, so they still read over bright sand.
const UNLIT := 0.55


## The deeds' own menu: how many you've done over the grid, and Back.
static func menu(profile: Node, back: Callable) -> Words:
	var words := Words.new("%d of %d deeds" % [Deeds.count(profile), Deeds.TABLE.size()])
	words.add_body(DeedsGrid.new(profile, Tuning.current()))
	words.add("Back", back)
	return words


func _init(profile: Node, tuning: Tuning) -> void:
	columns = COLUMNS
	theme_type_variation = &"DeedsGrid"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id: StringName in Deeds.TABLE:
		add_child(_tile(id, profile != null and profile.did(id), tuning))


static func _tile(id: StringName, done: bool, tuning: Tuning) -> PanelContainer:
	var shown: bool = done or not Deeds.TABLE[id].get("hidden", false)
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"DeedTile"
	tile.custom_minimum_size.x = TILE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.set_meta(&"deed", id)
	tile.set_meta(&"done", done)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"Column"
	column.modulate = Color.WHITE if done else Color(UNLIT, UNLIT, UNLIT)
	tile.add_child(column)
	var words := [[&"DeedName", Deeds.TABLE[id].name if shown else "????"]]
	if shown:
		words.append([&"DeedLine", Deeds.line(id, tuning)])
		for kit in Deeds.opens(id):
			words.append([&"DeedOpens", "opens the " + kit.label])
	for each: Array in words:
		var label := Label.new()
		label.theme_type_variation = each[0]
		label.text = each[1]
		label.uppercase = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
	return tile
