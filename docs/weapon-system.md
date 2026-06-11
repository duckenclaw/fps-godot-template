

## Melee weapons

Each Hand should include a CollisionShape3D with a shape of a thin and long cube, as well as an AnimationPlayer3D with different animations for attacks. 
Whenever a player attacks, the Collision Shape should check for any collisions until the animation has ended. If the a collision object is in enemy group, then it receives damage, if it's not "stagger" animation is played.

sword:
- type: melee-weapon
- grip: one-handed
- damage: 15
- range: 1.5
- speed: 1.0

greatsword [2x4]:
- type: melee-weapon
- grip: two-handed
- damage: 35
- range: 2.0
- speed: 0.75


## Ranged weapons

crossbow:
- type: ranged-weapon
- grip: one-handed
- damage: 10
- clip-size: 1
- accuracy: 0.95 (the lower the percentage the more the RayCast should tilt)
- ammo-type: bolt

## Implementation

Weapon stats live on `ItemResource` (`src/items/item_resource.gd`): `grip`, `speed`,
`damage`, `attack_animation`, `range` (melee), and `clip_size` / `accuracy` /
`ammo_type` (ranged). The `.tres` files in `assets/resources/items/` carry the data;
`bolt.tres` is the ammo item consumed by the crossbow.

`Hand` (`src/player/hand.gd`) drives attacks through the authored scene nodes in
`player.tscn`:
- Melee: plays the weapon's `attack_animation` (e.g. `right_slash`) on
  `RightHandAnimationPlayer` scaled by `speed`, enables `MeleeHitboxArea3D`
  monitoring for the swing, and damages bodies in the `enemy`/`destructible`
  groups via `take_damage()`. The hitbox is stretched to the weapon's `range`
  on equip. Hitting plain world geometry ends the swing early (`staggered`).
- Ranged: requires a loaded clip; each reload consumes `ammo_type` items from
  the player inventory (`Inventory.consume_item`). Firing plays the `shoot`
  animation and spawns a `BoltProjectile` (`src/weapons/bolt_projectile.tscn`)
  whose direction is tilted inside a cone of `(1 - accuracy) * 20°`. Bolts fly
  straight (raycast-stepped), damage `enemy`/`destructible` on impact, then
  stick in place; they despawn past 100 m or when more than 24 exist. The clip
  auto-refills 1 s after emptying; `reload` (R) refills manually.

Two-handed weapons equip exclusively to the right hand and force the left hand
empty (`player.gd::equip_from_quick`). Only the right hand has animations and a
melee hitbox; left-hand melee is inert and left-hand ranged fires without an
animation.

`Hands` (`src/player/hands.gd`) adds inertia: the hands node trails the camera's
per-frame rotation by a few degrees and eases back. The hands always render on
top of world geometry: every hand/weapon visual sits on render layer 2, which
the main camera culls; a `SubViewport` + overlay camera (`hands_camera.gd`,
composited through the `HandsLayer` CanvasLayer) draws only that layer above
the world but below the HUD.

Headless regression test: `godot --path . --headless --script tests/test_weapons.gd`.