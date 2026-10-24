class_name State
extends Node

## Base state class for a StateMachine.
##
## Genre-agnostic: `player` is the owning actor and is intentionally untyped so
## this base works for any node (a CharacterBody3D player, a CharacterBody2D, an
## enemy, an NPC). Concrete states access it dynamically, or declare their own
## typed accessor if they want static checking, e.g.:
##     @onready var body: CharacterBody3D = player

## The owning actor, assigned by StateMachine from its `owner`.
var player
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
