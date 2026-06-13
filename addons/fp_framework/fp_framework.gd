@tool
extends EditorPlugin
## FP Framework editor plugin.
##
## Registers the framework's autoload singletons when the plugin is enabled and
## removes them when disabled, so dropping the addons/fp_framework folder into
## any Godot project wires up the whole service layer automatically.
##
## Order matters: EventBus must exist before Localization (which emits on it),
## hence the explicit ordered list rather than a Dictionary.

const AUTOLOADS := [
	["EventBus", "res://addons/fp_framework/event_bus.gd"],
	["SceneManager", "res://addons/fp_framework/scene_manager.gd"],
	["AudioManager", "res://addons/fp_framework/audio_manager.gd"],
	["SaveManager", "res://addons/fp_framework/save_manager.gd"],
	["Localization", "res://addons/fp_framework/localization.gd"],
	["Debug", "res://addons/fp_framework/debug_overlay.gd"],
]

func _enter_tree() -> void:
	for entry in AUTOLOADS:
		var singleton_name: String = entry[0]
		if not ProjectSettings.has_setting("autoload/" + singleton_name):
			add_autoload_singleton(singleton_name, entry[1])

func _exit_tree() -> void:
	for entry in AUTOLOADS:
		var singleton_name: String = entry[0]
		if ProjectSettings.has_setting("autoload/" + singleton_name):
			remove_autoload_singleton(singleton_name)
