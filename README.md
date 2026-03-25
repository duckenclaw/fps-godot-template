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
| Pause | Escape | Pause game |

All controls can be rebound in the Options > Controls menu.

## Project Structure

```
fps-godot-template/
├── assets/              # Game assets
│   ├── images/          # Images and textures
│   ├── resources/       # Godot resources (.tres)
│   └── styles/          # UI themes and styles
├── docs/                # Documentation
│   ├── player_controller.md           # Movement system overview
│   ├── player_controller_technical.md # Movement technical docs
│   ├── settings_system.md             # Settings overview
│   ├── settings_system_technical.md   # Settings technical docs
│   └── todo.md                        # Development roadmap
├── src/                 # Source code
│   ├── globals/         # Autoload singletons
│   ├── player/          # Player controller and states
│   ├── ui/              # User interface screens and components
│   └── world/           # World scenes and objects
└── project.godot        # Godot project file
```

## Documentation

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

Assign your AudioStreamPlayers to the appropriate bus for proper volume control through the settings menu.

## Contributing

Contributions are welcome! Please ensure:
- Code follows the existing style and patterns
- New features include documentation
- Changes are tested in Godot 4.6+

## License

This template is provided as-is for use in your projects. Feel free to modify and extend it as needed.

## Version

**Template Version:** 1.0
**Godot Version:** 4.6+
**Last Updated:** 2025-03-25
