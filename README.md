# FPS Godot Template

A comprehensive first-person shooter template for Godot 4.6+ featuring advanced movement mechanics, state-based architecture, and a complete settings system.

## Features

### Advanced Movement System
- **State-Based Movement:** Clean state machine architecture for managing player behavior
- **Multiple Movement States:**
  - Idle and walking
  - Sprinting (forward only)
  - Jumping with variable height and coyote time
  - Dashing in camera direction
  - Sliding with momentum
  - Wallrunning with wall detection
- **Smooth Camera:** Head bobbing, FOV changes, camera tilt, and screen shake
- **Full documentation:** See [Player Controller Overview](docs/player_controller.md) and [Technical Documentation](docs/player_controller_technical.md)

### Comprehensive Settings System
- **Graphics:** Screen mode (Windowed/Fullscreen/Borderless), Resolution selection
- **Audio:** Separate volume controls for Master, Music, and Effects
- **Gameplay:** Difficulty settings, Mouse sensitivity, Camera invert options
- **Persistent Storage:** Settings save to disk and persist between sessions
- **Live Preview:** Audio changes can be heard immediately
- **Full documentation:** See [Settings System Overview](docs/settings_system.md) and [Technical Documentation](docs/settings_system_technical.md)

### User Interface
- HUD with health, mana, and stamina displays
- Main menu with play and options
- Pause menu
- Options screen with tabbed interface
- Key rebinding system

### Production Systems (Game Core addon)
- **EventBus:** decoupled, signal-driven gameplay events
- **SceneManager:** async level loading with fade transitions and a level registry
- **AudioManager:** music crossfade + pooled 2D/3D sound effects
- **SaveManager:** slotted save/load of game state (quick save/load on F5/F9)
- **Localization:** CSV-based translations with an in-game language selector
- **Debug overlay:** toggleable FPS/watch display (F3)
- Reusable **Health** component, **ItemDB** registry, and **Utils** helpers

See **[Game Core](docs/framework.md)** for details.

## Getting Started

### Prerequisites
- Godot Engine 4.6 or later
- Basic familiarity with Godot and GDScript

### How to Use
1. Clone or download this repository
2. Open the project in Godot 4.6+
3. Run the project (F5) or open the main scene
4. Press ESC to access the pause menu and options

### Default Controls

| Action | Key | Description |
|--------|-----|-------------|
| Move Forward | W | Move forward |
| Move Backward | S | Move backward |
| Move Left | A | Strafe left |
| Move Right | D | Strafe right |
| Jump | Space | Jump (hold for higher jump) |
| Sprint | Shift | Sprint while moving forward |
| Crouch | C | Crouch or slide if moving |
| Dash | V | Dash in camera direction |
| Interact | F | Interact with objects |
| Tilt Left | Q | Camera tilt left |
| Tilt Right | E | Camera tilt right |
| Inventory | I | Open/close inventory |
| Quick Save | F5 | Save game to slot 0 |
| Quick Load | F9 | Load game from slot 0 |
| Debug Overlay | F3 | Toggle the FPS / watch overlay |
| Pause | Escape | Pause game |

All controls can be rebound in the Options > Controls menu.

## Project Structure

```
fps-godot-template/
├── addons/                  # Reusable, shareable kits — see Modular Addon Architecture
│   ├── core/                # Service layer autoloads: EventBus, SceneManager,
│   │                        #   AudioManager, SaveManager, Localization, Debug
│   ├── settings_kit/        # SettingsManager base + key/gamepad rebind-row UI
│   ├── inventory_kit/       # ItemResource, ItemDB, Inventory, InventorySlot
│   ├── components_kit/      # Health component, StateMachine + State base
│   └── fps_controller/      # FPS genre kit: player, camera, hands, movement
│                            #   states, grab controller, projectile, props, UI
├── assets/                  # Images, models, sounds, localization, item .tres, styles
├── docs/                    # Documentation (see Documentation section below)
├── levels/                  # Level scenes (start from level_template.tscn)
├── src/                     # This template's game-specific code (not the kits)
│   ├── globals/             # GameSettings (extends SettingsManager) + Utils
│   ├── environments/        # WorldEnvironment resources
│   ├── ui/                  # App shell: main menu + title screen
│   └── test_3D.tscn         # Demo level entry point
└── project.godot            # Godot project file
```

## Modular Addon Architecture

The template is split into five self-contained addons under `addons/`, so the
reusable parts can be shared across games (FPS, third-person, 2D, top-down) while
each game keeps only its own code in `src/`. Four of the five are **game-agnostic**
and intended to be shared verbatim between projects; `fps_controller` is this
template's FPS-specific genre layer.

| Addon | What it provides | Shared across genres? |
|-------|------------------|-----------------------|
| **core** | `EventBus`, `SceneManager`, `AudioManager`, `SaveManager`, `Localization`, `Debug` autoloads | Yes |
| **settings_kit** | `SettingsManager` base (graphics/audio/gameplay/controller/locale persistence + key & gamepad rebinding) and the `RebindContainer` UI | Yes |
| **inventory_kit** | `ItemResource`, `ItemDB`, grid `Inventory`, `InventorySlot` — pure data/logic, no 2D/3D dependency | Yes |
| **components_kit** | `Health` component and a genre-agnostic `StateMachine` + `State` base | Yes |
| **fps_controller** | First-person player, camera, hands viewmodel, movement states, grab controller, projectile, example props, and the FPS gameplay/menu UI | No — FPS only |

**Dependency direction:** your game's `src/` code may depend on the addons, and
`fps_controller` depends on `core` + `components_kit` + `inventory_kit`. The four
shared kits never reference game `src/` code, so they can be lifted out into their
own repositories unchanged. This repo's `GameSettings` autoload
(`src/globals/game_settings.gd`) is a thin subclass of `settings_kit`'s
`SettingsManager` that only supplies this game's rebindable action list.

This is the first step of a larger plan: extract the four shared kits into their
own repositories (consumed by per-genre template repos via git submodule and the
Godot Asset Library), with this repo becoming the canonical FPS template. See
**[Modular Addons & Roadmap](docs/addons.md)**.

## Documentation

### Framework & Workflow
- **[Game Core](docs/framework.md)** - The reusable service layer: EventBus, SceneManager, AudioManager, SaveManager, Localization, Debug, plus the Health/ItemDB/Utils building blocks
- **[Making a Game](docs/making_a_game.md)** - End-to-end guide: import assets → define items → build levels → wire mechanics → ship

### Player Controller
- **[Player Controller Overview](docs/player_controller.md)** - Quick reference for movement states and components
- **[Player Controller Technical](docs/player_controller_technical.md)** - In-depth implementation details, API reference, and integration guide

### Settings System
- **[Settings System Overview](docs/settings_system.md)** - Quick reference for settings categories and persistence
- **[Settings System Technical](docs/settings_system_technical.md)** - In-depth implementation details, API reference, and integration guide

### Development
- **[Todo List](docs/todo.md)** - Development roadmap and planned features

## Key Systems

### State Machine Architecture

The player uses a clean state machine pattern for movement:
- Each state handles its own physics and transitions
- States communicate through the central Player controller
- Easy to add new movement states or modify existing ones

See [Player Controller Technical](docs/player_controller_technical.md#state-machine) for details.

### Settings Management

Settings are managed through a global singleton with persistent storage:

```gdscript
# Access settings anywhere in your code
var sensitivity = GameSettings.mouse_sensitivity
var difficulty = GameSettings.difficulty

# Settings are automatically loaded on startup
# and saved when the player clicks Apply in options
```

See [Settings System Technical](docs/settings_system_technical.md#integration-guide) for integration details.

### Component-Based Design

The template uses a modular component approach:
- **PlayerConfig:** Resource-based configuration for easy tuning
- **CameraController:** Independent camera system
- **StateMachine:** Reusable state management
- **Hands:** Weapon/item system foundation

This makes it easy to extend or modify specific systems without affecting others.

## Extending the Template

### Adding New Movement States

1. Create a new state script extending `State`
2. Implement `enter()`, `exit()`, `update(delta)`, and `physics_update(delta)`
3. Add the state as a child of StateMachine
4. Define transition conditions in the state's `physics_update()`

See [Player Controller Technical - Adding States](docs/player_controller_technical.md) for details.

### Adding New Settings

1. Add variable to `GameSettings` singleton
2. Add load/save logic in `load_settings()` and `save_settings()`
3. Add UI control to `options_screen.tscn`
4. Connect the control and handle in `options_screen.gd`
5. Update `_on_apply_button_pressed()` to include new setting

See [Settings System Technical - Adding Settings](docs/settings_system_technical.md#adding-new-settings) for step-by-step guide.

### Customizing Movement

All movement parameters are exposed in `PlayerConfig`:
- Movement speeds (walk, sprint, crouch, slide, wallrun)
- Jump settings (height, coyote time)
- Dash settings (speed, duration)
- Camera settings (sensitivity, FOV, head bob)
- And more...

Edit the default values in `src/player/player_config.gd` or create custom resource presets.

## Audio System

The template includes a 3-bus audio setup:
- **Master:** Overall volume control
- **Music:** Background music (child of Master)
- **Effects:** Sound effects (child of Master)

Assign your AudioStreamPlayers to the appropriate bus for proper volume control through the settings menu. `master_bus.tres` is registered as the project's default bus layout. For runtime playback, prefer the **AudioManager** autoload (`play_music`, `play_sfx`, `play_sfx_3d`) — see [Game Core](docs/framework.md#audiomanager).

## Contributing

Contributions are welcome! Please ensure:
- Code follows the existing style and patterns
- New features include documentation
- Changes are tested in Godot 4.6+

## License

This template is provided as-is for use in your projects. Feel free to modify and extend it as needed.

## Version

**Template Version:** 1.1
**Godot Version:** 4.6+
**Last Updated:** 2026-06-13
