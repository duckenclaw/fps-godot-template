class_name Hand
extends Node3D

## Hand controller. Holds an item, plays attack/stagger animations for melee weapons,
## and performs hit detection via a child Area3D enabled during attack swings.

signal hit_landed(target: Node, damage: float)
signal staggered()

@export var is_right_hand: bool = true

# Set by the player when equipping; lets the hand know damage/speed/grip.
var current_item_resource: ItemResource

# The instantiated model (a child of `anim_root`).
var equipped_item: Node3D = null

# Runtime nodes built in _ready.
var anim_root: Node3D
var attack_area: Area3D
var anim_player: AnimationPlayer

# Per-swing state.
var _attacking: bool = false
var _hit_bodies: Array = []

const ATTACK_ANIM: StringName = &"attack"
const STAGGER_ANIM: StringName = &"stagger"

func _ready() -> void:
	_build_runtime_nodes()
	_build_animations()

# -- Runtime nodes ------------------------------------------------------------

func _build_runtime_nodes() -> void:
	anim_root = Node3D.new()
	anim_root.name = "AnimRoot"
	add_child(anim_root)

	attack_area = Area3D.new()
	attack_area.name = "AttackArea"
	attack_area.monitoring = false
	attack_area.monitorable = false
	attack_area.collision_layer = 0
	attack_area.collision_mask = 0xFFFFFFFF
	anim_root.add_child(attack_area)

	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	# Thin, long cube extending forward from the hand.
	box.size = Vector3(0.08, 0.08, 1.0)
	shape.shape = box
	shape.position = Vector3(0, 0, -0.5)
	attack_area.add_child(shape)

	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)

	attack_area.body_entered.connect(_on_body_entered)
	attack_area.area_entered.connect(_on_area_entered)
	anim_player.animation_finished.connect(_on_animation_finished)

func _build_animations() -> void:
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(ATTACK_ANIM, _make_attack_anim())
	lib.add_animation(STAGGER_ANIM, _make_stagger_anim())
	anim_player.add_animation_library("", lib)

func _make_attack_anim() -> Animation:
	var a: Animation = Animation.new()
	a.length = 0.4
	a.loop_mode = Animation.LOOP_NONE

	var t_rot: int = a.add_track(Animation.TYPE_ROTATION_3D)
	a.track_set_path(t_rot, NodePath("AnimRoot"))
	a.rotation_track_insert_key(t_rot, 0.0, Quaternion.IDENTITY)
	a.rotation_track_insert_key(t_rot, 0.08, Quaternion(Vector3.RIGHT, 0.6))
	a.rotation_track_insert_key(t_rot, 0.20, Quaternion(Vector3.RIGHT, -1.3))
	a.rotation_track_insert_key(t_rot, 0.4, Quaternion.IDENTITY)

	var t_pos: int = a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_pos, NodePath("AnimRoot"))
	a.position_track_insert_key(t_pos, 0.0, Vector3.ZERO)
	a.position_track_insert_key(t_pos, 0.20, Vector3(0, 0, -0.25))
	a.position_track_insert_key(t_pos, 0.4, Vector3.ZERO)
	return a

func _make_stagger_anim() -> Animation:
	var a: Animation = Animation.new()
	a.length = 0.3
	a.loop_mode = Animation.LOOP_NONE

	var t_pos: int = a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_pos, NodePath("AnimRoot"))
	a.position_track_insert_key(t_pos, 0.0, Vector3.ZERO)
	a.position_track_insert_key(t_pos, 0.06, Vector3(0.08, 0.05, 0.18))
	a.position_track_insert_key(t_pos, 0.3, Vector3.ZERO)

	var t_rot: int = a.add_track(Animation.TYPE_ROTATION_3D)
	a.track_set_path(t_rot, NodePath("AnimRoot"))
	a.rotation_track_insert_key(t_rot, 0.0, Quaternion.IDENTITY)
	a.rotation_track_insert_key(t_rot, 0.06, Quaternion(Vector3.RIGHT, 0.35))
	a.rotation_track_insert_key(t_rot, 0.3, Quaternion.IDENTITY)
	return a

# -- Equip / unequip ----------------------------------------------------------

## Equip an item resource. Spawns the model under `anim_root`.
func equip_resource(item_res: ItemResource) -> void:
	unequip_item()
	current_item_resource = item_res
	if item_res == null or item_res.model == null:
		return
	var inst: Node = item_res.model.instantiate()
	if inst is Node3D:
		equipped_item = inst
		anim_root.add_child(equipped_item)
		equipped_item.position = Vector3.ZERO
		equipped_item.rotation = Vector3.ZERO

## Legacy entry point — accepts a pre-instantiated Node3D (no melee stats).
func equip_item(item: Node3D) -> void:
	unequip_item()
	current_item_resource = null
	if item == null:
		return
	equipped_item = item
	anim_root.add_child(equipped_item)
	equipped_item.position = Vector3.ZERO
	equipped_item.rotation = Vector3.ZERO

func unequip_item() -> void:
	if anim_player:
		anim_player.stop()
	if attack_area:
		attack_area.monitoring = false
	_attacking = false
	_hit_bodies.clear()
	if equipped_item:
		if equipped_item.get_parent() == anim_root:
			anim_root.remove_child(equipped_item)
		equipped_item.queue_free()
		equipped_item = null
	current_item_resource = null

func has_item() -> bool:
	return equipped_item != null

func get_equipped_item() -> Node3D:
	return equipped_item

# -- Attack -------------------------------------------------------------------

func attack() -> void:
	if current_item_resource and current_item_resource.is_melee():
		_begin_melee_attack()
	elif equipped_item and equipped_item.has_method("attack"):
		equipped_item.attack()

func _begin_melee_attack() -> void:
	if _attacking:
		return
	_attacking = true
	_hit_bodies.clear()
	var spd: float = max(0.1, current_item_resource.speed)
	anim_player.speed_scale = spd
	attack_area.monitoring = true
	anim_player.play(ATTACK_ANIM)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ATTACK_ANIM or anim_name == STAGGER_ANIM:
		attack_area.monitoring = false
		_attacking = false

# -- Hit detection ------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area3D) -> void:
	_handle_hit(area)

func _handle_hit(target: Node) -> void:
	if target == null or target in _hit_bodies:
		return
	if target.is_in_group(&"player"):
		return
	_hit_bodies.append(target)

	var dmg: float = current_item_resource.damage if current_item_resource else 0.0
	if target.is_in_group(&"enemy") or target.is_in_group(&"destructible"):
		if target.has_method("take_damage"):
			target.take_damage(dmg)
		hit_landed.emit(target, dmg)
	else:
		_stagger()

func _stagger() -> void:
	attack_area.monitoring = false
	anim_player.stop()
	anim_player.speed_scale = 1.0
	anim_player.play(STAGGER_ANIM)
	staggered.emit()
