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

func frames(n: int) -> void:
	for i in n:
		await physics_frame

## Wait until `cond` is true (or `max_frames` pass); returns whether it became true.
func until(cond: Callable, max_frames: int = 240) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await physics_frame
	return cond.call()

func _test_resources() -> void:
	var sword: ItemResource = load("res://assets/resources/items/sword.tres")
	check(sword.is_melee() and not sword.is_two_handed(), "sword is one-handed melee")
	check(sword.range == 1.5 and sword.damage == 15.0, "sword stats")
	var gs: ItemResource = load("res://assets/resources/items/greatsword.tres")
	check(gs.is_melee() and gs.is_two_handed(), "greatsword is two-handed melee")
	check(gs.damage == 35.0 and gs.speed == 0.75 and gs.range == 2.0, "greatsword stats")
	var cb: ItemResource = load("res://assets/resources/items/crossbow.tres")
	check(cb.is_ranged() and cb.is_weapon() and not cb.is_melee(), "crossbow is ranged weapon")
	check(cb.clip_size == 1 and cb.accuracy == 0.95 and cb.ammo_type == &"bolt" and cb.damage == 10.0, "crossbow stats")
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
	var anim: AnimationPlayer = hands.anim_player
	var inv: Inventory = player.inventory
	var dummy: TrainingDummy = scene.get_node("TrainingDummyPassive")

	# -- Arms rig --
	check(hands.skeleton != null and anim != null, "arms rig found")
	for clip in ["idle", "slash_left", "slash_right", "slash_down", "thrust", "draw", "sheath",
			"block", "block_loop", "parry", "unblock", "shoot", "reload"]:
		check(anim.has_animation("oh_" + clip), "animation oh_%s exists" % clip)
	check(rh.state == Hand.HandState.EMPTY and anim.current_animation == "relax", "unarmed hands idle")

	# -- Draw --
	var sword: ItemResource = load("res://assets/resources/items/sword.tres")
	hands.equip_right_hand(sword)
	check(rh.has_item() and rh.get_equipped_item() != null, "sword model equipped")
	check(rh.state == Hand.HandState.DRAW and anim.current_animation == "oh_draw", "equip plays draw")
	check(await until(func() -> bool: return rh.state == Hand.HandState.IDLE), "draw ends in idle")
	check(anim.current_animation == "oh_idle", "idle loop plays")

	# -- Melee combo --
	player.global_position = dummy.global_position + Vector3(0, 0.1, 1.5)  # face the dummy (-Z)
	await frames(10)
	var hp: float = dummy.health.current_health
	rh.attack()
	check(rh.state == Hand.HandState.ATTACK and anim.current_animation == "oh_slash_left", "first attack is slash_left")
	rh.attack()  # buffered: chains when the first swing reaches its cancel point
	check(await until(func() -> bool: return anim.current_animation == "oh_slash_right"), "buffered press chains into slash_right")
	check(dummy.health.current_health == hp - sword.damage, "first slash damaged the dummy once")
	check(await until(func() -> bool: return rh.state == Hand.HandState.IDLE), "returns to idle after the combo")
	check(dummy.health.current_health == hp - sword.damage * 2.0, "second slash damaged the dummy once")

	# -- Block / parry --
	player.stamina = player.max_stamina
	hands.use_left_hand()
	check(hands.is_blocking(), "left hand raises the guard")
	await frames(30)  # past the parry window
	var h0: float = player.health
	player.take_damage(20.0, dummy)
	check(is_equal_approx(player.health, h0 - 20.0 * (1.0 - player.config.block_damage_reduction)), "block absorbs most of a frontal hit")
	check(player.stamina < player.max_stamina, "blocking drains stamina")
	hands.release_left_hand()
	check(not hands.is_blocking(), "releasing lowers the guard")
	await frames(40)
	hands.use_left_hand()
	h0 = player.health
	player.take_damage(20.0, dummy)  # inside the parry window
	check(player.health == h0 and rh.state == Hand.HandState.PARRY, "a just-raised guard parries")
	hp = dummy.health.current_health
	rh.attack()  # riposte
	await until(func() -> bool: return dummy.health.current_health < hp)
	check(is_equal_approx(dummy.health.current_health, hp - sword.damage * player.config.riposte_multiplier), "riposte deals bonus damage")
	hands.release_left_hand()
	await until(func() -> bool: return rh.state == Hand.HandState.IDLE)
	Engine.time_scale = 1.0
	h0 = player.health
	player.take_damage(10.0, dummy)
	check(player.health == h0 - 10.0, "unguarded hits land in full")

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
	check(rh._clip == 1, "crossbow comes up loaded")
	check(inv.count_item(&"bolt") == 2, "loading consumed one bolt")
	check(await until(func() -> bool: return rh.state == Hand.HandState.IDLE and rh.current_item_resource == cb and rh.get_equipped_item() != null), "weapon swap sheathes then draws")
	rh.attack()
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == 1, "shot spawns a projectile")
	check(rh._clip == 0 and anim.current_animation == "oh_shoot", "shot empties the clip and plays shoot")
	rh.attack()  # mid-animation: ignored
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == 1, "cannot fire while the shot animation plays")
	check(await until(func() -> bool: return anim.current_animation == "oh_reload"), "auto-reload starts after the shot")
	check(await until(func() -> bool: return rh._clip == 1 and rh.state == Hand.HandState.IDLE), "reload refills the clip")
	check(inv.count_item(&"bolt") == 1, "reload consumed one bolt")
	rh.attack()
	await until(func() -> bool: return rh._clip == 1 and rh.state == Hand.HandState.IDLE)
	check(inv.count_item(&"bolt") == 0, "second reload consumes the last bolt")
	rh.attack()  # fires the last loaded bolt
	await until(func() -> bool: return rh.state == Hand.HandState.IDLE)
	await frames(10)
	check(rh._clip == 0 and rh.state == Hand.HandState.IDLE, "no ammo left: stays unloaded")
	var before: int = get_nodes_in_group(&"projectiles").size()
	rh.attack()  # dry fire
	await physics_frame
	check(get_nodes_in_group(&"projectiles").size() == before, "dry fire spawns nothing")

	# -- Sheath --
	hands.unequip_right_hand()
	check(await until(func() -> bool: return rh.state == Hand.HandState.EMPTY), "unequip sheathes to empty hands")
	check(not rh.has_item(), "no item after sheath")

	# -- Independent hands --
	var lh: Hand = hands.get_left_hand()
	var anim_l: AnimationPlayer = hands.anim_player_left
	check(anim_l != null and anim_l != anim, "left arm has its own animation player")
	hands.equip_left_hand(sword)
	check(lh.state == Hand.HandState.DRAW and anim_l.current_animation == "oh_draw", "left hand draws on its own")
	check(rh.state == Hand.HandState.EMPTY and anim.current_animation == "relax", "right arm is unaffected")
	await until(func() -> bool: return lh.state == Hand.HandState.IDLE)
	hands.use_right_hand()  # right hand is empty: its button guards with the left weapon
	check(lh.is_blocking() and hands.is_blocking(), "empty hand's button blocks with the other weapon")
	hands.release_right_hand()
	check(not hands.is_blocking(), "releasing it lowers the guard")
	await until(func() -> bool: return lh.state == Hand.HandState.IDLE and lh.current_clip() == &"idle")
	player.global_position = dummy.global_position + Vector3(0, 0.1, 1.5)
	await frames(10)
	hp = dummy.health.current_health
	hands.use_left_hand()
	check(lh.state == Hand.HandState.ATTACK and rh.state == Hand.HandState.EMPTY, "left button attacks with the left hand only")
	await until(func() -> bool: return lh.state == Hand.HandState.IDLE)
	check(dummy.health.current_health == hp - sword.damage, "left-hand slash damages the dummy")

	# -- Movement picks the attack --
	hands.equip_right_hand(sword)
	await until(func() -> bool: return rh.state == Hand.HandState.IDLE)
	for dir in [["left", &"slash_left", &"slash_right"], ["right", &"slash_right", &"slash_left"],
			["forward", &"thrust", &"thrust"], ["backward", &"thrust", &"thrust"]]:
		Input.action_press(dir[0])
		rh.attack()
		lh.attack()
		# The left hand plays mirrored clips, so its left/right clip names swap.
		check(rh.current_clip() == dir[1] and lh.current_clip() == dir[2], "moving %s picks the matching attack" % dir[0])
		Input.action_release(dir[0])
		await until(func() -> bool: return rh.state == Hand.HandState.IDLE and lh.state == Hand.HandState.IDLE)
	await frames(60)  # let the combo reset
	rh.attack()
	check(rh.current_clip() == &"slash_left", "standing still starts the combo")
	Input.action_press("left")
	rh.attack()  # queued: same direction again
	await until(func() -> bool: return anim.current_animation == "oh_slash_left_b")
	check(anim.current_animation == "oh_slash_left_b", "repeating an attack cross-fades into its twin clip")
	Input.action_release("left")
