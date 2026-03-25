# Settings System - Technical Documentation

## Overview

This document provides technical details about the implementation of the settings system. The settings system is a persistent configuration management system that handles graphics, audio, and gameplay options. It uses a singleton autoload pattern for global access and provides a comprehensive UI for player customization.

## Architecture

The settings system uses a centralized singleton (GameSettings) that manages all configuration data and persistence. The OptionsScreen UI provides the interface for modifying settings, which are only saved when the Apply button is clicked. Settings are integrated with the player system through PlayerConfig and CameraController.

### Component Hierarchy

```
GameSettings (Autoload Singleton)
├── Settings Storage (Variables)
├── ConfigFile Management (user://settings.cfg)
├── Graphics Application (DisplayServer API)
└── Audio Application (AudioServer API)

OptionsScreen (UI Control)
├── TabContainer
│   ├── Graphics Tab
│   │   ├── Screen Mode (OptionButton)
│   │   └── Resolution (OptionButton)
│   ├── Audio Tab
│   │   ├── Master Volume (HSlider)
│   │   ├── Music Volume (HSlider)
│   │   └── Effects Volume (HSlider)
│   ├── Gameplay Tab
│   │   ├── Difficulty (OptionButton)
│   │   ├── Sensitivity (HSlider)
│   │   ├── Invert X (CheckButton)
│   │   └── Invert Y (CheckButton)
│   └── Controls Tab
│       └── Key Rebinding
└── Button Container
    ├── Apply Button
    └── Close Button

Player Integration
├── PlayerConfig (settings storage)
├── Player.gd (loads settings on _ready)
└── CameraController (applies invert settings)
```

## Core Components

### GameSettings (game_settings.gd)

**Location:** `src/globals/game_settings.gd`

An autoload singleton that manages all game settings, persistence, and application.

**Responsibilities:**
- Store all settings in memory (graphics, audio, gameplay)
- Load settings from disk on startup
- Save settings to disk when requested
- Apply graphics settings (window mode, resolution)
- Apply audio settings (bus volumes via AudioServer)
- Provide global access to settings for all systems

**Key Methods:**
- `load_settings()` - Loads settings from `user://settings.cfg` using ConfigFile
- `save_settings()` - Saves all settings to `user://settings.cfg`
- `apply_graphics_settings()` - Applies window mode and resolution via DisplayServer
- `apply_audio_settings()` - Updates AudioServer bus volumes for Master/Music/Effects
- `set_bus_volume(bus_name, volume)` - Converts 0-100 range to dB and sets bus volume

**Settings Storage:**

Graphics:
- `screen_mode` (int) - DisplayServer window mode (0=Windowed, 1=Fullscreen, 3=Borderless)
- `resolution` (Vector2i) - Window resolution (default: 1920x1080)

Audio (0-100 range, converted to dB):
- `master_volume` (float) - Master bus volume (default: 50.0)
- `music_volume` (float) - Music bus volume (default: 50.0)
- `effects_volume` (float) - Effects bus volume (default: 50.0)

Gameplay:
- `difficulty` (String) - Game difficulty (default: "Normal")
- `mouse_sensitivity` (float) - Camera sensitivity (default: 0.003)
- `invert_camera_x` (bool) - Invert horizontal camera (default: false)
- `invert_camera_y` (bool) - Invert vertical camera (default: false)

**Volume Conversion:**
```gdscript
# Convert 0-100 slider value to dB (-80 to 0)
var db = linear_to_db(volume / 100.0)
AudioServer.set_bus_volume_db(bus_index, db)
```

**File Format:**
Settings are stored in INI-style format at `user://settings.cfg`:
```ini
[graphics]
screen_mode=0
resolution_x=1920
resolution_y=1080

[audio]
master_volume=50.0
music_volume=50.0
effects_volume=50.0

[gameplay]
difficulty="Normal"
mouse_sensitivity=0.003
invert_camera_x=false
invert_camera_y=false
```

### OptionsScreen (options_screen.gd)

**Location:** `src/ui/screens/options_screen.gd`

The UI controller for the options menu, managing all settings controls and user interaction.

**Responsibilities:**
- Display current settings in UI controls
- Track temporary settings changes (not saved until Apply)
- Provide live preview for audio settings
- Apply all settings when Apply button is clicked
- Update PlayerConfig when settings are applied
- Save settings to disk

**Key Methods:**
- `load_settings_to_ui()` - Populates UI controls with current GameSettings values
- `_on_screen_mode_item_selected(index)` - Updates temp screen mode setting
- `_on_resolution_item_selected(index)` - Parses resolution string and updates temp setting
- `_on_master_volume_changed(value)` - Updates temp volume and provides live preview
- `_on_music_volume_changed(value)` - Updates temp volume and provides live preview
- `_on_effects_volume_changed(value)` - Updates temp volume and provides live preview
- `_on_sensitivity_changed(value)` - Converts 0-100 slider to 0.001-0.005 sensitivity
- `_on_apply_button_pressed()` - Applies all settings, updates player, saves to disk
- `update_player_config()` - Finds player in scene tree and updates config

**Temporary Settings:**
All settings are stored in temp variables until Apply is clicked:
- `temp_screen_mode`, `temp_resolution`
- `temp_master_volume`, `temp_music_volume`, `temp_effects_volume`
- `temp_difficulty`, `temp_sensitivity`
- `temp_invert_x`, `temp_invert_y`

**UI Controls (@onready references):**
```gdscript
# Graphics
@onready var screen_mode_option: OptionButton
@onready var resolution_option: OptionButton

# Audio
@onready var master_volume_slider: HSlider
@onready var music_volume_slider: HSlider
@onready var effects_volume_slider: HSlider

# Gameplay
@onready var difficulty_option: OptionButton
@onready var sensitivity_slider: HSlider
@onready var invert_x_check: CheckButton
@onready var invert_y_check: CheckButton
```

### PlayerConfig (player_config.gd)

**Location:** `src/player/player_config.gd`

A Resource class storing player configuration including settings-related values.

**Settings-Related Properties:**
- `mouse_sensitivity` (0.002) - Camera rotation sensitivity
- `invert_camera_x` (false) - Invert horizontal camera rotation
- `invert_camera_y` (false) - Invert vertical camera rotation
- `difficulty` ("Normal") - Current difficulty setting

**Integration:**
Player loads these values from GameSettings in `_ready()`:
```gdscript
config.mouse_sensitivity = GameSettings.mouse_sensitivity
config.invert_camera_x = GameSettings.invert_camera_x
config.invert_camera_y = GameSettings.invert_camera_y
config.difficulty = GameSettings.difficulty
```

### CameraController (camera_controller.gd)

**Location:** `src/player/camera_controller.gd`

Handles camera movement and rotation, including invert settings.

**Invert Implementation:**
```gdscript
func rotate_camera(relative: Vector2) -> void:
    # Apply invert settings
    var horizontal_input = relative.x * (-1 if config.invert_camera_x else 1)
    var vertical_input = relative.y * (-1 if config.invert_camera_y else 1)

    # Horizontal rotation (Y axis)
    rotation_y -= horizontal_input * config.mouse_sensitivity
    player.rotation.y = rotation_y

    # Vertical rotation (X axis)
    rotation_x -= vertical_input * config.mouse_sensitivity
    rotation_x = clamp(rotation_x, -PI/2, PI/2)
    camera.rotation.x = rotation_x
```

**Location in code:** `src/player/camera_controller.gd:88-101`

## Settings Categories

### Graphics Settings

| Setting | Type | Default | Options | Description |
|---------|------|---------|---------|-------------|
| Screen Mode | int | 0 (Windowed) | 0=Windowed, 1=Fullscreen, 3=Borderless | Display mode |
| Resolution | Vector2i | 1920x1080 | 1920x1080, 1600x900, 1366x768, 1280x720, 1024x576 | Window/screen resolution |

**Application:**
- Window resizing is disabled (`window/size/resizable=false` in project.godot)
- Resolution changes only through options menu
- Windowed mode centers window on screen
- Fullscreen modes apply resolution before switching mode

### Audio Settings

| Setting | Type | Default | Range | Bus | Description |
|---------|------|---------|-------|-----|-------------|
| Master Volume | float | 50.0 | 0-100 | Master | Overall volume control |
| Music Volume | float | 50.0 | 0-100 | Music | Background music volume |
| Effects Volume | float | 50.0 | 0-100 | Effects | Sound effects volume |

**Audio Bus Structure:**
```
Master (Bus 0)
├── Music (Bus 1)
└── Effects (Bus 2)
```

**Location:** `assets/resources/master_bus.tres`

**Volume Scaling:**
- UI sliders use 0-100 range
- Converted to linear (0.0-1.0): `volume / 100.0`
- Converted to dB (-80 to 0): `linear_to_db(linear)`
- Applied via `AudioServer.set_bus_volume_db()`

**Live Preview:**
Audio sliders provide immediate feedback by calling `GameSettings.set_bus_volume()` on every change, allowing users to hear the effect before applying.

### Gameplay Settings

| Setting | Type | Default | Range/Options | Description |
|---------|------|---------|---------------|-------------|
| Difficulty | String | "Normal" | Easy, Normal, Hard | Game difficulty level |
| Mouse Sensitivity | float | 0.003 | 0.001-0.005 | Camera rotation speed |
| Invert Camera X | bool | false | true/false | Invert horizontal camera |
| Invert Camera Y | bool | false | true/false | Invert vertical camera |

**Sensitivity Conversion:**
- UI slider: 0-100 range
- Actual sensitivity: 0.001-0.005 range
- Conversion formula: `0.001 + (slider_value / 100.0) * (0.005 - 0.001)`
- Reverse formula: `(sensitivity - 0.001) / (0.005 - 0.001) * 100.0`

## Integration Guide

### Accessing Settings from Code

Settings are globally accessible through the GameSettings singleton:

```gdscript
# Get current difficulty
var difficulty = GameSettings.difficulty

# Get current sensitivity
var sensitivity = GameSettings.mouse_sensitivity

# Check if camera is inverted
if GameSettings.invert_camera_y:
    # Handle inverted camera
    pass

# Get audio volume
var music_vol = GameSettings.music_volume
```

### Adding New Settings

To add a new setting to the system:

1. **Add variable to GameSettings:**
```gdscript
# In src/globals/game_settings.gd
var new_setting: float = 10.0
```

2. **Add to load_settings():**
```gdscript
new_setting = config.get_value("category", "new_setting", 10.0)
```

3. **Add to save_settings():**
```gdscript
config.set_value("category", "new_setting", new_setting)
```

4. **Add UI control to options_screen.tscn:**
   - Add HSlider, OptionButton, or CheckButton to appropriate tab
   - Set unique_id for @onready reference

5. **Add @onready reference in options_screen.gd:**
```gdscript
@onready var new_setting_slider: HSlider = $Path/To/Control
```

6. **Connect signal and add handler:**
```gdscript
func _ready() -> void:
    new_setting_slider.value_changed.connect(_on_new_setting_changed)

func _on_new_setting_changed(value: float) -> void:
    temp_new_setting = value
    # Optional: live preview logic
```

7. **Update in _on_apply_button_pressed():**
```gdscript
GameSettings.new_setting = temp_new_setting
```

8. **Load to UI in load_settings_to_ui():**
```gdscript
temp_new_setting = GameSettings.new_setting
new_setting_slider.value = temp_new_setting
```

### Apply Button Workflow

The Apply button follows this sequence:

1. User changes settings in UI → Updates temp variables
2. User clicks Apply → `_on_apply_button_pressed()` called
3. Copy temp variables to GameSettings properties
4. Call `GameSettings.apply_graphics_settings()`
5. Call `GameSettings.apply_audio_settings()`
6. Call `update_player_config()` to sync player
7. Call `GameSettings.save_settings()` to persist to disk

**Code location:** `src/ui/screens/options_screen.gd:155-182`

### Player Integration

When the player spawns, it loads settings from GameSettings:

```gdscript
# In src/player/player.gd _ready()
config.mouse_sensitivity = GameSettings.mouse_sensitivity
config.invert_camera_x = GameSettings.invert_camera_x
config.invert_camera_y = GameSettings.invert_camera_y
config.difficulty = GameSettings.difficulty
```

**Code location:** `src/player/player.gd:60-64`

When Apply is clicked, the OptionsScreen finds the player and updates it:

```gdscript
func update_player_config() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player and player.config:
        player.config.mouse_sensitivity = GameSettings.mouse_sensitivity
        player.config.invert_camera_x = GameSettings.invert_camera_x
        player.config.invert_camera_y = GameSettings.invert_camera_y
        player.config.difficulty = GameSettings.difficulty
```

**Code location:** `src/ui/screens/options_screen.gd:186-194`

## Common Issues and Solutions

### Settings Not Persisting Between Sessions

**Problem:** Settings reset to defaults when restarting the game.

**Solution:** Ensure Apply button is clicked before closing the game. Settings are only saved to disk when Apply is pressed.

### Resolution Not Changing in Fullscreen

**Problem:** Resolution dropdown doesn't affect fullscreen display size.

**Solution:** This is expected behavior on macOS. Fullscreen mode uses native resolution. Use Borderless mode for custom resolutions.

### Camera Not Responding to Sensitivity Changes

**Problem:** Changing sensitivity slider has no effect on camera movement.

**Solution:** Click the Apply button. Sensitivity changes require Apply to update the player config.

### Audio Sliders Not Working

**Problem:** Volume sliders have no effect on audio.

**Solution:** Check that audio buses exist in `assets/resources/master_bus.tres`:
- Bus 0: Master
- Bus 1: Music
- Bus 2: Effects

Ensure AudioStreamPlayers are assigned to the correct bus.

### Settings File Location

**User data location:**
- **Windows:** `%APPDATA%/Godot/app_userdata/[project_name]/`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/[project_name]/`
- **Linux:** `~/.local/share/godot/app_userdata/[project_name]/`

File: `settings.cfg`

## File Reference

```
src/
├── globals/
│   └── game_settings.gd              # Settings singleton
├── player/
│   ├── player.gd                     # Loads settings on startup (line 60-64)
│   ├── player_config.gd              # Settings storage (line 39-40, 56)
│   └── camera_controller.gd          # Invert implementation (line 90-92)
└── ui/
    └── screens/
        ├── options_screen.gd         # Options menu logic
        └── options_screen.tscn       # Options menu UI

assets/
└── resources/
    └── master_bus.tres               # Audio bus layout

project.godot                          # GameSettings autoload (line 22)
```

## Version Information

**Godot Version:** 4.6
**Last Updated:** 2025-03-25
**Template Version:** 1.0
