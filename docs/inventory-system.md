Inventory system
- Pickup items into inventory by pressing "interact" action while `interact_raycast` is colliding with an item in group "interactable. If there are identical items in inventory already, check if it's amount is below max-stacks, if it is add it to the stack. Show "Not enough space" if player attempts pickup and there are no more empty slots.
- When pressing `equip_1`, `equip_2`, etc actions, the item in the corresponding slot will be equipped into the right hand if it's type is "weapon", any other type is equipped to the left hand. If the item is chosen but it's already in one of the hands, it equips it into the other hand.
- When an item is equipped it's model is added to the appropriate hand.

create item class @assets/resources/

```
item
- type: string
- weight: float kg
- price: float €
- slots: [width, height]
- icon: png file, stretched to fill width and height
- model: glb file
- max-stack: 1-99 int
```

Inventory UI (@src/ui/screens/inventory_screen.tscn @src/ui/screens/inventory_screen.gd)
- freezes player input processing, shows the cursor.
- inventory grid (8x5) with 8 slots for quick equip. For example you can put a sword from the inventory grid into the first quick equip slot and press 1 outside of inventory to equip it. All slots use @assets/images/slot-bg.png as the background. Quick equip slots don't remove the item from the inventory grid.
- drag and drop controls
- ability to throw items before you when dragging them out of inventory
- ctrl + click takes one item out of a stack
- auto-sort by type on button press
- when hovering over an item, show all it's properties in a tooltip.

Player UI @src/player/player.tscn @src/player/player.gd @src/player/hands.gd @src/player/hand.gd
- add quick equip slots display to the @src/ui/hud.tscn @src/ui/hud.gd. Add a glowing outline to the slot if it's equipped.

There are 3 example items with icons in @assets/images/ and models in @assets/models/

```
sword
- type: weapon
- weight: 3.0kg
- price: 5.0€
- slots: [1, 3]
- icon: assets/images/sword.png
- model: assets/models/sword.glb
- max-stack: 1

crossbow
- type: weapon
- weight: 1.0kg
- price: 2.0€
- slots: [1, 2]
- icon: assets/images/crossbow.png
- model: assets/models/crossbow.glb
- max-stack: 1

potion
- type: consumable
- weight: 0.5kg
- price: 0.75€
- slots: [1, 1]
- icon: assets/images/potion.png
- model: assets/models/potion.glb
- max-stack: 99
```