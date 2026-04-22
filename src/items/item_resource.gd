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
