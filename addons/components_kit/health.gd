class_name Health
extends Node
## Reusable health attribute component.
##
## Add as a child of any entity that can be damaged (enemies, destructibles, and
## optionally the player). The owning entity should forward damage to it, e.g.:
##
##     func take_damage(amount: float, source: Node = null) -> void:
##         $Health.take_damage(amount, source)
##
## The component emits local signals for HUD/VFX wiring and also announces
## damage/death on the global EventBus so any system can react without coupling.
## It implements the SaveManager "saveable" contract (save_data/load_data).

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, source: Node)
signal died

@export var max_health: float = 100.0
## Starting / current health. If left <= 0 it is initialised to max_health.
@export var current_health: float = 100.0
## When true, incoming damage is scaled by the active difficulty (Easy 0.5x,
## Hard 1.5x). Typically enabled for the player, disabled for enemies.
@export var difficulty_scaled: bool = false
@export var invulnerable: bool = false

var _is_dead: bool = false

func _ready() -> void:
	if current_health <= 0.0:
		current_health = max_health
	health_changed.emit(current_health, max_health)

## Apply damage. `source` is whoever caused it (may be null, e.g. fall damage).
func take_damage(amount: float, source: Node = null) -> void:
	if _is_dead or invulnerable or amount <= 0.0:
		return
	if difficulty_scaled:
		amount *= _difficulty_multiplier()

	current_health = clampf(current_health - amount, 0.0, max_health)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.damage_dealt.emit(get_parent(), amount, source)

	if current_health <= 0.0:
		_die()

func heal(amount: float) -> void:
	if _is_dead or amount <= 0.0:
		return
	current_health = clampf(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return _is_dead

## Revive to a fraction of max health (used by respawn logic).
func revive(fraction: float = 1.0) -> void:
	_is_dead = false
	current_health = clampf(max_health * fraction, 1.0, max_health)
	health_changed.emit(current_health, max_health)

func _die() -> void:
	_is_dead = true
	died.emit()
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.entity_died.emit(get_parent())

func _difficulty_multiplier() -> float:
	var gs := get_node_or_null("/root/GameSettings")
	if gs == null:
		return 1.0
	match String(gs.difficulty):
		"Easy": return 0.5
		"Hard": return 1.5
		_: return 1.0

# --- SaveManager "saveable" contract ----------------------------------------

func save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"dead": _is_dead,
	}

func load_data(data: Dictionary) -> void:
	max_health = float(data.get("max_health", max_health))
	current_health = float(data.get("current_health", current_health))
	_is_dead = bool(data.get("dead", false))
	health_changed.emit(current_health, max_health)
