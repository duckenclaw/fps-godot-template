

## Melee weapons

Each Hand should include a CollisionShape3D with a shape of a thin and long cube, as well as an AnimationPlayer3D with different animations for attacks. 
Whenever a player attacks, the Collision Shape should check for any collisions until the animation has ended. If the a collision object is in enemy group, then it receives damage, if it's not "stagger" animation is played.

sword:
- type: melee-weapon
- grip: one-handed
- damage: 15

greatsword [2x4]:
- type: melee-weapon
- grip: two-handed
- damage: 35

