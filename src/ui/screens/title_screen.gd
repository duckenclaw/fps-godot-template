extends Control

signal continue_game(type: String)
signal open_options()
signal exit_game()

@onready var _start_button: Button = $MarginContainer/ButtonsContainer/Start3DButton


func _ready() -> void:
	# Grab focus so the menu is immediately navigable with a controller/keyboard.
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		_grab_default_focus()


func _on_visibility_changed() -> void:
	if visible:
		_grab_default_focus()


func _grab_default_focus() -> void:
	if _start_button:
		_start_button.call_deferred("grab_focus")


func _on_start_button_pressed():
	continue_game.emit("2D")

func _on_start_3d_button_pressed():
	continue_game.emit("3D")

func _on_options_button_pressed():
	open_options.emit()


func _on_exit_button_pressed():
	exit_game.emit()
