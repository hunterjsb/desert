extends Node
## You across runs, at /root/Profile: one local file, apart from the run
## save, with no accounts. Its unlocks, finds and how-tos shown only ever
## grow, by unlock(), by discovering a kind of thing for the first time and by
## learn(), and only reset() empties it. Every unlock goes through unlock(),
## so achievements or cloud sync attach there and nowhere else. Beside them it
## keeps the origin you last came as, whose kit the main menu shows. A profile
## from another version is refused with a reason and left untouched on disk.

signal unlocked(id: String)
signal discovered(kind: String)

const KIND := "sandgame profile"
const VERSION := 1

## Where the profile lives; probes point it somewhere of their own.
var dir := "user://":
	set(to):
		dir = to
		_loaded = false
## Why the profile on disk can't be read, or "". While it's refused nothing
## is written over it, short of a reset.
var refused := ""

## Unix time each was first unlocked, each kind first found, and each how-to first shown.
var _unlocks := {}
var _found := {}
var _taught := {}
var _origin := ""
var _loaded := false


func path() -> String:
	return dir.path_join("profile.save")


## Says whether it's new.
func unlock(id: String) -> bool:
	_load()
	if _unlocks.has(id):
		return false
	_unlocks[id] = Time.get_unix_time_from_system()
	_write()
	unlocked.emit(id)
	return true


## A kind of thing found: recorded the first time only. Says whether it's new.
func discover(kind: String) -> bool:
	_load()
	if _found.has(kind):
		return false
	_found[kind] = Time.get_unix_time_from_system()
	_write()
	discovered.emit(kind)
	return true


## A how-to shown: recorded the first time only, so it's taught once a
## profile, never once a run. Says whether it's new.
func learn(id: String) -> bool:
	_load()
	if _taught.has(id):
		return false
	_taught[id] = Time.get_unix_time_from_system()
	_write()
	return true


## Unlocked, or a kind found.
func has(id: String) -> bool:
	_load()
	return _unlocks.has(id) or _found.has(id)


## Every kind found, first found first.
func discoveries() -> Array:
	_load()
	var kinds := _found.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool: return _found[a] < _found[b])
	return kinds


## The origin a run was begun or resumed as, by id.
func remember_origin(id: StringName) -> void:
	_load()
	if _origin != str(id):
		_origin = str(id)
		_write()


## The origin you last came as, or none before your first run.
func last_origin() -> StringName:
	_load()
	return StringName(_origin)


## Empties it, over a refused one too: Options asks first.
func reset() -> void:
	_unlocks.clear()
	_found.clear()
	_taught.clear()
	_origin = ""
	_loaded = true
	refused = ""
	_write()


func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var got := SaveFile.read(path(), KIND, VERSION)
	refused = got.refused
	var data: Dictionary = got.data
	_unlocks = data.get("unlocks", {})
	_found = data.get("found", {})
	_taught = data.get("taught", {})
	_origin = str(data.get("origin", ""))


func _write() -> void:
	if refused == "":
		SaveFile.write(path(), KIND, VERSION, {"unlocks": _unlocks, "found": _found, "taught": _taught,
			"origin": _origin})
