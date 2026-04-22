Weapon (subclass of item class)
- type: melee-weapon/ranged-weapon (assigns this value in item class)
- grip: one-handed/two-handed
- damage: int
- clip-size: int
- ammo: string

crossbow:
- type: ranged-weapon
- grip: one-handed
- damage: 10
- clip-size: 1
- ammo: bolt

sword:
- type: melee-weapon
- grip: one-handed
- damage: 15

greatsword:
- type: melee-weapon
- grip: two-handed
- damage: 35