extends Control

## Level id the "Start" button loads. Registered with SceneManager so levels are
## referenced by a stable id instead of a hard-coded path scattered across menus.
const START_LEVEL_ID := "level_test"
const START_LEVEL_PATH := "res://src/test_3D.tscn"

@onready var title_screen: Control = $TitleScreen
@onready var options_screen: Control = $OptionsScreen

func _ready() -> void:
	SceneManager.register_level(START_LEVEL_ID, START_LEVEL_PATH)

func _change_screen(screen: Control):
	# Disable all screens before turning on the target screen
	title_screen.visible = false
	options_screen.visible = false

	screen.visible = true

func _on_continue_game(type: String):
	# `type` is kept for compatibility with the title screen signal; the 3D level
	# is the production entry point. Route through SceneManager for the fade
	# transition and async load.
	SceneManager.change_scene(START_LEVEL_ID)

func _on_open_options():
	_change_screen(options_screen)

func _on_exit_game():
	get_tree().quit(0)

func _on_close_options():
	_change_screen(title_screen)
