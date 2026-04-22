class_name InventoryScreen
extends Control

## Full inventory UI: 8x5 grid + 8 quick slots, drag/drop with snap, sort, throw.

const SLOT_BG: Texture2D = preload("res://assets/images/slot-bg.png")
const PICKUP_SCENE: PackedScene = preload("res://src/items/pickup.tscn")
const CELL_SIZE: int = 64

@onready var _grid_area: Control = $Root/MarginContainer/HBoxContainer/Left/GridArea
@onready var _quick_bar: HBoxContainer = $Root/MarginContainer/HBoxContainer/Left/QuickBar
@onready var _sort_button: Button = $Root/MarginContainer/HBoxContainer/Right/SortButton
@onready var _weight_label: Label = $Root/MarginContainer/HBoxContainer/Right/WeightLabel
@onready var _price_label: Label = $Root/MarginContainer/HBoxContainer/Right/PriceLabel
@onready var _toast: Label = $Root/ToastLabel

var player: Node
var inventory: Inventory

var _grid_cells: Array[GridCellUI] = []
var _item_widgets: Array[ItemWidget] = []
var _quick_slots: Array[InventorySlotUI] = []

var _items_layer: Control
var _snap_ghost: Panel

var _toast_timer: float = 0.0

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_toast.visible = false
	_sort_button.pressed.connect(_on_sort_pressed)
	set_process(true)

	_grid_area.custom_minimum_size = Vector2(Inventory.GRID_W * CELL_SIZE, Inventory.GRID_H * CELL_SIZE)
	_grid_area.mouse_filter = Control.MOUSE_FILTER_PASS

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hide_snap_ghost()

func bind(p_player: Node) -> void:
	player = p_player
	inventory = p_player.get_node("Inventory")
	inventory.changed.connect(_on_inventory_changed)
	inventory.quick_changed.connect(_on_inventory_changed)
	inventory.pickup_failed.connect(_on_pickup_failed)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for c in _grid_area.get_children():
		c.queue_free()
	for c in _quick_bar.get_children():
		c.queue_free()
	_grid_cells.clear()
	_item_widgets.clear()
	_quick_slots.clear()

	# 40 grid background / drop cells (absolute positioned).
	for i in Inventory.GRID_SIZE:
		var cell: GridCellUI = GridCellUI.new()
		cell.slot_bg = SLOT_BG
		cell.cell_index = i
		cell.inventory = inventory
		cell.screen = self
		cell.size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.position = Vector2(Inventory.x_of(i) * CELL_SIZE, Inventory.y_of(i) * CELL_SIZE)
		_grid_area.add_child(cell)
		_grid_cells.append(cell)

	# Items layer above cells.
	_items_layer = Control.new()
	_items_layer.name = "ItemsLayer"
	_items_layer.anchor_right = 1.0
	_items_layer.anchor_bottom = 1.0
	_items_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_grid_area.add_child(_items_layer)

	# Snap ghost on top.
	_snap_ghost = Panel.new()
	_snap_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_snap_ghost.visible = false
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.9, 0.4, 0.25)
	sb.border_color = Color(0.3, 0.9, 0.4, 0.9)
	sb.set_border_width_all(2)
	_snap_ghost.add_theme_stylebox_override("panel", sb)
	_grid_area.add_child(_snap_ghost)

	# Quick bar (8 slots).
	for i in Inventory.QUICK_COUNT:
		var q: InventorySlotUI = InventorySlotUI.new()
		q.slot_bg = SLOT_BG
		q.inventory = inventory
		q.index = i
		q.throw_requested.connect(_on_throw_requested)
		_quick_bar.add_child(q)
		_quick_slots.append(q)

	_rebuild_item_widgets()

func _rebuild_item_widgets() -> void:
	if _items_layer == null:
		return
	for w in _item_widgets:
		w.queue_free()
	_item_widgets.clear()

	for anchor in inventory.all_anchors():
		var s: InventorySlot = inventory.get_slot_at_anchor(anchor)
		if s == null:
			continue
		var iw: ItemWidget = ItemWidget.new()
		iw.inventory = inventory
		iw.anchor = anchor
		iw.cell_size = CELL_SIZE
		iw.size = Vector2(s.item.slots.x * CELL_SIZE, s.item.slots.y * CELL_SIZE)
		iw.position = Vector2(Inventory.x_of(anchor) * CELL_SIZE, Inventory.y_of(anchor) * CELL_SIZE)
		iw.throw_requested.connect(_on_throw_requested)
		_items_layer.add_child(iw)
		_item_widgets.append(iw)

func _on_inventory_changed() -> void:
	_refresh()

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player and "is_inventory_open" in player:
		player.is_inventory_open = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if player and "is_inventory_open" in player:
		player.is_inventory_open = false
	get_tree().paused = false
	_hide_snap_ghost()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _refresh() -> void:
	_rebuild_item_widgets()
	for q in _quick_slots:
		q.refresh()
	if inventory:
		_weight_label.text = "Weight: %.2f kg" % inventory.total_weight()
		_price_label.text = "Value: %.2f \u20AC" % inventory.total_price()
	_update_outlines()

func _update_outlines() -> void:
	if player == null:
		return
	var left: ItemResource = player.get("equipped_left_item")
	var right: ItemResource = player.get("equipped_right_item")
	for q in _quick_slots:
		var it: ItemResource = q._get_item()
		q.set_outline(it != null and (it == left or it == right))

func _on_sort_pressed() -> void:
	if inventory:
		inventory.sort_by_type()

func _on_throw_requested(anchor: int, amount: int) -> void:
	_throw_from_anchor(anchor, amount)

func _throw_from_anchor(anchor: int, amount: int) -> void:
	if inventory == null or player == null:
		return
	var slot: InventorySlot = inventory.get_slot_at_anchor(anchor)
	if slot == null or slot.is_empty():
		return
	amount = min(amount, slot.count)
	var item: ItemResource = slot.item
	for _i in amount:
		inventory.remove_one(anchor)
		# After last removal the anchor might be freed, but remove_one handles empties.
	_spawn_thrown(item, amount)

func _spawn_thrown(item: ItemResource, count: int) -> void:
	if count <= 0 or item == null or player == null:
		return
	var cam: Node3D = player.get_node_or_null("CameraPivot/Camera3D")
	if cam == null:
		return
	var forward: Vector3 = -cam.global_transform.basis.z
	var origin: Vector3 = cam.global_position + forward * 0.8
	var velocity: Vector3 = forward * 6.0
	var world: Node = player.get_parent()
	Pickup.spawn(PICKUP_SCENE, item, count, world, origin, velocity)

# -------- background-drop (throw) --------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.get("source", "") == "grid"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.get("source", "") != "grid":
		return
	var anchor: int = data.get("anchor", -1)
	var slot: InventorySlot = inventory.get_slot_at_anchor(anchor)
	if slot == null:
		return
	_throw_from_anchor(anchor, slot.count)

# -------- snap ghost --------

func on_grid_hover(cell_index: int, data: Variant, is_valid: bool) -> void:
	if data.get("source", "") != "grid":
		_hide_snap_ghost()
		return
	var anchor: int = data.get("anchor", -1)
	var s: InventorySlot = inventory.get_slot_at_anchor(anchor)
	if s == null:
		_hide_snap_ghost()
		return
	var pick_dx: int = data.get("pick_dx", 0)
	var pick_dy: int = data.get("pick_dy", 0)
	var target_x: int = Inventory.x_of(cell_index) - pick_dx
	var target_y: int = Inventory.y_of(cell_index) - pick_dy
	var w: int = s.item.slots.x
	var h: int = s.item.slots.y
	# Clamp into grid for a visible ghost even if invalid.
	target_x = clamp(target_x, 0, Inventory.GRID_W - w)
	target_y = clamp(target_y, 0, Inventory.GRID_H - h)
	_show_snap_ghost(target_x, target_y, w, h, is_valid)

func _show_snap_ghost(cx: int, cy: int, w: int, h: int, is_valid: bool) -> void:
	if _snap_ghost == null:
		return
	_snap_ghost.position = Vector2(cx * CELL_SIZE, cy * CELL_SIZE)
	_snap_ghost.size = Vector2(w * CELL_SIZE, h * CELL_SIZE)
	var sb: StyleBoxFlat = _snap_ghost.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		if is_valid:
			sb.bg_color = Color(0.3, 0.9, 0.4, 0.25)
			sb.border_color = Color(0.3, 0.9, 0.4, 0.9)
		else:
			sb.bg_color = Color(0.9, 0.3, 0.3, 0.25)
			sb.border_color = Color(0.9, 0.3, 0.3, 0.9)
	_snap_ghost.visible = true
	_snap_ghost.get_parent().move_child(_snap_ghost, _snap_ghost.get_parent().get_child_count() - 1)

func _hide_snap_ghost() -> void:
	if _snap_ghost:
		_snap_ghost.visible = false

# -------- toast --------

func _on_pickup_failed(_item: ItemResource, _leftover: int) -> void:
	_show_toast("Not enough space")

func _show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_timer = 2.0

func _process(delta: float) -> void:
	if _toast.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast.visible = false
		elif _toast_timer < 0.6:
			_toast.modulate.a = _toast_timer / 0.6

func show_pickup_failed() -> void:
	_show_toast("Not enough space")
