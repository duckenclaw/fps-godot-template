class_name Hands
extends Node3D

## Hands manager — manages both left and right hands and exposes resource-aware
## equip helpers used by the player.

@onready var right_hand: Hand = $RightHand
@onready var left_hand: Hand = $LeftHand

func _ready() -> void:
	pass

## Trigger an attack with the left hand.
func use_left_hand() -> void:
	if left_hand:
		left_hand.attack()

## Trigger an attack with the right hand.
func use_right_hand() -> void:
	if right_hand:
		right_hand.attack()

## Equip an ItemResource to the right hand (spawns its model).
func equip_right_hand(item_res: ItemResource) -> void:
	if right_hand:
		right_hand.equip_resource(item_res)

## Equip an ItemResource to the left hand.
func equip_left_hand(item_res: ItemResource) -> void:
	if left_hand:
		left_hand.equip_resource(item_res)

func unequip_right_hand() -> void:
	if right_hand:
		right_hand.unequip_item()

func unequip_left_hand() -> void:
	if left_hand:
		left_hand.unequip_item()

func get_right_hand() -> Hand:
	return right_hand

func get_left_hand() -> Hand:
	return left_hand
