class_name InventorySlot
extends RefCounted

## Holds a stack of a single item type within an inventory grid cell.

var item: ItemResource
var count: int = 0

func _init(p_item: ItemResource = null, p_count: int = 0) -> void:
	item = p_item
	count = p_count

func is_empty() -> bool:
	return item == null or count <= 0

func space_left() -> int:
	if item == null:
		return 0
	return max(0, item.max_stack - count)

func duplicate_slot() -> InventorySlot:
	return InventorySlot.new(item, count)
