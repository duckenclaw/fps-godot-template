@tool
extends EditorPlugin
## Game Core editor plugin.
##
## Registers the core service-layer autoload singletons when the plugin is
## enabled and removes them when disabled, so dropping the addons/core folder
## into any Godot project wires up the whole service layer automatically.
##
## Order matters: EventBus must exist before Localization (which emits on it),
## hence the explicit ordered list rather than a Dictionary.

const AUTOLOADS := [
	["EventBus", "res://addons/core/event_bus.gd"],
	["SceneManager", "res://addons/core/scene_manager.gd"],
	["AudioManager", "res://addons/core/audio_manager.gd"],
	["SaveManager", "res://addons/core/save_manager.gd"],
	["Localization", "res://addons/core/localization.gd"],
	["Debug", "res://addons/core/debug_overlay.gd"],
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
