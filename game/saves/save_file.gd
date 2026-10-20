class_name SaveFile
extends RefCounted
## A versioned file: a header saying what it is and which version, then the
## data. One of another kind or version is refused on its header, before a
## byte of the data is read, so nothing is ever half-read. Written beside
## itself and moved into place, so a crash mid-write leaves the old file whole.


## Writes the data; says whether it landed.
static func write(path: String, kind: String, version: int, data: Dictionary) -> bool:
	return write_bytes(path, kind, version, var_to_bytes(data))


## The same from data already encoded by var_to_bytes, which a worker thread
## can write while the game goes on.
static func write_bytes(path: String, kind: String, version: int, bytes: PackedByteArray) -> bool:
	var full := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	var fresh := full + ".new"
	var file := FileAccess.open(fresh, FileAccess.WRITE)
	if file == null:
		push_warning("couldn't write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_pascal_string(kind)
	file.store_32(version)
	# Laid out as store_var would, so get_var reads it back.
	file.store_32(bytes.size())
	file.store_buffer(bytes)
	file.close()
	return DirAccess.rename_absolute(fresh, full) == OK


## {"data": the data, or {} if there's none or it's refused; "refused": why
## not, or ""; "found": the version its header says, -1 if none}.
static func read(path: String, kind: String, version: int) -> Dictionary:
	var out := {"data": {}, "refused": "", "found": -1}
	if not FileAccess.file_exists(path):
		return out
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		out.refused = "%s can't be opened" % path
	elif file.get_length() < 8 or file.get_pascal_string() != kind:
		out.refused = "%s isn't a %s" % [path, kind]
	else:
		var found := file.get_32()
		out.found = found
		if found != version:
			out.refused = "%s is %s version %d; this build reads version %d" % [path, kind, found, version]
		else:
			var data: Variant = file.get_var()
			if data is Dictionary and file.get_error() == OK:
				out.data = data
			else:
				out.refused = "%s is damaged" % path
	if out.refused != "":
		push_warning("refused: " + out.refused)
	return out


static func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
