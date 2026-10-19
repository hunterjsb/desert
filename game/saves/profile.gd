extends Node
## You across runs, at /root/Profile: one local file, apart from the run
## save, with no accounts. Its unlocks, deeds, finds and how-tos shown only
## ever grow, by unlock(), by a deed done (Deeds), by discovering a kind of
## thing for the first time and by learn(), and only reset() empties it, or the
## dev console's forget_deeds(). Every unlock goes through unlock() and every
## deed through deed(), so cloud sync and achievements attach there and
## nowhere else. Beside them it keeps the origin you last came as, whose kit
## the main menu shows, and what's new for the menu to mark until you've
## looked. A profile from another version is refused with a reason and left
## untouched on disk.

signal unlocked(id: String)
signal discovered(kind: String)
signal deed_done(id: String)

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
## Each deed done: when, and the run it was done in. And for a deed made of
## several things, each counted toward it so far, across every run, by when.
var _deeds := {}
var _toward := {}
## For a deed that's a number to reach, the best so far, across every run.
var _best := {}
## Not looked at yet: each deed done, by its id, and each start a deed
## opened, by start().
var _new := {}
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


## A deed done, with the run it was done in ({seed, origin, ironman}):
## recorded the first time only. Says whether it's new.
func deed(id: String, run := {}) -> bool:
	_load()
	if _deeds.has(id):
		return false
	var record := run.duplicate()
	record["at"] = Time.get_unix_time_from_system()
	var opens := Deeds.opens(id).filter(func(kit: Kit) -> bool: return not kit.is_open_to(self))
	_deeds[id] = record
	_new[id] = true
	for kit: Kit in opens:
		_new[start(kit.id)] = true
	_write()
	deed_done.emit(id)
	return true


func did(id: String) -> bool:
	_load()
	return _deeds.has(id)


## Every deed done, by id: when, and in which run.
func deeds() -> Dictionary:
	_load()
	return _deeds.duplicate(true)


## A thing counted toward a deed made of several, such as one kind of crop
## of three: the first time only. Says how many it has now.
func toward(id: String, part: String) -> int:
	_load()
	var got: Dictionary = _toward.get(id, {})
	if not got.has(part):
		got[part] = Time.get_unix_time_from_system()
		_toward[id] = got
		_write()
	return got.size()


## How many different things have counted toward a deed.
func toward_count(id: String) -> int:
	_load()
	return _toward.get(id, {}).size()


## The best toward a deed that's a number to reach, or 0.
func best(id: String) -> float:
	_load()
	return _best.get(id, 0.0)


## A better best toward a deed, kept; a worse one is ignored.
func improve(id: String, value: float) -> void:
	_load()
	if value > _best.get(id, 0.0):
		_best[id] = value
		_write()


## Dev only: every deed undone, and what had counted toward them.
func forget_deeds() -> void:
	_load()
	_deeds.clear()
	_toward.clear()
	_best.clear()
	_new.clear()
	_write()


## A deed done, or a start a deed opened (start()), not looked at yet.
func is_new(key: String) -> bool:
	_load()
	return _new.has(key)


## Looked at, so no longer new.
func seen(key: String) -> void:
	_load()
	if _new.erase(key):
		_write()


## A start's key for is_new() and seen(), by its id.
static func start(id: StringName) -> String:
	return "start/" + str(id)


## Unlocked, a deed done, or a kind found.
func has(id: String) -> bool:
	_load()
	return _unlocks.has(id) or _deeds.has(id) or _found.has(id)


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
	_deeds.clear()
	_toward.clear()
	_best.clear()
	_new.clear()
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
	_deeds = data.get("deeds", {})
	_toward = data.get("toward", {})
	# A place counted under an id since renamed counts under the new one.
	for id: String in _toward:
		var counted: Dictionary = _toward[id]
		for part: String in counted.keys():
			var now := str(History.RENAMED.get(StringName(part), part))
			if now != part:
				counted[now] = counted.get(now, counted[part])
				counted.erase(part)
	_best = data.get("best", {})
	_new = data.get("new", {})
	_origin = str(data.get("origin", ""))


func _write() -> void:
	if refused == "":
		SaveFile.write(path(), KIND, VERSION, {"unlocks": _unlocks, "found": _found, "taught": _taught,
			"deeds": _deeds, "toward": _toward, "best": _best, "new": _new, "origin": _origin})
