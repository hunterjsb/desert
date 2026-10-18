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


## The title, and Resume (with a save), New game, Deeds, Options, Quit, over
## the live desert, and the music's switch in the bottom left.
func show_main_menu(note := "") -> void:
	close_all()
	Dev.show_hint(false)
	if note == "" and main.save_refused() != "":
		note = "Your saved run can't be resumed: " + main.save_refused()
	var menu := Words.new(note, &"Shade")
	menu.root = true
	menu.add_title(TITLE)
	if main.has_save():
		menu.add("Resume", func() -> void: open(resume_view()))
	menu.add("New game", _new_game)
	menu.add("Deeds", _deeds)
	menu.add("Options", func() -> void: open(options()))
	menu.add("Quit", main.quit)
	menu.add_corner(func() -> bool: return Settings.music, func() -> void:
		Settings.music = not Settings.music
		Settings.save())
	open(menu)


## A menu laid out for where it opens: over the menu's desert down the left,
## the prop aside; over a run in the middle, on the scrim.
func _menu(note := "") -> Words:
	return Words.new(note, &"Scrim" if main == null or main.in_run() else &"ShadeSide")


## Resume shows your last camp aside as the save holds it, the save's
## numbers under it and how many deeds show done; confirm carries on.
func resume_view() -> Words:
	var store := main.saves()
	var data: Dictionary = store.held()
	var menu := _menu()
	menu.add("Continue", main.resume)
	menu.set_aside(numbers(Snapshot.summary(data), store.saved_at())
		+ [["Deeds", "%d of %d" % [Deeds.count(main.profile()), Deeds.TABLE.size()]]])
	if main.showpiece != null:
		main.showpiece.show_camp(data)
		menu.shows = Showpiece.CAMP
	return menu


## A save's numbers as Resume lists them; one from before time played was
## kept lists the rest.
static func numbers(save: Dictionary, saved: int) -> Array:
	var rows := []
	if not is_nan(save.played):
		var minutes := floori(save.played / 60.0)
		rows.append(["Played", "%d min" % minutes if minutes < 60
			else "%d h %d min" % [floori(minutes / 60.0), minutes % 60]])
	rows.append(["Saved", when(saved, floori(Time.get_unix_time_from_system()))])
	rows.append(["Day", str(save.day)])
	var kit := Kit.named(save.kit)
	rows.append(["Came as", (kit if kit != null else Kit.standard()).label])
	return rows


## When, by the clock on the wall where you are: today or yesterday and the
## time, else how many days ago.
static func when(unix: int, now: int) -> String:
	var bias := int(Time.get_time_zone_from_system().bias) * 60
	var days := floori((now + bias) / 86400.0) - floori((unix + bias) / 86400.0)
	var at := Time.get_datetime_dict_from_unix_time(unix + bias)
	if days >= 2:
		return "%d days ago" % days
	return "%s %02d:%02d" % ["yesterday" if days == 1 else "today", at.hour, at.minute]


## A kit's gear as the list under the prop shows it.
static func gear(kit: Kit) -> Array:
	var rows := []
	var all := kit.gear()
	for id in all:
		rows.append(["%d m line" % roundi(kit.rope_m) if id == &"line" else Catalog.short_label(id), str(all[id])])
	return rows


## Options, Deeds, Save in a Normal run, and Save & quit, over the running game.
## Save says how it went in its own word.
func system_menu() -> Words:
	var menu := Words.new("")
	menu.add("Options", func() -> void: open(options()))
	menu.add("Deeds", _deeds)
	if main.saves() != null and not main.ironman():
		var said := ["Save"]
		menu.add(func() -> String: return said[0], func() -> void:
			said[0] = "Saved" if main.save_run() else "Couldn't save")
	menu.add("Save & quit" if main.saves() != null else "Quit to menu", main.save_and_quit)
	return menu


## Who the new run comes as, down the left, the origin last played
## highlighted, so the piece on show stays as it stands aside; each with a
## few words under it, and one still locked shown as ????. The piece aside
## and the gear under it follow the highlight.
func origins() -> Words:
	var menu := _menu()
	var all := Kit.origins()
	menu.open_on(all.find(main.last_kit()))
	for kit in all:
		# The Surveyor is the game as meant; the starts deeds open are variations on it.
		if kit != all[0]:
			menu.set_apart()
		if kit.is_open_to(main.profile()):
			menu.add(kit.label, func() -> void: open(modes(kit)), Callable(), kit.about)
		else:
			menu.add("????", Callable())
	menu.moved.connect(func(at: int) -> void:
		menu.shows = all[at].id
		menu.set_aside(gear(all[at])))
	return menu


## Which rules the new run plays by, for good, laid out as the origins are:
## Normal highlighted. An origin the game isn't balanced round has no Ironman.
func modes(kit: Kit) -> Words:
	var menu := _menu()
	menu.shows = kit.id
	menu.set_aside(gear(kit))
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
	var menu := _menu("Options")
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


## Every key as it's bound now, beside what it does, as the keys list shows
## them; remapping comes later.
func controls() -> Words:
	var menu := _menu("Controls")
	var list := Controls.keys_label()
	list.theme_type_variation = &"KeysList"
	list.text = Controls.help()
	menu.add_body(list)
	menu.add("Back", close_top)
	return menu


## A question with the safe answer highlighted; back also declines.
func confirm(question: String, no: String, yes: String, act: Callable) -> Words:
	var menu := _menu(question)
	menu.add(no, close_top)
	menu.add(yes, func() -> void:
		close_top()
		act.call())
	return menu


## Every deed in its tree, under how many show done, laid out for where it opens.
func deeds() -> Words:
	var menu := _menu("%d of %d deeds" % [Deeds.count(main.profile()), Deeds.TABLE.size()])
	DeedsGrid.fill(menu, main.profile(), close_top)
	return menu


func _deeds() -> void:
	open(deeds())


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
