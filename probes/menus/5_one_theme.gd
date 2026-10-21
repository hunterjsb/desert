extends MenuProbe
## Menus & UI probe 5: one theme. Every UI there is, open at once: in a run,
## the bars, the inventory, the look-at readout, the death caption, the
## dev overlay and the dev console, then the system menu with its controls
## reader, Options, the deeds, the creative menu and a question
## over it; at the menu, its words and who you come as.
## Every control draws from the one theme: no theme of its own, no override of
## a colour, font, size or style, a type the theme defines, and a font of the
## theme's. No script in the game reaches past it for a font or a look of its
## own, and keys stand out in a colour that isn't the accent.

const THEME := preload("res://game/ui/theme.tres")
## Ways around the theme, in a script.
const PAST_IT := ["fallback_font", "add_theme_", "Theme.new(", "get_default_theme("]


func run() -> void:
	check(ThemeDB.get_project_theme() == THEME, "the project's theme is the one theme")
	var key := THEME.get_color(&"key", &"Palette")
	check(Controls.KEY_COLOR == key and key != THEME.get_color(&"accent", &"Palette"),
		"keys stand out in the theme's key colour, not the accent")
	await open_main(false)
	press(&"inventory")
	press(&"toggle_dev_overlay")
	press(&"console")
	await physics_frames(5)
	var ui := main.ui
	check(ui.dev_console.visible, "the console is open")
	_look()
	press(&"console")
	ui.open(ui.system_menu())
	press(&"ui_down")
	press(&"ui_accept")
	ui.open(ui.options())
	ui.open(ui.deeds())
	ui.open(ui.creative(world))
	ui.open(ui.confirm("A question", "No", "Yes", func() -> void: pass))
	await get_tree().process_frame
	_look()
	ui.close_all()
	main.save_and_quit()
	await faded_in()
	ui.open(ui.origins())
	ui.open(ui.options())
	await get_tree().process_frame
	_look()
	var kinds := PackedStringArray()
	for kind: String in _kinds:
		kinds.append("%d %s" % [_kinds[kind], kind])
	kinds.sort()
	print("%d controls: %s" % [_seen, ", ".join(kinds)])
	check(_seen > 60, "every UI was open (%d controls)" % _seen)
	check(_stray.is_empty(), "every control draws from the one theme (%s)" % ", ".join(_stray))
	var scripts := _past_it("res://game")
	check(scripts.is_empty(), "no script reaches past it (%s)" % ", ".join(scripts))


var _seen := 0
var _kinds := {}
var _stray := PackedStringArray()


## Every control there is now, and how any strays.
func _look() -> void:
	for control: Control in get_tree().root.find_children("*", "Control", true, false):
		_seen += 1
		_kinds[control.get_class()] = _kinds.get(control.get_class(), 0) + 1
		_stray.append_array(_strays(control))


## How a control strays from the theme, if it does.
func _strays(control: Control) -> PackedStringArray:
	var out := PackedStringArray()
	var what := "%s %s" % [control.get_class(), control.name]
	if control.theme != null and control.theme != THEME:
		out.append(what + " has a theme of its own")
	if control.theme_type_variation != &"" and not THEME.get_type_list().has(control.theme_type_variation):
		out.append("%s is a %s the theme doesn't define" % [what, control.theme_type_variation])
	var engine := ThemeDB.get_default_theme()
	var type := control.get_class()
	while type != "" and type != "CanvasItem":
		for name in engine.get_color_list(type):
			if control.has_theme_color_override(name):
				out.append("%s overrides %s" % [what, name])
		for name in engine.get_constant_list(type):
			if control.has_theme_constant_override(name):
				out.append("%s overrides %s" % [what, name])
		for name in engine.get_font_list(type):
			if control.has_theme_font_override(name):
				out.append("%s overrides %s" % [what, name])
		for name in engine.get_font_size_list(type):
			if control.has_theme_font_size_override(name):
				out.append("%s overrides %s" % [what, name])
		for name in engine.get_stylebox_list(type):
			if control.has_theme_stylebox_override(name):
				out.append("%s overrides %s" % [what, name])
		type = ClassDB.get_parent_class(type)
	var font_name := &"normal_font" if control is RichTextLabel else &"font"
	if (control is Label or control is Button or control is RichTextLabel) \
			and not _fonts().has(control.get_theme_font(font_name)):
		out.append(what + " draws in a font the theme doesn't have")
	return out


func _fonts() -> Array:
	var out := [THEME.default_font]
	for type in THEME.get_font_type_list():
		for name in THEME.get_font_list(type):
			out.append(THEME.get_font(name, type))
	return out


## Game scripts that draw in a font or a look the theme doesn't give them.
func _past_it(folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(folder.path_join(file))
			for way: String in PAST_IT:
				if way in text:
					out.append("%s uses %s" % [file, way])
	for sub in DirAccess.get_directories_at(folder):
		out.append_array(_past_it(folder.path_join(sub)))
	return out
