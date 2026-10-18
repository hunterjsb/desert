class_name UIRoot
extends CanvasLayer
## The one root of the menus, owning focus and the back action. Back closes
## the topmost thing open, a menu or else a panel of the game's (the
## inventory), and in a run with nothing open brings up the system menu.
## The dev console is topmost of all while it's open. Nothing here pauses:
## the menus only draw over a world that keeps running.

## Gameplay panels that back closes join this group and answer close(),
## saying whether they had anything open to close.
const PANELS := &"ui_panels"
## The screen takes this long to go black, or to come back, s.
const FADE_SECONDS := 0.5
## A note such as Saved stays this long before it fades, s.
const NOTE_SECONDS := 1.5
## A how-to stays long enough to read, s.
const HOW_TO_SECONDS := 9.0
## The game's name, as the main menu's title shows it: a rename is this line.
const TITLE := "Desert"

var main: Main
var dev_console: DevConsole
## Open menus, the topmost last.
var _menus: Array[Words] = []
var _fade: Panel
var _fading := false
var _note: Label
var _note_fading: Tween
var _how_to: RichTextLabel
var _how_to_fading: Tween


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
	_note = Label.new()
	_note.theme_type_variation = &"MenuNote"
	_note.uppercase = true
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_note.offset_left = -300.0
	_note.offset_right = 300.0
	_note.offset_top = 72.0
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.modulate.a = 0.0
	add_child(_note)
	_how_to = Controls.keys_label()
	_how_to.theme_type_variation = &"Hint"
	_how_to.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 100)
	_how_to.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_how_to.modulate.a = 0.0
	add_child(_how_to)
	dev_console = DevConsole.new()
	dev_console.ui = self
	add_child(dev_console)
	add_child(_fade)


func is_open() -> bool:
	return not _menus.is_empty()


## Nothing you hold down acts in the game meanwhile: the move keys polled
## each tick never come as events this could stop.
func holds_input() -> bool:
	return is_open() or _fading or dev_console.visible


## A word on how something went, such as a quick save, that fades by itself.
func note(text: String) -> void:
	_note.text = text
	_note_fading = _shown_for(_note, _note_fading, NOTE_SECONDS)


## A how-to, the first time this profile meets what it's about and never
## again: what the controls do, each {action} as its key. Says whether it showed.
func teach(id: String, text: String) -> bool:
	var profile := get_node_or_null(^"/root/Profile")
	if profile == null or not profile.learn(id):
		return false
	_how_to.text = "[center]%s[/center]" % Controls.bbcode(text)
	_how_to_fading = _shown_for(_how_to, _how_to_fading, HOW_TO_SECONDS)
	return true


## Shows a word at once and fades it after `seconds`, over any fade under way.
func _shown_for(words: Control, fading: Tween, seconds: float) -> Tween:
	words.modulate.a = 1.0
	if fading != null:
		fading.kill()
	var tween := words.create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(words, "modulate:a", 0.0, FADE_SECONDS)
	return tween


## The console over a run with nothing else open, or over the main menu
## alone for what needs no world: typing goes to it, over every menu.
func open_dev_console() -> void:
	if main == null or (is_open() if main.in_run() else not (_menus.size() == 1 and top().root)):
		return
	move_child(dev_console, -1)
	move_child(_fade, -1)
	dev_console.open()
	Controls.free_mouse(true)


## Back to the run, or to the menu it was opened over.
func close_dev_console() -> void:
	dev_console.close()
	if is_open():
		top().highlight()
	elif main != null and main.in_run():
		Controls.free_mouse(false)


func is_fading() -> bool:
	return _fading


func top() -> Words:
	return null if _menus.is_empty() else _menus.back()


## Opens a menu over whatever is open, with its first word highlighted.
func open(menu: Words) -> void:
	dev_console.close()
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


## Everything open, the console too: the run is changing over, or is over.
func close_all() -> void:
	dev_console.close()
	while not _menus.is_empty():
		var menu: Words = _menus.pop_back()
		remove_child(menu)
		menu.queue_free()


func back() -> void:
	if dev_console.visible:
		close_dev_console()
		return
	if not _menus.is_empty():
		if not top().root:
			Sounds.play(get_tree().root, Sounds.MENU_BACK, Sounds.UI)
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
## The console closes before its line would take the key that closes it.
func _input(event: InputEvent) -> void:
	if _fading:
		get_viewport().set_input_as_handled()
	elif dev_console.visible and (event.is_action_pressed(&"console") or event.is_action_pressed(&"ui_cancel")):
		back()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"console") and not dev_console.visible:
		open_dev_console()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"fullscreen"):
		# The same switch as Options', so either shows how it stands.
		_change(0, &"fullscreen", false)
		get_viewport().set_input_as_handled()
	elif (is_open() or dev_console.visible) and not event is InputEventMouseMotion:
		# A menu or the console is up: nothing reaches the game behind it.
		get_viewport().set_input_as_handled()


## The title, and Resume (with a save), New game, Options, Quit, over the live desert.
func show_main_menu(note := "") -> void:
	close_all()
	Dev.show_hint(false)
	if note == "" and main.save_refused() != "":
		note = "Your saved run can't be resumed: " + main.save_refused()
	var menu := Words.new(note, &"Shade")
	menu.root = true
	menu.add_title(TITLE)
	if main.has_save():
		menu.add("Resume", main.resume)
	menu.add("New game", _new_game)
	menu.add("Options", func() -> void: open(options()))
	menu.add("Quit", main.quit)
	open(menu)


## Options, Save in a Normal run, and Save & quit, over the running game.
## Save says how it went in its own word.
func system_menu() -> Words:
	var menu := Words.new("")
	menu.add("Options", func() -> void: open(options()))
	if main.saves() != null and not main.ironman():
		var said := ["Save"]
		menu.add(func() -> String: return said[0], func() -> void:
			said[0] = "Saved" if main.save_run() else "Couldn't save")
	menu.add("Save & quit" if main.saves() != null else "Quit to menu", main.save_and_quit)
	return menu


## Who the new run comes as, down the left, the origin last played
## highlighted, so the kit on show stays as it stands aside; each with a few
## words under it, and one still locked shown as ????. The kit on show then
## follows the highlight.
func origins() -> Words:
	var menu := Words.new("", &"ShadeSide")
	var all := Kit.origins()
	menu.open_on(all.find(main.last_kit()))
	for kit in all:
		if kit.is_open_to(main.profile()):
			menu.add(kit.label, func() -> void: open(modes(kit)), Callable(), kit.about)
		else:
			menu.add("????", Callable())
	menu.moved.connect(func(at: int) -> void:
		if main.showpiece != null:
			main.showpiece.picked = all[at])
	return menu


## Which rules the new run plays by, for good, laid out as the origins are:
## Normal highlighted. An origin the game isn't balanced round has no Ironman.
func modes(kit: Kit) -> Words:
	var menu := Words.new("", &"ShadeSide")
	menu.add("Normal", main.new_game.bind(false, false, kit), Callable(), "saves as you go")
	if kit.balanced:
		menu.add("Ironman", main.new_game.bind(true, false, kit), Callable(), "death ends the run")
	return menu


## After a death in a Normal run: the last save back, highlighted, or a new
## run on a new seed. Back doesn't wave it away.
func show_death() -> void:
	close_all()
	for panel in get_tree().get_nodes_in_group(PANELS):
		panel.close()
	var menu := Words.new("You died")
	menu.root = true
	if main.has_save():
		menu.add("Load last save", main.resume)
	menu.add("New run", main.new_game.bind(false, true))
	open(menu)


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
	list.text = Controls.help()
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
		open(confirm("This ends your saved run", "Keep it", "New game", func() -> void: open(origins())))
	else:
		open(origins())


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
