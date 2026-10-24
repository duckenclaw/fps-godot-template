# Modular Addons & Roadmap

This template is organised as a set of reusable Godot addons so that most of it
can be shared across games of different genres. This document describes the
addons, how they depend on each other, and the plan for distributing them.

## The five addons

All live under `addons/`. Each has its own `plugin.cfg` and can be enabled,
disabled, or published to the Godot Asset Library independently.

### core — *shared*
Game-agnostic service layer, registered as autoload singletons by its plugin:
`EventBus`, `SceneManager`, `AudioManager`, `SaveManager`, `Localization`, `Debug`.
`SceneManager` ships with an empty level registry — each game registers its own
level ids with `SceneManager.register_level(id, path)` (this template does so in
`src/ui/main_menu.gd`).

### settings_kit — *shared*
- `SettingsManager` (`class_name`): persists and applies graphics, audio, gameplay,
  controller and localization settings to `user://settings.cfg`, plus saves/loads
  rebindable key **and** gamepad bindings. It carries no project-specific data; the
  game supplies the action list via the `rebindable_actions` property.
- `RebindContainer` (scene + script): a single remappable action row that edits
  only its own device's binding, so one action can hold a key and a pad binding at
  once.

A game registers its own settings autoload that extends `SettingsManager`. Here,
`src/globals/game_settings.gd` does exactly that and sets this game's action list.

### inventory_kit — *shared*
Pure data/logic with no 2D/3D dependency: `ItemResource` (item data, incl. optional
weapon fields), `ItemDB` (id → resource registry; point `ItemDB.items_dir` at your
items folder), grid `Inventory` (stacking, quick-slots, weight/value), and
`InventorySlot`. Directly reusable in 2D, top-down or 3D games.

### components_kit — *shared*
- `Health`: event-driven, difficulty-scaled, saveable health component.
- `StateMachine` + `State`: a genre-agnostic node state machine. `State.player` is
  the owning actor and is deliberately untyped, so the same machine drives a 3D
  player, a 2D character, an enemy or an NPC.

### fps_controller — *FPS only*
This template's genre layer: the first-person player scene, movement states
(walk/sprint/crouch/slide/dash/wallrun), mouse + gamepad camera (head-bob, tilt,
FOV, shake), the hands viewmodel system, a grab controller for physics objects, a
projectile, example world props (door, box, walls, ramps), and the FPS gameplay and
menu UI (HUD, pause, options, inventory screen). Depends on `core`,
`components_kit` and `inventory_kit`.

## Dependency rules

- Game code in `src/` may depend on any addon.
- `fps_controller` depends on `core` + `components_kit` + `inventory_kit`.
- The four shared kits never reference game `src/` code, so they can be lifted into
  their own repositories unchanged.

The app shell that stays in `src/` is intentionally small: `main_menu` +
`title_screen` (the screens you customise per game), `GameSettings`, `Utils`, the
demo level, and environment resources.

## Roadmap — the "megatemplate" ecosystem

Phase 1 (this repo) is done: the code is split into the five addons above and the
FPS demo still runs. The remaining phases turn this into a shareable ecosystem:

1. **Extract the shared kits** (`core`, `settings_kit`, `inventory_kit`,
   `components_kit`) into their own git repositories, preserving history with
   `git subtree split`.
2. **Hub repo** (`godot-game-kit`) aggregates the kit repos as submodules, with a
   demo project that exercises every shared kit, shared docs, CI, and versioning.
3. **Publish** each shared kit to the Godot Asset Library; document both install
   paths (git submodule and Asset Library).
4. **Per-genre template repos** — `fps-template` (this repo), `third-person-template`,
   `2d-sidescroller-template`, `topdown-template` — each a GitHub "template
   repository" that pulls the shared kits as submodules and adds its own genre
   controller (`fps_controller`, `third_person_controller`, `platformer_controller_2d`,
   `topdown_controller`). The genre controllers reuse the same four shared kits.

New genres get the whole shared base (services, settings/rebinding, items/inventory,
health, state machine) for free and only implement their own controller + a genre
settings adapter (e.g. 2D games skip FOV/mouse-look and remap "look" to zoom/aim).
