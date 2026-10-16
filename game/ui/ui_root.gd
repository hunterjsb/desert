class_name UIRoot
extends CanvasLayer
## The one root of the menus, owning focus and the back action. Back closes
## the topmost thing open, a menu or else a panel of the game's (the
## inventory), and in a run with nothing open brings up the system menu.
## Nothing here pauses: the menus only draw over a world that keeps running.

## Gameplay panels that back closes join this group and answer close(),
## saying whether they had anything open to close.
const PANELS := &"ui_panels"
## The screen takes this long to go black, or to come back, s.
const FADE_SECONDS := 0.5

var main: Main
## Open menus, the topmost last.
var _menus: Array[Words] = []
var _fade: Panel
var _fading := false


func _enter_tree() -> void:
	Controls.ui = self


func _exit_tree() -> void:
	if Controls.ui == self:
		Controls.ui = null


func _ready() -> void:
	layer = 110
	Settings.load_saved()
	Settings.apply(get_window())
	_fade = Panel.new()
	_fade.theme_type_variation = &"Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func is_open() -> bool:
	return not _menus.is_empty()


## Nothing you hold down acts in the game meanwhile: the move keys polled
## each tick never come as events this could stop.
func holds_input() -> bool:
	return is_open() or _fading


func top() -> Words:
	return null if _menus.is_empty() else _menus.back()


## Opens a menu over whatever is open, with its first word highlighted.
func open(menu: Words) -> void:
	if not _menus.is_empty():
		_menus.back().cover()
	_menus.append(menu)
	add_child(menu)
	move_child(menu, _fade.get_index())
	menu.highlight()
	Controls.free_mouse(true)


## Closes the topmost menu; the last one closed in a run hands the mouse back to look.
func close_top() -> void:
	if _menus.is_empty():
		return
	var menu: Words = _menus.pop_back()
	remove_child(menu)
	menu.queue_free()
	if not _menus.is_empty():
		_menus.back().uncover()
	elif main != null and main.in_run():
		Controls.free_mouse(false)


func close_all() -> void:
	while not _menus.is_empty():
		var menu: Words = _menus.pop_back()
		remove_child(menu)
		menu.queue_free()


func back() -> void:
	if not _menus.is_empty():
		if not top().root:
			close_top()
		return
	for panel in get_tree().get_nodes_in_group(PANELS):
		if panel.close():
			return
	if main != null and main.in_run():
		open(system_menu())


## To black, or back from it; input waits meanwhile.
func fade(to_black: bool) -> void:
	_fading = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := _fade.create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, FADE_SECONDS)
	await tween.finished
	_fading = to_black
	if not to_black:
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Nothing gets through while the screen fades, not even to a menu's words.
func _input(_event: InputEvent) -> void:
	if _fading:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
	elif is_open() and not event is InputEventMouseMotion:
		# A menu is up: nothing reaches the game behind it.
		get_viewport().set_input_as_handled()


## Resume (with a save), New game, Options, Quit, over the live desert.
func show_main_menu(note := "") -> void:
	close_all()
	Dev.show_hint(false)
	if note == "" and main.save_refused() != "":
		note = "Your saved run can't be resumed: " + main.save_refused()
	var menu := Words.new(note, &"Shade")
	menu.root = true
	if main.has_save():
		menu.add("Resume", main.resume)
	menu.add("New game", _new_game)
	menu.add("Options", func() -> void: open(options()))
	menu.add("Quit", main.quit)
	open(menu)


## Options and Save & quit, over the running game.
func system_menu() -> Words:
	var menu := Words.new("")
	menu.add("Options", func() -> void: open(options()))
	menu.add("Save & quit" if main.saves() != null else "Quit to menu", main.save_and_quit)
	return menu


func options() -> Words:
	var menu := Words.new("Options")
	menu.add(func() -> String: return "Volume   %d%%" % roundi(Settings.volume * 100.0),
		_change.bind(1, &"volume", true), _change.bind(&"volume", false))
	menu.add(func() -> String: return "Fullscreen   %s" % _on(Settings.fullscreen),
		_change.bind(1, &"fullscreen", true), _change.bind(&"fullscreen", false))
	menu.add(func() -> String: return "Vsync   %s" % _on(Settings.vsync),
		_change.bind(1, &"vsync", true), _change.bind(&"vsync", false))
	menu.add(func() -> String: return "Render scale   %d%%" % roundi(Settings.render_scale * 100.0),
		_change.bind(1, &"render_scale", true), _change.bind(&"render_scale", false))
	menu.add("Controls", func() -> void: open(controls()))
	if main.profile() != null:
		menu.add("Reset profile", func() -> void:
			open(confirm("This forgets everything you've found", "Keep it", "Reset", main.reset_profile)))
	menu.add("Back", close_top)
	return menu


## Every key as it's bound now, to read; remapping comes later.
func controls() -> Words:
	var menu := Words.new("Controls")
	var list := Controls.keys_label()
	var lines := PackedStringArray()
	for pair: Array in Controls.HELP:
		lines.append("%s  %s" % [Controls.bbcode(pair[0]), Controls.bbcode(pair[1])])
	list.text = "\n".join(lines)
	var panel := PanelContainer.new()
	panel.add_child(list)
	menu.add_body(panel)
	menu.add("Back", close_top)
	return menu


## A question with the safe answer highlighted; back also declines.
func confirm(question: String, no: String, yes: String, act: Callable) -> Words:
	var menu := Words.new(question)
	menu.add(no, close_top)
	menu.add(yes, func() -> void:
		close_top()
		act.call())
	return menu


func _new_game() -> void:
	if main.has_save():
		open(confirm("This ends your saved run", "Keep it", "New game", main.new_game))
	else:
		main.new_game()


## Confirm steps a setting on, round from the last value to the first; left
## and right step it either way and stop at the ends.
func _change(by: int, what: StringName, wrap: bool) -> void:
	match what:
		&"volume":
			var to := snappedf(Settings.volume + by * 0.1, 0.1)
			Settings.volume = (0.0 if to > 1.0 else to) if wrap else clampf(to, 0.0, 1.0)
		&"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		&"vsync":
			Settings.vsync = not Settings.vsync
		&"render_scale":
			var at := Settings.SCALES.find(Settings.render_scale) + by
			Settings.render_scale = Settings.SCALES[posmod(at, Settings.SCALES.size()) if wrap
				else clampi(at, 0, Settings.SCALES.size() - 1)]
	Settings.apply(get_window())
	Settings.save()


static func _on(on: bool) -> String:
	return "on" if on else "off"
