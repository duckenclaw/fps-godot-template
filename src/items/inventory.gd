class_name Inventory
extends Node

## Grid-based inventory: 8x5 slots + 8 quick-equip references.
## Items occupy rectangular regions defined by `item.slots` (width, height).
## Only the anchor (top-left) cell of an occupied rect holds the InventorySlot;
## all other covered cells point back to the anchor via `cell_owner`.

signal changed
signal quick_changed
signal pickup_failed(item: ItemResource, leftover: int)

const GRID_W: int = 8
const GRID_H: int = 5
const GRID_SIZE: int = GRID_W * GRID_H
const QUICK_COUNT: int = 8

var slots: Array = []            # Size GRID_SIZE. InventorySlot at anchor, else null.
var cell_owner: Array[int] = []  # Size GRID_SIZE. Anchor index for each cell, or -1.
var quick: Array[int] = []       # Size QUICK_COUNT. Grid (anchor) index or -1.

func _ready() -> void:
	slots.resize(GRID_SIZE)
	cell_owner.resize(GRID_SIZE)
	for i in GRID_SIZE:
		cell_owner[i] = -1
	quick.resize(QUICK_COUNT)
	for i in QUICK_COUNT:
		quick[i] = -1

# -------- helpers --------

static func xy_to_index(x: int, y: int) -> int:
	return y * GRID_W + x

static func x_of(index: int) -> int:
	return index % GRID_W

static func y_of(index: int) -> int:
	return index / GRID_W

## Returns true if the w*h rect anchored at `anchor` fits inside the grid
## and none of its cells are owned by a different item than `ignore_anchor`.
func rect_fits(anchor: int, w: int, h: int, ignore_anchor: int = -1) -> bool:
	if anchor < 0:
		return false
	var ax: int = x_of(anchor)
	var ay: int = y_of(anchor)
	if ax < 0 or ay < 0 or ax + w > GRID_W or ay + h > GRID_H:
		return false
	for dy in h:
		for dx in w:
			var ci: int = xy_to_index(ax + dx, ay + dy)
			var owner: int = cell_owner[ci]
			if owner != -1 and owner != ignore_anchor:
				return false
	return true

func _place_rect(anchor: int, w: int, h: int) -> void:
	var ax: int = x_of(anchor)
	var ay: int = y_of(anchor)
	for dy in h:
		for dx in w:
			cell_owner[xy_to_index(ax + dx, ay + dy)] = anchor

func _clear_rect(anchor: int, w: int, h: int) -> void:
	var ax: int = x_of(anchor)
	var ay: int = y_of(anchor)
	for dy in h:
		for dx in w:
			cell_owner[xy_to_index(ax + dx, ay + dy)] = -1

func _find_empty_anchor_for(item: ItemResource) -> int:
	var w: int = item.slots.x
	var h: int = item.slots.y
	for y in (GRID_H - h + 1):
		for x in (GRID_W - w + 1):
			var a: int = xy_to_index(x, y)
			if rect_fits(a, w, h):
				return a
	return -1

# -------- reads --------

## Get the InventorySlot at a cell (any cell of the item, not necessarily anchor).
func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= GRID_SIZE:
		return null
	var anchor: int = cell_owner[index]
	if anchor < 0:
		return null
	return slots[anchor]

## Get the slot anchored at `anchor` (strict, anchor only).
func get_slot_at_anchor(anchor: int) -> InventorySlot:
	if anchor < 0 or anchor >= GRID_SIZE:
		return null
	return slots[anchor]

## Return the anchor index owning a given cell (or -1).
func get_anchor_of_cell(index: int) -> int:
	if index < 0 or index >= GRID_SIZE:
		return -1
	return cell_owner[index]

## Collect all anchors currently placed, in index order.
func all_anchors() -> Array[int]:
	var out: Array[int] = []
	for i in GRID_SIZE:
		if slots[i] != null:
			out.append(i)
	return out

func get_quick_index(quick_idx: int) -> int:
	if quick_idx < 0 or quick_idx >= QUICK_COUNT:
		return -1
	return quick[quick_idx]

func get_quick_item(quick_idx: int) -> ItemResource:
	var anchor: int = get_quick_index(quick_idx)
	if anchor < 0:
		return null
	var s: InventorySlot = slots[anchor]
	return s.item if s else null

# -------- writes --------

## Try to pick up `count` of `item`. Returns leftover (0 = fully picked up).
func try_pickup(item: ItemResource, count: int = 1) -> int:
	if item == null or count <= 0:
		return count

	var remaining: int = count

	# First pass: top up existing stacks.
	if item.max_stack > 1:
		for i in GRID_SIZE:
			if remaining <= 0:
				break
			var s: InventorySlot = slots[i]
			if s and s.item == item and s.count < item.max_stack:
				var take: int = min(s.space_left(), remaining)
				s.count += take
				remaining -= take

	# Second pass: place new anchors.
	while remaining > 0:
		var anchor: int = _find_empty_anchor_for(item)
		if anchor < 0:
			break
		var take: int = min(item.max_stack, remaining)
		slots[anchor] = InventorySlot.new(item, take)
		_place_rect(anchor, item.slots.x, item.slots.y)
		remaining -= take

	if remaining != count:
		changed.emit()
	if remaining > 0:
		pickup_failed.emit(item, remaining)
	return remaining

## Remove one item at the given cell. Returns the removed ItemResource or null.
func remove_one(cell_index: int) -> ItemResource:
	var anchor: int = get_anchor_of_cell(cell_index)
	if anchor < 0:
		return null
	var s: InventorySlot = slots[anchor]
	if s == null or s.is_empty():
		return null
	var item: ItemResource = s.item
	s.count -= 1
	if s.count <= 0:
		_clear_rect(anchor, s.item.slots.x, s.item.slots.y)
		slots[anchor] = null
		_clear_quick_pointing_to(anchor)
	changed.emit()
	return item

## Remove the entire stack at the given cell.
func remove_stack(cell_index: int) -> InventorySlot:
	var anchor: int = get_anchor_of_cell(cell_index)
	if anchor < 0:
		return null
	var s: InventorySlot = slots[anchor]
	if s == null:
		return null
	_clear_rect(anchor, s.item.slots.x, s.item.slots.y)
	slots[anchor] = null
	_clear_quick_pointing_to(anchor)
	changed.emit()
	return s

func _clear_quick_pointing_to(anchor: int) -> void:
	var dirty: bool = false
	for i in QUICK_COUNT:
		if quick[i] == anchor:
			quick[i] = -1
			dirty = true
	if dirty:
		quick_changed.emit()

func _retarget_quick(old_anchor: int, new_anchor: int) -> void:
	if old_anchor == new_anchor:
		return
	var dirty: bool = false
	for i in QUICK_COUNT:
		if quick[i] == old_anchor:
			quick[i] = new_anchor
			dirty = true
	if dirty:
		quick_changed.emit()

## Move the item anchored at `src_anchor` so its new anchor becomes `dst_anchor`.
## Returns true if the move succeeded.
func move_item(src_anchor: int, dst_anchor: int) -> bool:
	if src_anchor < 0 or src_anchor >= GRID_SIZE:
		return false
	if dst_anchor < 0 or dst_anchor >= GRID_SIZE:
		return false
	var s: InventorySlot = slots[src_anchor]
	if s == null:
		return false
	var w: int = s.item.slots.x
	var h: int = s.item.slots.y

	# If dst has another item, try to merge stacks (same item, room).
	var dst_owner: int = cell_owner[dst_anchor]
	if dst_owner != -1 and dst_owner != src_anchor:
		var s_dst: InventorySlot = slots[dst_owner]
		if s_dst and s_dst.item == s.item and s_dst.count < s_dst.item.max_stack:
			var take: int = min(s_dst.space_left(), s.count)
			s_dst.count += take
			s.count -= take
			if s.count <= 0:
				_clear_rect(src_anchor, w, h)
				slots[src_anchor] = null
				_clear_quick_pointing_to(src_anchor)
			changed.emit()
			return true
		return false

	# Otherwise, require rect fits (ignoring self).
	if not rect_fits(dst_anchor, w, h, src_anchor):
		return false

	_clear_rect(src_anchor, w, h)
	slots[src_anchor] = null
	slots[dst_anchor] = s
	_place_rect(dst_anchor, w, h)
	_retarget_quick(src_anchor, dst_anchor)
	changed.emit()
	return true

## Bind a quick slot to a grid anchor.
func set_quick(quick_idx: int, cell_index: int) -> void:
	if quick_idx < 0 or quick_idx >= QUICK_COUNT:
		return
	var anchor: int = get_anchor_of_cell(cell_index)
	if anchor < 0:
		return
	quick[quick_idx] = anchor
	quick_changed.emit()

func clear_quick(quick_idx: int) -> void:
	if quick_idx < 0 or quick_idx >= QUICK_COUNT:
		return
	if quick[quick_idx] == -1:
		return
	quick[quick_idx] = -1
	quick_changed.emit()

func swap_quick(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= QUICK_COUNT or b >= QUICK_COUNT or a == b:
		return
	var tmp: int = quick[a]
	quick[a] = quick[b]
	quick[b] = tmp
	quick_changed.emit()

## Auto-sort: repack by type. Larger items placed first to avoid fragmentation.
func sort_by_type() -> void:
	# Remember each quick's pointed item identity to preserve bindings across sort.
	var quick_items: Array = []
	quick_items.resize(QUICK_COUNT)
	for i in QUICK_COUNT:
		quick_items[i] = get_quick_item(i)

	var all_slots: Array = []
	for i in GRID_SIZE:
		if slots[i] != null:
			all_slots.append(slots[i])
	all_slots.sort_custom(_sort_cmp)

	# Clear grid.
	for i in GRID_SIZE:
		slots[i] = null
		cell_owner[i] = -1

	# Re-place each slot.
	for s in all_slots:
		var anchor: int = _find_empty_anchor_for(s.item)
		if anchor < 0:
			continue  # shouldn't happen for a previously-fitting set
		slots[anchor] = s
		_place_rect(anchor, s.item.slots.x, s.item.slots.y)

	# Rebind quick slots to the new anchor index of the remembered item.
	for i in QUICK_COUNT:
		var wanted: ItemResource = quick_items[i]
		if wanted == null:
			quick[i] = -1
			continue
		quick[i] = _find_first_anchor_of(wanted)

	changed.emit()
	quick_changed.emit()

func _find_first_anchor_of(item: ItemResource) -> int:
	for i in GRID_SIZE:
		var s: InventorySlot = slots[i]
		if s and s.item == item:
			return i
	return -1

static func _sort_cmp(a: InventorySlot, b: InventorySlot) -> bool:
	if a.item.type != b.item.type:
		return String(a.item.type) < String(b.item.type)
	var area_a: int = a.item.slots.x * a.item.slots.y
	var area_b: int = b.item.slots.x * b.item.slots.y
	if area_a != area_b:
		return area_a > area_b  # larger first for packing
	return a.item.display_name < b.item.display_name

# -------- totals --------

func total_weight() -> float:
	var w: float = 0.0
	for s in slots:
		if s:
			w += s.item.weight * s.count
	return w

func total_price() -> float:
	var p: float = 0.0
	for s in slots:
		if s:
			p += s.item.price * s.count
	return p
