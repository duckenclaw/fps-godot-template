extends Node
## Localization manager.
##
## Autoloaded as "Localization" by the FP Framework plugin. A thin wrapper over
## Godot's TranslationServer that also persists the chosen locale through
## GameSettings so it survives restarts. UI should use tr("KEY"); changing the
## locale here re-translates everything automatically.

const DEFAULT_LOCALE := "en"

func _ready() -> void:
	var saved := DEFAULT_LOCALE
	var gs := get_node_or_null("/root/GameSettings")
	if gs and "locale" in gs and String(gs.locale) != "":
		saved = String(gs.locale)
	set_language(saved)

## Locales that have a loaded translation (e.g. ["en", "fr", ...]).
func get_languages() -> PackedStringArray:
	return TranslationServer.get_loaded_locales()

## Switch the active locale, persist it, and announce the change.
func set_language(locale: String) -> void:
	TranslationServer.set_locale(locale)
	var gs := get_node_or_null("/root/GameSettings")
	if gs and "locale" in gs:
		gs.locale = locale
		if gs.has_method("save_settings"):
			gs.save_settings()
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.setting_changed.emit("locale", locale)

func get_current_language() -> String:
	return TranslationServer.get_locale()
