extends Node
## Global settings manager for game configuration
## Handles saving/loading settings and applying audio configuration

const SETTINGS_PATH = "user://settings.cfg"

# Graphics settings
var screen_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync_enabled: bool = true
var brightness: float = 50.0  # 0-100 range
var field_of_view: float = 90.0  # 60-120 range

# Audio settings (0-100 range for sliders, converted to dB)
var master_volume: float = 50.0
var music_volume: float = 50.0
var effects_volume: float = 50.0

# Gameplay settings
var difficulty: String = "Normal"
var mouse_sensitivity: float = 0.003
var invert_camera_x: bool = false
var invert_camera_y: bool = false


func _ready() -> void:
	load_settings()
	apply_graphics_settings()
	apply_audio_settings()
	apply_vsync()
	apply_brightness()


## Load settings from config file
func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)

	if error != OK:
		print("No settings file found, using defaults")
		return

	# Graphics
	screen_mode = config.get_value("graphics", "screen_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	var res_x = config.get_value("graphics", "resolution_x", 1920)
	var res_y = config.get_value("graphics", "resolution_y", 1080)
	resolution = Vector2i(res_x, res_y)
	vsync_enabled = config.get_value("graphics", "vsync_enabled", true)
	brightness = config.get_value("graphics", "brightness", 50.0)
	field_of_view = config.get_value("graphics", "field_of_view", 90.0)

	# Audio
	master_volume = config.get_value("audio", "master_volume", 50.0)
	music_volume = config.get_value("audio", "music_volume", 50.0)
	effects_volume = config.get_value("audio", "effects_volume", 50.0)

	# Gameplay
	difficulty = config.get_value("gameplay", "difficulty", "Normal")
	mouse_sensitivity = config.get_value("gameplay", "mouse_sensitivity", 0.003)
	invert_camera_x = config.get_value("gameplay", "invert_camera_x", false)
	invert_camera_y = config.get_value("gameplay", "invert_camera_y", false)

	print("Settings loaded successfully")


## Save settings to config file
func save_settings() -> void:
	var config = ConfigFile.new()

	# Graphics
	config.set_value("graphics", "screen_mode", screen_mode)
	config.set_value("graphics", "resolution_x", resolution.x)
	config.set_value("graphics", "resolution_y", resolution.y)
	config.set_value("graphics", "vsync_enabled", vsync_enabled)
	config.set_value("graphics", "brightness", brightness)
	config.set_value("graphics", "field_of_view", field_of_view)

	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)

	# Gameplay
	config.set_value("gameplay", "difficulty", difficulty)
	config.set_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "invert_camera_x", invert_camera_x)
	config.set_value("gameplay", "invert_camera_y", invert_camera_y)

	var error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Failed to save settings: " + str(error))
	else:
		print("Settings saved successfully")


## Apply audio settings to AudioServer buses
func apply_audio_settings() -> void:
	set_bus_volume("Master", master_volume)
	set_bus_volume("Music", music_volume)
	set_bus_volume("Effects", effects_volume)


## Convert slider value (0-100) to dB and apply to bus
func set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_error("Audio bus not found: " + bus_name)
		return

	# Convert 0-100 range to dB (-80 to 0)
	# 0 = -80dB (muted), 50 = ~-10dB, 100 = 0dB (full volume)
	var db = linear_to_db(volume / 100.0)
	AudioServer.set_bus_volume_db(bus_index, db)


## Apply graphics settings (window mode and resolution)
func apply_graphics_settings() -> void:
	# Set window mode first
	DisplayServer.window_set_mode(screen_mode)

	# For windowed mode, set resolution and center window
	if screen_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)
		# Center the window on screen
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)
	# For fullscreen modes, resolution is handled by the display mode
	elif screen_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or screen_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		# Set size before fullscreen to ensure correct resolution
		DisplayServer.window_set_size(resolution)

	print("Graphics settings applied: mode=%d, resolution=%s" % [screen_mode, resolution])


## Apply VSync setting
func apply_vsync() -> void:
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	print("VSync %s" % ("enabled" if vsync_enabled else "disabled"))


## Apply brightness setting
func apply_brightness() -> void:
	# Brightness is applied via WorldEnvironment in the scene
	# This function updates the global value which scenes can reference
	# The actual application happens in the camera or environment setup
	pass


## Get brightness adjustment value (for use by scenes)
func get_brightness_adjustment() -> float:
	# Convert 0-100 slider to 0.0-2.0 multiplier (50 = 1.0, no change)
	return brightness / 50.0


## Apply FOV to a camera
func apply_fov_to_camera(camera: Camera3D) -> void:
	if camera:
		camera.fov = field_of_view
		print("FOV set to %d" % field_of_view)
