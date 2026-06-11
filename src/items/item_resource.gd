class_name ItemResource
extends Resource

## Data resource describing a single item type.

@export var id: StringName = &""
@export var display_name: String = ""
@export var type: StringName = &"misc"
@export var weight: float = 0.0
@export var price: float = 0.0
@export var slots: Vector2i = Vector2i(1, 1)
@export var icon: Texture2D
@export var model: PackedScene
@export_range(1, 99) var max_stack: int = 1
@export_multiline var description: String = ""

# -- Weapon fields (used when `type` == "melee-weapon" or "ranged-weapon") --
## "one-handed" or "two-handed". Two-handed weapons display only in the right hand.
@export var grip: StringName = &"one-handed"
## Attack-animation speed multiplier (1.0 = base).
@export var speed: float = 1.0
## Damage dealt per successful hit.
@export var damage: float = 0.0
## Name of the animation the holding hand plays on attack (e.g. "right_slash", "shoot").
@export var attack_animation: StringName = &""
## Melee hitbox reach in meters.
@export var range: float = 1.5

# -- Ranged-weapon fields --
## Shots before a reload is required.
@export var clip_size: int = 0
## 0..1; lower accuracy tilts projectiles further off-aim.
@export var accuracy: float = 1.0
## Item id consumed per shot (e.g. "bolt").
@export var ammo_type: StringName = &""

func is_weapon() -> bool:
	return type == &"weapon" or type == &"melee-weapon" or type == &"ranged-weapon"

func is_melee() -> bool:
	return type == &"melee-weapon"

func is_ranged() -> bool:
	return type == &"ranged-weapon"

func is_two_handed() -> bool:
	return grip == &"two-handed"
