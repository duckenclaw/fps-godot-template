

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

Weapon stats live on `ItemResource` (`addons/inventory_kit/item_resource.gd`): `grip`,
`speed`, `damage`, `attack_animation`, `range` (melee), and `clip_size` / `accuracy` /
`ammo_type` (ranged). The `.tres` files in `assets/resources/items/` carry the data;
`bolt.tres` is the ammo item consumed by the crossbow.

### Arms rig

The viewmodel is a skinned arms rig, `addons/fps_controller/assets/models/arms/arms.glb`,
exported from `assets/models/fps-arms/arms_rig.blend`. `Hands` (`player/hands.gd`) sits
at the camera origin and instances it so the rig's `camera` bone coincides with the real
camera. The hands camera renders it at a fixed 75 degree FOV (`viewmodel_fov` on
`HandsCamera`), which is what the animations were authored for.

One-handed animation set (actions named `oh_*` in the .blend):
`idle`, `slash_left`, `slash_right`, `slash_down`, `thrust`, `draw`, `sheath`, `block`,
`block_loop`, `parry`, `unblock`, `shoot`, `reload`. Camera motion keyed on the `camera`
bone is replayed on the real camera.

To change or add animations: edit the actions in Blender, select `ArmsRig` + `ArmsMesh`
and export glTF Binary over `arms.glb` with animation mode "Broadcast actions" and
"Always sample animations" on. A different set (e.g. two-handed) can be added under
another prefix and selected with `Hand.anim_set`.

### Holding any model

`RightHand` / `LeftHand` in `player.tscn` are `BoneAttachment3D` sockets on the rig's
`weapon.R` / `weapon.L` bones. Socket axes: **+Y along the blade** (out of the thumb
side of the fist), **-Z where the knuckles face**. The equipped item's `model` scene is
instanced under the socket:
- melee models need their blade along +Y with the grip at the origin;
- ranged models point -Z and are levelled with the camera automatically;
- a Node3D named `Grip` inside the model overrides where the palm goes, and a Node3D
  named `Muzzle` sets where projectiles spawn.

### Two independent hands

Any weapon can go in either hand, and the arms never share an animation. The clips are
authored on the right arm only; at load `Hands` splits each one into a right-arm clip
and a mirrored left-arm clip and plays them on two AnimationPlayers that drive separate
halves of the skeleton (`Hands.anim_player` / `Hands.anim_player_left`). Each `Hand`
runs its own state machine on its own player, so one hand can swing while the other
draws, blocks or reloads. New animations only ever need to be made for the right arm.

### Combat (`player/hand.gd`)

Each hand button (`right_hand`, `left_hand`) uses the weapon in that hand.

| Input | Result |
| --- | --- |
| hand button + moving left | Slash to the left. |
| hand button + moving right | Slash to the right. |
| hand button + moving forward / backward | Thrust (lunges when moving forward; more damage and reach). |
| hand button, standing still | Combo: slash left, slash right, slash down (mirrored for the left hand). |
| pressing again during a swing | Queues the next attack for the swing's cancel point. |
| button of a hand holding no weapon (hold) | Block with the other hand's melee weapon: absorbs `block_damage_reduction` of frontal hits and drains stamina. Out of stamina = guard break. |
| the same button, just before a hit | Parry: no damage, attacker's `on_parried()` is called, next attack within `riposte_window` deals `riposte_multiplier` damage. |
| hand button (ranged) | Fire; the clip reloads automatically when empty. |
| `reload` | Lower the weapon, refill the clip from the inventory, raise it. |

With a weapon in both hands there is no free button to block with.

Hits are a sphere swept from the camera along each attack's blade path during its hit
window (`Hand.ATTACKS`), so fast swings cannot tunnel. Anything in the `enemy` /
`destructible` groups gets `take_damage(amount, player)` and, if it has one,
`apply_knockback(impulse)`. Rigid bodies are shoved; hitting plain geometry sparks and
emits `staggered`. A weapon whose `attack_animation` names an entry in `Hand.ATTACKS`
(e.g. `thrust`) always uses that attack instead of the combo.

Feel: hit-stop, camera punch and shake, blade trail, impact particles, arm bob / sway /
recoil springs, a beat of slow motion on parry. Sounds are synthesised placeholders
(`weapons/combat_sfx.gd`); assign real ones to the `sfx_*` exports on `Hands`. Tuning
lives in the "Combat" group of `PlayerConfig`.

Two-handed weapons equip exclusively to the right hand and force the left hand empty
(`player.gd::equip_from_quick`); they currently reuse the one-handed animations.

`objects/training_dummy.tscn` is a practice enemy: it takes damage, and telegraphs a
blow (club rises, body glows) so blocking and parrying can be tried.

Headless regression test: `godot --path . --headless --script tests/test_weapons.gd`.
