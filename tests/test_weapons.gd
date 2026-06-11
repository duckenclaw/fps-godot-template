extends SceneTree

## Headless verification of the weapon system. Run with:
## godot --path . --headless --script tests/test_weapons.gd

var _failures: int = 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: " + msg)
	else:
		_failures += 1
		print("FAIL: " + msg)

func _initialize() -> void:
	_run()

func _run() -> void:
	_test_resources()
	await _test_inventory()
	await _test_player_weapons()
	print("RESULT: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)

func _test_resources() -> void:
	var sword: ItemResource = load("res://assets/resources/items/sword.tres")
	check(sword.is_melee() and not sword.is_two_handed(), "sword is one-handed melee")
	check(sword.attack_animation == &"right_slash" and sword.range == 1.5 and sword.damage == 15.0, "sword stats")
	var gs: ItemResource = load("res://assets/resources/items/greatsword.tres")
	check(gs.is_melee() and gs.is_two_handed(), "greatsword is two-handed melee")
	check(gs.damage == 35.0 and gs.speed == 0.75 and gs.range == 2.0, "greatsword stats")
	var cb: ItemResource = load("res://assets/resources/items/crossbow.tres")
	check(cb.is_ranged() and cb.is_weapon() and not cb.is_melee(), "crossbow is ranged weapon")
	check(cb.clip_size == 1 and cb.accuracy == 0.95 and cb.ammo_type == &"bolt" and cb.damage == 10.0, "crossbow stats")
	check(cb.attack_animation == &"shoot", "crossbow uses shoot animation")
	var bolt: ItemResource = load("res://assets/resources/items/bolt.tres")
	check(bolt.id == &"bolt" and bolt.max_stack == 20, "bolt ammo item")

func _test_inventory() -> void:
	var inv: Inventory = Inventory.new()
	root.add_child(inv)
	await process_frame  # let _ready size the grid arrays
	var bolt: ItemResource = load("res://assets/resources/items/bolt.tres")
	inv.try_pickup(bolt, 5)
	check(inv.count_item(&"bolt") == 5, "count_item after pickup")
	check(inv.consume_item(&"bolt", 2) == 2 and inv.count_item(&"bolt") == 3, "consume_item partial")
	check(inv.consume_item(&"bolt", 10) == 3 and inv.count_item(&"bolt") == 0, "consume_item clamps to stock")
	inv.queue_free()

func _test_player_weapons() -> void:
	var scene: Node = (load("res://src/test_3D.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame

	var player: Node = scene.get_node("Player")
	var hands: Hands = player.hands
	var rh: Hand = hands.get_right_hand()
	var inv: Inventory = player.inventory

	# -- Melee --
	var sword: ItemResource = load("res://assets/resources/items/sword.tres")
	hands.equip_right_hand(sword)
	check(rh.has_item(), "sword model equipped")
	rh.attack()
	check(rh.melee_hitbox.monitoring, "melee attack enables hitbox monitoring")
	check(rh.anim_player.current_animation == "right_slash", "melee attack plays right_slash")
	for i in 60:
		await physics_frame
	check(not rh.melee_hitbox.monitoring, "hitbox monitoring off after swing")
	check(rh.anim_player.current_animation == "idle", "returns to idle after swing")

	# -- Two-handed exclusivity --
	var gs: ItemResource = load("res://assets/resources/items/greatsword.tres")
	inv.try_pickup(gs, 1)
	inv.try_pickup(sword, 1)
	inv.set_quick(0, inv._find_first_anchor_of(gs))
	inv.set_quick(1, inv._find_first_anchor_of(sword))
	player.equip_from_quick(1)   # sword -> right
	player.equip_from_quick(1)   # sword already right -> swaps to left
	check(player.equipped_left_item == sword, "sword swapped to left hand")
	player.equip_from_quick(0)   # greatsword: two-handed
	check(player.equipped_right_item == gs, "greatsword equips to right hand")
	check(player.equipped_left_item == null, "greatsword clears the left hand")

	# -- Ranged --
	var cb: ItemResource = load("res://assets/resources/items/crossbow.tres")
	var bolt: ItemResource = load("res://assets/resources/items/bolt.tres")
	inv.try_pickup(bolt, 3)
	hands.equip_right_hand(cb)
	check(rh._clip == 1, "crossbow auto-reloads on equip")
	check(inv.count_item(&"bolt") == 2, "reload consumed one bolt")
	rh.attack()
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == 1, "shot spawns a projectile")
	check(rh._clip == 0, "clip empty after shot")
	check(rh.anim_player.current_animation == "shoot", "ranged attack plays shoot")
	rh.attack()  # mid-animation: blocked
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == 1, "cannot fire while attack animation plays")
	for i in 75:  # > RELOAD_DELAY (1s)
		await physics_frame
	check(rh._clip == 1 and inv.count_item(&"bolt") == 1, "auto-reload refills clip from inventory")
	rh.attack()
	rh.reload()
	for i in 75:
		await physics_frame
	check(inv.count_item(&"bolt") == 0, "manual reload consumes last bolt")
	rh.attack()  # fires last loaded bolt
	for i in 5:
		await physics_frame
	for i in 75:
		await physics_frame
	check(rh._clip == 0, "dry: no ammo left to reload")
	var before: int = get_nodes_in_group(&"projectiles").size()
	rh.attack()  # dry fire
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == before, "dry fire spawns nothing")

	# Projectiles should have stuck or flown away; all spawned ones exist in world
	check(before >= 2, "multiple projectiles existed in world")
