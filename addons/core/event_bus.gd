extends Node
## Global signal hub for decoupled gameplay communication.
##
## Autoloaded as "EventBus" by the FP Framework plugin. Any system can emit or
## connect to these signals without holding a reference to the other side, which
## keeps the HUD, audio, VFX and gameplay layers loosely coupled.
##
## Keep this file SIGNAL-ONLY — no state, no logic. That prevents it from slowly
## turning into a god object.

# --- Combat / entities -------------------------------------------------------

## Emitted whenever any entity takes damage. `source` may be null (e.g. fall damage).
signal damage_dealt(target: Node, amount: float, source: Node)

## Emitted when an entity's health reaches zero.
signal entity_died(entity: Node)

# --- Inventory / items -------------------------------------------------------

## Emitted when an item is successfully picked up into an inventory.
signal item_picked_up(item: Resource, count: int)

# --- Scene / level lifecycle -------------------------------------------------

## Emitted by SceneManager right before a scene change begins (after fade-out start).
signal level_loading(path: String)

## Emitted by SceneManager once the new scene is in the tree and faded in.
signal level_loaded(path: String)

# --- Settings ----------------------------------------------------------------

## Emitted when a runtime setting changes (e.g. locale), so listeners can react.
signal setting_changed(key: String, value: Variant)
