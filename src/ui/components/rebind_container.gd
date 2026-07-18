extends HBoxContainer

## A single remappable action row. Handles either the keyboard/mouse binding or
## the controller binding of an action, chosen by `device_type`, so one action can
## carry both a key and a pad binding at once (they live side by side in the
## action's event list and this row only ever touches its own device's events).

@export var action: String = "Unassigned"
## "keyboard" (keyboard + mouse events) or "controller" (joypad button/axis events).
@export var device_type: String = "keyboard"

@onready var action_name: Label = $Name
@onready var action_hotkey: Button = $Hotkey

var _listening: bool = false

func _ready() -> void:
	# Grouped per-device so the "disable others while listening" logic only affects
	# rows of the same device (and actually works — the old code never joined a group).
	add_to_group("RebindContainer_" + device_type)
	set_process_input(false)
	set_action_name()
	set_action_hotkey()

# set label of the action to the name of the action
func set_action_name() -> void:
	action_name.text = action.capitalize()

# set text of the rebind button to the bound input matching this row's device
func set_action_hotkey() -> void:
	var event := _get_matching_event()
	action_hotkey.text = _event_to_text(event) if event != null else "—"

## First event on this action that belongs to this row's device (or null).
func _get_matching_event() -> InputEvent:
	if not InputMap.has_action(action.to_lower()):
		return null
	for e in InputMap.action_get_events(action.to_lower()):
		if _matches_device(e):
			return e
	return null

func _matches_device(event: InputEvent) -> bool:
	if device_type == "controller":
		return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return event is InputEventKey or event is InputEventMouseButton


func _on_hotkey_rebind_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_start_listening()
	else:
		_stop_listening()

func _start_listening() -> void:
	_listening = true
	action_hotkey.text = "..."
	set_process_input(true)
	for row in get_tree().get_nodes_in_group("RebindContainer_" + device_type):
		if row != self:
			row.action_hotkey.disabled = true

func _stop_listening() -> void:
	_listening = false
	set_process_input(false)
	for row in get_tree().get_nodes_in_group("RebindContainer_" + device_type):
		if row != self:
			row.action_hotkey.disabled = false
	set_action_hotkey()

func _input(event: InputEvent) -> void:
	if not _listening:
		return
	if not _is_acceptable(event):
		return
	get_viewport().set_input_as_handled()
	rebind_action_hotkey(event)

## Accept only meaningful presses for this row's device.
func _is_acceptable(event: InputEvent) -> bool:
	if device_type == "controller":
		if event is InputEventJoypadButton:
			return event.pressed
		if event is InputEventJoypadMotion:
			return absf(event.axis_value) > 0.5
		return false
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	return false

func rebind_action_hotkey(event: InputEvent) -> void:
	var act := action.to_lower()
	var new_event := _normalize(event)
	# Erase only this device's existing events so the other device's binding survives.
	for e in InputMap.action_get_events(act):
		if _matches_device(e):
			InputMap.action_erase_event(act, e)
	InputMap.action_add_event(act, new_event)
	# Untoggling fires _on_hotkey_rebind_toggled(false) -> _stop_listening() -> refresh.
	action_hotkey.button_pressed = false

## Store a clean, reusable event (e.g. full-deflection trigger/axis on the same side).
func _normalize(event: InputEvent) -> InputEvent:
	if event is InputEventJoypadMotion:
		var m := InputEventJoypadMotion.new()
		m.axis = event.axis
		m.axis_value = 1.0 if event.axis_value > 0.0 else -1.0
		return m
	return event

# ---------- display helpers ----------

func _event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return _mouse_button_name(event.button_index)
	if event is InputEventJoypadButton:
		return joy_button_name(event.button_index)
	if event is InputEventJoypadMotion:
		return joy_axis_name(event.axis, event.axis_value)
	return "?"

func _mouse_button_name(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT: return "Mouse Left"
		MOUSE_BUTTON_RIGHT: return "Mouse Right"
		MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
		MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
		_: return "Mouse %d" % index

func joy_button_name(index: int) -> String:
	match index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_BACK: return "Back"
		JOY_BUTTON_GUIDE: return "Guide"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_LEFT_STICK: return "L-Stick Click"
		JOY_BUTTON_RIGHT_STICK: return "R-Stick Click"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_DPAD_UP: return "D-Pad Up"
		JOY_BUTTON_DPAD_DOWN: return "D-Pad Down"
		JOY_BUTTON_DPAD_LEFT: return "D-Pad Left"
		JOY_BUTTON_DPAD_RIGHT: return "D-Pad Right"
		_: return "Button %d" % index

func joy_axis_name(axis: int, value: float = 1.0) -> String:
	match axis:
		JOY_AXIS_TRIGGER_LEFT: return "LT"
		JOY_AXIS_TRIGGER_RIGHT: return "RT"
		JOY_AXIS_LEFT_X: return "L-Stick %s" % ("Right" if value > 0 else "Left")
		JOY_AXIS_LEFT_Y: return "L-Stick %s" % ("Down" if value > 0 else "Up")
		JOY_AXIS_RIGHT_X: return "R-Stick %s" % ("Right" if value > 0 else "Left")
		JOY_AXIS_RIGHT_Y: return "R-Stick %s" % ("Down" if value > 0 else "Up")
		_: return "Axis %d" % axis
