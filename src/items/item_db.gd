class_name ItemDB
extends RefCounted
## Lightweight item registry.
##
## Scans the items resource folder once and maps ItemResource.id -> ItemResource,
## so systems that only have an item id (most importantly the save system) can
## resolve it back to the actual resource. Usage:
##
##     var sword := ItemDB.get_item(&"sword")
##
## Add new item .tres files to ITEMS_DIR and they are picked up automatically.

const ITEMS_DIR := "res://assets/resources/items"

static var _items: Dictionary = {}
static var _loaded: bool = false

## Resolve an item by its id, or null if unknown.
static func get_item(id: StringName) -> ItemResource:
	_ensure_loaded()
	return _items.get(id, null)

## Every registered item resource.
static func all_items() -> Array:
	_ensure_loaded()
	return _items.values()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("ItemDB: cannot open %s" % ITEMS_DIR)
		return
	for f in dir.get_files():
		var fname := f
		# Exported builds may list imported resources with a .remap suffix.
		if fname.ends_with(".remap"):
			fname = fname.trim_suffix(".remap")
		if not fname.ends_with(".tres"):
			continue
		var res: Resource = load(ITEMS_DIR + "/" + fname)
		if res is ItemResource and res.id != &"":
			_items[res.id] = res
