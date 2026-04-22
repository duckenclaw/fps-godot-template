# Settings System

The settings system manages all game configuration including graphics, audio, and gameplay options. It uses a singleton autoload (GameSettings) to persist settings between sessions and provides a comprehensive options menu UI for player customization. Settings are saved to disk only when the Apply button is clicked.

## Settings Categories

Graphics:
- Screen Mode: Windowed, Fullscreen, Borderless
- Resolution: Multiple presets (1920x1080, 1600x900, 1366x768, 1280x720, 1024x576)
- VSync: On/Off
- Brightness: 0-100%
- Field of View: 60-120 degrees

Audio:
- Master Volume: 0-100%
- Music Volume: 0-100%
- Effects Volume: 0-100%

Gameplay:
- Difficulty: Easy, Normal, Hard
- Mouse Sensitivity: 0-100% (mapped to 0.001-0.005)
- Camera Invert X: On/Off
- Camera Invert Y: On/Off

## Component Hierarchy

- GameSettings (Autoload Singleton)
  - Settings storage and persistence
  - ConfigFile save/load (user://settings.cfg)
  - Graphics application (window mode, resolution, vsync)
  - Audio application (AudioServer bus volumes)
  - FOV application (applies to player camera)
- OptionsScreen (UI)
  - Graphics tab (screen mode, resolution, vsync, brightness, fov)
  - Audio tab (master, music, effects sliders)
  - Gameplay tab (difficulty, sensitivity, invert options)
  - Controls tab (key rebinding)
  - Apply/Close buttons
- PlayerConfig (Resource)
  - Gameplay settings (difficulty, sensitivity, invert flags)
- Player
  - Loads settings from GameSettings on startup
  - Updates config when settings are applied

## File Locations

Core:
- `src/globals/game_settings.gd` - Settings singleton
- `src/ui/screens/options_screen.gd` - Options menu script
- `src/ui/screens/options_screen.tscn` - Options menu UI
- `src/player/player_config.gd` - Player configuration resource
- `assets/resources/master_bus.tres` - Audio bus layout (Master, Music, Effects)

Integration:
- `src/player/player.gd` - Loads settings on startup
- `src/player/camera_controller.gd` - Applies camera invert settings and FOV
- `project.godot` - GameSettings autoload registration

## How It Works

1. **Game Startup**: GameSettings loads settings from `user://settings.cfg`, applies graphics (resolution, vsync), audio, and brightness
2. **Player Spawn**: Player loads sensitivity, invert, difficulty, and FOV from GameSettings
3. **Options Menu**: User adjusts settings (audio, brightness, and FOV have live preview)
4. **Apply Button**: Saves all settings to disk, applies graphics changes (resolution, vsync), updates player config and camera FOV
5. **Runtime**: Settings persist until next Apply or game restart

## Settings Persistence

Settings are stored in `user://settings.cfg` using Godot's ConfigFile format:
- [graphics] - screen_mode, resolution_x, resolution_y, vsync_enabled, brightness, field_of_view
- [audio] - master_volume, music_volume, effects_volume
- [gameplay] - difficulty, mouse_sensitivity, invert_camera_x, invert_camera_y

Settings only save when Apply is clicked, allowing users to preview changes before committing.

## New Graphics Settings

### VSync
- Controls vertical synchronization to eliminate screen tearing
- Enabled by default for smoother visuals
- Applied immediately via DisplayServer.window_set_vsync_mode()
- Can be toggled in Graphics tab

### Brightness
- Range: 0-100% (50% = default, no change)
- Converts to 0.0-2.0 multiplier for rendering
- Applied via WorldEnvironment or post-processing
- Note: Implementation requires scene-level brightness control (e.g., DirectionalLight intensity or WorldEnvironment exposure)

### Field of View (FOV)
- Range: 60-120 degrees (90 = default)
- Applied directly to the player's Camera3D.fov
- Loaded on player spawn from GameSettings
- Updated in real-time when Apply is clicked
- Slider shows current value during adjustment
