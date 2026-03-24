class_name State
extends Node

## Base state class for the player state machine

var player: CharacterBody3D
var state_machine: Node

func _ready() -> void:
	pass

## Called when entering the state
func enter() -> void:
	pass

## Called when exiting the state
func exit() -> void:
	pass

## Called every physics frame, returns the name of the next state or empty string to stay
func update(delta: float) -> String:
	return ""

## Called to handle input events
func handle_input(event: InputEvent) -> void:
	pass
