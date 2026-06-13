# FP Framework (Core Service Layer)

The reusable, genre-agnostic services live in the **`addons/fp_framework/`** plugin. Enabling the
plugin registers a set of autoload singletons; dropping the folder into any Godot project wires them
up automatically (the plugin's `_enter_tree()` calls `add_autoload_singleton`).

| Autoload | File | Responsibility |
|----------|------|----------------|
| `EventBus` | `event_bus.gd` | Global, signal-only hub for decoupled gameplay events |
| `SceneManager` | `scene_manager.gd` | Async scene loading, fade transitions, level registry |
| `AudioManager` | `audio_manager.gd` | Music crossfade + pooled one-shot 2D/3D SFX |
| `SaveManager` | `save_manager.gd` | Slotted save/load of game **state** (not preferences) |
| `Localization` | `localization.gd` | Locale switching on top of Godot's TranslationServer |
| `Debug` | `debug_overlay.gd` | Toggleable on-screen FPS + watch overlay (F3) |

> `GameSettings` (`src/globals/game_settings.gd`) stays in the project itself: it holds the
> project-specific **preferences** schema (audio/video/controls/locale). The framework services are
> the parts that are identical across any first-person project.

---

## EventBus

A signal-only node. Emit and connect from anywhere — neither side needs a reference to the other.

```gdscript
# Listen (e.g. in a quest tracker)
EventBus.entity_died.connect(_on_entity_died)

# Announce (done for you by Health / Player / SceneManager)
EventBus.damage_dealt.emit(target, amount, source)
```

Signals: `damage_dealt(target, amount, source)`, `entity_died(entity)`,
`item_picked_up(item, count)`, `level_loading(path)`, `level_loaded(path)`, `setting_changed(key, value)`.

## SceneManager

Replaces scattered `get_tree().change_scene_to_*` calls. Loads scenes on a background thread, plays
a fade, and lets you refer to levels by id.

```gdscript
SceneManager.register_level("level_01", "res://levels/level_01.tscn")
SceneManager.change_scene("level_01")          # by id
SceneManager.change_scene("res://levels/x.tscn")  # or by path
SceneManager.reload_current_scene()            # e.g. on death without a save

SceneManager.load_progress.connect(func(p): print(p))  # for a loading bar
```

It unpauses the tree during a transition, so pause-menu → main-menu "just works".

## AudioManager

```gdscript
AudioManager.play_music(my_track)              # crossfades from the current track
AudioManager.stop_music()
AudioManager.play_sfx(ui_click)                # pooled, non-positional
AudioManager.play_sfx_3d(impact, hit_position) # positional, frees itself
```

Music plays on the **Music** bus, SFX on the **Effects** bus — both driven by the volumes in the
options menu. (The project's `master_bus.tres` is registered as the default bus layout in
`project.godot`.)

## SaveManager

Saves game **state** to `user://saves/slot_N.save` (JSON). This is separate from `GameSettings`,
which stores preferences. Any node can persist by joining the `saveable` group and implementing the
contract:

```gdscript
var save_id := "player"            # optional stable key (else the node path is used)

func save_data() -> Dictionary:    # return JSON-friendly values only
    return {"hp": hp}

func load_data(data: Dictionary) -> void:
    hp = data.get("hp", hp)
```

```gdscript
SaveManager.save_game(0)
SaveManager.load_game(0)           # loads the saved scene first if needed, then restores
SaveManager.list_saves()           # -> [0, 1, ...]
```

The `Player` and the reusable `Health` component already implement this contract. **Quick save/load**
are bound to **F5 / F9**.

> Convert non-JSON types yourself (e.g. store a `Vector3` as `[x, y, z]`) — see `Player.save_data()`.

## Localization

A thin wrapper over `TranslationServer` that persists the chosen locale via `GameSettings.locale`.

```gdscript
Localization.set_language("es")
Localization.get_languages()       # -> ["en", "es"]
```

Translations live in `assets/localization/translations.csv` and are registered in `project.godot`
(`[internationalization]`). The CSV uses the **English source string as the key**, so Godot's
automatic `Control` translation localizes static UI text with no scene edits; add a locale column and
fill in rows to support a new language. The options menu has a **Language** dropdown built at runtime
from the loaded locales.

## Debug overlay

Press **F3** (or trigger the `debug_toggle` action). Register live values from anywhere:

```gdscript
Debug.watch("state", state_machine.current_state.name)
Debug.watch("speed", velocity.length())
```

---

## Project-side building blocks (in `src/`, not the addon)

These are gameplay-specific but reusable within the template:

- **`Health`** (`src/components/health.gd`) — attribute component with `health_changed` / `damaged` /
  `died` signals, optional difficulty scaling, and the save contract. Add it as a child of any
  damageable entity and forward `take_damage(amount, source)` to it.
- **`ItemDB`** (`src/items/item_db.gd`) — scans `assets/resources/items/*.tres` and maps
  `ItemResource.id → resource`, so saves can store item ids. `ItemDB.get_item(&"sword")`.
- **`Utils`** (`src/globals/utils.gd`) — static helpers: `remap_range`, `remap_clamped`,
  `weighted_pick`, `random_element`, `damp`, `format_time`.
