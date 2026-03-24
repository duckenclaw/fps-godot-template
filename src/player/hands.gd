class_name Hands
extends Node3D

## Hands manager - manages both left and right hands

@onready var right_hand: Hand = $RightHand
@onready var left_hand: Hand = $LeftHand

func _ready() -> void:
	pass

## Handle left hand attack input
func use_left_hand() -> void:
	if left_hand:
		left_hand.attack()

## Handle right hand attack input
func use_right_hand() -> void:
	if right_hand:
		right_hand.attack()

## Equip item to right hand
func equip_right_hand(item: Node3D) -> void:
	if right_hand:
		right_hand.equip_item(item)

## Equip item to left hand
func equip_left_hand(item: Node3D) -> void:
	if left_hand:
		left_hand.equip_item(item)

## Unequip right hand
func unequip_right_hand() -> void:
	if right_hand:
		right_hand.unequip_item()

## Unequip left hand
func unequip_left_hand() -> void:
	if left_hand:
		left_hand.unequip_item()

## Get right hand reference
func get_right_hand() -> Hand:
	return right_hand

## Get left hand reference
func get_left_hand() -> Hand:
	return left_hand
