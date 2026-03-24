class_name Hand
extends Node3D

## Hand controller - handles item equipping and attacking

@export var is_right_hand: bool = true

var equipped_item: Node3D = null

func _ready() -> void:
	pass

## Equip an item to this hand
func equip_item(item: Node3D) -> void:
	# Remove current item if any
	if equipped_item:
		unequip_item()

	equipped_item = item
	add_child(equipped_item)

	# Reset item position and rotation
	equipped_item.position = Vector3.ZERO
	equipped_item.rotation = Vector3.ZERO

## Unequip the current item
func unequip_item() -> void:
	if equipped_item:
		remove_child(equipped_item)
		equipped_item = null

## Perform attack with equipped item
func attack() -> void:
	if equipped_item and equipped_item.has_method("attack"):
		equipped_item.attack()

## Get the currently equipped item
func get_equipped_item() -> Node3D:
	return equipped_item

## Check if hand has an item equipped
func has_item() -> bool:
	return equipped_item != null
