class_name StateMachine
extends Node

## State machine for managing player states

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Wait for player to be ready
	await owner.ready

	# Register all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = owner
			child.state_machine = self

	# Start with initial state
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float) -> void:
	# Don't process when paused
	if owner.has_method("is_paused") and owner.is_paused:
		return

	if current_state:
		var next_state_name = current_state.update(delta)
		if next_state_name != "":
			transition_to(next_state_name)

func _input(event: InputEvent) -> void:
	# Don't process when paused
	if owner.has_method("is_paused") and owner.is_paused:
		return

	if current_state:
		current_state.handle_input(event)

## Transition to a new state by name
func transition_to(state_name: String) -> void:
	var next_state = states.get(state_name.to_lower())

	if next_state == null:
		push_warning("State '%s' not found" % state_name)
		return

	if current_state:
		current_state.exit()

	current_state = next_state
	print("transitioning to state: " + get_current_state_name())
	print(owner.global_rotation)
	current_state.enter()

## Get the current state name
func get_current_state_name() -> String:
	return current_state.name if current_state else ""
