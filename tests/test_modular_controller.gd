extends SceneTree

## Headless tests for the modular FPS controller: mechanic flags, the walk/run
## toggle, and making optional states removable. Run with:
##   godot --headless --path . --script tests/test_modular_controller.gd

const PLAYER := "res://addons/fps_controller/player/player.tscn"

var _failures := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: " + msg)
	else:
		_failures += 1
		print("FAIL: " + msg)

func _initialize() -> void:
	_run()

func _run() -> void:
	await _test_flags_and_toggle()
	await _test_state_removal()
	print("RESULT: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)

func _spawn_player() -> Node:
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	root.add_child(p)
	await process_frame
	await physics_frame
	return p

func _test_flags_and_toggle() -> void:
	var p := await _spawn_player()
	var sm = p.state_machine

	check(InputMap.has_action("walk_run_toggle"), "walk_run_toggle action auto-registered (Capslock)")

	# Walk/run toggle drives the base speed.
	p.is_running = true
	check(is_equal_approx(p.base_move_speed(), p.config.run_speed), "run mode uses run_speed")
	p.is_running = false
	check(is_equal_approx(p.base_move_speed(), p.config.walk_speed), "walk mode uses walk_speed")
	p.is_running = true

	# StateMachine.has_state.
	check(sm.has_state("MovingState"), "has_state finds a core state")
	check(not sm.has_state("NotAState"), "has_state false for a missing state")

	# Optional mechanics enabled by default (flags on + states present).
	check(p.can_dash(), "dash enabled by default")
	check(p.can_slide(), "slide enabled by default")

	# Turning a flag off disables the mechanic.
	p.config.enable_dash = false
	check(not p.can_dash(), "config.enable_dash=false disables dash")
	p.config.enable_dash = true
	check(p.can_dash(), "re-enabling the flag restores dash")

	p.config.enable_wallrun = false
	check(not p.can_wallrun(), "config.enable_wallrun=false disables wallrun")

	p.free()

func _test_state_removal() -> void:
	# Remove the DashingState node BEFORE the scene enters the tree, so the
	# StateMachine never registers it — the editor-time equivalent of deleting it.
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	var dash := p.get_node_or_null("StateMachine/DashingState")
	check(dash != null, "DashingState present in the default player")
	if dash:
		dash.free()
	root.add_child(p)
	await process_frame
	await physics_frame

	check(not p.state_machine.has_state("DashingState"), "removed DashingState is not registered")
	check(not p.can_dash(), "deleting the DashingState node disables dash (flag still on)")
	check(p.can_slide(), "other mechanics unaffected by removing one state")
	p.free()
