@tool
extends EditorPlugin
## Inventory Kit editor plugin.
##
## Library addon: ships the ItemResource, ItemDB, Inventory and InventorySlot
## classes (all global via class_name) for direct use, so there is nothing to
## auto-register. The plugin entry exists only so the addon can be enabled/disabled
## and published to the Asset Library.
##
## Point ItemDB at your items folder if it isn't the default:
##     ItemDB.items_dir = "res://data/items"
