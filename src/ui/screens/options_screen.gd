extends Control
## Options screen for managing game settings
## Settings are applied when the Apply button is clicked

signal close_options()

# Graphics controls
@onready var screen_mode_option: OptionButton = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/ScreenMode/OptionButton
@onready var resolution_option: OptionButton = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/Resolution/OptionButton
@onready var vsync_check: CheckButton = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/VSync/CheckButton
@onready var brightness_slider: HSlider = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/Brightness/HSlider
@onready var brightness_label: Label = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/Brightness/Value
@onready var fov_slider: HSlider = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/FieldOfView/HSlider
@onready var fov_label: Label = $MarginContainer/OptionsContainer/Graphics/MarginContainer/FlowContainer/FieldOfView/Value

# Audio controls
@onready var master_volume_slider: HSlider = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Master/HSlider
@onready var master_volume_label: Label = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Master/Value
@onready var music_volume_slider: HSlider = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Music/HSlider
@onready var music_volume_label: Label = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Music/Value
@onready var effects_volume_slider: HSlider = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Effects/HSlider
@onready var effects_volume_label: Label = $MarginContainer/OptionsContainer/Audio/MarginContainer/FlowContainer/Effects/Value

# Gameplay controls
@onready var difficulty_option: OptionButton = $MarginContainer/OptionsContainer/Gameplay/MarginContainer/FlowContainer/Difficulty/OptionButton
@onready var sensitivity_slider: HSlider = $MarginContainer/OptionsContainer/Gameplay/MarginContainer/FlowContainer/CameraSensitivity/HSlider
@onready var sensitivity_label: Label = $MarginContainer/OptionsContainer/Gameplay/MarginContainer/FlowContainer/CameraSensitivity/Value
@onready var invert_x_check: CheckButton = $MarginContainer/OptionsContainer/Gameplay/MarginContainer/FlowContainer/InvertX/CheckButton
@onready var invert_y_check: CheckButton = $MarginContainer/OptionsContainer/Gameplay/MarginContainer/FlowContainer/InvertY/CheckButton

# Temporary settings (not saved until Apply is clicked)
var temp_screen_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var temp_resolution: Vector2i = Vector2i(1920, 1080)
var temp_vsync_enabled: bool = true
var temp_brightness: float = 50.0
var temp_fov: float = 90.0
var temp_master_volume: float = 50.0
var temp_music_volume: float = 50.0
var temp_effects_volume: float = 50.0
var temp_difficulty: String = "Normal"
var temp_sensitivity: float = 0.003
var temp_invert_x: bool = false
var temp_invert_y: bool = false


func _ready() -> void:
	# Connect slider signals for live preview
	brightness_slider.value_changed.connect(_on_brightness_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	effects_volume_slider.value_changed.connect(_on_effects_volume_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	# Load current settings from GameSettings
	load_settings_to_ui()


## Load settings from GameSettings singleton and update UI
func load_settings_to_ui() -> void:
	# Graphics
	temp_screen_mode = GameSettings.screen_mode
	temp_resolution = GameSettings.resolution
	temp_vsync_enabled = GameSettings.vsync_enabled
	temp_brightness = GameSettings.brightness
	temp_fov = GameSettings.field_of_view

	# Set screen mode dropdown
	match temp_screen_mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			screen_mode_option.selected = 0
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			screen_mode_option.selected = 1
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			screen_mode_option.selected = 2

	# Set resolution dropdown
	var resolution_text = "%dx%d" % [temp_resolution.x, temp_resolution.y]
	for i in resolution_option.item_count:
		if resolution_option.get_item_text(i) == resolution_text:
			resolution_option.selected = i
			break

	# Set VSync checkbox
	vsync_check.button_pressed = temp_vsync_enabled

	# Set brightness slider
	brightness_slider.value = temp_brightness
	brightness_label.text = "%d%%" % temp_brightness

	# Set FOV slider
	fov_slider.value = temp_fov
	fov_label.text = "%d" % temp_fov

	# Audio
	temp_master_volume = GameSettings.master_volume
	temp_music_volume = GameSettings.music_volume
	temp_effects_volume = GameSettings.effects_volume

	master_volume_slider.value = temp_master_volume
	master_volume_label.text = "%d%%" % temp_master_volume
	music_volume_slider.value = temp_music_volume
	music_volume_label.text = "%d%%" % temp_music_volume
	effects_volume_slider.value = temp_effects_volume
	effects_volume_label.text = "%d%%" % temp_effects_volume

	# Gameplay
	temp_difficulty = GameSettings.difficulty
	temp_sensitivity = GameSettings.mouse_sensitivity
	temp_invert_x = GameSettings.invert_camera_x
	temp_invert_y = GameSettings.invert_camera_y

	# Set difficulty dropdown
	for i in difficulty_option.item_count:
		if difficulty_option.get_item_text(i) == temp_difficulty:
			difficulty_option.selected = i
			break

	# Convert sensitivity from 0.001-0.005 range to 0-100 slider range
	var sensitivity_percent = (temp_sensitivity - 0.001) / (0.005 - 0.001) * 100.0
	sensitivity_slider.value = sensitivity_percent
	sensitivity_label.text = "%d%%" % sensitivity_percent

	invert_x_check.button_pressed = temp_invert_x
	invert_y_check.button_pressed = temp_invert_y


## Graphics: Screen mode changed
func _on_screen_mode_item_selected(index: int) -> void:
	match index:
		0:  # Windowed
			temp_screen_mode = DisplayServer.WINDOW_MODE_WINDOWED
		1:  # Fullscreen
			temp_screen_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		2:  # Borderless
			temp_screen_mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Graphics: Resolution changed
func _on_resolution_item_selected(index: int) -> void:
	var resolution_text = resolution_option.get_item_text(index)
	var parts = resolution_text.split("x")
	if parts.size() == 2:
		temp_resolution = Vector2i(int(parts[0]), int(parts[1]))


## Graphics: Brightness changed
func _on_brightness_changed(value: float) -> void:
	temp_brightness = value
	brightness_label.text = "%d%%" % value


## Graphics: FOV changed
func _on_fov_changed(value: float) -> void:
	temp_fov = value
	fov_label.text = "%d" % value


## Audio: Master volume changed (live preview)
func _on_master_volume_changed(value: float) -> void:
	temp_master_volume = value
	master_volume_label.text = "%d%%" % value
	# Live preview
	GameSettings.set_bus_volume("Master", value)


## Audio: Music volume changed (live preview)
func _on_music_volume_changed(value: float) -> void:
	temp_music_volume = value
	music_volume_label.text = "%d%%" % value
	# Live preview
	GameSettings.set_bus_volume("Music", value)


## Audio: Effects volume changed (live preview)
func _on_effects_volume_changed(value: float) -> void:
	temp_effects_volume = value
	effects_volume_label.text = "%d%%" % value
	# Live preview
	GameSettings.set_bus_volume("Effects", value)


## Gameplay: Sensitivity changed
func _on_sensitivity_changed(value: float) -> void:
	sensitivity_label.text = "%d%%" % value
	# Convert 0-100 slider range to 0.001-0.005 sensitivity range
	temp_sensitivity = 0.001 + (value / 100.0) * (0.005 - 0.001)


## Apply button: Save all settings
func _on_apply_button_pressed() -> void:
	# Update GameSettings with all temp values
	GameSettings.screen_mode = temp_screen_mode
	GameSettings.resolution = temp_resolution
	GameSettings.vsync_enabled = vsync_check.button_pressed
	GameSettings.brightness = temp_brightness
	GameSettings.field_of_view = temp_fov
	GameSettings.master_volume = temp_master_volume
	GameSettings.music_volume = temp_music_volume
	GameSettings.effects_volume = temp_effects_volume
	GameSettings.difficulty = temp_difficulty
	GameSettings.mouse_sensitivity = temp_sensitivity
	GameSettings.invert_camera_x = invert_x_check.button_pressed
	GameSettings.invert_camera_y = invert_y_check.button_pressed

	# Get difficulty from dropdown
	GameSettings.difficulty = difficulty_option.get_item_text(difficulty_option.selected)

	# Apply graphics settings (window mode and resolution)
	GameSettings.apply_graphics_settings()

	# Apply VSync
	GameSettings.apply_vsync()

	# Apply brightness
	GameSettings.apply_brightness()

	# Apply audio settings
	GameSettings.apply_audio_settings()

	# Update player config if player exists
	update_player_config()

	# Save settings to disk
	GameSettings.save_settings()

	print("Settings applied and saved")


## Update player config with new settings
func update_player_config() -> void:
	# Find player in scene tree
	var player = get_tree().get_first_node_in_group("player")
	if player and player.config:
		player.config.mouse_sensitivity = GameSettings.mouse_sensitivity
		player.config.invert_camera_x = GameSettings.invert_camera_x
		player.config.invert_camera_y = GameSettings.invert_camera_y
		player.config.difficulty = GameSettings.difficulty

		# Apply FOV to camera if it exists
		if player.camera_3d:
			GameSettings.apply_fov_to_camera(player.camera_3d)

		print("Player config updated")


## Close button: Close options menu
func _on_close_options_pressed() -> void:
	close_options.emit()
