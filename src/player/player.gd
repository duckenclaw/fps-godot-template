extends CharacterBody3D


@export var config: PlayerConfig

# Player stats
@export_group("Stats")
@export var max_health: float = 100.0
@export var max_mana: float = 100.0
@export var max_stamina: float = 100.0

var health: float = 100.0
var mana: float = 100.0
var stamina: float = 100.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: CameraController = $CameraPivot
@onready var camera: CameraController = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var interact_raycast: RayCast3D = $CameraPivot/Camera3D/InteractRayCast
@onready var hands: Hands = $CameraPivot/Camera3D/Hands
@onready var state_machine: StateMachine = $StateMachine
@onready var inventory: Inventory = $Inventory

# UI references
@onready var hud: Control = $CanvasLayer/HUD if has_node("CanvasLayer/HUD") else null
@onready var pause_menu: Control = $CanvasLayer/PauseMenu if has_node("CanvasLayer/PauseMenu") else null
@onready var inventory_screen: InventoryScreen = $CanvasLayer/InventoryScreen if has_node("CanvasLayer/InventoryScreen") else null

# Currently equipped items (ItemResource references)
var equipped_left_item: ItemResource
var equipped_right_item: ItemResource

# Inventory open flag — gates input / physics the same way is_paused does.
var is_inventory_open: bool = false

# Input flags (set during input handling, used by states)
var jump_pressed: bool = false
var dash_pressed: bool = false
var crouch_pressed: bool = false

# Crouch toggle state
var is_crouch_toggled: bool = false

# Track if currently falling from a jump (for coyote time)
var is_falling_from_jump: bool = false

# Game state
var is_paused: bool = false

# Wallrun detection
@onready var wallrun_raycast_right: RayCast3D = RayCast3D.new()
@onready var wallrun_raycast_left: RayCast3D = RayCast3D.new()

# Height settings
const NORMAL_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.25
const SLIDE_HEIGHT: float = 1.0
const CAMERA_OFFSET: float = 0.1
const HEIGHT_TRANSITION_SPEED: float = 10.0
var current_height: float = NORMAL_HEIGHT
var target_height: float = NORMAL_HEIGHT

func _ready() -> void:
	# Create default config if none exists
	if not config:
		config = PlayerConfig.new()

	# Load settings from GameSettings singleton
	config.mouse_sensitivity = GameSettings.mouse_sensitivity
	config.invert_camera_x = GameSettings.invert_camera_x
	config.invert_camera_y = GameSettings.invert_camera_y
	config.difficulty = GameSettings.difficulty

	# Setup wallrun raycasts
	setup_wallrun_raycasts()

	# Pass config to camera
	if camera:
		camera.config = config

	# Initialize stats
	health = max_health
	mana = max_mana
	stamina = max_stamina

	# Connect to pause menu
	if pause_menu:
		pause_menu.player = self

	# Wire inventory UI
	if inventory_screen:
		inventory_screen.bind(self)
	if inventory:
		inventory.changed.connect(_refresh_quick_hud)
		inventory.quick_changed.connect(_refresh_quick_hud)
		inventory.pickup_failed.connect(_on_inventory_pickup_failed)

	# Update HUD
	update_hud()
	_refresh_quick_hud()

	# Set initial height
	set_player_height(NORMAL_HEIGHT)

func _input(event: InputEvent) -> void:
	# Handle pause
	if event.is_action_pressed("ui_cancel"):
		if is_inventory_open and inventory_screen:
			inventory_screen.close()
			return
		toggle_pause()
		return

	# Don't process other inputs when paused
	if is_paused:
		return

	# Toggle inventory
	if event.is_action_pressed("inventory"):
		if inventory_screen:
			inventory_screen.toggle()
		return

	# While inventory is open, only allow UI — block gameplay actions.
	if is_inventory_open:
		return

	# Handle interact action
	if event.is_action_pressed("interact"):
		try_interact()

	# Handle hand actions
	if event.is_action_pressed("left_hand"):
		hands.use_left_hand()

	if event.is_action_pressed("right_hand"):
		hands.use_right_hand()

	# Quick-equip
	for i in 8:
		if event.is_action_pressed("equip_%d" % (i + 1)):
			equip_from_quick(i)
			return

func _physics_process(delta: float) -> void:
	# Don't process physics when paused or inventory is open
	if is_paused or is_inventory_open:
		return

	# Smoothly interpolate height
	update_height_smooth(delta)

	# Update input flags for states to use
	jump_pressed = Input.is_action_just_pressed("jump")
	dash_pressed = Input.is_action_just_pressed("dash")
	crouch_pressed = Input.is_action_just_pressed("crouch")

	# Toggle crouch state when crouch is pressed
	if crouch_pressed:
		is_crouch_toggled = not is_crouch_toggled

## Get 2D input direction
func get_input_direction() -> Vector2:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.y = Input.get_action_strength("forward") - Input.get_action_strength("backward")
	return input_dir.normalized()

## Get 3D movement direction relative to camera
func get_move_direction() -> Vector3:
	var input_dir = get_input_direction()

	# Get camera forward and right vectors (flattened to XZ plane)
	var forward = -camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera_pivot.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	# Calculate movement direction
	return (forward * input_dir.y + right * input_dir.x).normalized()

## Try to interact with object in front of player
func try_interact() -> void:
	if interact_raycast.is_colliding():
		var collider = interact_raycast.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact()

## Setup wallrun detection raycasts
func setup_wallrun_raycasts() -> void:
	# Right raycast
	wallrun_raycast_right.target_position = Vector3(1.0, 0, 0)
	wallrun_raycast_right.enabled = true
	add_child(wallrun_raycast_right)

	# Left raycast
	wallrun_raycast_left.target_position = Vector3(-1.0, 0, 0)
	wallrun_raycast_left.enabled = true
	add_child(wallrun_raycast_left)

## Check if player can wallrun
func can_wallrun() -> bool:
	# Must be in the air
	if is_on_floor():
		return false

	# Must be moving
	var input_dir = get_input_direction()
	if input_dir.length() < 0.1:
		return false

	# Check if either side has a wall
	var has_wall = wallrun_raycast_right.is_colliding() or wallrun_raycast_left.is_colliding()
	if not has_wall:
		return false

	# Get wall normal
	var wall_normal = get_wallrun_normal()

	# Don't wallrun if facing the wall directly
	var forward = -camera_pivot.global_transform.basis.z
	var dot = forward.dot(wall_normal)

	# If dot product is positive, player is facing away from wall (good for wallrun)
	# If negative, player is facing the wall (don't wallrun)
	return dot > -0.3

## Get the normal vector of the wall player is next to (for wallrunning)
func get_wallrun_normal() -> Vector3:
	if wallrun_raycast_right.is_colliding():
		return wallrun_raycast_right.get_collision_normal()
	elif wallrun_raycast_left.is_colliding():
		return wallrun_raycast_left.get_collision_normal()
	return Vector3.ZERO

# ====================
# Height Management
# ====================

## Set target player height (will interpolate smoothly)
func set_player_height(height: float) -> void:
	target_height = height

## Update height with smooth interpolation
func update_height_smooth(delta: float) -> void:
	if abs(current_height - target_height) > 0.01:
		current_height = lerp(current_height, target_height, HEIGHT_TRANSITION_SPEED * delta)

		# Update collision shape
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			var capsule: CapsuleShape3D = collision_shape.shape
			capsule.height = current_height

			# Position collision shape so bottom stays at ground (y = 0)
			# Capsule center should be at height / 2
			collision_shape.position.y = current_height / 2.0

		# Update camera position (height - offset from top)
		if camera_pivot:
			camera_pivot.position.y = current_height - CAMERA_OFFSET

## Set to normal standing height
func set_normal_height() -> void:
	set_player_height(NORMAL_HEIGHT)

## Set to crouching height
func set_crouch_height() -> void:
	set_player_height(CROUCH_HEIGHT)

## Set to sliding height
func set_slide_height() -> void:
	set_player_height(SLIDE_HEIGHT)

# ====================
# Stat Management
# ====================

## Update health value and clamp it
func set_health(value: float) -> void:
	health = clamp(value, 0, max_health)
	update_hud()
	if health <= 0:
		die()

## Update mana value and clamp it
func set_mana(value: float) -> void:
	mana = clamp(value, 0, max_mana)
	update_hud()

## Update stamina value and clamp it
func set_stamina(value: float) -> void:
	stamina = clamp(value, 0, max_stamina)
	update_hud()

## Take damage
func take_damage(amount: float) -> void:
	set_health(health - amount)

## Heal player
func heal(amount: float) -> void:
	set_health(health + amount)

## Use mana
func use_mana(amount: float) -> bool:
	if mana >= amount:
		set_mana(mana - amount)
		return true
	return false

## Restore mana
func restore_mana(amount: float) -> void:
	set_mana(mana + amount)

## Use stamina
func use_stamina(amount: float) -> bool:
	if stamina >= amount:
		set_stamina(stamina - amount)
		return true
	return false

## Restore stamina
func restore_stamina(amount: float) -> void:
	set_stamina(stamina + amount)

## Update HUD display
func update_hud() -> void:
	if hud and hud.has_method("update_bar"):
		hud.update_bar("health", health, max_health)
		hud.update_bar("mana", mana, max_mana)
		hud.update_bar("stamina", stamina, max_stamina)

## Called when player dies
func die() -> void:
	# TODO: Implement death logic
	print("Player died")

# ====================
# Pause System
# ====================

## Toggle pause state
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

## Pause the game
func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if pause_menu:
		pause_menu.visible = true
		pause_menu.show_main_menu()

## Resume the game
func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if pause_menu:
		pause_menu.visible = false

# ====================
# Inventory / Equip
# ====================

## Equip the item bound to a quick slot. If it's already held, move it to the other hand.
func equip_from_quick(quick_idx: int) -> void:
	if inventory == null or hands == null:
		return
	var item: ItemResource = inventory.get_quick_item(quick_idx)
	if item == null:
		return

	# Already in one of the hands -> move to the other hand.
	if item == equipped_right_item:
		_unequip_right()
		_equip_left(item)
		return
	if item == equipped_left_item:
		_unequip_left()
		_equip_right(item)
		return

	# Fresh equip -> right for weapons, left for everything else.
	if item.type == &"weapon":
		_equip_right(item)
	else:
		_equip_left(item)

func _equip_right(item: ItemResource) -> void:
	if item == null or item.model == null:
		return
	_unequip_right()
	var inst: Node3D = item.model.instantiate() as Node3D
	if inst == null:
		return
	hands.equip_right_hand(inst)
	equipped_right_item = item
	_refresh_quick_hud()

func _equip_left(item: ItemResource) -> void:
	if item == null or item.model == null:
		return
	_unequip_left()
	var inst: Node3D = item.model.instantiate() as Node3D
	if inst == null:
		return
	hands.equip_left_hand(inst)
	equipped_left_item = item
	_refresh_quick_hud()

func _unequip_right() -> void:
	if equipped_right_item == null:
		return
	hands.unequip_right_hand()
	equipped_right_item = null

func _unequip_left() -> void:
	if equipped_left_item == null:
		return
	hands.unequip_left_hand()
	equipped_left_item = null

func _refresh_quick_hud() -> void:
	if hud and hud.has_method("update_quick_bar"):
		hud.update_quick_bar(inventory, equipped_left_item, equipped_right_item)

func _on_inventory_pickup_failed(_item: ItemResource, _leftover: int) -> void:
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Not enough space")
	elif inventory_screen and inventory_screen.visible:
		inventory_screen.show_pickup_failed()
