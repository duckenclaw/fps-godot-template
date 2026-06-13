extends CanvasLayer
## On-screen debug overlay.
##
## Autoloaded as "Debug" by the FP Framework plugin. Hidden until toggled with
## F3 (or a project-defined "debug_toggle" input action). Shows the FPS plus any
## values registered with watch():
##
##     Debug.watch("state", state_machine.current_state.name)
##
## Watches persist until updated, so call watch() each frame for live values.

const TOGGLE_KEYCODE := KEY_F3

var _label: Label
var _watches: Dictionary = {}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.position = Vector2(8, 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	_label = Label.new()
	_label.text = "FPS: 0"
	margin.add_child(_label)

func _input(event: InputEvent) -> void:
	var toggled := false
	if InputMap.has_action("debug_toggle") and event.is_action_pressed("debug_toggle"):
		toggled = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEYCODE:
		toggled = true
	if toggled:
		visible = not visible

func _process(_delta: float) -> void:
	if not visible:
		return
	var text := "FPS: %d" % Engine.get_frames_per_second()
	for key in _watches:
		text += "\n%s: %s" % [key, str(_watches[key])]
	_label.text = text

## Register or update a named value shown in the overlay.
func watch(key: String, value: Variant) -> void:
	_watches[key] = value

## Remove a watched value.
func unwatch(key: String) -> void:
	_watches.erase(key)
