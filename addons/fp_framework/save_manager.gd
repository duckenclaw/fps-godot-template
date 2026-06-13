extends Node
## Global save / load manager for game STATE.
##
## Autoloaded as "SaveManager" by the FP Framework plugin. This is deliberately
## separate from GameSettings: GameSettings stores *preferences* (audio, video,
## controls), while SaveManager stores *game progress* (player position, stats,
## inventory, world state) in slotted files under user://saves/.
##
## Contract — nodes that want to persist must:
##   1. join the "saveable" group,
##   2. implement `func save_data() -> Dictionary` returning JSON-friendly data
##      (numbers, strings, bools, arrays, dictionaries — convert Vector3 etc. to
##      arrays yourself),
##   3. implement `func load_data(data: Dictionary) -> void`,
##   4. optionally expose a unique `save_id: String`; otherwise the node's scene
##      path is used as the key.

const SAVE_DIR := "user://saves"
const SAVE_EXT := ".save"
const SAVEABLE_GROUP := "saveable"

signal game_saved(slot: int)
signal game_loaded(slot: int)

var _pending_load: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slot_path(slot: int) -> String:
	return "%s/slot_%d%s" % [SAVE_DIR, slot, SAVE_EXT]

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

## Return the slot numbers that currently hold a save, sorted ascending.
func list_saves() -> Array[int]:
	var result: Array[int] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return result
	for f in dir.get_files():
		if f.begins_with("slot_") and f.ends_with(SAVE_EXT):
			var num := f.trim_prefix("slot_").trim_suffix(SAVE_EXT)
			if num.is_valid_int():
				result.append(num.to_int())
	result.sort()
	return result

func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

## Walk the "saveable" group, collect each node's data and write a slot file.
func save_game(slot: int = 0) -> void:
	var current := get_tree().current_scene
	var data := {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_scene": current.scene_file_path if current else "",
		"entities": {},
	}
	for node in get_tree().get_nodes_in_group(SAVEABLE_GROUP):
		if node.has_method("save_data"):
			data["entities"][_node_key(node)] = node.save_data()

	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open slot %d for writing" % slot)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	game_saved.emit(slot)

## Load a slot. If it points to a different scene than the active one, the scene
## is loaded first (through SceneManager when available) and then state restored.
func load_game(slot: int = 0) -> void:
	if not has_save(slot):
		push_warning("SaveManager: no save in slot %d" % slot)
		return
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: corrupt save in slot %d" % slot)
		return
	var data: Dictionary = parsed

	var scene_path: String = data.get("current_scene", "")
	var current := get_tree().current_scene
	var needs_scene_change := scene_path != "" and (current == null or current.scene_file_path != scene_path)

	if needs_scene_change:
		_pending_load = data
		var sm := get_node_or_null("/root/SceneManager")
		if sm:
			await sm.change_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
			await get_tree().process_frame
			await get_tree().process_frame
		_restore(_pending_load, slot)
		_pending_load = {}
	else:
		_restore(data, slot)

func _restore(data: Dictionary, slot: int) -> void:
	var entities: Dictionary = data.get("entities", {})
	for node in get_tree().get_nodes_in_group(SAVEABLE_GROUP):
		var key := _node_key(node)
		if entities.has(key) and node.has_method("load_data"):
			node.load_data(entities[key])
	game_loaded.emit(slot)

func _node_key(node: Node) -> String:
	if "save_id" in node and String(node.save_id) != "":
		return String(node.save_id)
	return str(node.get_path())
