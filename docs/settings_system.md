# Settings System

The settings system manages all game configuration including graphics, audio, and gameplay options. It uses a singleton autoload (GameSettings) to persist settings between sessions and provides a comprehensive options menu UI for player customization. Settings are saved to disk only when the Apply button is clicked.

## Settings Categories

Graphics:
- Screen Mode: Windowed, Fullscreen, Borderless
- Resolution: Multiple presets (1920x1080, 1600x900, 1366x768, 1280x720, 1024x576)

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
  - Graphics application (window mode, resolution)
  - Audio application (AudioServer bus volumes)
- OptionsScreen (UI)
  - Graphics tab (screen mode, resolution)
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
- `src/player/camera_controller.gd` - Applies camera invert settings
- `project.godot` - GameSettings autoload registration

## How It Works

1. **Game Startup**: GameSettings loads settings from `user://settings.cfg`, applies graphics and audio
2. **Player Spawn**: Player loads sensitivity, invert, and difficulty from GameSettings
3. **Options Menu**: User adjusts settings (audio has live preview)
4. **Apply Button**: Saves all settings to disk, applies graphics changes, updates player config
5. **Runtime**: Settings persist until next Apply or game restart

## Settings Persistence

Settings are stored in `user://settings.cfg` using Godot's ConfigFile format:
- [graphics] - screen_mode, resolution_x, resolution_y
- [audio] - master_volume, music_volume, effects_volume
- [gameplay] - difficulty, mouse_sensitivity, invert_camera_x, invert_camera_y

Settings only save when Apply is clicked, allowing users to preview changes before committing.
