extends Node
## Global scene / level manager.
##
## Autoloaded as "SceneManager" by the FP Framework plugin. Replaces scattered
## `get_tree().change_scene_to_*` calls with a single entry point that:
##   - loads scenes asynchronously (no hitch on large levels),
##   - plays a fade transition,
##   - exposes a level registry so levels are referenced by id, not raw path,
##   - announces lifecycle through EventBus (level_loading / level_loaded).
##
## Usage:
##   SceneManager.change_scene("main_menu")              # by registered id
##   SceneManager.change_scene("res://levels/foo.tscn")  # or by direct path

const TRANSITION_SCENE := preload("res://addons/fp_framework/transition.tscn")

## Emitted during async load with a 0.0..1.0 progress value (for loading screens).
signal load_progress(progress: float)

## Level registry: id -> scene path. Add to this with register_level() so the
## rest of the game can refer to levels by a stable id.
var levels: Dictionary = {
	"main_menu": "res://src/ui/main_menu.tscn",
	"level_template": "res://levels/level_template.tscn",
}

var _transition: CanvasLayer
var _color_rect: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	# Keep working while the tree is paused (pause menu -> main menu, etc.).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_transition = TRANSITION_SCENE.instantiate()
	add_child(_transition)
	_color_rect = _transition.get_node("ColorRect")
	_color_rect.modulate.a = 0.0

## Register (or override) a level id -> path mapping.
func register_level(id: String, path: String) -> void:
	levels[id] = path

## Resolve a level id to a scene path. If it isn't a known id, it is assumed to
## already be a resource path and returned unchanged.
func resolve(id_or_path: String) -> String:
	return levels.get(id_or_path, id_or_path)

## Change to a scene by level id or resource path, with a fade transition and
## threaded loading. Returns when the new scene is in the tree and faded in.
func change_scene(id_or_path: String, fade_time: float = 0.4) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	var path := resolve(id_or_path)
	EventBus.level_loading.emit(path)

	await _fade(1.0, fade_time)

	# In case we came from a paused state (e.g. the pause menu).
	get_tree().paused = false

	var packed := await _load_threaded(path)
	if packed == null:
		push_error("SceneManager: failed to load scene '%s'" % path)
		await _fade(0.0, fade_time)
		_is_transitioning = false
		return

	get_tree().change_scene_to_packed(packed)
	# Wait a frame so the new scene's _ready has run before we reveal it.
	await get_tree().process_frame
	await _fade(0.0, fade_time)

	_is_transitioning = false
	EventBus.level_loaded.emit(path)

## Reload the currently active scene (e.g. on player death without a save).
func reload_current_scene(fade_time: float = 0.4) -> void:
	var current := get_tree().current_scene
	if current and current.scene_file_path != "":
		await change_scene(current.scene_file_path, fade_time)

func _load_threaded(path: String) -> PackedScene:
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		return null
	var progress: Array = []
	while true:
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				load_progress.emit(progress[0] if progress.size() > 0 else 0.0)
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				load_progress.emit(1.0)
				return ResourceLoader.load_threaded_get(path)
			_:
				return null
	return null

func _fade(target_alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_color_rect.modulate.a = target_alpha
		return
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", target_alpha, duration)
	await tween.finished
