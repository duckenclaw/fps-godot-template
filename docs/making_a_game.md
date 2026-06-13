# Making a Game From This Template

This template aims to get you from an empty project to a shippable first-person game by doing four
things: import assets, define data, build levels, and wire mechanics. Everything below builds on the
[FP Framework](framework.md) services.

## 1. Import your assets

Drop models, textures, sounds and music into `assets/`. Godot imports them automatically. For 3D
models, prefer `.glb`. For audio, put music and SFX anywhere under `assets/sounds/` — playback goes
through `AudioManager` on the correct bus.

## 2. Define your items

Items are data, not code. Create new `ItemResource` `.tres` files in `assets/resources/items/`
(copy an existing one like `sword.tres`). Give each a unique `id` — `ItemDB` indexes them by id and
the save system references them that way.

- Weapons set `type` (`melee-weapon` / `ranged-weapon`), `damage`, `attack_animation`, and `model`.
- Ranged weapons add `clip_size`, `accuracy`, `ammo_type`.
- Consumables/misc set `max_stack`, `weight`, `price`, `icon`.

## 3. Build a level

1. Duplicate `levels/level_template.tscn`. It already contains a `WorldEnvironment`, the
   `Environment`, a `Player` instance, a `SpawnPoint`, and a directional light.
2. Add your geometry (use `StaticBody3D` + collision for walls/floors).
3. Place **pickups**: instance `src/items/pickup.tscn` and set its `item` to one of your
   `ItemResource`s. (Add it to the `movable` group if you want it grabbable.)
4. Add **doors** (`src/objects/door.tscn`) and **movable objects** (`src/objects/movable_box.tscn`).
5. Register the level so it can be loaded by id:

   ```gdscript
   SceneManager.register_level("level_01", "res://levels/level_01.tscn")
   ```

   (Or add it to the `levels` dictionary in `scene_manager.gd`.)

## 4. Wire the flow

- **Start / transitions:** load levels with `SceneManager.change_scene("level_01")` — you get an
  async load and a fade for free. The main menu's Start button already does this.
- **Music:** call `AudioManager.play_music(track)` when a level loads (e.g. from a listener on
  `EventBus.level_loaded`).
- **Damage & death:** give enemies/destructibles a `Health` child and forward `take_damage`. The
  player already takes damage with difficulty scaling, screen shake and a HUD flash, and respawns via
  the most recent save on death.
- **Save/Load:** mark anything that should persist as `saveable` (the player already is). Quick
  save/load are on **F5 / F9**; call `SaveManager.save_game(slot)` from your own menus for slots.
- **Localization:** add UI strings to `assets/localization/translations.csv`. Static `Control` text
  is translated automatically; for code-built strings just keep the English text as the key.

## 5. Ship

- Set your real main scene / icon / name in **Project Settings**.
- Configure export presets (`export_presets.cfg`) for your platforms.
- Re-check the options menu (resolution/vsync/volume/language) persists as expected.

See [framework.md](framework.md) for the full API of each service.
