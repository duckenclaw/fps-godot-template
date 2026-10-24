extends SettingsManager
## FPS template settings autoload (registered as "GameSettings").
##
## All persistence and apply logic lives in SettingsManager (addons/settings_kit).
## This subclass only supplies this game's rebindable action list; a 2D or
## top-down template would ship its own list here and inherit everything else.

## Actions this game exposes in the Controls/Controller rebind UI and persists.
const FPS_REBINDABLE_ACTIONS: Array[String] = [
	"forward", "backward", "left", "right",
	"jump", "dash", "sprint", "crouch",
	"interact", "inventory", "reload",
	"tilt_left", "tilt_right",
	"right_hand", "left_hand",
	"equip_1", "equip_2", "equip_3", "equip_4",
	"equip_5", "equip_6", "equip_7", "equip_8",
]


func _ready() -> void:
	# Supply the action list before the base _ready() runs load_keybinds().
	rebindable_actions = FPS_REBINDABLE_ACTIONS
	super()
